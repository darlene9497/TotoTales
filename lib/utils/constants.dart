class AppConstants {
  // App Info
  static const String appName = 'TotoTales';
  static const String appTagline = 'Magical Stories for Every Child';
  
  // Age Categories
  static const String littleExplorers = 'Little Explorers';
  static const String brightLearners = 'Bright Learners';
  static const String juniorDreamers = 'Junior Dreamers';
  
  static const String littleExplorersAge = 'Ages 3-5';
  static const String brightLearnersAge = 'Ages 6-8';
  static const String juniorDreamersAge = 'Ages 9-12';
  
  static const String littleExplorersDescription = 'Simple stories with big pictures';
  static const String brightLearnersDescription = 'Fun adventures and learning';
  static const String juniorDreamersDescription = 'Exciting tales and mysteries';
  
  // Languages
  static const Map<String, String> languages = {
    'English': '🇬🇧',
    'Swahili': '🇰🇪',
    'French': '🇫🇷',
    'German': '🇩🇪',
    'Dutch': '🇳🇱',
    'Spanish': '🇪🇸',
    'Portuguese': '🇵🇹',
  };
  
  static const List<String> freeLanguages = ['English', 'Swahili', 'French'];
  static const List<String> premiumLanguages = ['German', 'Dutch', 'Spanish', 'Portuguese'];
  
  // UI Constants
  static const double defaultPadding = 20.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  
  // Animation Durations
  static const int splashDuration = 3000; // milliseconds
  static const int cardAnimationDuration = 300;
  static const int pageTransitionDuration = 250;
  
  // Story Categories
  static const List<String> storyCategories = [
    'Adventure',
    'Fantasy',
    'Educational',
    'Animals',
    'Friendship',
    'Family',
    'Science',
    'History',
  ];
  
  // Premium Features
  static const List<String> premiumFeatures = [
    'Access to all languages',
    'Unlimited stories',
    'Offline reading',
    'Audio narration',
    'Personalized recommendations',
    'Ad-free experience',
  ];
}