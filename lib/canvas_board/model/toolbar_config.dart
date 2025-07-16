// ToolbarConfig model for CanvasBoard
class ToolbarConfig {
  final bool showAddImage;
  final bool showUndo;
  final bool showRedo;
  final bool showZoom;
  final bool showExport;
  final bool showReset;
  final bool showLayerControls;

  const ToolbarConfig({
    this.showAddImage = true,
    this.showUndo = true,
    this.showRedo = true,
    this.showZoom = true,
    this.showExport = true,
    this.showReset = true,
    this.showLayerControls = true,
  });

  ToolbarConfig copyWith({
    bool? showAddImage,
    bool? showUndo,
    bool? showRedo,
    bool? showZoom,
    bool? showExport,
    bool? showReset,
    bool? showLayerControls,
  }) => ToolbarConfig(
        showAddImage: showAddImage ?? this.showAddImage,
        showUndo: showUndo ?? this.showUndo,
        showRedo: showRedo ?? this.showRedo,
        showZoom: showZoom ?? this.showZoom,
        showExport: showExport ?? this.showExport,
        showReset: showReset ?? this.showReset,
        showLayerControls: showLayerControls ?? this.showLayerControls,
      );
} 