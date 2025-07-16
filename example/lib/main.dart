import 'dart:io';

import 'package:example/screenshot_exp.dart';
import 'package:figma_board/canvas_board/canvas_board.dart';
import 'package:figma_board/canvas_board/controller/canvas_board_controller.dart';
import 'package:figma_board/canvas_board/model/canvas_item.dart';
import 'package:figma_board/canvas_board/model/toolbar_config.dart';
import 'package:flutter/material.dart';
// NOTE: Add these dependencies to your pubspec.yaml:
// flutter_colorpicker: ^1.0.3
// image_picker: ^1.0.4
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';

// void main() {
//   runApp(const MyApp());
// }
void main() => runApp(MaterialApp(home: ImageGroupDemo()));


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CanvasBoard Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CanvasBoardDemo(),
    );
  }
}

class CanvasBoardDemo extends StatefulWidget {
  const CanvasBoardDemo({super.key});

  @override
  State<CanvasBoardDemo> createState() => _CanvasBoardDemoState();
}

class _CanvasBoardDemoState extends State<CanvasBoardDemo> {
  final GlobalKey _canvasKey = GlobalKey();
  String? _exportedPath;
  final CanvasBoardController _controller = CanvasBoardController();
  Color _backgroundColor = Colors.white;
  ImageProvider? _backgroundImage;

