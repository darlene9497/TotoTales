// ignore_for_file: deprecated_member_use, avoid_print
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/story.dart';

class StorySaveService {
  static const String _savedStoriesKey = 'saved_stories';
  static const String _recentlyViewedKey = 'recently_viewed_stories';

  /// Save a story to favorites
  static Future<bool> saveStory(Story story) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStories = await getSavedStories();
      
      // Check if story is already saved
      final existingIndex = savedStories.indexWhere((s) => s.id == story.id);
      if (existingIndex == -1) {
        savedStories.add(story);
        final storiesJson = savedStories.map((s) => s.toJson()).toList();
        await prefs.setString(_savedStoriesKey, jsonEncode(storiesJson));
        return true;
      }
      return false;
    } catch (e) {
      print('Error saving story: $e');
      return false;
    }
  }

  /// Remove a story from favorites
  static Future<bool> removeSavedStory(String storyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStories = await getSavedStories();
      
      savedStories.removeWhere((story) => story.id == storyId);
      final storiesJson = savedStories.map((s) => s.toJson()).toList();
      await prefs.setString(_savedStoriesKey, jsonEncode(storiesJson));
      return true;
    } catch (e) {
      print('Error removing saved story: $e');
      return false;
    }
  }

  /// Get all saved stories
  static Future<List<Story>> getSavedStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storiesJson = prefs.getString(_savedStoriesKey);
      
      if (storiesJson == null) return [];
      
      final List<dynamic> decodedStories = jsonDecode(storiesJson);
      return decodedStories.map((json) => Story.fromJson(json)).toList();
    } catch (e) {
      print('Error getting saved stories: $e');
      return [];
    }
  }

  /// Check if a specific story is saved
  static Future<bool> isStorySaved(String storyId) async {
    try {
      final savedStories = await getSavedStories();
      return savedStories.any((story) => story.id == storyId);
    } catch (e) {
      print('Error checking if story is saved: $e');
      return false;
    }
  }

  /// Add story to recently viewed
  static Future<void> addToRecentlyViewed(Story story) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentStories = await getRecentlyViewedStories();
      
      // Remove if already exists to avoid duplicates
      recentStories.removeWhere((s) => s.id == story.id);
      
      // Add to beginning of list
      recentStories.insert(0, story);
      
      // Keep only last 10 recently viewed stories
      if (recentStories.length > 10) {
        recentStories.removeRange(10, recentStories.length);
      }
      
      final storiesJson = recentStories.map((s) => s.toJson()).toList();
      await prefs.setString(_recentlyViewedKey, jsonEncode(storiesJson));
    } catch (e) {
      print('Error adding to recently viewed: $e');
    }
  }

  /// Get recently viewed stories
  static Future<List<Story>> getRecentlyViewedStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storiesJson = prefs.getString(_recentlyViewedKey);
      
      if (storiesJson == null) return [];
      
      final List<dynamic> decodedStories = jsonDecode(storiesJson);
      return decodedStories.map((json) => Story.fromJson(json)).toList();
    } catch (e) {
      print('Error getting recently viewed stories: $e');
      return [];
    }
  }

  /// Clear all saved stories
  static Future<bool> clearSavedStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedStoriesKey);
      return true;
    } catch (e) {
      print('Error clearing saved stories: $e');
      return false;
    }
  }

  /// Clear recently viewed stories
  static Future<bool> clearRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentlyViewedKey);
      return true;
    } catch (e) {
      print('Error clearing recently viewed: $e');
      return false;
    }
  }

  /// Get total count of saved stories
  static Future<int> getSavedStoriesCount() async {
    final savedStories = await getSavedStories();
    return savedStories.length;
  }

  /// Search through saved stories
  static Future<List<Story>> searchSavedStories(String query) async {
    if (query.isEmpty) return await getSavedStories();
    
    final savedStories = await getSavedStories();
    final lowerQuery = query.toLowerCase();
    
    return savedStories.where((story) {
      return story.title.toLowerCase().contains(lowerQuery) ||
             story.category.toLowerCase().contains(lowerQuery) ||
             story.ageRange.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get saved stories by category
  static Future<List<Story>> getSavedStoriesByCategory(String category) async {
    final savedStories = await getSavedStories();
    return savedStories.where((story) => 
        story.category.toLowerCase() == category.toLowerCase()).toList();
  }

  /// Get saved stories by age range
  static Future<List<Story>> getSavedStoriesByAgeRange(String ageRange) async {
    final savedStories = await getSavedStories();
    return savedStories.where((story) => story.ageRange == ageRange).toList();
  }

  /// Export saved stories as JSON string (for backup)
  static Future<String> exportSavedStories() async {
    try {
      final savedStories = await getSavedStories();
      final export = {
        'exported_at': DateTime.now().toIso8601String(),
        'stories': savedStories.map((s) => s.toJson()).toList(),
      };
      return jsonEncode(export);
    } catch (e) {
      print('Error exporting saved stories: $e');
      return '';
    }
  }

  /// Import saved stories from JSON string (for restore)
  static Future<bool> importSavedStories(String jsonString) async {
    try {
      final Map<String, dynamic> importData = jsonDecode(jsonString);
      final List<dynamic> storiesData = importData['stories'];
      
      final stories = storiesData.map((json) => Story.fromJson(json)).toList();
      
      // Clear existing and save imported stories
      final prefs = await SharedPreferences.getInstance();
      final storiesJson = stories.map((s) => s.toJson()).toList();
      await prefs.setString(_savedStoriesKey, jsonEncode(storiesJson));
      
      return true;
    } catch (e) {
      print('Error importing saved stories: $e');
      return false;
    }
  }
}