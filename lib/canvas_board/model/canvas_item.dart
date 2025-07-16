// CanvasItem model for CanvasBoard
import 'dart:ui';

class CanvasItem {
  final String id;
  final String source; // URL or asset path
  final Offset position;
  final double scale;
  final double rotation;
  final bool isFlippedHorizontally;
  final bool isFlippedVertically;
  // Deprecated: use isFlippedHorizontally instead
  final bool flipped;
  final Rect? cropRect;
  final int zIndex;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSelected;
  final bool isLocked;
  final double width;
  final double? height;

  const CanvasItem({
    required this.id,
    required this.source,
    this.width = 150,
    this.height,
    this.position = const Offset(0, 0),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.isFlippedHorizontally = false,
    this.isFlippedVertically = false,
    this.flipped = false,
    this.cropRect,
    this.zIndex = 0,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.isLocked = false,
    this.isSelected = false,
  });

  factory CanvasItem.fromImage(String id, String source) =>
      CanvasItem(id: id, source: source);

  CanvasItem copyWith({
    String? id,
    String? source,
    double? width,
    double? height,
    bool? isLocked,
    Offset? position,
    double? scale,
    double? rotation,
    bool? isFlippedHorizontally,
    bool? isFlippedVertically,
    bool? flipped,
    Rect? cropRect,
    int? zIndex,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSelected,
  }) => CanvasItem(
    id: id ?? this.id,
    source: source ?? this.source,
    width: width ?? this.width,
    height: height ?? this.height,
    isLocked: isLocked ?? this.isLocked,
    position: position ?? this.position,
    scale: scale ?? this.scale,
    rotation: rotation ?? this.rotation,
    isFlippedHorizontally: isFlippedHorizontally ?? this.isFlippedHorizontally,
    isFlippedVertically: isFlippedVertically ?? this.isFlippedVertically,
    flipped: flipped ?? this.flipped,
    cropRect: cropRect ?? this.cropRect,
    zIndex: zIndex ?? this.zIndex,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isSelected: isSelected ?? this.isSelected,
  );

  factory CanvasItem.fromJson(Map<String, dynamic> json) => CanvasItem(
    id: json['id'] as String,
    source: json['source'] as String,
    width: (json['width'] as num?)?.toDouble() ?? 100.0,
    height: (json['height'] as num?)?.toDouble() ?? 100.0,
    position: Offset(
      (json['position']['dx'] as num).toDouble(),
      (json['position']['dy'] as num).toDouble(),
    ),
    scale: (json['scale'] as num).toDouble(),
    rotation: (json['rotation'] as num).toDouble(),
    isFlippedHorizontally:
        json['isFlippedHorizontally'] as bool? ??
        json['flipped'] as bool? ??
        false,
    isFlippedVertically: json['isFlippedVertically'] as bool? ?? false,
    flipped: json['flipped'] as bool? ?? false,
    cropRect: json['cropRect'] != null
        ? Rect.fromLTWH(
            (json['cropRect']['left'] as num).toDouble(),
            (json['cropRect']['top'] as num).toDouble(),
            (json['cropRect']['width'] as num).toDouble(),
            (json['cropRect']['height'] as num).toDouble(),
          )
        : null,
    zIndex: json['zIndex'] as int,
    isDeleted: json['isDeleted'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    isSelected: json['isSelected'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'width': width,
    'height': height,
    'position': {'dx': position.dx, 'dy': position.dy},
    'scale': scale,
    'rotation': rotation,
    'isFlippedHorizontally': isFlippedHorizontally,
    'isFlippedVertically': isFlippedVertically,
    'flipped': flipped,
    'cropRect': cropRect != null
        ? {
            'left': cropRect!.left,
            'top': cropRect!.top,
            'width': cropRect!.width,
            'height': cropRect!.height,
          }
        : null,
    'zIndex': zIndex,
    'isDeleted': isDeleted,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}

class CanvasItemMeta {
  final String id;
  final String source;
  final Offset position;
  final double scale;
  final int zIndex;
  final double rotation;
  final bool isFlippedHorizontally;
  final bool isFlippedVertically;
  @Deprecated('use isFlippedHorizontally/isFlippedVertically instead')
  final bool flipped;
  final Rect? cropRect;

  const CanvasItemMeta({
    required this.id,
    required this.source,
    required this.position,
    required this.scale,
    required this.rotation,
    this.isFlippedHorizontally = false,
    this.isFlippedVertically = false,
    this.flipped = false,
    this.zIndex = 0,
    this.cropRect,
  });

  factory CanvasItemMeta.fromItem(CanvasItem item) => CanvasItemMeta(
    id: item.id,
    source: item.source,
    position: item.position,
    scale: item.scale,
    rotation: item.rotation,
    isFlippedHorizontally: item.isFlippedHorizontally,
    isFlippedVertically: item.isFlippedVertically,
    flipped: item.flipped,
    cropRect: item.cropRect,
    zIndex: item.zIndex,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'position': {'dx': position.dx, 'dy': position.dy},
    'scale': scale,
    'rotation': rotation,
    'zIndex': zIndex,
    'isFlippedHorizontally': isFlippedHorizontally,
    'isFlippedVertically': isFlippedVertically,
    // 'flipped': flipped,
    'cropRect': cropRect != null
        ? {
            'left': cropRect!.left,
            'top': cropRect!.top,
            'width': cropRect!.width,
            'height': cropRect!.height,
          }
        : null,
  };
}
