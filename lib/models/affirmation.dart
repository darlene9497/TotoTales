import 'package:cloud_firestore/cloud_firestore.dart';

class Affirmation {
  final String id;
  final String text;
  final String ageRange;
  final String category;
  final String backgroundImageUrl;
  final DateTime? createdAt;
  final bool isFavorite;
  final int usageCount;
  final Map<String, dynamic>? metadata;

  Affirmation({
    required this.id,
    required this.text,
    required this.ageRange,
    required this.category,
    required this.backgroundImageUrl,
    this.createdAt,
    this.isFavorite = false,
    this.usageCount = 0,
    this.metadata,
  });

  /// Create an Affirmation from JSON data
  factory Affirmation.fromJson(Map<String, dynamic> json) {
    return Affirmation(
      id: json['id'] as String,
      text: json['text'] as String,
      ageRange: json['ageRange'] as String,
      category: json['category'] as String,
      backgroundImageUrl: json['backgroundImageUrl'] as String,
      createdAt: json['createdAt'] != null 
        ? (json['createdAt'] is Timestamp 
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String))
        : null,
      isFavorite: json['isFavorite'] as bool? ?? false,
      usageCount: json['usageCount'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert Affirmation to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'ageRange': ageRange,
      'category': category,
      'backgroundImageUrl': backgroundImageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'isFavorite': isFavorite,
      'usageCount': usageCount,
      'metadata': metadata,
    };
  }

  /// Create a copy of this affirmation with some fields changed
  Affirmation copyWith({
    String? id,
    String? text,
    String? ageRange,
    String? category,
    String? backgroundImageUrl,
    DateTime? createdAt,
    bool? isFavorite,
    int? usageCount,
    Map<String, dynamic>? metadata,
  }) {
    return Affirmation(
      id: id ?? this.id,
      text: text ?? this.text,
      ageRange: ageRange ?? this.ageRange,
      category: category ?? this.category,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      usageCount: usageCount ?? this.usageCount,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get formatted category name for display
  String get formattedCategory {
    return category
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
          ? word[0].toUpperCase() + word.substring(1).toLowerCase()
          : word)
        .join(' ');
  }

  /// Get age-appropriate text size
  double get textSize {
    switch (ageRange) {
      case 'Ages 3-5':
        return 24.0;
      case 'Ages 6-8':
        return 22.0;
      case 'Ages 9-12':
        return 20.0;
      default:
        return 22.0;
    }
  }

  /// Get color for age range
  String get ageColor {
    switch (ageRange) {
      case 'Ages 3-5':
        return '#FF6B6B'; // Red-pink for little explorers
      case 'Ages 6-8':
        return '#4ECDC4'; // Teal for bright learners
      case 'Ages 9-12':
        return '#45B7D1'; // Blue for junior dreamers
      default:
        return '#6C5CE7'; // Purple as default
    }
  }

  /// Check if affirmation is for specific age range
  bool isForAgeRange(String targetAgeRange) {
    return ageRange == targetAgeRange;
  }

  /// Check if affirmation belongs to specific category
  bool isInCategory(String targetCategory) {
    return category.toLowerCase() == targetCategory.toLowerCase();
  }

  /// Get short preview of the affirmation text
  String get preview {
    if (text.length <= 50) return text;
    return '${text.substring(0, 47)}...';
  }

  /// Check if this is a daily affirmation (based on metadata)
  bool get isDailyAffirmation {
    return metadata?['isDaily'] == true;
  }

  /// Get the source of the affirmation (AI-generated or fallback)
  String get source {
    return metadata?['source'] ?? 'ai';
  }

  /// Mark as favorite
  Affirmation markAsFavorite() {
    return copyWith(isFavorite: true);
  }

  /// Remove from favorites
  Affirmation removeFromFavorites() {
    return copyWith(isFavorite: false);
  }

  /// Increment usage count
  Affirmation incrementUsage() {
    return copyWith(usageCount: usageCount + 1);
  }

  /// Get word count for analytics
  int get wordCount {
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Get estimated reading time in seconds
  int get estimatedReadingTime {
    // Average reading speed for children: 100-200 words per minute
    // Using 150 WPM as middle ground
    const wordsPerMinute = 150;
    const wordsPerSecond = wordsPerMinute / 60;
    return (wordCount / wordsPerSecond).ceil();
  }

  /// Check if affirmation contains specific keyword
  bool containsKeyword(String keyword) {
    return text.toLowerCase().contains(keyword.toLowerCase());
  }

  /// Get affirmation tags for categorization
  List<String> get tags {
    final tags = <String>[category, ageRange];
    
    // Add content-based tags
    if (text.toLowerCase().contains('brave') || text.toLowerCase().contains('courage')) {
      tags.add('courage');
    }
    if (text.toLowerCase().contains('smart') || text.toLowerCase().contains('intelligent')) {
      tags.add('intelligence');
    }
    if (text.toLowerCase().contains('kind') || text.toLowerCase().contains('caring')) {
      tags.add('kindness');
    }
    if (text.toLowerCase().contains('strong') || text.toLowerCase().contains('powerful')) {
      tags.add('strength');
    }
    
    return tags.toSet().toList(); // Remove duplicates
  }

  /// Create a shareable format
  String toShareableText() {
    return '''
✨ Today's Affirmation ✨

"$text"

- For: $ageRange
- Category: $formattedCategory
- From: TotoTales 📚

#TotoTales #KidsAffirmations #$category
    '''.trim();
  }

  @override
  String toString() {
    return 'Affirmation(id: $id, text: $text, ageRange: $ageRange, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Affirmation &&
        other.id == id &&
        other.text == text &&
        other.ageRange == ageRange &&
        other.category == category;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        text.hashCode ^
        ageRange.hashCode ^
        category.hashCode;
  }
}