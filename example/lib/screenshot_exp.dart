import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';

void main() => runApp(MaterialApp(home: ImageGroupDemo()));

class ImageItem {
  Offset position;
  File file;
  Size size;
  ImageItem({required this.position, required this.file, required this.size});
}

class ImageGroupDemo extends StatefulWidget {
  const ImageGroupDemo({super.key});

  @override
  State<ImageGroupDemo> createState() => _ImageGroupDemoState();
}

class _ImageGroupDemoState extends State<ImageGroupDemo> {
  List<ImageItem> images = [];
  final ImagePicker picker = ImagePicker();
  final Random random = Random();

  // Pick image from gallery and add to group with a default position
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final imageFile = File(picked.path);
      final decodedImage = await decodeImageFromList(
        await imageFile.readAsBytes(),
      );
      final imgSize = Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );

      // SCALE TO HALF SIZE
      final scaledSize = Size(imgSize.width * 0.5, imgSize.height * 0.5);

      setState(() {
        images.add(
          ImageItem(
            file: imageFile,
            position: Offset(
              40.0 + random.nextInt(100),
              60.0 + random.nextInt(100),
            ),
            size: scaledSize,
          ),
        );
      });
    }
  }

  Rect? getGroupBoundingBox() {
    if (images.isEmpty) return null;
    double minX = images.map((e) => e.position.dx).reduce(min);
    double minY = images.map((e) => e.position.dy).reduce(min);
    double maxX = images.map((e) => e.position.dx + e.size.width).reduce(max);
    double maxY = images.map((e) => e.position.dy + e.size.height).reduce(max);
    return Rect.fromLTRB(minX - 18, minY - 18, maxX + 18, maxY + 18);
  }

  ImageGroupBoardController controller = ImageGroupBoardController();
  final GlobalKey repaintBoundaryKey = GlobalKey();
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Image Group Board Controller Demo"),
        actions: [
          IconButton(
            icon: Icon(Icons.rotate_left),
            onPressed: () {
              if (controller.items.isNotEmpty) {
                controller.rotateImage(controller.items.last.id, -15);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.flip),
            onPressed: () {
              if (controller.items.isNotEmpty) {
                controller.flipImage(controller.items.last.id);
              }
            },
          ),
          // ... More buttons for resize/crop etc
        ],
      ),
      body: ImageGroupBoard(
        controller: controller,
        repaintBoundaryKey: repaintBoundaryKey,
        screenshotController: screenshotController,
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: () async {
              controller.export(context, screenshotController);
            },
            child: Icon(Icons.camera_alt),
          ),
          SizedBox(width: 100),
          FloatingActionButton(
            onPressed: () async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: ImageSource.gallery,
              );
              if (picked != null) {
                final imageFile = File(picked.path);
                final decodedImage = await decodeImageFromList(
                  await imageFile.readAsBytes(),
                );
                final imgSize = Size(
                  decodedImage.width * 0.5,
                  decodedImage.height * 0.5,
                );
                controller.addImage(imageFile, imgSize);
              }
            },
            child: Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class ImageAction {
  final String id;
  ImageAction(this.id);
}

class ImageGroupBoard extends StatefulWidget {
  final ImageGroupBoardController controller;
  final GlobalKey repaintBoundaryKey;
  final ScreenshotController screenshotController;
  const ImageGroupBoard({
    super.key,
    required this.controller,
    required this.repaintBoundaryKey,
    required this.screenshotController,
  });

  @override
  State<ImageGroupBoard> createState() => _ImageGroupBoardState();
}

