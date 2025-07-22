import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the child's age range from Firestore
  Future<String?> getChildAgeRange() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return data?['ageRange'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching age range: $e');
      return null;
    }
  }

  // Update the child's age range in Firestore
  Future<bool> updateChildAgeRange(String ageRange) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'ageRange': ageRange});

      return true;
    } catch (e) {
      print('Error updating age range: $e');
      return false;
    }
  }

  // Convert age to age range
  static String ageToAgeRange(int age) {
    if (age >= 3 && age <= 5) return '3-5';
    if (age >= 6 && age <= 8) return '6-8';
    if (age >= 9 && age <= 12) return '9-12';
    return '3-5'; // Default
  }
}
