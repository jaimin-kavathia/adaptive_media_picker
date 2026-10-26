import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../core/models.dart';

/// Full-screen crop editor used where no native cropper exists (Web and
/// desktop). Pure Flutter, so it works on every platform including WASM.
///
/// Internal: reached through `AdaptiveMediaPicker` when
/// [PickOptions.wantToCrop] is true.
class BuiltInCropPage extends StatefulWidget {
  /// Creates the editor for [image]. Prefer [BuiltInCropPage.show].
  const BuiltInCropPage({
    super.key,
    required this.image,
    this.aspectRatio,
    this.lockAspectRatio = false,
    this.circle = false,
    this.labels = const PickerLabels(),
  });

  /// Encoded source image (JPEG, PNG, ...).
  final Uint8List image;

  /// Initial aspect ratio, or null for free-form.
  final CropAspectRatioOption? aspectRatio;

  /// When true (and [aspectRatio] is set), the ratio selector is hidden so
  /// users can't change it.
  final bool lockAspectRatio;

  /// Circular crop UI (forces a locked 1:1 ratio); the result is a PNG with
  /// transparent corners.
  final bool circle;

  /// Text for the editor.
  final PickerLabels labels;

  /// Pushes the editor and resolves with the cropped, encoded bytes, or
  /// `null` if the user cancels.
  static Future<Uint8List?> show({
    required BuildContext context,
    required Uint8List image,
    CropAspectRatioOption? aspectRatio,
    bool lockAspectRatio = false,
    Brightness? themeBrightness,
    Color? primaryColor,
    bool circle = false,
    PickerLabels labels = const PickerLabels(),
  }) {
    final ThemeData base = Theme.of(context);
    final Brightness brightness = themeBrightness ?? base.brightness;
    final ColorScheme scheme = brightness == base.colorScheme.brightness
        ? base.colorScheme.copyWith(
            primary: primaryColor ?? base.colorScheme.primary,
          )
        : ColorScheme.fromSeed(
            seedColor: primaryColor ?? base.colorScheme.primary,
            brightness: brightness,
          );
    final ThemeData themed = base.copyWith(colorScheme: scheme);
    return Navigator.of(context).push<Uint8List>(
      MaterialPageRoute<Uint8List>(
        fullscreenDialog: true,
        builder: (_) => Theme(
          data: themed,
          child: BuiltInCropPage(
            image: image,
            aspectRatio: aspectRatio,
            lockAspectRatio: lockAspectRatio,
            circle: circle,
            labels: labels,
          ),
        ),
      ),
    );
  }

  /// Numeric width/height ratio for [option]; null means free-form.
  static double? ratioValue(CropAspectRatioOption? option) {
    switch (option) {
      case null:
      case CropAspectRatioOption.original:
        return null;
      case CropAspectRatioOption.square:
        return 1;
      case CropAspectRatioOption.ratio3x2:
        return 3 / 2;
      case CropAspectRatioOption.ratio4x3:
        return 4 / 3;
      case CropAspectRatioOption.ratio5x4:
        return 5 / 4;
      case CropAspectRatioOption.ratio7x5:
        return 7 / 5;
      case CropAspectRatioOption.ratio16x9:
        return 16 / 9;
    }
  }

  @override
  State<BuiltInCropPage> createState() => _BuiltInCropPageState();
}

class _BuiltInCropPageState extends State<BuiltInCropPage> {
  late final Map<CropAspectRatioOption, String> _ratioLabels = {
    CropAspectRatioOption.original: widget.labels.cropFreeRatio,
    CropAspectRatioOption.square: '1:1',
    CropAspectRatioOption.ratio3x2: '3:2',
    CropAspectRatioOption.ratio4x3: '4:3',
    CropAspectRatioOption.ratio5x4: '5:4',
    CropAspectRatioOption.ratio7x5: '7:5',
    CropAspectRatioOption.ratio16x9: '16:9',
  };

  final CropController _controller = CropController();
  late CropAspectRatioOption _ratio = widget.circle
      ? CropAspectRatioOption.square
      : widget.aspectRatio ?? CropAspectRatioOption.original;
  bool _ready = false;
  bool _cropping = false;

  bool get _locked =>
      widget.circle ||
      (widget.lockAspectRatio &&
          BuiltInCropPage.ratioValue(widget.aspectRatio) != null);

  void _onCropped(CropResult result) {
    if (!mounted) return;
    switch (result) {
      case CropSuccess(:final croppedImage):
        Navigator.of(context).pop(croppedImage);
      case CropFailure(:final cause):
        debugPrint('Built-in cropping failed: $cause');
        setState(() => _cropping = false);
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(widget.labels.cropFailed)));
    }
  }

  void _selectRatio(CropAspectRatioOption option) {
    setState(() => _ratio = option);
    _controller.aspectRatio = BuiltInCropPage.ratioValue(option);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.labels.cropTitle),
        actions: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).okButtonLabel,
            icon: const Icon(Icons.check),
            onPressed: !_ready || _cropping
                ? null
                : () {
                    setState(() => _cropping = true);
                    widget.circle
                        ? _controller.cropCircle()
                        : _controller.crop();
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Dark backdrop and padding keep the corner handles fully
                  // visible when the image spans the whole width.
                  ColoredBox(
                    color: Colors.black,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Crop(
                        image: widget.image,
                        controller: _controller,
                        onCropped: _onCropped,
                        aspectRatio: BuiltInCropPage.ratioValue(_ratio),
                        withCircleUi: widget.circle,
                        baseColor: Colors.black,
                        maskColor: Colors.black.withValues(alpha: 0.6),
                        cornerDotBuilder: (size, edgeAlignment) =>
                            DotControl(color: scheme.primary),
                        progressIndicator: const CircularProgressIndicator(),
                        onStatusChanged: (status) {
                          final bool ready = status == CropStatus.ready;
                          if (mounted && ready != _ready) {
                            setState(() => _ready = ready);
                          }
                        },
                      ),
                    ),
                  ),
                  if (_cropping)
                    const ColoredBox(
                      color: Colors.black26,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
            if (!_locked)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in _ratioLabels.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _ratio == entry.key,
                        onSelected: _ready && !_cropping
                            ? (_) => _selectRatio(entry.key)
                            : null,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
