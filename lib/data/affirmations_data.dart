import '../models/affirmation.dart';

class AffirmationsData {
  static List<Affirmation> affirmations = [
    // Little Explorers (Ages 3-5)
    Affirmation(
      id: '1',
      text: 'I am brave and curious!',
      ageRange: 'Ages 3-5',
      category: 'courage',
      backgroundImageUrl: 'assets/images/backgrounds/rainbow_sky.png',
    ),
    Affirmation(
      id: '2',
      text: 'I am loved and special!',
      ageRange: 'Ages 3-5',
      category: 'self-love',
      backgroundImageUrl: 'assets/images/backgrounds/sunny_field.png',
    ),
    Affirmation(
      id: '3',
      text: 'I can learn new things!',
      ageRange: 'Ages 3-5',
      category: 'learning',
      backgroundImageUrl: 'assets/images/backgrounds/starry_night.png',
    ),
    Affirmation(
      id: '4',
      text: 'I am a good friend!',
      ageRange: 'Ages 3-5',
      category: 'friendship',
      backgroundImageUrl: 'assets/images/backgrounds/flower_garden.png',
    ),
    Affirmation(
      id: '5',
      text: 'I am strong and healthy!',
      ageRange: 'Ages 3-5',
      category: 'health',
      backgroundImageUrl: 'assets/images/backgrounds/ocean_waves.png',
    ),

    // Bright Learners (Ages 6-8)
    Affirmation(
      id: '6',
      text: 'I am smart and creative!',
      ageRange: 'Ages 6-8',
      category: 'intelligence',
      backgroundImageUrl: 'assets/images/backgrounds/rainbow_sky.png',
    ),
    Affirmation(
      id: '7',
      text: 'I can solve problems!',
      ageRange: 'Ages 6-8',
      category: 'problem-solving',
      backgroundImageUrl: 'assets/images/backgrounds/mountain_view.png',
    ),
    Affirmation(
      id: '8',
      text: 'I am kind and helpful!',
      ageRange: 'Ages 6-8',
      category: 'kindness',
      backgroundImageUrl: 'assets/images/backgrounds/forest_path.png',
    ),
    Affirmation(
      id: '9',
      text: 'I believe in myself!',
      ageRange: 'Ages 6-8',
      category: 'confidence',
      backgroundImageUrl: 'assets/images/backgrounds/butterfly_meadow.png',
    ),
    Affirmation(
      id: '10',
      text: 'I am getting better every day!',
      ageRange: 'Ages 6-8',
      category: 'growth',
      backgroundImageUrl: 'assets/images/backgrounds/sunrise_hills.png',
    ),

    // Junior Dreamers (Ages 9-12)
    Affirmation(
      id: '11',
      text: 'I am capable of amazing things!',
      ageRange: 'Ages 9-12',
      category: 'potential',
      backgroundImageUrl: 'assets/images/backgrounds/galaxy_stars.png',
    ),
    Affirmation(
      id: '12',
      text: 'I am responsible and trustworthy!',
      ageRange: 'Ages 9-12',
      category: 'responsibility',
      backgroundImageUrl: 'assets/images/backgrounds/castle_clouds.png',
    ),
    Affirmation(
      id: '13',
      text: 'I learn from my mistakes!',
      ageRange: 'Ages 9-12',
      category: 'resilience',
      backgroundImageUrl: 'assets/images/backgrounds/adventure_map.png',
    ),
    Affirmation(
      id: '14',
      text: 'I am a leader and team player!',
      ageRange: 'Ages 9-12',
      category: 'leadership',
      backgroundImageUrl: 'assets/images/backgrounds/magical_forest.png',
    ),
    Affirmation(
      id: '15',
      text: 'I can make a difference in the world!',
      ageRange: 'Ages 9-12',
      category: 'impact',
      backgroundImageUrl: 'assets/images/backgrounds/world_map.png',
    ),
  ];

  static List<Affirmation> getAffirmationsByAge(String ageRange) {
    return affirmations.where((affirmation) => affirmation.ageRange == ageRange).toList();
  }

  static Affirmation getRandomAffirmation(String ageRange) {
    final ageAffirmations = getAffirmationsByAge(ageRange);
    if (ageAffirmations.isEmpty) return affirmations.first;
    return ageAffirmations[DateTime.now().millisecondsSinceEpoch % ageAffirmations.length];
  }

  static List<String> getBackgroundImages() {
    return [
      'assets/images/backgrounds/rainbow_sky.png',
      'assets/images/backgrounds/sunny_field.png',
      'assets/images/backgrounds/starry_night.png',
      'assets/images/backgrounds/flower_garden.png',
      'assets/images/backgrounds/ocean_waves.png',
      'assets/images/backgrounds/mountain_view.png',
      'assets/images/backgrounds/forest_path.png',
      'assets/images/backgrounds/butterfly_meadow.png',
      'assets/images/backgrounds/sunrise_hills.png',
      'assets/images/backgrounds/galaxy_stars.png',
      'assets/images/backgrounds/castle_clouds.png',
      'assets/images/backgrounds/adventure_map.png',
      'assets/images/backgrounds/magical_forest.png',
      'assets/images/backgrounds/world_map.png',
    ];
  }
}