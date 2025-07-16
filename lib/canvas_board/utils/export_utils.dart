// Requires path_provider dependency. Add to pubspec.yaml:
// dependencies:
//   path_provider: ^2.0.0
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

/// Exports the widget referenced by [boundaryKey] as an image file.
/// [imageFormat] can be 'png' (default) or 'jpg'.
/// Returns the file path, or null if failed.
Future<String?> exportWidgetToImage(
  GlobalKey boundaryKey, {
  String imageFormat = 'png',
}) async {
  try {
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData;
    Uint8List bytes;
    String ext = imageFormat.toLowerCase();
    if (ext == 'jpg' || ext == 'jpeg') {
      // Get raw RGBA bytes and encode to JPEG using image package
      byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;
      final img.Image baseSize = img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: byteData.buffer,
        order: img.ChannelOrder.rgba,
      );
      bytes = Uint8List.fromList(img.encodeJpg(baseSize));
      ext = 'jpg';
    } else {
      // Default to PNG
      byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      bytes = byteData.buffer.asUint8List();
      ext = 'png';
    }
    final dir = Directory.systemTemp;
    final file = File(
      '${dir.path}/canvas_export_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    await file.writeAsBytes(bytes);
    return file.path;
  } catch (e) {
    return null;
  }
}

/// Backward compatible PNG export
Future<String?> exportWidgetToPng(GlobalKey boundaryKey) =>
    exportWidgetToImage(boundaryKey, imageFormat: 'png');
