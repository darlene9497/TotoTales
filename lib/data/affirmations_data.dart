// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/affirmation.dart';
import '../services/gemini_service.dart';

class AffirmationsData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // In-memory cache for quick access
  static final Map<String, List<Affirmation>> _memoryCache = {};
  static final Map<String, DateTime> _lastFetchTime = {};
  
  // Cache duration (2 hours for memory, 24 hours for Firestore)
  static const Duration _memoryCacheDuration = Duration(hours: 2);
  static const Duration _firestoreCacheDuration = Duration(hours: 24);
  
  /// Get affirmations by age range with proper caching and generation
  static Future<List<Affirmation>> getAffirmationsByAge(String ageRange) async {
    try {
      // Check memory cache first
      if (_isMemoryCacheValid(ageRange)) {
        return _memoryCache[ageRange]!;
      }
      
      // Check Firestore cache
      final cachedAffirmations = await _getFromFirestoreCache(ageRange);
      if (cachedAffirmations.isNotEmpty) {
        _memoryCache[ageRange] = cachedAffirmations;
        _lastFetchTime[ageRange] = DateTime.now();
        return cachedAffirmations;
      }
      
      // Generate new affirmations
      final affirmations = await _generateAffirmationsForAge(ageRange);
      
      // Cache in memory and Firestore
      _memoryCache[ageRange] = affirmations;
      _lastFetchTime[ageRange] = DateTime.now();
      await _saveToFirestoreCache(ageRange, affirmations);
      
      return affirmations;
    } catch (e) {
      print('Error fetching affirmations for $ageRange: $e');
      
      // Return cached data if available, even if expired
      if (_memoryCache.containsKey(ageRange)) {
        return _memoryCache[ageRange]!;
      }
      
      // Return fallback affirmations
      return _getFallbackAffirmations(ageRange);
    }
  }
  
  /// Generate a batch of affirmations for a specific age range
  static Future<List<Affirmation>> _generateAffirmationsForAge(String ageRange) async {
  final categories = getAvailableCategories();
  final affirmations = <Affirmation>[];
  
  try {
    // Reduce batch size to avoid rate limits
    // Generate only 1 affirmation per category initially
    for (final category in categories.take(10)) { // Take only first 10 categories
      try {
        final affirmation = await _generateWithRetry(ageRange, category: category);
        affirmations.add(affirmation);
        
        // Longer delay to avoid rate limiting (1-2 seconds)
        await Future.delayed(Duration(milliseconds: 1000 + (DateTime.now().millisecondsSinceEpoch % 1000)));
      } catch (e) {
        print('Error generating affirmation for $category: $e');
        // Add fallback for this category
        affirmations.add(_getFallbackAffirmation(ageRange, category));
      }
    }
    
    // Add some general affirmations (reduce from 5 to 3)
    for (int i = 0; i < 3; i++) {
      try {
        final affirmation = await _generateWithRetry(ageRange);
        affirmations.add(affirmation);
        await Future.delayed(Duration(milliseconds: 1000 + (DateTime.now().millisecondsSinceEpoch % 1000)));
      } catch (e) {
        print('Error generating general affirmation: $e');
        affirmations.add(_getFallbackAffirmation(ageRange));
      }
    }
    
    return affirmations;
  } catch (e) {
    print('Error in batch generation: $e');
      return _getFallbackAffirmations(ageRange);
    }
  }
  
  /// Get random affirmation with improved logic
  static Future<Affirmation> getRandomAffirmation(String ageRange) async {
    try {
      // Get affirmations for the age range
      final affirmations = await getAffirmationsByAge(ageRange);
      
      if (affirmations.isNotEmpty) {
        // Use current time as seed for randomness
        final index = DateTime.now().millisecondsSinceEpoch % affirmations.length;
        return affirmations[index];
      }
      
      // If no cached affirmations, generate a new one
      return await _generateSingleAffirmation(ageRange);
    } catch (e) {
      print('Error getting random affirmation: $e');
      return _getFallbackAffirmation(ageRange);
    }
  }
  
  /// Get daily affirmation with date-based consistency
  static Future<Affirmation> getDailyAffirmation(String ageRange) async {
    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      // Check if we have today's affirmation in Firestore
      final dailyAffirmation = await _getDailyAffirmationFromFirestore(ageRange, dateKey);
      if (dailyAffirmation != null) {
        return dailyAffirmation;
      }
      
      // Generate new daily affirmation
      final affirmation = await _generateSingleAffirmation(ageRange);
      
      // Save as today's affirmation
      await _saveDailyAffirmationToFirestore(ageRange, dateKey, affirmation);
      
      return affirmation;
    } catch (e) {
      print('Error getting daily affirmation: $e');
      return _getFallbackAffirmation(ageRange);
    }
  }
  
  /// Get affirmation by specific category
  static Future<Affirmation> getAffirmationByCategory(String ageRange, String category) async {
    try {
      // First try to get from cached affirmations
      final cachedAffirmations = await getAffirmationsByAge(ageRange);
      final categoryAffirmations = cachedAffirmations.where((a) => a.category == category).toList();
      
      if (categoryAffirmations.isNotEmpty) {
        final index = DateTime.now().millisecondsSinceEpoch % categoryAffirmations.length;
        return categoryAffirmations[index];
      }
      
      // Generate new affirmation for this category
      final affirmation = await GeminiService.generateAffirmation(ageRange, category: category);
      
      // Add to cache
      if (_memoryCache.containsKey(ageRange)) {
        _memoryCache[ageRange]!.add(affirmation);
      }
      
      return affirmation;
    } catch (e) {
      print('Error getting affirmation by category: $e');
      return _getFallbackAffirmation(ageRange, category);
    }
  }
  
  /// Generate single affirmation
  static Future<Affirmation> _generateSingleAffirmation(String ageRange, [String? category]) async {
    try {
      return await GeminiService.generateAffirmation(ageRange, category: category);
    } catch (e) {
      print('Error generating single affirmation: $e');
      return _getFallbackAffirmation(ageRange, category);
    }
  }
  
  /// Check if memory cache is valid
  static bool _isMemoryCacheValid(String ageRange) {
    return _memoryCache.containsKey(ageRange) &&
           _lastFetchTime.containsKey(ageRange) &&
           DateTime.now().difference(_lastFetchTime[ageRange]!) < _memoryCacheDuration;
  }
  
  /// Get affirmations from Firestore cache
  static Future<List<Affirmation>> _getFromFirestoreCache(String ageRange) async {
    try {
      if (_auth.currentUser == null) return [];
      
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('affirmations_cache')
          .doc(ageRange)
          .get();
      
      if (!doc.exists) return [];
      
      final data = doc.data()!;
      final timestamp = data['timestamp'] as Timestamp;
      
      // Check if cache is still valid
      if (DateTime.now().difference(timestamp.toDate()) > _firestoreCacheDuration) {
        return [];
      }
      
      final affirmationsData = data['affirmations'] as List;
      return affirmationsData.map((item) => Affirmation.fromJson(item)).toList();
    } catch (e) {
      print('Error getting from Firestore cache: $e');
      return [];
    }
  }
  
  /// Save affirmations to Firestore cache
  static Future<void> _saveToFirestoreCache(String ageRange, List<Affirmation> affirmations) async {
    try {
      if (_auth.currentUser == null) return;
      
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('affirmations_cache')
          .doc(ageRange)
          .set({
        'affirmations': affirmations.map((a) => a.toJson()).toList(),
        'timestamp': FieldValue.serverTimestamp(),
        'ageRange': ageRange,
      });
    } catch (e) {
      print('Error saving to Firestore cache: $e');
    }
  }
  
  /// Get daily affirmation from Firestore
  static Future<Affirmation?> _getDailyAffirmationFromFirestore(String ageRange, String dateKey) async {
    try {
      if (_auth.currentUser == null) return null;
      
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('daily_affirmations')
          .doc('${ageRange}_$dateKey')
          .get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return Affirmation.fromJson(data['affirmation']);
    } catch (e) {
      print('Error getting daily affirmation from Firestore: $e');
      return null;
    }
  }
  
  /// Save daily affirmation to Firestore
  static Future<void> _saveDailyAffirmationToFirestore(String ageRange, String dateKey, Affirmation affirmation) async {
    try {
      if (_auth.currentUser == null) return;
      
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('daily_affirmations')
          .doc('${ageRange}_$dateKey')
          .set({
        'affirmation': affirmation.toJson(),
        'date': dateKey,
        'ageRange': ageRange,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving daily affirmation to Firestore: $e');
    }
  }
  
  /// Get fallback affirmations list
  static List<Affirmation> _getFallbackAffirmations(String ageRange) {
    final categories = getAvailableCategories();
    final fallbacks = <Affirmation>[];
    
    for (final category in categories) {
      fallbacks.add(_getFallbackAffirmation(ageRange, category));
    }
    
    // Add some general fallbacks
    fallbacks.addAll([
      _getFallbackAffirmation(ageRange),
      _getFallbackAffirmation(ageRange, 'motivation'),
      _getFallbackAffirmation(ageRange, 'happiness'),
    ]);
    
    return fallbacks;
  }

  static Future<Affirmation> _generateWithRetry(String ageRange, {String? category, int maxRetries = 3}) async {
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        final affirmation = await GeminiService.generateAffirmation(ageRange, category: category);
        return affirmation;
      } catch (e) {
        retryCount++;
        
        // Check if it's a rate limit error
        if (e.toString().contains('429')) {
          // Exponential backoff: 1s, 2s, 4s
          final delay = Duration(seconds: 1 << retryCount);
          print('Rate limit hit, retrying in ${delay.inSeconds}s (attempt $retryCount/$maxRetries)');
          await Future.delayed(delay);
        } else {
          // Non-rate limit error, don't retry
          rethrow;
        }
      }
    }
    
    // If all retries failed, return fallback
    return _getFallbackAffirmation(ageRange, category);
  }
  
  /// Enhanced fallback affirmation generator
  static Affirmation _getFallbackAffirmation(String ageRange, [String? category]) {
    final Map<String, Map<String, List<String>>> fallbacks = {
      'Ages 3-5': {
        'courage': [
          'I am brave like a superhero!',
          'I can try new things!',
          'I am strong and fearless!',
          'I face challenges with a smile!',
        ],
        'self-love': [
          'I am special and wonderful!',
          'I love myself just as I am!',
          'I am amazing in my own way!',
          'I am loved and cherished!',
        ],
        'learning': [
          'I love to learn new things!',
          'Learning is fun and exciting!',
          'I am curious about the world!',
          'Every day I discover something new!',
        ],
        'friendship': [
          'I am a wonderful friend!',
          'I share and care for others!',
          'I make friends easily!',
          'I am kind to everyone I meet!',
        ],
        'health': [
          'I am strong and healthy!',
          'I take care of my body!',
          'I eat healthy foods!',
          'I love to move and play!',
        ],
        'default': [
          'I am amazing just as I am!',
          'I can do anything I set my mind to!',
          'I am loved and important!',
          'I make the world brighter!',
        ],
      },
      'Ages 6-8': {
        'intelligence': [
          'I am smart and creative!',
          'I think of great ideas!',
          'I solve problems with ease!',
          'My mind is powerful and bright!',
        ],
        'problem-solving': [
          'I can figure things out!',
          'I find solutions to challenges!',
          'I think before I act!',
          'I am a problem-solving champion!',
        ],
        'kindness': [
          'I am kind to others!',
          'I spread joy wherever I go!',
          'I help those who need it!',
          'My kindness makes a difference!',
        ],
        'confidence': [
          'I believe in myself!',
          'I am confident and capable!',
          'I trust my abilities!',
          'I face challenges with confidence!',
        ],
        'growth': [
          'I get better every day!',
          'I learn from my mistakes!',
          'I am always growing and improving!',
          'I embrace new challenges!',
        ],
        'default': [
          'I am capable of great things!',
          'I have unique talents and gifts!',
          'I make good choices!',
          'I am proud of who I am!',
        ],
      },
      'Ages 9-12': {
        'potential': [
          'I have unlimited potential!',
          'I can achieve my dreams!',
          'I am capable of amazing things!',
          'My future is bright and full of possibilities!',
        ],
        'responsibility': [
          'I am responsible and reliable!',
          'I keep my promises!',
          'I take care of what matters!',
          'I am trustworthy and dependable!',
        ],
        'resilience': [
          'I bounce back from challenges!',
          'I am stronger than my problems!',
          'I learn and grow from difficulties!',
          'I never give up on myself!',
        ],
        'leadership': [
          'I am a natural leader!',
          'I inspire others with my actions!',
          'I make positive changes!',
          'I lead with kindness and courage!',
        ],
        'impact': [
          'I can change the world!',
          'My actions make a difference!',
          'I contribute to making things better!',
          'I have the power to help others!',
        ],
        'default': [
          'I am ready for any challenge!',
          'I believe in my ability to succeed!',
          'I am unique and valuable!',
          'I create my own opportunities!',
        ],
      },
    };

    final ageGroup = fallbacks[ageRange] ?? fallbacks['Ages 6-8']!;
    final categoryAffirmations = ageGroup[category ?? 'default'] ?? ageGroup['default']!;
    
    // Use timestamp for consistent randomness
    final index = DateTime.now().millisecondsSinceEpoch % categoryAffirmations.length;
    final text = categoryAffirmations[index];

    return Affirmation(
      id: '${DateTime.now().millisecondsSinceEpoch}_fallback',
      text: text,
      ageRange: ageRange,
      category: category ?? 'default',
      backgroundImageUrl: _getRandomBackground(),
    );
  }
  
  /// Get random background image
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
      'assets/images/backgrounds/rainbow_bridge.jpg',
      'assets/images/backgrounds/dreamland.jpg',
    ];
    
    return backgrounds[DateTime.now().millisecondsSinceEpoch % backgrounds.length];
  }
  
  /// Get available categories
  static List<String> getAvailableCategories() {
    return [
      'courage', 'self-love', 'learning', 'friendship', 'health',
      'intelligence', 'problem-solving', 'kindness', 'confidence', 'growth',
      'potential', 'responsibility', 'resilience', 'leadership', 'impact',
      'creativity', 'empathy', 'gratitude', 'mindfulness', 'adventure'
    ];
  }
  
  /// Clear all caches
  static void clearCache() {
    _memoryCache.clear();
    _lastFetchTime.clear();
  }
  
  /// Clear cache for specific age range
  static void clearCacheForAge(String ageRange) {
    _memoryCache.remove(ageRange);
    _lastFetchTime.remove(ageRange);
  }
  
  /// Check if cache is valid for age range
  static bool isCacheValid(String ageRange) {
    return _isMemoryCacheValid(ageRange);
  }
  
  /// Track affirmation usage
  static Future<void> trackAffirmationUsage(Affirmation affirmation) async {
    try {
      if (_auth.currentUser == null) return;
      
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('affirmation_history')
          .add({
        'affirmationId': affirmation.id,
        'text': affirmation.text,
        'category': affirmation.category,
        'ageRange': affirmation.ageRange,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error tracking affirmation usage: $e');
    }
  }
  
  /// Get affirmation statistics
  static Future<Map<String, dynamic>> getAffirmationStats() async {
    try {
      if (_auth.currentUser == null) return {};
      
      final historySnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('affirmation_history')
          .get();
      
      final categories = <String, int>{};
      for (final doc in historySnapshot.docs) {
        final category = doc.data()['category'] as String;
        categories[category] = (categories[category] ?? 0) + 1;
      }
      
      return {
        'totalAffirmations': historySnapshot.docs.length,
        'favoriteCategories': categories,
        'lastUsed': historySnapshot.docs.isNotEmpty 
          ? historySnapshot.docs.last.data()['timestamp']
          : null,
      };
    } catch (e) {
      print('Error getting affirmation stats: $e');
      return {};
    }
  }
}