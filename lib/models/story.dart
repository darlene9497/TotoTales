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
  });
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
}

class User {
  final String id;
  final String name;
  final String selectedAgeRange;
  final String preferredLanguage;
  final bool isPremium;
  final List<String> completedStories;
  final DateTime lastActive;

  User({
    required this.id,
    required this.name,
    required this.selectedAgeRange,
    required this.preferredLanguage,
    this.isPremium = false,
    this.completedStories = const [],
    required this.lastActive,
  });
}

class Affirmation {
  final String id;
  final String text;
  final String ageRange;
  final String category;
  final String backgroundImageUrl;

  Affirmation({
    required this.id,
    required this.text,
    required this.ageRange,
    required this.category,
    required this.backgroundImageUrl,
  });
}