  Future<void> _pickBackgroundColor() async {
    Color tempColor = _backgroundColor;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick Background Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: tempColor,
            onColorChanged: (color) => tempColor = color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _backgroundColor = tempColor);
              Navigator.of(context).pop();
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBackgroundImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _backgroundImage = FileImage(File(image.path));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CanvasBoard(
        canvasKey: _canvasKey,
        initialBackgroundColor: _backgroundColor,
        initialBackgroundImage: _backgroundImage,
        toolbarOptions: const ToolbarConfig(
          showAddImage: true,
          showUndo: true,
          showRedo: true,
          showZoom: true,
          showExport: true,
          showReset: true,
          showLayerControls: true,
        ),
        specialFloatingItem: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            _controller.removeItem(_controller.selectedItem?.id ?? '');
          },
          tooltip: 'Delete',
        ),

        floatingItems: [
          IconButton(
            icon: Icon(Icons.crop),
            onPressed: () => print('Crop'),
            tooltip: 'Crop',
          ),
          IconButton(
            icon: Icon(Icons.flip),
            onPressed: () {
              _controller.flipHorizontal(_controller.selectedItem?.id ?? '');
            },
            tooltip: 'Flip Horizontal',
          ),
          IconButton(
            key: const ValueKey('_lockItem'),
            icon: Icon(Icons.lock),
            onPressed: () {
              _controller.setIsImageLocked(!_controller.isImageLocked);
              // setState(() {});
            },
            tooltip: 'Lock',
          ),
        ],
        controller: _controller,
        showDefaultToolbar: false,
        // toolbarBuilder: (context, controller) => MyCustomToolbar(
        //   controller: controller,
        //   onPickBackgroundColor: _pickBackgroundColor,
        //   onPickBackgroundImage: _pickBackgroundImage,
        // ),
        onExport: (path) {
          setState(() {
            _exportedPath = path;
          });
          print('path: $path');
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exported!'),
              content: SelectableText.rich(
                TextSpan(
                  text: 'PNG saved at:\n',
                  style: const TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: path,
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
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
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Row(
        children: [
          FloatingActionButton(
            onPressed: () async {
              _controller.selectItem(null);
              await Future.delayed(const Duration(milliseconds: 100), () async {
                final path = await _controller.exportAsImage(
                  _canvasKey,
                  imageFormat: 'png',
                );
                if (path != null) {
                  print('path: $path');
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Exported!'),
                      content: Text('PNG saved at:\n$path'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              });
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            elevation: 0,
            mini: true,
            child: const Icon(Icons.camera_alt),
          ),
          FloatingActionButton(
            onPressed: () {
              //
              _showAddImageDialog(context);
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            elevation: 0,
            mini: true,
            child: const Icon(Icons.add),
          ),
        ],
      ),
      // bottomNavigationBar: MyCustomToolbar(
      //   controller: _controller,
      //   onPickBackgroundColor: _pickBackgroundColor,
      //   onPickBackgroundImage: _pickBackgroundImage,
      //   // onAddImage: _showAddImageDialog,
      // ),
    );
  }

  Future<void> _showAddImageDialog(BuildContext context) async {
    final type = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Image', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context, 'network'),
              child: const Text(
                'From Network URL',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'local'),
              child: const Text(
                'From Local Asset',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'gallery'),
              child: const Text(
                'From Gallery',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'file'),
              child: const Text(
                'From File',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
    String? source;
    if (type == 'network') {
      final url = await showDialog<String>(
        context: context,
        builder: (context) {
          String input = '';
          return AlertDialog(
            title: const Text('Enter Image URL'),
            content: TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'https://...'),
              onChanged: (v) => input = v,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, input),
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
      if (url != null && url.isNotEmpty) source = url;
    } else if (type == 'local') {
      final asset = await showDialog<String>(
        context: context,
        builder: (context) {
          String input = '';
          return AlertDialog(
            title: const Text('Enter Asset Path'),
            content: TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'assets/images/...'),
              onChanged: (v) => input = v,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, input),
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
      if (asset != null && asset.isNotEmpty) source = asset;
    } else if (type == 'gallery') {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        source = 'file://${image.path}';
      }
    } else if (type == 'file') {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        source = 'file://${image.path}';
      }
    }
    if (source != null && source.isNotEmpty) {
      final id = UniqueKey().toString();
      final now = DateTime.now();
      _controller.addItem(
        CanvasItem(
          width: 100,
          height: 100,
          id: id,
          source: source,
          position: const Offset(100, 100),
          scale: 1.0,
          rotation: 0.0,
          isFlippedHorizontally: false,
          isFlippedVertically: false,
          flipped: false,
          cropRect: null,
          zIndex: _controller.items.length,
          isDeleted: false,
          createdAt: now,
          updatedAt: now,
          isSelected: true,
        ),
      );
      _controller.selectItem(id);
    }
  }
}

class MyCustomToolbar extends StatelessWidget {
  final CanvasBoardController controller;
  final VoidCallback onPickBackgroundColor;
  final VoidCallback onPickBackgroundImage;
  // final VoidCallback onAddImage;
  const MyCustomToolbar({
    super.key,
    required this.controller,
    required this.onPickBackgroundColor,
    required this.onPickBackgroundImage,
    // required this.onAddImage,
  });

  Future<void> _showAddImageDialog(BuildContext context) async {
    final type = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Add Image'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'network'),
            child: const Text('From Network URL'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'local'),
            child: const Text('From Local Asset'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'gallery'),
            child: const Text('From Gallery'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'file'),
            child: const Text('From File'),
          ),
        ],
      ),
    );
    String? source;
    if (type == 'network') {
      final url = await showDialog<String>(
        context: context,
        builder: (context) {
          String input = '';
          return AlertDialog(
            title: const Text('Enter Image URL'),
            content: TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'https://...'),
              onChanged: (v) => input = v,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, input),
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
      if (url != null && url.isNotEmpty) source = url;
    } else if (type == 'local') {
      final asset = await showDialog<String>(
        context: context,
        builder: (context) {
          String input = '';
          return AlertDialog(
            title: const Text('Enter Asset Path'),
            content: TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'assets/images/...'),
              onChanged: (v) => input = v,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, input),
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
      if (asset != null && asset.isNotEmpty) source = asset;
    } else if (type == 'gallery') {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        source = 'file://${image.path}';
      }
    } else if (type == 'file') {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        source = 'file://${image.path}';
      }
    }
    if (source != null && source.isNotEmpty) {
      final id = UniqueKey().toString();
      final now = DateTime.now();
      controller.addItem(
        CanvasItem(
          width: 100,
          height: 100,
          id: id,
          source: source,
          position: const Offset(100, 100),
          scale: 1.0,
          rotation: 0.0,
          isFlippedHorizontally: false,
          isFlippedVertically: false,
          flipped: false,
          cropRect: null,
          zIndex: controller.items.length,
          isDeleted: false,
          createdAt: now,
          updatedAt: now,
          isSelected: true,
        ),
      );
      controller.selectItem(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        child: Container(
          height: null,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.start,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: controller.canUndoNotifier,
                builder: (context, canUndo, _) => IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: 'Undo',
                  onPressed: canUndo ? controller.undo : null,
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: controller.canRedoNotifier,
                builder: (context, canRedo, _) => IconButton(
                  icon: const Icon(Icons.redo),
                  tooltip: 'Redo',
                  onPressed: canRedo ? controller.redo : null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.save_alt),
                tooltip: 'Export',
                onPressed: () async {
                  controller.selectItem(null);
                  final format = await showDialog<String>(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Export Format'),
                      children: [
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, 'png'),
                          child: const Text('PNG'),
                        ),
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, 'jpg'),
                          child: const Text('JPG'),
                        ),
                      ],
                    ),
                  );
                  if (format != null) {
                    final state = context
                        .findAncestorStateOfType<_CanvasBoardDemoState>();
                    final key = state?._canvasKey;
                    if (key != null) {
                      final path = await controller.exportAsImage(
                        key,
                        imageFormat: format,
                      );
                      if (path != null && context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Exported!'),
                            content: SelectableText.rich(
                              TextSpan(
                                text: 'Image saved at:\n',
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  TextSpan(
                                    text: path,
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ],
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
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_photo_alternate),
                tooltip: 'Add Image',
                onPressed: () => _showAddImageDialog(context),
              ),
              ValueListenableBuilder<CanvasItem?>(
                valueListenable: controller.selectedItemNotifier,
                builder: (context, selected, _) => IconButton(
                  icon: const Icon(Icons.flip),
                  tooltip: 'Flip Horizontal',
                  onPressed: selected != null
                      ? () => controller.flipHorizontal(selected.id)
                      : null,
                ),
              ),
              ValueListenableBuilder<CanvasItem?>(
                valueListenable: controller.selectedItemNotifier,
                builder: (context, selected, _) => IconButton(
                  icon: const Icon(Icons.flip_camera_android),
                  tooltip: 'Flip Vertical',
                  onPressed: selected != null
                      ? () => controller.flipVertical(selected.id)
                      : null,
                ),
              ),
              ValueListenableBuilder<CanvasItem?>(
                valueListenable: controller.selectedItemNotifier,
                builder: (context, selected, _) => IconButton(
                  icon: const Icon(Icons.rotate_left),
                  tooltip: 'Rotate Left',
                  onPressed: selected != null
                      ? () => controller.rotateItem(
                          selected.id,
                          selected.rotation - 0.25 * 3.141592653589793,
                        )
                      : null,
                ),
              ),
              ValueListenableBuilder<CanvasItem?>(
                valueListenable: controller.selectedItemNotifier,
                builder: (context, selected, _) => IconButton(
                  icon: const Icon(Icons.rotate_right),
                  tooltip: 'Rotate Right',
                  onPressed: selected != null
                      ? () => controller.rotateItem(
                          selected.id,
                          selected.rotation + 0.25 * 3.141592653589793,
                        )
                      : null,
                ),
              ),
              ValueListenableBuilder<CanvasItem?>(
                valueListenable: controller.selectedItemNotifier,
                builder: (context, selected, _) => IconButton(
                  icon: const Icon(Icons.zoom_in),
                  tooltip: 'Zoom In',
                  onPressed: selected != null
                      ? () => controller.scaleItem(
                          selected.id,
                          selected.scale + 0.07,
                        )
                      : null,
                ),
              ),
              ValueListenableBuilder<CanvasItem?>(
                valueListenable: controller.selectedItemNotifier,
                builder: (context, selected, _) => IconButton(
                  icon: const Icon(Icons.zoom_out),
                  tooltip: 'Zoom Out',
                  onPressed: selected != null && selected.scale > 0.07
                      ? () => controller.scaleItem(
                          selected.id,
                          selected.scale - 0.07,
                        )
                      : null,
                ),
              ),
              ValueListenableBuilder<CanvasItem?>(
                valueListenable: controller.selectedItemNotifier,
                builder: (context, selected, _) => IconButton(
                  icon: const Icon(Icons.vertical_align_top),
                  tooltip: 'Bring to Front',
                  onPressed: selected != null
                      ? () => controller.bringToFront(selected.id)
                      : null,
                ),
              ),
              ValueListenableBuilder<CanvasItem?>(
                valueListenable: controller.selectedItemNotifier,
                builder: (context, selected, _) => IconButton(
                  icon: const Icon(Icons.vertical_align_bottom),
                  tooltip: 'Send to Back',
                  onPressed: selected != null
                      ? () => controller.sendToBack(selected.id)
                      : null,
                ),
              ),
              ValueListenableBuilder<CanvasItem?>(
                valueListenable: controller.selectedItemNotifier,
                builder: (context, selected, _) => IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  onPressed: selected != null
                      ? () => controller.removeItem(selected.id)
                      : null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Reset',
                onPressed: controller.reset,
              ),
              IconButton(
                icon: const Icon(Icons.format_color_fill),
                tooltip: 'Background Color',
                onPressed: onPickBackgroundColor,
              ),
              IconButton(
                icon: const Icon(Icons.image),
                tooltip: 'Background Image',
                onPressed: onPickBackgroundImage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
