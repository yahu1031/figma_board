import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/canvas_item.dart';
import 'canvas_state.dart';

class CanvasCubit extends Cubit<CanvasState> {
  CanvasCubit({bool isPreviewMode = false, List<CanvasItem>? initialItems})
    : super(
        CanvasState(items: initialItems ?? [], isPreviewMode: isPreviewMode),
      );

  void addItem(CanvasItem item) {
    if (state.isPreviewMode) return;
    _pushUndo();
    emit(
      state.copyWith(
        items: [
          ...state.items.map((e) => e.copyWith(isSelected: false)),
          item.copyWith(isSelected: true),
        ],
        selectedItemId: item.id,
        redoStack: [],
      ),
    );
  }

  void removeItem(String id) {
    if (state.isPreviewMode) return;
    _pushUndo();
    emit(
      state.copyWith(
        items: state.items.where((item) => item.id != id).toList(),
        selectedItemId: state.selectedItemId == id
            ? null
            : state.selectedItemId,
        redoStack: [],
      ),
    );
  }

  void updateItem(CanvasItem updated) {
    if (state.isPreviewMode) return;
    _pushUndo();
    emit(
      state.copyWith(
        selectedItemId: updated.isSelected ? updated.id : state.selectedItemId,
        items: state.items
            .map((item) => item.id == updated.id ? updated : item)
            .toList(),
        redoStack: [],
      ),
    );
  }

  void selectItem(String? id) {
    if (state.isPreviewMode) return;
    final _state = state.copyWith(
      selectedItemId: id,
      items: state.items
          .map((e) => e.copyWith(isSelected: e.id == id))
          .toList(),
    );
    emit(_state);
  }

  void moveItem(String id, Offset newPosition) {
    final item = state.items.where((e) => e.id == id).isNotEmpty
        ? state.items.where((e) => e.id == id).first
        : null;
    if (item == null || state.isPreviewMode) return;
    updateItem(item.copyWith(position: newPosition, updatedAt: DateTime.now()));
  }

  void scaleItem(String id, double scale) {
    final item = state.items.where((e) => e.id == id).isNotEmpty
        ? state.items.where((e) => e.id == id).first
        : null;
    if (item == null || state.isPreviewMode) return;
    updateItem(item.copyWith(scale: scale, updatedAt: DateTime.now()));
  }

  void rotateItem(String id, double rotation) {
    final item = state.items.where((e) => e.id == id).isNotEmpty
        ? state.items.where((e) => e.id == id).first
        : null;
    if (item == null || state.isPreviewMode) return;
    updateItem(item.copyWith(rotation: rotation, updatedAt: DateTime.now()));
  }

  CanvasItem? _findItemById(String id) {
    return state.items.where((e) => e.id == id).isNotEmpty
        ? state.items.where((e) => e.id == id).first
        : null;
  }

  void rotateLeft(String id) {
    final item = _findItemById(id);
    if (item == null || state.isPreviewMode) return;
    updateItem(
      item.copyWith(
        rotation: item.rotation - 0.25 * 3.141592653589793,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void rotateRight(String id) {
    final item = _findItemById(id);
    if (item == null || state.isPreviewMode) return;
    updateItem(
      item.copyWith(
        rotation: item.rotation + 0.25 * 3.141592653589793,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void flipHorizontal(String id) {
    final item = _findItemById(id);
    if (item == null || state.isPreviewMode) return;
    updateItem(
      item.copyWith(
        isFlippedHorizontally: !item.isFlippedHorizontally,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void flipVertical(String id) {
    final item = _findItemById(id);
    if (item == null || state.isPreviewMode) return;
    updateItem(
      item.copyWith(
        isFlippedVertically: !item.isFlippedVertically,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void flipItem(String id) {
    flipHorizontal(id);
  }

  void bringToFront(String id) {
    if (state.isPreviewMode) return;
    final items = List<CanvasItem>.from(state.items);
    final idx = items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final item = items[idx];
    final maxZ = items.map((e) => e.zIndex).fold(0, (a, b) => a > b ? a : b);
    // Update zIndex for all items
    final updatedItems = items.map((e) {
      if (e.id == id) {
        return e.copyWith(zIndex: maxZ);
      } else if (e.zIndex > item.zIndex) {
        // Decrement zIndex for items above the current one
        return e.copyWith(zIndex: e.zIndex - 1);
      }
      return e;
    }).toList();
    _pushUndo();
    emit(state.copyWith(items: updatedItems, redoStack: []));
  }

  void sendToBack(String id) {
    if (state.isPreviewMode) return;
    final items = List<CanvasItem>.from(state.items);
    final idx = items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final item = items[idx];
    final updatedItems = items.map((e) {
      if (e.id == id) {
        return e.copyWith(zIndex: 0);
      } else if (e.zIndex < item.zIndex) {
        // Increment zIndex for items below the current one
        return e.copyWith(zIndex: e.zIndex + 1);
      }
      return e;
    }).toList();
    _pushUndo();
    emit(state.copyWith(items: updatedItems, redoStack: []));
  }

  void undo() {
    if (state.undoStack.isEmpty) return;
    final prev = state.undoStack.last;
    final newUndo = List<List<CanvasItem>>.from(state.undoStack)..removeLast();
    emit(
      state.copyWith(
        items: prev,
        undoStack: newUndo,
        redoStack: [state.items, ...state.redoStack],
      ),
    );
  }

  void redo() {
    if (state.redoStack.isEmpty) return;
    final next = state.redoStack.first;
    final newRedo = List<List<CanvasItem>>.from(state.redoStack)..removeAt(0);
    emit(
      state.copyWith(
        items: next,
        undoStack: [...state.undoStack, state.items],
        redoStack: newRedo,
      ),
    );
  }

  void reset() {
    if (state.isPreviewMode) return;
    _pushUndo();
    emit(state.copyWith(items: [], selectedItemId: null, redoStack: []));
  }

  void _pushUndo() {
    emit(
      state.copyWith(
        undoStack: [
          ...state.undoStack,
          state.items.map((e) => e.copyWith()).toList(),
        ],
      ),
    );
  }
}
