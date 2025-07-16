import '../model/canvas_item.dart';

class CanvasState {
  final List<CanvasItem> items;
  final String? selectedItemId;
  final List<List<CanvasItem>> undoStack;
  final List<List<CanvasItem>> redoStack;
  final bool isPreviewMode;

  const CanvasState({
    required this.items,
    this.selectedItemId,
    this.undoStack = const [],
    this.redoStack = const [],
    this.isPreviewMode = false,
  });

  CanvasState copyWith({
    List<CanvasItem>? items,
    String? selectedItemId,
    List<List<CanvasItem>>? undoStack,
    List<List<CanvasItem>>? redoStack,
    bool? isPreviewMode,
  }) => CanvasState(
    items: items ?? this.items,
    selectedItemId: selectedItemId ?? this.selectedItemId,
    undoStack: undoStack ?? this.undoStack,
    redoStack: redoStack ?? this.redoStack,
    isPreviewMode: isPreviewMode ?? this.isPreviewMode,
  );
}
