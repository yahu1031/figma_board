import 'package:flutter/material.dart';

import '../cubit/canvas_cubit.dart';
import '../model/canvas_item.dart';
import '../model/toolbar_config.dart';
import '../utils/export_utils.dart';

/// Controller for programmatic control of CanvasBoard.
/// Exposes all board actions and state for external usage.
class CanvasBoardController extends ChangeNotifier {
  late final CanvasCubit _cubit;
  ToolbarConfig _toolbarConfig;

  /// Notifies when the selected item changes.
  final ValueNotifier<CanvasItem?> selectedItemNotifier = ValueNotifier(null);

  /// Notifies when the undo state changes.
  final ValueNotifier<bool> canUndoNotifier = ValueNotifier(false);

  /// Notifies when the redo state changes.
  final ValueNotifier<bool> canRedoNotifier = ValueNotifier(false);

  /// Notifies when the items list changes.
  final ValueNotifier<List<CanvasItem>> itemsNotifier = ValueNotifier([]);

  CanvasBoardController({
    ToolbarConfig? initialToolbarConfig,
    List<CanvasItem>? initialItems,
  }) : _toolbarConfig = initialToolbarConfig ?? const ToolbarConfig() {
    _cubit = CanvasCubit(initialItems: initialItems);
    _updateNotifiers();
    _cubit.stream.listen((_) {
      _updateNotifiers();
      notifyListeners();
    });
  }

  // lock the image from being moved
  bool _isImageLocked = false;
  bool get isImageLocked => _isImageLocked;
  void setIsImageLocked(bool value) {
    _isImageLocked = value;
    _cubit.updateItem(selectedItem!.copyWith(isLocked: value));
    notifyListeners();
  }

  // --- State Getters ---
  List<CanvasItem> get items => _cubit.state.items;
  CanvasItem? get selectedItem {
    final id = _cubit.state.selectedItemId;
    if (id == null) return null;
    for (final item in _cubit.state.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  ToolbarConfig get toolbarConfig => _toolbarConfig;
  bool get canUndo => _cubit.state.undoStack.isNotEmpty;
  bool get canRedo => _cubit.state.redoStack.isNotEmpty;

  void _updateNotifiers() {
    selectedItemNotifier.value = selectedItem;
    canUndoNotifier.value = canUndo;
    canRedoNotifier.value = canRedo;
    itemsNotifier.value = List.unmodifiable(items);
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _updateNotifiers();
  }

  // --- Board Actions ---
  /// Add a new item to the board.
  void addItem(CanvasItem item) {
    _cubit.addItem(item);
    notifyListeners();
  }

  /// Remove an item by id.
  void removeItem(String id) {
    _cubit.removeItem(id);
    notifyListeners();
  }

  /// Update an item.
  void updateItem(CanvasItem item) {
    _cubit.updateItem(item);
    notifyListeners();
  }

  /// Select an item by id (or null to unselect).
  void selectItem(String? itemId) {
    _cubit.selectItem(itemId);
    notifyListeners();
  }

  /// Move an item to a new position.
  void moveItem(String id, Offset newPosition) {
    _cubit.moveItem(id, newPosition);
    notifyListeners();
  }

  /// Scale an item.
  void scaleItem(String id, double scale) {
    _cubit.scaleItem(id, scale);
    notifyListeners();
  }

  /// Rotate an item.
  void rotateItem(String id, double rotation) {
    _cubit.rotateItem(id, rotation);
    notifyListeners();
  }

  /// Flip an item horizontally.
  void flipHorizontal(String id) {
    if (isImageLocked) return;
    _cubit.flipHorizontal(id);
    notifyListeners();
  }

  /// Flip an item vertically.
  void flipVertical(String id) {
    _cubit.flipVertical(id);
    notifyListeners();
  }

  /// Bring an item to the front.
  void bringToFront(String id) {
    _cubit.bringToFront(id);
    notifyListeners();
  }

  /// Send an item to the back.
  void sendToBack(String id) {
    _cubit.sendToBack(id);
    notifyListeners();
  }

  /// Undo last action.
  void undo() {
    _cubit.undo();
    notifyListeners();
  }

  /// Redo last undone action.
  void redo() {
    _cubit.redo();
    notifyListeners();
  }

  /// Reset the board.
  void reset() {
    _cubit.reset();
    notifyListeners();
  }

  /// Export the board as an image. Returns the file path or null.
  /// [key] is the GlobalKey of the RepaintBoundary.
  /// [imageFormat] can be 'png' (default) or 'jpg'.
  Future<String?> exportAsImage(GlobalKey key, {String imageFormat = 'png'}) {
    return exportWidgetToImage(key, imageFormat: imageFormat);
  }

  /// Set toolbar config and notify listeners.
  void setToolbarConfig(ToolbarConfig config) {
    _toolbarConfig = config;
    notifyListeners();
  }

  // --- Internal Cubit Access (for CanvasBoard widget) ---
  CanvasCubit get cubit => _cubit;

  @override
  void dispose() {
    selectedItemNotifier.dispose();
    canUndoNotifier.dispose();
    canRedoNotifier.dispose();
    itemsNotifier.dispose();
    _cubit.close();
    super.dispose();
  }
}
