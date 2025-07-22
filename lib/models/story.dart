class Story {
  final String id;
  final String title;
  final String language;
  final String ageRange;
  final String category;
  final String coverImageUrl;
  final List<StoryPage> pages;
  final bool isPremium;
  final DateTime dateAdded;
  final int popularity;
  final String description;
  final bool isSaved;

  Story({
    required this.id,
    required this.title,
    required this.language,
    required this.ageRange,
    required this.category,
    required this.coverImageUrl,
    required this.pages,
    this.isPremium = false,
    required this.dateAdded,
    this.popularity = 0,
    required this.description,
    this.isSaved = false,
  });

  // copyWith method for updating save state
  Story copyWith({
    String? id,
    String? title,
    String? language,
    String? ageRange,
    String? category,
    String? coverImageUrl,
    List<StoryPage>? pages,
    bool? isPremium,
    DateTime? dateAdded,
    int? popularity,
    String? description,
    bool? isSaved,
  }) {
    return Story(
      id: id ?? this.id,
      title: title ?? this.title,
      language: language ?? this.language,
      ageRange: ageRange ?? this.ageRange,
      category: category ?? this.category,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      pages: pages ?? this.pages,
      isPremium: isPremium ?? this.isPremium,
      dateAdded: dateAdded ?? this.dateAdded,
      popularity: popularity ?? this.popularity,
      description: description ?? this.description,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'language': language,
      'ageRange': ageRange,
      'category': category,
      'coverImageUrl': coverImageUrl,
      'pages': pages.map((page) => page.toJson()).toList(),
      'isPremium': isPremium,
      'dateAdded': dateAdded.toIso8601String(),
      'popularity': popularity,
      'description': description,
      'isSaved': isSaved,
    };
  }

  // Create from JSON
  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      language: json['language'] ?? 'English',
      ageRange: json['ageRange'] ?? 'Ages 6-8',
      category: json['category'] ?? 'General',
      coverImageUrl: json['coverImageUrl'] ?? '',
      pages: (json['pages'] as List<dynamic>?)
          ?.map((pageJson) => StoryPage.fromJson(pageJson))
          .toList() ?? [],
      isPremium: json['isPremium'] ?? false,
      dateAdded: DateTime.parse(json['dateAdded'] ?? DateTime.now().toIso8601String()),
      popularity: json['popularity'] ?? 0,
      description: json['description'] ?? '',
      isSaved: json['isSaved'] ?? false,
    );
  }
}

class StoryPage {
  final int pageNumber;
  final String imageUrl;
  final String text;

  StoryPage({
    required this.pageNumber,
    required this.imageUrl,
    required this.text,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'imageUrl': imageUrl,
      'text': text,
    };
  }

  // Create from JSON
  factory StoryPage.fromJson(Map<String, dynamic> json) {
    return StoryPage(
      pageNumber: json['pageNumber'] ?? 1,
      imageUrl: json['imageUrl'] ?? '',
      text: json['text'] ?? '',
    );
  }
}