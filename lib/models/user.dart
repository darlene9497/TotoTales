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