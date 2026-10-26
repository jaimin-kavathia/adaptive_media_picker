import 'package:flutter/material.dart';
import 'package:adaptive_media_picker/adaptive_media_picker.dart';

// This example demonstrates common usage patterns for AdaptiveMediaPicker:
// - An avatar flow: source sheet (camera / gallery / remove), circle crop,
//   front camera and a file size limit
// - Single / multiple images, single / multiple videos, mixed media
// - Typed errors and Android lost-data recovery
// Camera requests fall back to the gallery on web/desktop.

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness brightness) => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: brightness,
      ),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'adaptive_media_picker example',
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      home: ExampleHomePage(
        darkMode: _darkMode,
        onToggleTheme: () => setState(() => _darkMode = !_darkMode),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({
    super.key,
    required this.darkMode,
    required this.onToggleTheme,
  });

  final bool darkMode;
  final VoidCallback onToggleTheme;

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  final AdaptiveMediaPicker _picker = AdaptiveMediaPicker();
  List<PickedMedia> _items = const [];
  PickedMedia? _avatar;
  String _status = 'Ready';

  PickOptions get _baseOptions => PickOptions(
    imageQuality: 85,
    themeBrightness: widget.darkMode ? Brightness.dark : Brightness.light,
    settingsDialogTitle: 'Permission required',
    settingsDialogMessage: 'Please allow Photos/Camera to continue.',
    logTag: 'example',
  );

  @override
  void initState() {
    super.initState();
    // Android may kill the app while the camera is open; recover that pick.
    _picker.recoverLostData().then((result) {
      if (result != null && mounted) _show(result.items, result.error);
    });
  }

  void _show(List<PickedMedia> items, PickError? error) {
    setState(() {
      _items = items;
      _status = switch (error) {
        null => 'Picked ${items.length} item(s).',
        PickError.canceled => 'Canceled.',
        PickError.cropCanceled => 'Crop canceled; kept the original image.',
        PickError.permissionDenied => 'Permission denied.',
        PickError.fileTooLarge => 'That file is too large.',
        PickError.unsupportedType => 'That file type is not supported.',
        PickError.io || PickError.unknown => 'Picking failed (see log).',
      };
    });
  }

  Future<void> _single(
    Future<PickResultSingle> Function() pick, {
    bool avatar = false,
  }) async {
    final result = await pick();
    if (!mounted) return;
    if (avatar) {
      if (result.removeRequested) {
        setState(() {
          _avatar = null;
          _status = 'Avatar removed.';
        });
        return;
      }
      if (result.item != null) setState(() => _avatar = result.item);
    }
    _show([?result.item], result.error);
  }

  Future<void> _multiple(Future<PickResultMultiple> Function() pick) async {
    final result = await pick();
    if (!mounted) return;
    _show(result.items, result.error);
    if (result.rejected.isNotEmpty) {
      setState(() => _status += ' ${result.rejected.length} rejected.');
    }
  }

  Future<void> _pickAvatar() => _single(
    () => _picker.pickImage(
      context: context,
      sourceSheet: SourceSheetOptions(
        title: 'Profile photo',
        removeLabel: _avatar == null ? null : 'Remove photo',
      ),
      options: PickOptions(
        imageQuality: 85,
        wantToCrop: true,
        cropShape: CropShape.circle,
        preferredCameraDevice: CameraDevice.front,
        maxFileSizeBytes: 5 * 1024 * 1024,
        allowedMimeTypes: const ['image/*'],
        themeBrightness: widget.darkMode ? Brightness.dark : Brightness.light,
      ),
    ),
    avatar: true,
  );

  @override
  Widget build(BuildContext context) {
    final options = _baseOptions;
    final actions = <(String, VoidCallback)>[
      (
        'Pick image (gallery)',
        () => _single(
          () => _picker.pickImage(context: context, options: options),
        ),
      ),
      (
        'Pick image (choose source)',
        () => _single(
          () => _picker.pickImage(
            context: context,
            options: options,
            sourceSheet: const SourceSheetOptions(),
          ),
        ),
      ),
      (
        'Pick image (crop 16:9)',
        () => _single(
          () => _picker.pickImage(
            context: context,
            options: PickOptions(
              wantToCrop: true,
              cropAspectRatio: CropAspectRatioOption.ratio16x9,
              themeBrightness: options.themeBrightness,
            ),
          ),
        ),
      ),
      (
        'Pick multiple images (gallery)',
        () => _multiple(
          () => _picker.pickMultiImage(
            context: context,
            options: PickOptions(maxImages: 5, imageQuality: 85),
          ),
        ),
      ),
      (
        'Pick video (gallery)',
        () => _single(
          () => _picker.pickVideo(context: context, options: options),
        ),
      ),
      (
        'Pick video (choose source)',
        () => _single(
          () => _picker.pickVideo(
            context: context,
            sourceSheet: const SourceSheetOptions(),
            options: const PickOptions(maxVideoDuration: Duration(seconds: 10)),
          ),
        ),
      ),
      (
        'Pick multiple videos',
        () => _multiple(
          () => _picker.pickMultiVideo(
            context: context,
            options: const PickOptions(maxImages: 3),
          ),
        ),
      ),
      (
        'Pick photos & videos',
        () => _multiple(
          () => _picker.pickMultipleMedia(
            context: context,
            options: const PickOptions(maxImages: 10),
          ),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Picker Demo'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(widget.darkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: _Avatar(media: _avatar),
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('Tap the avatar to change it')),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, onPressed) in actions)
                FilledButton.tonal(onPressed: onPressed, child: Text(label)),
            ],
          ),
          const SizedBox(height: 16),
          Text(_status, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No items')),
            )
          else
            for (final item in _items) _MediaTile(media: item),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.media});

  final PickedMedia? media;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = CircleAvatar(
      radius: 48,
      backgroundColor: scheme.primaryContainer,
      child: Icon(Icons.person, size: 48, color: scheme.onPrimaryContainer),
    );
    if (media == null) return placeholder;
    return FutureBuilder(
      // readAsBytes works everywhere, including web blob URLs.
      future: media!.readAsBytes(),
      builder: (context, snapshot) => snapshot.hasData
          ? CircleAvatar(
              radius: 48,
              backgroundImage: MemoryImage(snapshot.data!),
            )
          : placeholder,
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.media});

  final PickedMedia media;

  @override
  Widget build(BuildContext context) {
    final size = media.sizeInBytes == null
        ? ''
        : '${(media.sizeInBytes! / 1024).toStringAsFixed(0)} KB';
    final dims = media.width == null ? '' : '${media.width}x${media.height}';
    return Card.filled(
      child: ListTile(
        leading: SizedBox.square(
          dimension: 48,
          child: media.isVideo
              ? const Icon(Icons.movie_outlined)
              : FutureBuilder(
                  future: media.readAsBytes(),
                  builder: (context, snapshot) => snapshot.hasData
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.image_outlined),
                ),
        ),
        title: Text(media.name ?? media.path, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            media.mimeType ?? 'unknown type',
            dims,
            size,
          ].where((s) => s.isNotEmpty).join(' · '),
        ),
      ),
    );
  }
}
