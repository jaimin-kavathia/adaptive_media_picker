import 'package:flutter/material.dart';
import 'package:adaptive_media_picker/adaptive_media_picker.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
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

  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  Future<void> _runPickSingleImage({required ImageSource source}) async {
    setState(() => _status = 'Requesting...');
    final result = await _picker.pickImage(
      context: context,
      options: PickOptions(
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
      if (!result.permissionResolution.granted) {
        _items = const [];
        _status = result.permissionResolution.permanentlyDenied
            ? 'Permission permanently denied. Prompted to open settings.'
            : 'Permission denied.';
      } else {
        _items = result.item == null ? const [] : [result.item!];
      }
      _status = 'Picked ${_items.length} item(s).';

    });
  }

  Future<void> _runPickMultiImage({int? maxImages}) async {
    setState(() => _status = 'Requesting...');
    final result = await _picker.pickMultiImage(
      context: context,
      options: PickOptions(
        maxImages: maxImages,
        source: ImageSource.gallery,
        imageQuality: 80,
        showOpenSettingsDialog: true,
        settingsDialogTitle: 'Permission required',
        settingsDialogMessage: 'Please allow Photos/Camera to continue.',
        settingsButtonLabel: 'Open Settings',
        cancelButtonLabel: 'Cancel',
      ),
    );
    setState(() {
      if (!result.permissionResolution.granted) {
        _items = const [];
        _status = result.permissionResolution.permanentlyDenied
            ? 'Permission permanently denied. Prompted to open settings.'
            : 'Permission denied.';
      } else {
        _items = result.items;
      }
      _status = 'Picked ${_items.length} item(s).';

    });
  }

  Future<void> _runPickVideo({required ImageSource source}) async {
    setState(() => _status = 'Requesting...');
    final result = await _picker.pickVideo(
      context: context,
      options: PickOptions(
        source: source,
        showOpenSettingsDialog: true,
        settingsDialogTitle: 'Permission required',
        settingsDialogMessage: 'Please allow Photos/Camera to continue.',
        settingsButtonLabel: 'Open Settings',
        cancelButtonLabel: 'Cancel',
      ),
    );
    setState(() {
      if (!result.permissionResolution.granted) {
        _items = const [];
        _status = result.permissionResolution.permanentlyDenied
            ? 'Permission permanently denied. Prompted to open settings.'
            : 'Permission denied.';
      } else {
        _items = result.item == null ? const [] : [result.item!];
      }
      _status = 'Picked ${_items.length} item(s).';

    });
  }

  @override
  Widget build(BuildContext context) {
    final cameraDisabled =
        _isDesktop; // Desktop camera not supported without a delegate

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
                  onPressed: () => _runPickSingleImage(source: ImageSource.gallery),
                  child: const Text('Pick image (gallery)'),
                ),
                ElevatedButton(
                  onPressed: () => _runPickMultiImage(maxImages: 5),
                  child: const Text('Pick multiple images (gallery)'),
                ),
                ElevatedButton(
                  onPressed: cameraDisabled
                      ? null
                      : () => _runPickSingleImage(source: ImageSource.camera),
                  child: const Text('Pick image (camera)'),
                ),
                ElevatedButton(
                  onPressed: () => _runPickVideo(source: ImageSource.gallery),
                  child: const Text('Pick video (gallery)'),
                ),
                ElevatedButton(
                  onPressed: cameraDisabled
                      ? null
                      : () => _runPickVideo(source: ImageSource.camera),
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
