import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/story.dart';
import '../models/user.dart';

class ProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get current user ID
  static String? get currentUserId => fb_auth.FirebaseAuth.instance.currentUser?.uid;
  
  // Get user's favorite stories
  static Future<List<Story>> getFavoriteStories() async {
    try {
      if (currentUserId == null) return [];
      
      final favoritesRef = _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('favorites');
      
      final snapshot = await favoritesRef.orderBy('savedAt', descending: true).get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _mapToStory(data);
      }).toList();
    } catch (e) {
      print('Error getting favorite stories: $e');
      return [];
    }
  }
  
  // Get user's completed stories
  static Future<List<Story>> getCompletedStories() async {
    try {
      if (currentUserId == null) return [];
      
      final completedRef = _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('completed_stories');
      
      final snapshot = await completedRef.orderBy('completedAt', descending: true).get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _mapToStory(data);
      }).toList();
    } catch (e) {
      print('Error getting completed stories: $e');
      return [];
    }
  }
  
  // Check if a story is favorited
  static Future<bool> isStoryFavorited(String storyId) async {
    try {
      if (currentUserId == null) return false;
      
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('favorites')
          .doc(storyId)
          .get();
      
      return doc.exists;
    } catch (e) {
      print('Error checking if story is favorited: $e');
      return false;
    }
  }
  
  // Check if a story is completed
  static Future<bool> isStoryCompleted(String storyId) async {
    try {
      if (currentUserId == null) return false;
      
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('completed_stories')
          .doc(storyId)
          .get();
      
      return doc.exists;
    } catch (e) {
      print('Error checking if story is completed: $e');
      return false;
    }
  }
  
  // Add story to favorites
  static Future<bool> addToFavorites(Story story) async {
    try {
      if (currentUserId == null) return false;
      
      await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('favorites')
          .doc(story.id)
          .set({
        'id': story.id,
        'title': story.title,
        'language': story.language,
        'ageRange': story.ageRange,
        'category': story.category,
        'coverImageUrl': story.coverImageUrl,
        'description': story.description,
        'dateAdded': story.dateAdded.toIso8601String(),
        'popularity': story.popularity,
        'isPremium': story.isPremium,
        'pages': story.pages.map((page) => {
          'pageNumber': page.pageNumber,
          'imageUrl': page.imageUrl,
          'text': page.text,
        }).toList(),
        'savedAt': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      print('Error adding story to favorites: $e');
      return false;
    }
  }
  
  // Remove story from favorites
  static Future<bool> removeFromFavorites(String storyId) async {
    try {
      if (currentUserId == null) return false;
      
      await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('favorites')
          .doc(storyId)
          .delete();
      
      return true;
    } catch (e) {
      print('Error removing story from favorites: $e');
      return false;
    }
  }
  
  // Add story to completed
  static Future<bool> markAsCompleted(Story story) async {
    try {
      if (currentUserId == null) return false;
      
      await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('completed_stories')
          .doc(story.id)
          .set({
        'id': story.id,
        'title': story.title,
        'language': story.language,
        'ageRange': story.ageRange,
        'category': story.category,
        'coverImageUrl': story.coverImageUrl,
        'description': story.description,
        'dateAdded': story.dateAdded.toIso8601String(),
        'popularity': story.popularity,
        'isPremium': story.isPremium,
        'pages': story.pages.map((page) => {
          'pageNumber': page.pageNumber,
          'imageUrl': page.imageUrl,
          'text': page.text,
        }).toList(),
        'completedAt': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      print('Error marking story as completed: $e');
      return false;
    }
  }
  
  // Toggle favorite status
  static Future<bool> toggleFavorite(Story story) async {
    try {
      final isFavorited = await isStoryFavorited(story.id);
      
      if (isFavorited) {
        return await removeFromFavorites(story.id);
      } else {
        return await addToFavorites(story);
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }
  
  // Get favorite story IDs (for quick checking)
  static Future<Set<String>> getFavoriteStoryIds() async {
    try {
      if (currentUserId == null) return {};
      
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('favorites')
          .get();
      
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      print('Error getting favorite story IDs: $e');
      return {};
    }
  }
  
  // Get completed story IDs (for quick checking)
  static Future<Set<String>> getCompletedStoryIds() async {
    try {
      if (currentUserId == null) return {};
      
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('completed_stories')
          .get();
      
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      print('Error getting completed story IDs: $e');
      return {};
    }
  }
  
  // Get user statistics
  static Future<Map<String, int>> getUserStats() async {
    try {
      if (currentUserId == null) return {'favorites': 0, 'completed': 0};
      
      final favoritesCount = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('favorites')
          .get()
          .then((snapshot) => snapshot.size);
      
      final completedCount = await _firestore
          .collection('users')
          .doc(currentUserId!)
          .collection('completed_stories')
          .get()
          .then((snapshot) => snapshot.size);
      
      return {
        'favorites': favoritesCount,
        'completed': completedCount,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {'favorites': 0, 'completed': 0};
    }
  }
  
  // Fetch user profile from Firestore
  static Future<User?> getUserProfile() async {
    try {
      if (currentUserId == null) return null;
      final doc = await _firestore.collection('users').doc(currentUserId!).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      return User.fromFirestore(data, doc.id);
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Update reading streak and last active date
  static Future<void> updateReadingStreak() async {
    if (currentUserId == null) return;
    final userRef = _firestore.collection('users').doc(currentUserId!);
    final doc = await userRef.get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final lastActiveDate = (data['lastActiveDate'] as Timestamp?)?.toDate();
    final today = DateTime.now();
    int streak = data['readingStreak'] ?? 1;
    if (lastActiveDate != null) {
      final diff = today.difference(DateTime(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day)).inDays;
      if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        streak = 1;
      }
    }
    await userRef.update({
      'lastActiveDate': today,
      'readingStreak': streak,
    });
  }

  // Update age range
  static Future<void> updateAgeRange(String ageRange) async {
    if (currentUserId == null) return;
    await _firestore.collection('users').doc(currentUserId!).update({
      'ageRange': ageRange,
    });
  }

  // Get reading level based on completed stories count
  static String getReadingLevel(int storiesRead) {
    if (storiesRead < 5) return 'Beginner';
    if (storiesRead < 15) return 'Explorer';
    if (storiesRead < 30) return 'Adventurer';
    return 'Master';
  }
  
  // Get user's premium status
  static Future<bool> isPremiumUser() async {
    try {
      if (currentUserId == null) return false;
      final doc = await _firestore.collection('users').doc(currentUserId!).get();
      if (!doc.exists) return false;
      final data = doc.data()!;
      return data['isPremium'] ?? false;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }
  
  // Helper method to convert Firestore data to Story object
  static Story _mapToStory(Map<String, dynamic> data) {
    return Story(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      language: data['language'] ?? 'English',
      ageRange: data['ageRange'] ?? 'Ages 6-8',
      category: data['category'] ?? 'General',
      coverImageUrl: data['coverImageUrl'] ?? '',
      description: data['description'] ?? '',
      dateAdded: data['dateAdded'] != null 
          ? DateTime.parse(data['dateAdded'])
          : DateTime.now(),
      popularity: data['popularity'] ?? 0,
      isPremium: data['isPremium'] ?? false,
      pages: (data['pages'] as List<dynamic>?)
          ?.map((pageData) => StoryPage(
                pageNumber: pageData['pageNumber'] ?? 1,
                imageUrl: pageData['imageUrl'] ?? '',
                text: pageData['text'] ?? '',
              ))
          .toList() ?? [],
      isSaved: true, // Since this is from favorites/completed, it's saved
    );
  }
}