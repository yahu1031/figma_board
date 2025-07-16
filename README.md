<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.

# CanvasBoard (Figma-style Flutter Canvas)

A modular, responsive, Figma-like canvas board for Flutter. Supports adding images (network/local), move, scale, rotate, flip, z-order, remove, undo/redo, export as PNG, zoom, and more. No 3rd-party UI packages, pure Flutter SDK + Bloc.

## Features
- Add image (network URL or local asset)
- Move, scale, rotate, flip, crop, remove
- Layer management (bring to front, send to back)
- Undo/redo
- Export as PNG
- Zoom in/out
- Responsive, theme-aware
- Error/empty state handling

## Dependencies
Add these to your `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.0
  path_provider: ^2.0.0
```

## Usage Example
```dart
import 'package:your_package/canvas_board/canvas_board.dart';
import 'package:flutter/material.dart';

class MyCanvasScreen extends StatelessWidget {
  final GlobalKey canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Canvas Board')),
      body: CanvasBoard(
        canvasKey: canvasKey,
        initialBackgroundColor: Colors.white,
        toolbarOptions: const ToolbarConfig(
          showAddImage: true,
          showUndo: true,
          showRedo: true,
          showZoom: true,
          showExport: true,
          showReset: true,
          showLayerControls: true,
        ),
        onExport: (path) {
          // Handle exported PNG file path
          debugPrint('Exported to: $path');
        },
      ),
    );
  }
}
```

## Preview Mode
```dart
CanvasBoard.preview(
  previewSize: const Size(300, 500),
  initialItems: [...],
  initialBackgroundColor: Colors.grey[100],
)
```

## Notes
- For local assets, add image paths to your pubspec.yaml assets section.
- For export, path_provider is required for file system access.
- All error messages are shown using SelectableText.rich (no SnackBars).
- Undo/redo, z-order, and all actions are managed via Bloc/Cubit.

## License
MIT
