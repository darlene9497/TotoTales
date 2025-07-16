import '../models/affirmation.dart';
import '../services/gemini_service.dart';

class AffirmationsData {
  // Cache for storing generated affirmations
  static final Map<String, List<Affirmation>> _affirmationCache = {};
  static final Map<String, DateTime> _lastFetchTime = {};
  
  // Cache duration (1 hour)
  static const Duration _cacheDuration = Duration(hours: 1);
  
  static Future<List<Affirmation>> getAffirmationsByAge(String ageRange) async {
    // Check if we have cached data that's still fresh
    if (_affirmationCache.containsKey(ageRange) &&
        _lastFetchTime.containsKey(ageRange) &&
        DateTime.now().difference(_lastFetchTime[ageRange]!) < _cacheDuration) {
      return _affirmationCache[ageRange]!;
    }
    
    try {
      // Generate new affirmations
      final affirmations = <Affirmation>[];
      
      // Cache the results
      _affirmationCache[ageRange] = affirmations;
      _lastFetchTime[ageRange] = DateTime.now();
      
      return affirmations;
    } catch (e) {
      print('Error fetching affirmations for $ageRange: $e');
      
      // Return cached data if available, even if expired
      if (_affirmationCache.containsKey(ageRange)) {
        return _affirmationCache[ageRange]!;
      }
      
      // Return empty list if no cache and API fails
      return [];
    }
  }
  
  static Future<Affirmation> getRandomAffirmation(String ageRange) async {
    try {
      // Try to get from cache first
      if (_affirmationCache.containsKey(ageRange) && 
          _affirmationCache[ageRange]!.isNotEmpty) {
        final cached = _affirmationCache[ageRange]!;
        return cached[DateTime.now().millisecondsSinceEpoch % cached.length];
      }
      
      // Generate a new affirmation
      final affirmation = await GeminiService.generateAffirmation(ageRange);
      
      // Add to cache
      if (!_affirmationCache.containsKey(ageRange)) {
        _affirmationCache[ageRange] = [];
      }
      _affirmationCache[ageRange]!.add(affirmation);
      _lastFetchTime[ageRange] = DateTime.now();
      
      return affirmation;
    } catch (e) {
      print('Error getting random affirmation: $e');
      // Return a fallback affirmation
      return _getFallbackAffirmation(ageRange);
    }
  }
  
  static Future<Affirmation> getDailyAffirmation(String ageRange) async {
    try {
      // Use date as seed for consistent daily affirmation
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month}-${today.day}';
      final cacheKey = '${ageRange}_daily_$dateKey';
      
      // Check if we already have today's affirmation cached
      if (_affirmationCache.containsKey(cacheKey) && 
          _affirmationCache[cacheKey]!.isNotEmpty) {
        return _affirmationCache[cacheKey]!.first;
      }
      
      // Generate today's affirmation
      final affirmation = await GeminiService.generateAffirmation(ageRange);
      
      // Cache it
      _affirmationCache[cacheKey] = [affirmation];
      _lastFetchTime[cacheKey] = DateTime.now();
      
      return affirmation;
    } catch (e) {
      print('Error getting daily affirmation: $e');
      return _getFallbackAffirmation(ageRange);
    }
  }
  
  static Future<Affirmation> getAffirmationByCategory(String ageRange, String category) async {
    try {
      final affirmation = await GeminiService.generateAffirmation(ageRange, category: category);
      
      // Add to cache
      if (!_affirmationCache.containsKey(ageRange)) {
        _affirmationCache[ageRange] = [];
      }
      _affirmationCache[ageRange]!.add(affirmation);
      _lastFetchTime[ageRange] = DateTime.now();
      
      return affirmation;
    } catch (e) {
      print('Error getting affirmation by category: $e');
      return _getFallbackAffirmation(ageRange, category);
    }
  }
  
  static void clearCache() {
    _affirmationCache.clear();
    _lastFetchTime.clear();
  }
  
  static void clearCacheForAge(String ageRange) {
    _affirmationCache.remove(ageRange);
    _lastFetchTime.remove(ageRange);
  }
  
  static bool isCacheValid(String ageRange) {
    return _affirmationCache.containsKey(ageRange) &&
      _lastFetchTime.containsKey(ageRange) &&
      DateTime.now().difference(_lastFetchTime[ageRange]!) < _cacheDuration;
  }
  
  static Affirmation _getFallbackAffirmation(String ageRange, [String? category]) {
    final Map<String, Map<String, String>> fallbacks = {
      'Ages 3-5': {
        'courage': 'I am brave like a lion!',
        'self-love': 'I am special and loved!',
        'learning': 'I love to learn new things!',
        'friendship': 'I am a wonderful friend!',
        'health': 'I am strong and healthy!',
        'default': 'I am amazing just as I am!',
      },
      'Ages 6-8': {
        'intelligence': 'I am smart and creative!',
        'problem-solving': 'I can figure things out!',
        'kindness': 'I am kind to others!',
        'confidence': 'I believe in myself!',
        'growth': 'I get better every day!',
        'default': 'I am capable of great things!',
      },
      'Ages 9-12': {
        'potential': 'I have unlimited potential!',
        'responsibility': 'I am responsible and reliable!',
        'resilience': 'I bounce back from challenges!',
        'leadership': 'I am a natural leader!',
        'impact': 'I can change the world!',
        'default': 'I am ready for any challenge!',
      },
    };

    final ageGroup = fallbacks[ageRange] ?? fallbacks['Ages 6-8']!;
    final text = ageGroup[category ?? 'default'] ?? ageGroup['default']!;

    return Affirmation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      ageRange: ageRange,
      category: category ?? 'default',
      backgroundImageUrl: _getRandomBackground(),
    );
  }
  
  static String _getRandomBackground() {
    final backgrounds = [
      'assets/images/backgrounds/rainbow_sky.jpg',
      'assets/images/backgrounds/sunny_field.jpg',
      'assets/images/backgrounds/starry_night.jpg',
      'assets/images/backgrounds/flower_garden.jpg',
      'assets/images/backgrounds/ocean_waves.jpg',
      'assets/images/backgrounds/mountain_view.jpg',
      'assets/images/backgrounds/forest_path.jpg',
      'assets/images/backgrounds/butterfly_meadow.jpg',
      'assets/images/backgrounds/sunny_hills.jpg',
      'assets/images/backgrounds/galaxy_stars.jpg',
      'assets/images/backgrounds/castle_clouds.jpg',
      'assets/images/backgrounds/adventure_map.jpg',
      'assets/images/backgrounds/magical_forest.jpg',
      'assets/images/backgrounds/world_map.jpg',
    ];
    
    return backgrounds[DateTime.now().millisecondsSinceEpoch % backgrounds.length];
  }
  
  static List<String> getAvailableCategories() {
    return [
      'courage', 'self-love', 'learning', 'friendship', 'health',
      'intelligence', 'problem-solving', 'kindness', 'confidence', 'growth',
      'potential', 'responsibility', 'resilience', 'leadership', 'impact'
    ];
  }
}