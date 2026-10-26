import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_permission/smart_permission.dart';

import '../core/models.dart';

/// Bottom-sheet grid shown when the OS grants only limited Photos access
/// (iOS "Selected Photos").
///
/// `AdaptiveMediaPicker` presents it automatically; you only need it
/// directly to show the same sheet from your own flow via
/// [LimitedAccessPicker.show]. On Web it is not available.
class LimitedAccessPicker extends StatefulWidget {
  /// Whether the sheet should allow multiple selection.
  final bool allowMultiple;

  /// Maximum number of items to allow when [allowMultiple] is true.
  final int? maxImages;

  /// The media type displayed in the sheet.
  final MediaType mediaType;

  /// Text used by the sheet and its dialogs.
  final PickerLabels labels;

  /// Creates a [LimitedAccessPicker]. Prefer using [LimitedAccessPicker.show].
  const LimitedAccessPicker({
    super.key,
    this.allowMultiple = false,
    this.maxImages,
    this.mediaType = MediaType.image,
    this.labels = const PickerLabels(),
  });

  /// Shows the limited-access bottom sheet and returns the selected assets,
  /// or `null` if dismissed.
  ///
  /// [themeBrightness] and [primaryColor] override the ambient theme.
  static Future<List<AssetEntity>?> show({
    required BuildContext context,
    bool allowMultiple = false,
    int? maxImages,
    MediaType mediaType = MediaType.image,
    Brightness? themeBrightness,
    Color? primaryColor,
    PickerLabels labels = const PickerLabels(),
  }) async {
    final ThemeData base = Theme.of(context);
    final Brightness brightness = themeBrightness ?? base.brightness;
    final Color schemePrimary = primaryColor ?? base.colorScheme.primary;
    final ColorScheme scheme = base.colorScheme.copyWith(
      brightness: brightness,
      primary: schemePrimary,
    );
    final ThemeData themed = base.copyWith(
      colorScheme: scheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
    );

    return await showModalBottomSheet<List<AssetEntity>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: themed.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      builder: (ctx) => Theme(
        data: themed,
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: LimitedAccessPicker(
            allowMultiple: allowMultiple,
            maxImages: maxImages,
            mediaType: mediaType,
            labels: labels,
          ),
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

  RequestType get _requestType => switch (widget.mediaType) {
    MediaType.image => RequestType.image,
    MediaType.video => RequestType.video,
    MediaType.any => RequestType.common,
  };

  bool _matches(AssetEntity asset) => switch (widget.mediaType) {
    MediaType.image => asset.type == AssetType.image,
    MediaType.video => asset.type == AssetType.video,
    MediaType.any =>
      asset.type == AssetType.image || asset.type == AssetType.video,
  };

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    List<AssetEntity> assets = const [];
    try {
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: _requestType,
      );
      if (albums.isNotEmpty) {
        assets = await albums.first.getAssetListRange(start: 0, end: 500);
      }
    } catch (e) {
      debugPrint('LimitedAccessPicker could not load assets: $e');
    }
    if (!mounted) return;
    final List<AssetEntity> filtered = assets.where(_matches).toList();
    if (filtered.isEmpty) {
      // Nothing shared with the app yet: offer to change the selection.
      // Choosing an action closes the sheet.
      await _promptManageLimited();
    }
    if (!mounted) return;
    setState(() {
      _assets = filtered;
      _loading = false;
    });
  }

  Future<void> _promptManageLimited() async {
    final PickerLabels labels = widget.labels;
    final bool isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    final action = await showDialog<_LimitedAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(labels.limitedEmptyTitle),
        content: Text(labels.limitedEmptyMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_LimitedAction.cancel),
            child: Text(labels.cancel),
          ),
          if (isIOS)
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(_LimitedAction.manageLimited),
              child: Text(labels.manageSelection),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_LimitedAction.openSettings),
            child: Text(labels.openSettings),
          ),
        ],
      ),
    );

    if (!mounted) return;
    switch (action) {
      case _LimitedAction.manageLimited:
        await PhotoManager.presentLimited(type: _requestType);
        if (mounted) Navigator.of(context).pop(null);
      case _LimitedAction.openSettings:
        await openAppSettings();
        if (mounted) Navigator.of(context).pop(null);
      case _LimitedAction.cancel:
      case null:
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
    final PickerLabels labels = widget.labels;
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (widget.mediaType) {
          MediaType.image => labels.selectImagesTitle,
          MediaType.video => labels.selectVideosTitle,
          MediaType.any => labels.selectMediaTitle,
        }),
        actions: [
          if (widget.allowMultiple)
            TextButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_selected.toList()),
              child: Text(
                _selected.isEmpty
                    ? labels.done
                    : widget.maxImages == null
                    ? '${labels.done} (${_selected.length})'
                    : '${labels.done} (${_selected.length}/${widget.maxImages})',
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
          ? Center(
              child: Text(
                labels.nothingAvailable,
                style: Theme.of(context).textTheme.bodyMedium,
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
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.check,
                  size: 14,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
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
      _data = widget.cache[key];
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
