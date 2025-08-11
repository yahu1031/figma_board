import 'dart:async';

import 'package:figma_board/canvas_board/canvas_toolbar.dart';
import 'package:figma_board/canvas_board/utils/export_utils.dart';
import 'package:figma_board/canvas_board/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'canvas_item_widget.dart';
import 'controller/canvas_board_controller.dart';
import 'cubit/canvas_cubit.dart';
import 'cubit/canvas_state.dart';
import 'model/canvas_item.dart';
import 'model/toolbar_config.dart';

class CanvasBoard extends StatefulWidget {
  final Color? initialBackgroundColor;
  final ImageProvider? initialBackgroundImage;
  final List<CanvasItem> initialItems;
  final Widget? specialFloatingItem;
  final void Function(String)? onExport;
  final List<Widget>? floatingItems;
  final ToolbarConfig toolbarOptions;
  final GlobalKey? canvasKey;
  final bool isPreviewMode;
  final Size? previewSize;
  final void Function(List<CanvasItemMeta>)? onItemMetadataUpdate;
  final CanvasBoardController? controller;
  final Widget Function(BuildContext, CanvasBoardController)? toolbarBuilder;
  final bool showDefaultToolbar;

  CanvasBoard({
    super.key,
    this.specialFloatingItem,
    this.floatingItems,
    this.initialBackgroundColor = Colors.white,
    this.initialBackgroundImage,
    this.initialItems = const [],
    this.onExport,
    this.toolbarOptions = const ToolbarConfig(),
    this.canvasKey,
    this.isPreviewMode = false,
    this.previewSize,
    this.onItemMetadataUpdate,
    this.controller,
    this.toolbarBuilder,
    this.showDefaultToolbar = false,
  }) : assert(
         floatingItems == null || floatingItems.length <= 5,
         'Maximum 5 toolbar items allowed',
       );

  const CanvasBoard.preview({
    super.key,
    this.floatingItems,
    this.previewSize,
    this.initialItems = const [],
    this.specialFloatingItem,
    this.initialBackgroundColor = Colors.white,
    this.initialBackgroundImage,
  }) : onExport = null,
       showDefaultToolbar = false,
       controller = null,
       toolbarBuilder = null,
       toolbarOptions = const ToolbarConfig(),
       canvasKey = null,
       isPreviewMode = true,
       onItemMetadataUpdate = null;

  @override
  State<CanvasBoard> createState() => _CanvasBoardState();
}

class _CanvasBoardState extends State<CanvasBoard>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final CanvasCubit _cubit;

  late final StreamSubscription<CanvasState> _cubitSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit =
        widget.controller?.cubit ??
        CanvasCubit(initialItems: widget.initialItems);
    widget.controller?.addListener(_setState);
    _cubitSubscription = _cubit.stream.listen((_) => _setState());
  }

  void _setState() => setState(() {});

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller?.removeListener(_setState);
    _cubitSubscription.cancel();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider<CanvasCubit>.value(
      value: _cubit,
      child: _CanvasBoardView(
        initialBackgroundColor: widget.initialBackgroundColor,
        specialFloatingItem: widget.specialFloatingItem,
        initialBackgroundImage: widget.initialBackgroundImage,
        initialItems: widget.initialItems,
        floatingItems: widget.floatingItems,
        onExport: widget.onExport,
        toolbarOptions: widget.toolbarOptions,
        canvasKey: widget.canvasKey,
        isPreviewMode: widget.isPreviewMode,
        previewSize: widget.previewSize,
        onItemMetadataUpdate: widget.onItemMetadataUpdate,
        controller: widget.controller,
        toolbarBuilder: widget.toolbarBuilder,
        showDefaultToolbar: widget.showDefaultToolbar,
      ),
    );
  }
}

class _CanvasBoardView extends StatefulWidget {
  final Color? initialBackgroundColor;
  final ImageProvider? initialBackgroundImage;
  final List<CanvasItem> initialItems;
  final void Function(String)? onExport;
  final ToolbarConfig toolbarOptions;
  final GlobalKey? canvasKey;
  final bool isPreviewMode;
  final Size? previewSize;
  final void Function(List<CanvasItemMeta>)? onItemMetadataUpdate;
  final CanvasBoardController? controller;
  final Widget Function(BuildContext, CanvasBoardController)? toolbarBuilder;
  final bool showDefaultToolbar;
  final List<Widget>? floatingItems;
  final Widget? specialFloatingItem;

  const _CanvasBoardView({
    required this.initialBackgroundColor,
    this.floatingItems,
    required this.initialBackgroundImage,
    required this.initialItems,
    required this.onExport,
    required this.toolbarOptions,
    required this.canvasKey,
    required this.isPreviewMode,
    required this.previewSize,
    this.onItemMetadataUpdate,
    this.controller,
    this.toolbarBuilder,
    this.showDefaultToolbar = false,
    this.specialFloatingItem,
  });

  @override
  State<_CanvasBoardView> createState() => _CanvasBoardViewState();
}

