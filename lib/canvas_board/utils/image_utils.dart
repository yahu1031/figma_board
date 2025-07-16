import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Shows a dialog to enter a network image URL. Returns the URL or null.
Future<String?> pickNetworkImageUrl(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Enter Image URL'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: 'https://...'),
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.done,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final url = controller.text.trim();
            if (url.isNotEmpty) {
              Navigator.of(context).pop(url);
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

/// Pick an image from the device gallery. Returns a File or null.
Future<File?> pickImageFromGallery() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(source: ImageSource.gallery);
  return picked != null ? File(picked.path) : null;
}

/// Pick an image file from the device (any file). Returns a File or null.
Future<File?> pickImageFromFile() async {
  final result = await FilePicker.platform.pickFiles(type: FileType.image);
  if (result != null && result.files.single.path != null) {
    return File(result.files.single.path!);
  }
  return null;
}

/// Shows a dialog to enter a local asset image path. Returns the path or null.
Future<String?> pickLocalAssetPath(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Enter Asset Path'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'assets/images/example.png',
        ),
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final path = controller.text.trim();
            if (path.isNotEmpty) {
              Navigator.of(context).pop(path);
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
