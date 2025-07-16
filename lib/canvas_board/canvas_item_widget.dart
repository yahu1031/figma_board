import 'dart:io'; // Added for File

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'model/canvas_item.dart';

typedef CanvasItemWidgetFloatingToolbarBuilder =
    Widget Function(BuildContext context, double width, double height);

class CanvasItemWidget extends StatefulWidget {
  final CanvasItem item;
  final bool isSelected;
  final VoidCallback? onTap;
  final ValueChanged<Offset>? onMove;
  final Offset? initialPosition;
  final ValueChanged<double>? onScale;
  final ValueChanged<double>? onRotate;
  final VoidCallback? onFlip;
  final VoidCallback? onRemove;
  final VoidCallback? onBringToFront;
  final VoidCallback? onSendToBack;
  final Widget? specialFloatingItem;
  final bool isLocked;

  /// User-provided floating toolbar builder. Gets context, itemWidth, itemHeight.
  /// Return a widget (e.g., Positioned) to display as a floating toolbar.
  final CanvasItemWidgetFloatingToolbarBuilder? floatingToolbarBuilder;

  const CanvasItemWidget({
    super.key,
    required this.item,
    this.isSelected = false,
    this.onTap,
    this.initialPosition,
    this.onMove,
    this.onScale,
    this.onRotate,
    this.onFlip,
    this.onRemove,
    this.onBringToFront,
    this.onSendToBack,
    this.floatingToolbarBuilder,
    this.specialFloatingItem,
    required this.isLocked,
  });

  @override
  State<CanvasItemWidget> createState() => _CanvasItemWidgetState();

  /// Default floating toolbar builder utility.
  /// Usage:
  /// floatingToolbarBuilder: CanvasItemWidget.defaultFloatingToolbarBuilder([
  ///   IconButton(...),
  ///   ...
  /// ])
  static CanvasItemWidgetFloatingToolbarBuilder defaultFloatingToolbarBuilder(
    List<Widget>? items,
    Widget? specialFloatingItem,
    bool isLocked,
  ) {
    return (BuildContext context, double width, double height) {
      if (items == null || items.isEmpty) return const SizedBox.shrink();
      final visibleItems = items.take(5).toList();
      final screen = MediaQuery.of(context).size;
      const margin = 20.0;
      const itemSpacing = 8.0;
      const minToolbarWidth = 48.0;
      final toolbarWidth = minToolbarWidth;
      final toolbarHeight =
          (visibleItems.length * minToolbarWidth) +
          ((visibleItems.length - 1) * itemSpacing);
      // Default: right of item, vertically centered
      double left = width + margin;
      double top = (height - toolbarHeight) / 2;
      // Flip to left if overflow right
      if (left + toolbarWidth > screen.width) {
        left = -toolbarWidth - margin;
      }
      // Flip to right if overflow left
      if (left < 0) {
        left = width + margin;
        if (left + toolbarWidth > screen.width) {
          left = screen.width - toolbarWidth - margin;
        }
      }
      // Flip to top if overflow bottom
      if (top + toolbarHeight > screen.height) {
        top = screen.height - toolbarHeight - margin;
      }
      // Flip to bottom if overflow top
      if (top < 0) {
        top = margin;
      }
      return Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(8),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < visibleItems.length; i++) ...[
                    Opacity(
                      opacity:
                          isLocked &&
                              visibleItems[i].key != const ValueKey('_lockItem')
                          ? 0.5
                          : 1,
                      child: IgnorePointer(
                        ignoring:
                            isLocked &&
                            visibleItems[i].key != const ValueKey('_lockItem'),
                        child: visibleItems[i],
                      ),
                    ),
                    if (i < visibleItems.length - 1)
                      SizedBox(height: itemSpacing),
                  ],
                ],
              ),
            ),
            if (specialFloatingItem != null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: specialFloatingItem,
              ),
          ],
        ),
      );
    };
  }

  /// Use clamped instead of newPosition
  static Offset clampPositionToScreen({
    required Offset position,
    required double itemWidth,
    required double itemHeight,
    required Size screenSize,
    double margin = 0,
  }) {
    final minX = margin;
    final minY = margin;
    final maxX = screenSize.width - itemWidth - margin;
    final maxY = screenSize.height - itemHeight - margin;
    return Offset(position.dx.clamp(minX, maxX), position.dy.clamp(minY, maxY));
  }
}