class _CanvasBoardViewState extends State<_CanvasBoardView> {
  List<CanvasItemMeta>? _lastMeta;

  @override
  void didUpdateWidget(covariant _CanvasBoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeCallMetadataUpdate(context);
  }

  void _maybeCallMetadataUpdate(BuildContext context) {
    if (widget.isPreviewMode || widget.onItemMetadataUpdate == null) return;
    final state = context.read<CanvasCubit>().state;
    final meta = state.items.map((e) => CanvasItemMeta.fromItem(e)).toList();
    if (_lastMeta == null || !_listEquals(_lastMeta!, meta)) {
      _lastMeta = meta;
      widget.onItemMetadataUpdate?.call(meta);
    }
  }

  bool _listEquals(List<CanvasItemMeta> a, List<CanvasItemMeta> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanvasCubit, CanvasState>(
      builder: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeCallMetadataUpdate(context);
        });
        final items = state.items..sort((a, b) => a.zIndex.compareTo(b.zIndex));
        final selectedItem = state.selectedItemId == null
            ? null
            : (items.where((e) => e.id == state.selectedItemId).isNotEmpty
                  ? items.where((e) => e.id == state.selectedItemId).first
                  : null);
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: widget.initialBackgroundColor ?? Colors.white,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.isPreviewMode
                    ? null
                    : () {
                        context.read<CanvasCubit>().selectItem(null);
                      },
                child: RepaintBoundary(
                  child: Container(
                    width:
                        widget.previewSize?.width ??
                        MediaQuery.of(context).size.width,
                    height:
                        widget.previewSize?.height ??
                        MediaQuery.of(context).size.height - 100,
                    decoration: BoxDecoration(
                      image: widget.initialBackgroundImage != null
                          ? DecorationImage(
                              image: widget.initialBackgroundImage!,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: RepaintBoundary(
                      key: widget.canvasKey,
                      child: Container(
                        width:
                            widget.previewSize?.width ??
                            MediaQuery.of(context).size.width,
                        height:
                            widget.previewSize?.height ??
                            MediaQuery.of(context).size.height - 100,
                        child: Stack(
                          alignment: Alignment.center,
                          fit: StackFit.expand,
                          clipBehavior: Clip.none,
                          children: [
                            ...items.map(
                              (item) => Positioned(
                                left: item.position.dx,
                                top: item.position.dy,
                                child: CanvasItemWidget(
                                  isLocked:
                                      widget
                                          .controller
                                          ?.selectedItem
                                          ?.isLocked ??
                                      false,
                                  floatingToolbarBuilder:
                                      CanvasItemWidget.defaultFloatingToolbarBuilder(
                                        widget.floatingItems,
                                        widget.specialFloatingItem,
                                        widget
                                                .controller
                                                ?.selectedItem
                                                ?.isLocked ??
                                            false,
                                      ),
                                  key: ValueKey(item.id),
                                  initialPosition: item.position,
                                  item: item,
                                  isSelected: item.isSelected,
                                  onTap: widget.isPreviewMode
                                      ? null
                                      : () {
                                          context
                                              .read<CanvasCubit>()
                                              .selectItem(item.id);
                                          context
                                              .read<CanvasCubit>()
                                              .bringToFront(item.id);
                                        },
                                  onMove: widget.isPreviewMode
                                      ? null
                                      : (delta) {
                                          final newPos = item.position + delta;
                                          context.read<CanvasCubit>().moveItem(
                                            item.id,
                                            newPos,
                                          );
                                        },
                                  onScale: widget.isPreviewMode
                                      ? null
                                      : (scale) {
                                          context.read<CanvasCubit>().scaleItem(
                                            item.id,
                                            scale,
                                          );
                                        },
                                  onRotate: widget.isPreviewMode
                                      ? null
                                      : (rotation) {
                                          context
                                              .read<CanvasCubit>()
                                              .rotateItem(item.id, rotation);
                                        },
                                  onFlip: widget.isPreviewMode
                                      ? null
                                      : () => context
                                            .read<CanvasCubit>()
                                            .flipItem(item.id),
                                  onRemove: widget.isPreviewMode
                                      ? null
                                      : () => context
                                            .read<CanvasCubit>()
                                            .removeItem(item.id),
                                  onBringToFront: widget.isPreviewMode
                                      ? null
                                      : () => context
                                            .read<CanvasCubit>()
                                            .bringToFront(item.id),
                                  onSendToBack: widget.isPreviewMode
                                      ? null
                                      : () => context
                                            .read<CanvasCubit>()
                                            .sendToBack(item.id),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!widget.isPreviewMode &&
                widget.toolbarBuilder != null &&
                widget.controller != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child:
                    widget.toolbarBuilder != null && widget.controller != null
                    ? widget.toolbarBuilder!(context, widget.controller!)
                    : widget.showDefaultToolbar
                    ? CanvasToolbar(
                        config: widget.toolbarOptions,
                        isPreviewMode: widget.isPreviewMode,
                        onAddImage: () async {
                          final type = await showDialog<String>(
                            context: context,
                            builder: (context) => SimpleDialog(
                              title: const Text('Add Image'),
                              children: [
                                SimpleDialogOption(
                                  onPressed: () =>
                                      Navigator.pop(context, 'network'),
                                  child: const Text('From Network URL'),
                                ),
                                SimpleDialogOption(
                                  onPressed: () =>
                                      Navigator.pop(context, 'local'),
                                  child: const Text('From Local Asset'),
                                ),
                                SimpleDialogOption(
                                  onPressed: () =>
                                      Navigator.pop(context, 'gallery'),
                                  child: const Text('From Gallery'),
                                ),
                                SimpleDialogOption(
                                  onPressed: () =>
                                      Navigator.pop(context, 'file'),
                                  child: const Text('From File'),
                                ),
                              ],
                            ),
                          );
                          String? source;
                          if (type == 'network') {
                            source = await pickNetworkImageUrl(context);
                          } else if (type == 'local') {
                            source = await pickLocalAssetPath(context);
                          } else if (type == 'gallery') {
                            final file = await pickImageFromGallery();
                            if (file != null) {
                              source = 'file://${file.path}';
                            }
                          } else if (type == 'file') {
                            final file = await pickImageFromFile();
                            if (file != null) {
                              source = 'file://${file.path}';
                            }
                          }
                          if (source != null && source.isNotEmpty) {
                            final id = UniqueKey().toString();
                            final now = DateTime.now();
                            final item = CanvasItem(
                              width: 100,
                              height: 100,
                              id: id,
                              source: source,
                              position: const Offset(100, 100),
                              scale: 1.0,
                              isSelected: true,
                              rotation: 0.0,
                              flipped: false,
                              cropRect: null,
                              zIndex: items.length,
                              isDeleted: false,
                              createdAt: now,
                              updatedAt: now,
                            );
                            context.read<CanvasCubit>().addItem(item);
                            context.read<CanvasCubit>().selectItem(item.id);
                          }
                        },
                        onUndo: () => context.read<CanvasCubit>().undo(),
                        onRedo: () => context.read<CanvasCubit>().redo(),
                        onReset: () => context.read<CanvasCubit>().reset(),
                        onBringToFront: state.selectedItemId == null
                            ? null
                            : () => context.read<CanvasCubit>().bringToFront(
                                state.selectedItemId!,
                              ),
                        onSendToBack: state.selectedItemId == null
                            ? null
                            : () => context.read<CanvasCubit>().sendToBack(
                                state.selectedItemId!,
                              ),
                        onExport: () async {
                          if (widget.canvasKey == null) return;
                          final path = await exportWidgetToPng(
                            widget.canvasKey!,
                          );
                          if (path != null) {
                            if (widget.onExport != null) widget.onExport!(path);
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Export Failed'),
                                content: SelectableText.rich(
                                  TextSpan(
                                    text: 'Failed to export canvas as PNG.',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        onZoomIn: state.selectedItemId == null
                            ? null
                            : () {
                                final item = selectedItem;
                                if (item != null) {
                                  context.read<CanvasCubit>().scaleItem(
                                    item.id,
                                    (item.scale * 1.1).clamp(0.2, 10.0),
                                  );
                                }
                              },
                        onZoomOut: state.selectedItemId == null
                            ? null
                            : () {
                                final item = selectedItem;
                                if (item != null) {
                                  context.read<CanvasCubit>().scaleItem(
                                    item.id,
                                    (item.scale / 1.1).clamp(0.2, 10.0),
                                  );
                                }
                              },
                        canUndo: state.undoStack.isNotEmpty,
                        canRedo: state.redoStack.isNotEmpty,
                        canBringToFront:
                            state.items.isNotEmpty &&
                            state.selectedItemId != null,
                        canSendToBack:
                            state.items.isNotEmpty &&
                            state.selectedItemId != null,
                        canRemove:
                            state.items.isNotEmpty &&
                            state.selectedItemId != null,
                        canZoom: state.selectedItemId != null,
                        canReset: state.items.isNotEmpty,
                        onRemove: state.selectedItemId == null
                            ? null
                            : () => context.read<CanvasCubit>().removeItem(
                                state.selectedItemId!,
                              ),
                        onRotateLeft: state.selectedItemId == null
                            ? null
                            : () => context.read<CanvasCubit>().rotateLeft(
                                state.selectedItemId!,
                              ),
                        onRotateRight: state.selectedItemId == null
                            ? null
                            : () => context.read<CanvasCubit>().rotateRight(
                                state.selectedItemId!,
                              ),
                        onFlipHorizontal: state.selectedItemId == null
                            ? null
                            : () => context.read<CanvasCubit>().flipHorizontal(
                                state.selectedItemId!,
                              ),
                        onFlipVertical: state.selectedItemId == null
                            ? null
                            : () => context.read<CanvasCubit>().flipVertical(
                                state.selectedItemId!,
                              ),
                      )
                    : SizedBox.shrink(),
              ),
          ],
        );
      },
    );
  }
}