class _ImageGroupBoardState extends State<ImageGroupBoard> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    widget.controller.onUpdate = () => setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      boardSize = MediaQuery.of(context).size;
    });
  }

  late Size boardSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    boardSize = MediaQuery.of(context).size;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  Size getGroupSize(List<_ImageItemData> groupItems) {
    if (groupItems.isEmpty) return Size.zero;

    double minX = groupItems
        .map((e) => e.position.dx)
        .reduce((a, b) => a < b ? a : b);
    double minY = groupItems
        .map((e) => e.position.dy)
        .reduce((a, b) => a < b ? a : b);
    double maxX = groupItems
        .map((e) => e.position.dx + e.size.width * e.scale)
        .reduce((a, b) => a > b ? a : b);
    double maxY = groupItems
        .map((e) => e.position.dy + e.size.height * e.scale)
        .reduce((a, b) => a > b ? a : b);

    return Size(maxX - minX + 68, maxY - minY + 68);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.controller.items;
    final groupRect = images.isEmpty ? null : _calculateBoundingBox(images);

    return GestureDetector(
      onTap: () => widget.controller.unselectImage(),
      child: Screenshot(
        controller: widget.screenshotController,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.transparent,
          child: RepaintBoundary(
            key: widget.repaintBoundaryKey,
            child: Stack(
              children: [
                if (groupRect != null)
                  Positioned(
                    left: groupRect.left,
                    top: groupRect.top,
                    width: groupRect.width,
                    height: groupRect.height,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.11),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.blue, width: 1.5),
                      ),
                    ),
                  ),
                ...images.map((item) => _buildImageItem(item)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Offset _clampPosition(
    Offset pos,
    Size itemSize,
    Size boardSize, {
    double bottomMargin = 26,
    double margin = 0,
  }) {
    double x = pos.dx;
    double y = pos.dy;
    // Left, right, top clamp as usual
    if (x < margin) x = margin;
    if (y < margin) y = margin;
    if (x + itemSize.width > boardSize.width - margin)
      x = boardSize.width - margin - itemSize.width;
    // Bottom only, extra 26
    if (y + itemSize.height > boardSize.height - bottomMargin)
      y = boardSize.height - bottomMargin - itemSize.height;
    return Offset(x, y);
  }

  Widget _buildImageItem(_ImageItemData item) {
    final isSelected = widget.controller.selectedImageId == item.id;
    // For vertical centering of the column:
    final buttonColumnHeight = 220.0; // Adjust as per number of buttons

    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: GestureDetector(
        onTap: () {
          widget.controller.selectImage(item.id);
        },
        onPanUpdate: (details) {
          final newPos = item.position + details.delta;
          final clamped = _clampPosition(
            newPos,
            item.size,
            boardSize,
            margin: 26, // or your left/right/top margin
            bottomMargin: 100, // 26px only for bottom!
          );
          widget.controller.moveImage(item.id, clamped);
        },

        onLongPress: () {
          widget.controller.removeImage(item.id);
          if (widget.controller.selectedImageId == item.id) {
            widget.controller.unselectImage();
          }
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Image with border and shadow
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..scale(item.flipped ? -item.scale : item.scale, item.scale)
                ..rotateZ(item.rotation * 3.1415927 / 180),
              child: Container(
                width: item.size.width,
                height: item.size.height,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.deepPurple
                        : Colors.grey.shade300,
                    width: isSelected ? 2.2 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.08),
                        blurRadius: 14,
                      ),
                  ],
                ),
                child: Image.file(
                  item.file,
                  width: item.size.width,
                  height: item.size.height,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Only if selected, show vertical floating action column
            if (isSelected)
              Positioned(
                right: -60,
                top: (item.size.height / 2) - (buttonColumnHeight / 2),
                child: _FloatingActionColumn(
                  onCrop: () {}, // TODO: implement crop
                  onResize: () {}, // TODO: implement resize
                  onLock: () {}, // TODO: implement lock
                  onDelete: () {
                    widget.controller.removeImage(item.id);
                    widget.controller.unselectImage();
                  },
                  onFlip: () => widget.controller.flipImage(item.id),
                  onRotate: () => widget.controller.rotateImage(item.id, 15),
                ),
              ),
            // Optional: Bottom-right corner resize handle
            if (isSelected)
              Positioned(
                right: -15,
                bottom: -15,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final newSize = Size(
                      max(item.size.width + details.delta.dx, 50),
                      max(item.size.height + details.delta.dy, 50),
                    );
                    widget.controller.resizeImage(item.id, newSize);
                  },
                  child: Material(
                    elevation: 2,
                    shape: CircleBorder(),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.open_in_full,
                        size: 19,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Rect _calculateBoundingBox(List<_ImageItemData> items) {
    double minX = items.map((e) => e.position.dx).reduce(min);
    double minY = items.map((e) => e.position.dy).reduce(min);
    double maxX = items
        .map((e) => e.position.dx + e.size.width * e.scale)
        .reduce(max);
    double maxY = items
        .map((e) => e.position.dy + e.size.height * e.scale)
        .reduce(max);
    return Rect.fromLTRB(minX - 18, minY - 18, maxX + 18, maxY + 18);
  }
}

class _FloatingActionColumn extends StatelessWidget {
  final VoidCallback? onCrop, onResize, onLock, onDelete, onFlip, onRotate;
  const _FloatingActionColumn({
    this.onCrop,
    this.onResize,
    this.onLock,
    this.onDelete,
    this.onFlip,
    this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(32),
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FloatIconBtn(icon: Icons.crop, onTap: onCrop),
            SizedBox(height: 10),
            _FloatIconBtn(icon: Icons.straighten, onTap: onResize),
            SizedBox(height: 10),
            _FloatIconBtn(icon: Icons.lock_outline, onTap: onLock),
            SizedBox(height: 10),
            _FloatIconBtn(icon: Icons.flip, onTap: onFlip),
            SizedBox(height: 10),
            _FloatIconBtn(icon: Icons.rotate_right, onTap: onRotate),
            SizedBox(height: 16),
            _FloatIconBtn(
              icon: Icons.delete,
              color: Colors.red,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _FloatIconBtn({
    required this.icon,
    this.color = Colors.black87,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: CircleBorder(),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        customBorder: CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class ImageGroupBoardController extends ChangeNotifier {
  // Internal list to hold images and their properties
  final List<_ImageItemData> _items = [];
  Function()? onUpdate;

  String? selectedImageId;

  void selectImage(String id) {
    selectedImageId = id;
    notifyListeners();
    onUpdate?.call();
  }

  Future<String?> exportGroupAsImage(
    BuildContext context,
    ScreenshotController controller,
  ) async {
    try {
      final Uint8List? bytes = await controller.capture(pixelRatio: 3.0);
      if (bytes == null) return null;
      final directory = Directory.systemTemp;
      final filePath =
          '${directory.path}/group_export_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      debugPrint("Export failed: $e");
      return null;
    }
  }

  void export(BuildContext context, ScreenshotController controller) async {
    final path = await exportGroupAsImage(context, controller);
    print("Saved group image: $path");
  }

  /// Helper to render widget to boundary (offscreen)
  Future<RenderRepaintBoundary?> _renderWidgetToBoundary(
    Widget widget,
    GlobalKey key,
    Size size, {
    double pixelRatio = 3.0,
  }) async {
    final repaintBoundary = key;
    final overlay = OverlayEntry(
      builder: (_) => Center(
        child: SizedBox(width: size.width, height: size.height, child: widget),
      ),
    );
    final context = WidgetsBinding.instance.rootElement!;
    Overlay.of(context, rootOverlay: true).insert(overlay);

    await Future.delayed(Duration(milliseconds: 50));
    RenderRepaintBoundary? boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    overlay.remove();
    return boundary;
  }

  Future<String?> exportAsImage(GlobalKey boardKey) async {
    try {
      // 1. Get the render boundary
      RenderRepaintBoundary boundary =
          boardKey.currentContext?.findRenderObject() as RenderRepaintBoundary;

      // 2. Convert to image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return null;

      // 3. Get directory to save
      final directory = Directory.systemTemp;
      final filePath =
          '${directory.path}/canvas_export_${DateTime.now().millisecondsSinceEpoch}.png';

      // 4. Save image to file
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return filePath;
    } catch (e) {
      debugPrint('Export failed: $e');
      return null;
    }
  }

  void unselectImage() {
    selectedImageId = null;
    notifyListeners();
    onUpdate?.call();
  }

  // Expose current images
  List<_ImageItemData> get items => List.unmodifiable(_items);

  // Add new image
  void addImage(File file, Size size, {Offset? position}) {
    final item = _ImageItemData(
      id: UniqueKey().toString(),
      file: file,
      position: position ?? Offset(50, 50),
      size: size,
      scale: 1.0,
      rotation: 0.0,
      flipped: false,
      cropRect: null,
    );
    _items.add(item);
    notifyListeners();
    onUpdate?.call();
  }

  // Remove image
  void removeImage(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    onUpdate?.call();
  }

  // Resize image
  void resizeImage(String id, Size newSize) {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx].size = newSize;
      notifyListeners();
      onUpdate?.call();
    }
  }

  // Flip image horizontally
  void flipImage(String id) {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx].flipped = !_items[idx].flipped;
      notifyListeners();
      onUpdate?.call();
    }
  }

  // Rotate image by degrees
  void rotateImage(String id, double degrees) {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx].rotation = (_items[idx].rotation + degrees) % 360;
      notifyListeners();
      onUpdate?.call();
    }
  }

  // Crop image
  void cropImage(String id, Rect cropRect) {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx].cropRect = cropRect;
      notifyListeners();
      onUpdate?.call();
    }
  }

  // Move image
  void moveImage(String id, Offset newPosition) {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx].position = newPosition;
      notifyListeners();
      onUpdate?.call();
    }
  }

  // Set scale (for pinch zoom)
  void scaleImage(String id, double scale) {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx].scale = scale;
      notifyListeners();
      onUpdate?.call();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
    onUpdate?.call();
  }
}

// You can move this to a separate file/class for clarity
class _ImageItemData {
  final String id;
  File file;
  Offset position;
  Size size;
  double scale;
  double rotation;
  bool flipped;
  Rect? cropRect;

  _ImageItemData({
    required this.id,
    required this.file,
    required this.position,
    required this.size,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.flipped = false,
    this.cropRect,
  });
}