class _CanvasItemWidgetState extends State<CanvasItemWidget>
    with AutomaticKeepAliveClientMixin {
  late ValueNotifier<Offset> _position;
  double? _imageWidth;
  double? _imageHeight;
  Offset? _rotationStartLocal;
  double? _rotationStartAngle;
  double? _rotationStartValue;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _position = ValueNotifier(widget.initialPosition ?? Offset.zero);
    _resolveImage();
  }

  @override
  void didUpdateWidget(CanvasItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reset image dimensions if the image source actually changes
    if (oldWidget.item.source != widget.item.source) {
      _imageWidth = null;
      _imageHeight = null;

      _resolveImage();
    }
  }

  void _getImageDimensions(ImageProvider provider) {
    final ImageStream stream = provider.resolve(const ImageConfiguration());
    stream.addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            if (info.image.width > 300) {
              final aspectRatio = info.image.width / info.image.height;
              _imageWidth = 300.0;
              _imageHeight = 300.0 / aspectRatio;
            } else {
              _imageWidth = info.image.width.toDouble();
              _imageHeight = info.image.height.toDouble();
            }
          });
        }
      }),
    );
  }

  void _resolveImage() {
    final src = widget.item.source;
    if (src.startsWith('http')) {
      _getImageDimensions(Image.network(src).image);
    } else if (src.startsWith('file://')) {
      _getImageDimensions(
        Image.file(File(src.replaceFirst('file://', ''))).image,
      );
    } else {
      _getImageDimensions(Image.asset(src).image);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final handleSize = 16.0; // Always 16 logical pixels, not affected by scale
    final double originalWidth = _imageWidth ?? 1;
    final double minScale = 180 / originalWidth;
    final double maxScale = 1.5;
    final item = widget.item;
    final scale = item.scale;
    final borderSize = 1.0; // Not divided by scale, always 2 logical pixels
    final screenWidth = MediaQuery.of(context).size.width;
    final adaptiveSensitivity = screenWidth
        .clamp(600, 1800)
        .toDouble(); // min 600, max 1800
    final isMobile =
        Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS;
    // Calculate width and height based on scale
    final double? itemWidth = _imageWidth != null ? _imageWidth! * scale : null;
    final double? itemHeight = _imageHeight != null
        ? _imageHeight! * scale
        : null;
    final double? itemWidthWithToolbar = (itemWidth ?? 0) + (48);
    final double? itemHeightWithToolbar =
        ((itemHeight ?? 0) * 5) + (!widget.isSelected ? 0 : 48);
    Widget content = Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      // alignment: Alignment.center,
      // clipBehavior: Clip.none,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.onTap,
          onScaleUpdate: widget.isLocked
              ? null
              : (details) {
                  if (details.pointerCount == 1) {
                    // Single finger: pan
                    final delta = details.focalPointDelta;
                    final screen = MediaQuery.of(context).size;
                    final newPosition = _position.value + delta;
                    final clamped = CanvasItemWidget.clampPositionToScreen(
                      position: newPosition,
                      itemWidth: itemWidth ?? 0,
                      itemHeight: itemHeight ?? 0,
                      screenSize: screen,
                      margin: 0,
                    );
                    widget.onMove?.call(clamped - _position.value);
                    _position.value = clamped;
                  } else if (details.pointerCount == 2) {
                    // Two fingers: pinch to zoom (reduced sensitivity)
                    final sensitivity = 0.1; // Lower = less sensitive
                    final adjustedScale = 1 + (details.scale - 1) * sensitivity;
                    final newScale = (scale * adjustedScale).clamp(
                      minScale,
                      maxScale,
                    );
                    widget.onScale?.call(newScale);
                  } else if (details.scale != 1.0) {
                    final newScale = (scale * details.scale).clamp(
                      minScale,
                      maxScale,
                    );
                    widget.onScale?.call(newScale);
                  }
                },
          child: SizedBox(
            width: itemWidthWithToolbar! - 48,
            // height: itemHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10), // space for border/handles
                  child: Container(
                    width: itemWidthWithToolbar,
                    height: itemHeight == null ? null : itemHeight - 20,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: item.isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: _imageWidth == null
                          ? const Center(child: CircularProgressIndicator())
                          : item.source.startsWith('http')
                          ? Image.network(
                              item.source,
                              width: itemWidth,
                              // height: itemHeight,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.red,
                                    child: const Center(
                                      child: Icon(
                                        Icons.error,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                            )
                          : item.source.startsWith('file://')
                          ? Image.file(
                              File(item.source.replaceFirst('file://', '')),
                              width: itemWidth,
                              height: itemHeight,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.red,
                                    child: const Center(
                                      child: Icon(
                                        Icons.error,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                            )
                          : Image.asset(
                              item.source,
                              width: itemWidth,
                              height: itemHeight,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                if (item.isSelected &&
                    _imageWidth != null &&
                    _imageHeight != null &&
                    !widget.isLocked)
                  _buildFigmaHandles(itemWidth!, itemHeight ?? 0),
              ],
            ),
          ),
        ),
        if (item.isSelected &&
            widget.floatingToolbarBuilder != null &&
            _imageWidth != null &&
            _imageHeight != null)
          widget.floatingToolbarBuilder!(context, itemWidth!, itemHeight ?? 0),
      ],
    );

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateZ(item.rotation),
      child: SizedBox(
        width: (itemWidth ?? 0) + (!widget.isSelected ? 0 : 48),
        height: (itemHeight ?? 0) + (!widget.isSelected ? 0 : 48 + 68),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            item.isFlippedHorizontally ? -1 : 1,
            item.isFlippedVertically ? -1 : 1,
            1,
          ),
          child: content,
        ),
      ),
    );
  }

  List<Widget> _buildResizeHandles({
    required double handleSize,
    required double borderSize,
    required double scale,
    required double minScale,
    required double maxScale,
    required double sensitivity,
  }) {
    // Only corners: topLeft, topRight, bottomRight, bottomLeft
    final positions = [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomRight,
      Alignment.bottomLeft,
    ];
    // Direction logic for each handle
    final List<int Function(Offset)> handleDirections = [
      // topLeft
      (delta) => (delta.dx < 0 || delta.dy < 0) ? 1 : -1,
      // topRight
      (delta) => (delta.dx > 0 || delta.dy < 0) ? 1 : -1,
      // bottomRight
      (delta) => (delta.dx > 0 || delta.dy > 0) ? 1 : -1,
      // bottomLeft
      (delta) => (delta.dx < 0 || delta.dy > 0) ? 1 : -1,
    ];
    return List.generate(positions.length, (i) {
      return Positioned.fill(
        child: Align(
          alignment: positions[i],
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (details) {
              final delta = details.delta;
              final direction = handleDirections[i](delta);
              final magnitude = delta.distance / sensitivity;
              final scaleDelta = direction * magnitude;
              final newScale = (scale + scaleDelta).clamp(minScale, maxScale);
              widget.onScale?.call(newScale);
            },
            child: Container(
              width: handleSize / scale,
              height: handleSize / scale,
              decoration: BoxDecoration(
                color: kDebugMode
                    ? Colors.red
                    : Colors.transparent, // Invisible handle
                border: Border.all(
                  color: Colors.transparent,
                  width: borderSize,
                ),
                shape: BoxShape.rectangle,
              ),
            ),
          ),
        ),
      );
    });
  }

  // Only 4-corner handles for Figma-style selection
  Widget _buildFigmaHandles(double width, double height) {
    const handleSize = 16.0;
    const offset = 1;
    final position = Offset(
      (width - handleSize / 2) - offset,
      (height - handleSize / 2) - offset,
    );
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanStart: (details) {
          final center = Offset(width / 2, height / 2);
          _rotationStartLocal = details.localPosition;
          _rotationStartAngle = (details.localPosition - center).direction;
          _rotationStartValue = widget.item.rotation;
        },
        onPanUpdate: (details) {
          final center = Offset(width / 2, height / 2);
          final currentAngle = (details.localPosition - center).direction;
          final deltaAngle = currentAngle - (_rotationStartAngle ?? 0);
          final newRotation = (_rotationStartValue ?? 0) + deltaAngle;
          widget.onRotate?.call(newRotation);
        },
        child: Container(
          width: handleSize,
          height: handleSize,
          color: Colors.transparent,
          child: Icon(
            Icons.rotate_90_degrees_ccw,
            size: handleSize,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
