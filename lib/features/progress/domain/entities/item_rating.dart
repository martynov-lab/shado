/// Lowest and highest star rating; `0` means no rating.
const int kMinStars = 1;
const int kMaxStars = 5;

/// How well the user knows one lesson item, from 1 to 5 stars.
class ItemRating {
  const ItemRating({
    required this.lessonId,
    required this.itemKey,
    required this.stars,
    required this.ratedAt,
  });

  factory ItemRating.fromJson(Map<String, dynamic> json) => ItemRating(
    lessonId: json['lesson_id'] as String? ?? '',
    itemKey: json['item_key'] as String? ?? '',
    stars: (json['stars'] as num?)?.toInt() ?? 0,
    ratedAt:
        DateTime.tryParse(json['rated_at'] as String? ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  final String lessonId;

  /// `p:<phrase id>` or `s:<segment text hash>`.
  final String itemKey;

  /// 1–5; `0` removes the rating.
  final int stars;

  /// When the user rated; the later rating wins between devices.
  final DateTime ratedAt;

  Map<String, dynamic> toJson() => {
    'lesson_id': lessonId,
    'item_key': itemKey,
    'stars': stars,
    'rated_at': ratedAt.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemRating &&
          other.lessonId == lessonId &&
          other.itemKey == itemKey &&
          other.stars == stars &&
          other.ratedAt == ratedAt;

  @override
  int get hashCode => Object.hash(lessonId, itemKey, stars, ratedAt);

  @override
  String toString() => 'ItemRating($lessonId, $itemKey, $stars)';
}
