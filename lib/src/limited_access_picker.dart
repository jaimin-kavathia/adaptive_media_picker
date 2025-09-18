import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

import 'models.dart';

/// Simple, package-provided limited access picker UI.
/// Apps can provide their own UI by not using this and handling assets directly.
/// Bottom-sheet grid UI used when OS grants limited photo/video access.
class LimitedAccessPicker extends StatefulWidget {
  final bool allowMultiple;
  final int? maxImages;
  final MediaType mediaType;

  const LimitedAccessPicker({
    super.key,
    this.allowMultiple = false,
    this.maxImages,
    this.mediaType = MediaType.image,
  });

  /// Presents the limited-access picker as a modal bottom sheet and returns
  /// selected assets, or `null` if dismissed.
  static Future<List<AssetEntity>?> show({
    required BuildContext context,
    bool allowMultiple = false,
    int? maxImages,
    MediaType mediaType = MediaType.image,
  }) async {
    return await showModalBottomSheet<List<AssetEntity>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.85,
        child: LimitedAccessPicker(
          allowMultiple: allowMultiple,
          maxImages: maxImages,
          mediaType: mediaType,
        ),
      ),
    );
  }

  @override
  State<LimitedAccessPicker> createState() => _LimitedAccessPickerState();
}

class _LimitedAccessPickerState extends State<LimitedAccessPicker> {
  List<AssetEntity> _assets = [];
  final Set<AssetEntity> _selected = {};
  bool _loading = true;
  final Map<String, Uint8List?> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final RequestType requestType = widget.mediaType == MediaType.video
        ? RequestType.video
        : RequestType.image;
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: requestType,
    );
    if (albums.isNotEmpty) {
      final List<AssetEntity> assets = await albums.first.getAssetListRange(
        start: 0,
        end: 500,
      );
      final filtered = assets
          .where(
            (a) => widget.mediaType == MediaType.video
                ? a.type == AssetType.video
                : a.type == AssetType.image,
          )
          .toList();
      if (filtered.isEmpty) {
        // Limited access likely has no selected items; offer to manage limited selection or open settings
        await _promptManageLimited(requestType);
      }
      setState(() {
        _assets = filtered;
        _loading = false;
      });
    } else {
      // No albums; in limited mode, allow user to adjust
      await _promptManageLimited(requestType);
      setState(() => _loading = false);
    }
  }

  Future<void> _promptManageLimited(RequestType type) async {
    final isVideo = widget.mediaType == MediaType.video;
    final bool isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final bool isMacOS =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    final platformMessage = isIOS
        ? 'Go to: Settings > App > Photos > Limited Access > Select ${isVideo ? 'videos' : 'images'} to share with this app.'
        : isMacOS
        ? 'Go to: System Settings > Privacy & Security > Photos > Enable access for this app. Then select ${isVideo ? 'videos' : 'images'}.'
        : 'Go to: Settings > Apps > This app > Permissions > Photos and Videos > Select limited ${isVideo ? 'videos' : 'images'} for this app.';

    final action = await showDialog<_LimitedAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isVideo ? 'No videos available' : 'No images available'),
        content: Text(
          (isIOS || isMacOS)
              ? 'You are in limited access mode. $platformMessage'
              : 'No ${isVideo ? 'videos' : 'images'} found under limited access. $platformMessage',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_LimitedAction.cancel),
            child: const Text('Cancel'),
          ),
          if (isIOS || isMacOS)
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(_LimitedAction.manageLimited),
              child: const Text('Manage Selection'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_LimitedAction.openSettings),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    switch (action) {
      case _LimitedAction.manageLimited:
        if (isIOS) {
          await PhotoManager.presentLimited(type: type);
          await Future.delayed(const Duration(milliseconds: 300));
          // Reload after user adjusted selection
          final List<AssetPathEntity> albums =
              await PhotoManager.getAssetPathList(onlyAll: true, type: type);
          if (albums.isNotEmpty) {
            final List<AssetEntity> assets = await albums.first
                .getAssetListRange(start: 0, end: 500);
            setState(() {
              _assets = assets
                  .where(
                    (a) => widget.mediaType == MediaType.video
                        ? a.type == AssetType.video
                        : a.type == AssetType.image,
                  )
                  .toList();
            });
          }
        } else if (isMacOS) {
          // macOS does not show presentLimited; open settings instead and close sheet
          await openAppSettings();
          if (mounted) Navigator.of(context).pop(null);
        }
        break;
      case _LimitedAction.openSettings:
        await openAppSettings();
        if (mounted) Navigator.of(context).pop(null);
        break;
      case _LimitedAction.cancel:
      default:
        break;
    }
  }

  void _toggle(AssetEntity asset) {
    if (!widget.allowMultiple) {
      Navigator.of(context).pop(<AssetEntity>[asset]);
      return;
    }
    final bool isSelected = _selected.contains(asset);
    if (isSelected) {
      setState(() {
        _selected.remove(asset);
      });
    } else {
      if (widget.maxImages == null || _selected.length < widget.maxImages!) {
        setState(() {
          _selected.add(asset);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mediaType == MediaType.video
              ? 'Select videos'
              : 'Select images',
        ),
        actions: [
          if (widget.allowMultiple)
            TextButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_selected.toList()),
              child: const Text('Done'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
          ? Center(
              child: Text(
                'No ${widget.mediaType == MediaType.video ? 'videos' : 'images'} available.',
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _assets.length,
              itemBuilder: (ctx, i) => _AssetTile(
                asset: _assets[i],
                selected: _selected.contains(_assets[i]),
                onTap: () => _toggle(_assets[i]),
                cache: _thumbnailCache,
              ),
            ),
    );
  }
}

enum _LimitedAction { manageLimited, openSettings, cancel }

class _AssetTile extends StatelessWidget {
  final AssetEntity asset;
  final bool selected;
  final VoidCallback onTap;
  final Map<String, Uint8List?> cache;

  const _AssetTile({
    required this.asset,
    required this.selected,
    required this.onTap,
    required this.cache,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Thumb(asset: asset, cache: cache),
          if (asset.type == AssetType.video)
            const Positioned(
              bottom: 6,
              left: 6,
              child: Icon(Icons.videocam, size: 16, color: Colors.white),
            ),
          if (selected)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _Thumb extends StatefulWidget {
  final AssetEntity asset;
  final Map<String, Uint8List?> cache;

  const _Thumb({required this.asset, required this.cache});

  @override
  State<_Thumb> createState() => _ThumbState();
}

class _ThumbState extends State<_Thumb> {
  Uint8List? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String key = widget.asset.id;
    if (widget.cache.containsKey(key)) {
      setState(() => _data = widget.cache[key]);
      return;
    }
    final Uint8List? bytes = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(256, 256),
    );
    widget.cache[key] = bytes;
    if (mounted) setState(() => _data = bytes);
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return const ColoredBox(color: Color(0xFFE0E0E0));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(_data!, fit: BoxFit.cover),
    );
  }
}
