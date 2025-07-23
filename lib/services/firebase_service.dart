// ignore_for_file: deprecated_member_use, avoid_print
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Helper method to convert age to age range
  String _ageToAgeRange(String childAge) {
    // Extract numeric age from string like "5 years old" or "Ages 6-8"
    final RegExp ageRegex = RegExp(r'(\d+)');
    final match = ageRegex.firstMatch(childAge);
    
    if (match != null) {
      final age = int.tryParse(match.group(1)!) ?? 5;
      if (age >= 3 && age <= 5) return '3-5';
      if (age >= 6 && age <= 8) return '6-8';
      if (age >= 9 && age <= 12) return '9-12';
    }
    
    // Handle age range formats like "Ages 6-8"
    if (childAge.contains('3-5')) return '3-5';
    if (childAge.contains('6-8')) return '6-8';
    if (childAge.contains('9-12')) return '9-12';
    
    return '3-5'; // Default to youngest range
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile(User user, {
    String? parentName,
    String? childName,
    String? childAge,
    String? preferredLanguage,
  }) async {
    try {
      final ageRange = _ageToAgeRange(childAge ?? 'Ages 6-8');
      
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'parentName': parentName ?? user.displayName ?? 'Parent',
        'childName': childName ?? 'Little Explorer',
        'childAge': childAge ?? 'Ages 6-8',
        'ageRange': ageRange,
        'preferredLanguage': preferredLanguage ?? 'English',
        'isPremium': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'dailyAffirmationStreak': 0,
        'totalStoriesRead': 0,
        'favoriteCategories': [],
        'profileImageUrl': user.photoURL ?? '',
        'settings': {
          'notifications': true,
          'darkMode': false,
          'autoPlay': true,
          'fontSize': 'medium',
        },
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }

  // Register with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String parentName,
    required String childName,
    required String childAge,
    String? preferredLanguage,
  }) async {
    try {
      print("Attempting to register user with email: $email");
      
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        print("ERROR: Firebase not initialized!");
        throw Exception("Firebase not initialized");
      }
      
      print("Firebase apps available: ${Firebase.apps.length}");
      print("Current Firebase app: ${Firebase.app().name}");
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("User registration successful!");
      
      User? user = result.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(parentName);
        
        // Create user profile
        await _createUserProfile(
          user,
          parentName: parentName,
          childName: childName,
          childAge: childAge,
          preferredLanguage: preferredLanguage,
        );
      }

      return result;
    } catch (e) {
      print('Error registering: $e');
      print('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      if (result.user != null) {
        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .update({'lastLoginAt': FieldValue.serverTimestamp()});
      }

      return result;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);

      // Create or update user profile
      if (result.user != null) {
        await _createUserProfile(result.user!);
      }

      return result;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? parentName,
    String? childName,
    String? childAge,
    String? preferredLanguage,
  }) async {
    try {
      if (_auth.currentUser == null) return;

      Map<String, dynamic> updates = {};
      if (parentName != null) updates['parentName'] = parentName;
      if (childName != null) updates['childName'] = childName;
      if (childAge != null) {
        updates['childAge'] = childAge;
        updates['ageRange'] = _ageToAgeRange(childAge); // Update age range when age changes
      }
      if (preferredLanguage != null) updates['preferredLanguage'] = preferredLanguage;

      if (updates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update(updates);
      }
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (_auth.currentUser == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Ensure ageRange exists, create it if missing
        if (!data.containsKey('ageRange')) {
          String ageRange = _ageToAgeRange(data['childAge'] ?? 'Ages 6-8');
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .update({'ageRange': ageRange});
          data['ageRange'] = ageRange;
        }
        
        return data;
      }
    } catch (e) {
      print('Error getting user profile: $e');
    }
    return null;
  }

  // Get child's age range specifically
  Future<String?> getChildAgeRange() async {
    try {
      if (_auth.currentUser == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String? ageRange = data['ageRange'];
        
        // If ageRange doesn't exist, create it from childAge
        if (ageRange == null) {
          ageRange = _ageToAgeRange(data['childAge'] ?? 'Ages 6-8');
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .update({'ageRange': ageRange});
        }
        
        return ageRange;
      }
    } catch (e) {
      print('Error getting child age range: $e');
    }
    return null;
  }

  // Update child's age range
  Future<bool> updateChildAgeRange(String ageRange) async {
    try {
      if (_auth.currentUser == null) return false;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({
        'ageRange': ageRange,
        'ageRangeUpdatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating child age range: $e');
      return false;
    }
  }

  // Update child's age and automatically update age range
  Future<bool> updateChildAge(String childAge) async {
    try {
      if (_auth.currentUser == null) return false;

      String ageRange = _ageToAgeRange(childAge);
      
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({
        'childAge': childAge,
        'ageRange': ageRange,
        'ageUpdatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating child age: $e');
      return false;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      if (_auth.currentUser == null) return;

      String uid = _auth.currentUser!.uid;
      
      // Delete user data from Firestore
      await _firestore.collection('users').doc(uid).delete();
      
      // Delete user authentication
      await _auth.currentUser!.delete();
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  // Update premium status
  Future<void> updatePremiumStatus(bool isPremium) async {
    try {
      if (_auth.currentUser == null) return;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({
        'isPremium': isPremium,
        'premiumUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating premium status: $e');
    }
  }

  // Get user's premium status
  Future<bool> isPremiumUser() async {
    try {
      if (_auth.currentUser == null) return false;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['isPremium'] ?? false;
      }
    } catch (e) {
      print('Error checking premium status: $e');
    }
    return false;
  }

  // Update user settings
  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      if (_auth.currentUser == null) return;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'settings': settings});
    } catch (e) {
      print('Error updating user settings: $e');
    }
  }

  // Track reading progress
  Future<void> trackStoryRead(String storyId) async {
    try {
      if (_auth.currentUser == null) return;

      DocumentReference userRef = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);
        
        if (snapshot.exists) {
          Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
          int totalStories = userData['totalStoriesRead'] ?? 0;
          
          transaction.update(userRef, {
            'totalStoriesRead': totalStories + 1,
            'lastStoryReadAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // Add to reading history
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('readingHistory')
          .add({
        'storyId': storyId,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error tracking story read: $e');
    }
  }

  // Get reading statistics
  Future<Map<String, dynamic>> getReadingStats() async {
    try {
      if (_auth.currentUser == null) return {};

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        // Get reading history count
        QuerySnapshot historySnapshot = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('readingHistory')
            .get();

        // Get affirmations count
        QuerySnapshot affirmationsSnapshot = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('affirmations')
            .get();

        return {
          'totalStoriesRead': userData['totalStoriesRead'] ?? 0,
          'dailyAffirmationStreak': userData['dailyAffirmationStreak'] ?? 0,
          'readingHistoryCount': historySnapshot.docs.length,
          'affirmationsCount': affirmationsSnapshot.docs.length,
          'isPremium': userData['isPremium'] ?? false,
          'memberSince': userData['createdAt'],
          'lastLogin': userData['lastLoginAt'],
          'ageRange': userData['ageRange'] ?? '3-5',
          'childAge': userData['childAge'] ?? 'Ages 6-8',
        };
      }
    } catch (e) {
      print('Error getting reading stats: $e');
    }
    return {};
  }

  // Check if user profile is complete
  Future<bool> isProfileComplete() async {
    try {
      Map<String, dynamic>? profile = await getUserProfile();
      if (profile == null) return false;

      return profile['parentName'] != null &&
             profile['childName'] != null &&
             profile['childAge'] != null &&
             profile['ageRange'] != null;
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
    }
  }

  // Initialize user profile with age range if missing
  Future<void> initializeProfileWithAgeRange() async {
    try {
      if (_auth.currentUser == null) return;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // If ageRange is missing, add it
        if (!data.containsKey('ageRange')) {
          String ageRange = _ageToAgeRange(data['childAge'] ?? 'Ages 6-8');
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .update({'ageRange': ageRange});
        }
      }
    } catch (e) {
      print('Error initializing profile with age range: $e');
    }
  }

  // Helper method to get error message
  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}