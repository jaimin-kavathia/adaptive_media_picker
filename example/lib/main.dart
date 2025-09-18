import 'package:flutter/material.dart';
import 'package:adaptive_media_picker/adaptive_media_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

// This example demonstrates common usage patterns for AdaptiveMediaPicker:
// - Single image from gallery
// - Multiple images from gallery (with a max limit)
// - Single video from gallery
// - Camera requests (which fall back to gallery on web/desktop)

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'adaptive_media_picker example',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const ExampleHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  final AdaptiveMediaPicker _picker = AdaptiveMediaPicker();
  List<PickedMedia> _items = const [];
  String _status = 'Ready';

  bool get _isDesktop => !kIsWeb && (defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux);

  Future<void> _runPick({
    required bool allowMultiple,
    required MediaType mediaType,
    required ImageSource source,
    int? maxImages,
  }) async {
    setState(() => _status = 'Requesting...');

    // The picker handles permissions, limited-access UI, and platform caveats.
    // On web/desktop, ImageSource.camera automatically falls back to gallery.
    final result = await _picker.pickImage(
      context: context,
      options: PickOptions(
        allowMultiple: allowMultiple,
        mediaType: mediaType,
        maxImages: maxImages,
        source: source,
        imageQuality: 80,
        showOpenSettingsDialog: true,
        settingsDialogTitle: 'Permission required',
        settingsDialogMessage: 'Please allow Photos/Camera to continue.',
        settingsButtonLabel: 'Open Settings',
        cancelButtonLabel: 'Cancel',
      ),
    );

    setState(() {
      _items = result.items;
      if (!result.permissionResolution.granted) {
        _status = result.permissionResolution.permanentlyDenied
            ? 'Permission permanently denied. Prompted to open settings.'
            : 'Permission denied.';
      } else if (result.permissionResolution.limited) {
        _status = 'Limited access: selected ${result.items.length} item(s).';
      } else {
        _status = 'Picked ${result.items.length} item(s).';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cameraDisabled = _isDesktop; // Desktop camera not supported without a delegate

    return Scaffold(
      appBar: AppBar(title: const Text('adaptive_media_picker example')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => _runPick(
                    allowMultiple: false,
                    mediaType: MediaType.image,
                    source: ImageSource.gallery,
                  ),
                  child: const Text('Pick image (gallery)'),
                ),
                ElevatedButton(
                  onPressed: () => _runPick(
                    allowMultiple: true,
                    mediaType: MediaType.image,
                    source: ImageSource.gallery,
                    maxImages: 5,
                  ),
                  child: const Text('Pick multiple images (gallery)'),
                ),
                ElevatedButton(
                  onPressed: cameraDisabled
                      ? null
                      : () => _runPick(
                            allowMultiple: false,
                            mediaType: MediaType.image,
                            source: ImageSource.camera,
                          ),
                  child: const Text('Pick image (camera)'),
                ),
                ElevatedButton(
                  onPressed: () => _runPick(
                    allowMultiple: false,
                    mediaType: MediaType.video,
                    source: ImageSource.gallery,
                  ),
                  child: const Text('Pick video (gallery)'),
                ),
                ElevatedButton(
                  onPressed: cameraDisabled
                      ? null
                      : () => _runPick(
                            allowMultiple: false,
                            mediaType: MediaType.video,
                            source: ImageSource.camera,
                          ),
                  child: const Text('Pick video (camera)'),
                ),
              ],
            ),
          ),
          if (cameraDisabled)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Note: On desktop, camera capture is not supported in this package. The call falls back to gallery.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _status,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('No items'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) {
                      final item = _items[i];
                      return Card(
                        child: ListTile(
                          dense: true,
                          title: Text(item.path),
                          subtitle: Text(item.mimeType ?? ''),
                          trailing: (item.width != null && item.height != null)
                              ? Text('${item.width}x${item.height}')
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
