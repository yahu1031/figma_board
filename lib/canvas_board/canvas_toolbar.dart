import 'package:flutter/material.dart';

import 'model/toolbar_config.dart';

class CanvasToolbar extends StatelessWidget {
  final ToolbarConfig config;
  final VoidCallback? onAddImage;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onExport;
  final VoidCallback? onReset;
  final VoidCallback? onBringToFront;
  final VoidCallback? onSendToBack;
  final VoidCallback? onRemove;
  final VoidCallback? onRotateLeft;
  final VoidCallback? onRotateRight;
  final VoidCallback? onFlipHorizontal;
  final VoidCallback? onFlipVertical;
  final bool isPreviewMode;
  final bool canUndo;
  final bool canRedo;
  final bool canBringToFront;
  final bool canSendToBack;
  final bool canRemove;
  final bool canZoom;
  final bool canReset;

  const CanvasToolbar({
    super.key,
    required this.config,
    this.onAddImage,
    this.onUndo,
    this.onRedo,
    this.onZoomIn,
    this.onZoomOut,
    this.onExport,
    this.onReset,
    this.onBringToFront,
    this.onSendToBack,
    this.onRemove,
    this.onRotateLeft,
    this.onRotateRight,
    this.onFlipHorizontal,
    this.onFlipVertical,
    this.isPreviewMode = false,
    this.canUndo = true,
    this.canRedo = true,
    this.canBringToFront = true,
    this.canSendToBack = true,
    this.canRemove = true,
    this.canZoom = true,
    this.canReset = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (config.showAddImage)
            IconButton(
              icon: const Icon(Icons.add_photo_alternate),
              tooltip: 'Add Image',
              onPressed: isPreviewMode ? null : onAddImage,
            ),
          if (config.showUndo)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: isPreviewMode || !canUndo ? null : onUndo,
            ),
          if (config.showRedo)
            IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo',
              onPressed: isPreviewMode || !canRedo ? null : onRedo,
            ),
          if (config.showZoom)
            IconButton(
              icon: const Icon(Icons.zoom_in),
              tooltip: 'Zoom In',
              onPressed: isPreviewMode || !canZoom ? null : onZoomIn,
            ),
          if (config.showZoom)
            IconButton(
              icon: const Icon(Icons.zoom_out),
              tooltip: 'Zoom Out',
              onPressed: isPreviewMode || !canZoom ? null : onZoomOut,
            ),
          if (config.showExport)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export',
              onPressed: isPreviewMode ? null : onExport,
            ),
          if (config.showReset)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset',
              onPressed: isPreviewMode || !canReset ? null : onReset,
            ),
          if (config.showLayerControls)
            IconButton(
              icon: const Icon(Icons.vertical_align_top),
              tooltip: 'Bring to Front',
              onPressed: isPreviewMode || !canBringToFront
                  ? null
                  : onBringToFront,
            ),
          if (config.showLayerControls)
            IconButton(
              icon: const Icon(Icons.vertical_align_bottom),
              tooltip: 'Send to Back',
              onPressed: isPreviewMode || !canSendToBack ? null : onSendToBack,
            ),
          if (config.showLayerControls)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Remove Selected',
              onPressed: isPreviewMode || !canRemove ? null : onRemove,
              color: Colors.red,
            ),
          if (!isPreviewMode && canRemove) ...[
            IconButton(
              icon: const Icon(Icons.rotate_left),
              tooltip: 'Rotate Left',
              onPressed: onRotateLeft,
            ),
            IconButton(
              icon: const Icon(Icons.rotate_right),
              tooltip: 'Rotate Right',
              onPressed: onRotateRight,
            ),
            IconButton(
              icon: const Icon(Icons.flip),
              tooltip: 'Flip Horizontal',
              onPressed: onFlipHorizontal,
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_android),
              tooltip: 'Flip Vertical',
              onPressed: onFlipVertical,
            ),
          ],
        ],
      ),
    );
  }
}
