import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String selectedAgeRange;
  final String preferredLanguage;
  final bool isPremium;
  final List<String> completedStories;
  final DateTime lastActive;
  final int readingStreak;
  final DateTime lastActiveDate;

  User({
    required this.id,
    required this.name,
    required this.selectedAgeRange,
    required this.preferredLanguage,
    this.isPremium = false,
    this.completedStories = const [],
    required this.lastActive,
    this.readingStreak = 1,
    required this.lastActiveDate,
  });

  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? lastActive;
    DateTime? lastActiveDate;
    if (data['lastActive'] is Timestamp) {
      lastActive = (data['lastActive'] as Timestamp).toDate();
    } else if (data['lastActive'] is DateTime) {
      lastActive = data['lastActive'] as DateTime;
    } else {
      lastActive = DateTime.now();
    }
    if (data['lastActiveDate'] is Timestamp) {
      lastActiveDate = (data['lastActiveDate'] as Timestamp).toDate();
    } else if (data['lastActiveDate'] is DateTime) {
      lastActiveDate = data['lastActiveDate'] as DateTime;
    } else {
      lastActiveDate = DateTime.now();
    }
    return User(
      id: id,
      name: data['childName'] ?? '',
      selectedAgeRange: data['ageRange'] ?? '3-5',
      preferredLanguage: data['preferredLanguage'] ?? 'English',
      isPremium: data['isPremium'] ?? false,
      completedStories: List<String>.from(data['completedStories'] ?? []),
      lastActive: lastActive,
      readingStreak: data['readingStreak'] ?? 1,
      lastActiveDate: lastActiveDate,
    );
  }
}