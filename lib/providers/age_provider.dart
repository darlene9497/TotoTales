// ignore_for_file: deprecated_member_use, avoid_print
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AgeProvider extends ChangeNotifier {
  String? _childAgeRange;
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  String? get childAgeRange => _childAgeRange;
  bool get isLoading => _isLoading;

  // Initialize age range on app start
  Future<void> initializeAgeRange() async {
    _isLoading = true;
    notifyListeners();

    try {
      // First ensure the profile has age range
      await _authService.initializeProfileWithAgeRange();
      
      // Then get the age range
      _childAgeRange = await _authService.getChildAgeRange();
      _childAgeRange ??= '3-5'; // Default if not found
    } catch (e) {
      print('Error initializing age range: $e');
      _childAgeRange = '3-5'; // Default on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update age range
  Future<bool> updateAgeRange(String newAgeRange) async {
    final success = await _authService.updateChildAgeRange(newAgeRange);
    if (success) {
      _childAgeRange = newAgeRange;
      notifyListeners();
    }
    return success;
  }

  // Update child age (which automatically updates age range)
  Future<bool> updateChildAge(String childAge) async {
    final success = await _authService.updateChildAge(childAge);
    if (success) {
      // Refresh the age range
      await initializeAgeRange();
    }
    return success;
  }

  // Get age range display format
  String getAgeRangeDisplay() {
    switch (_childAgeRange) {
      case '3-5':
        return 'Ages 3-5';
      case '6-8':
        return 'Ages 6-8';
      case '9-12':
        return 'Ages 9-12';
      default:
        return 'Ages 3-5';
    }
  }

  // Check if a specific age range is enabled
  bool isAgeRangeEnabled(String ageRange) {
    return ageRange == _childAgeRange;
  }

  // Reset provider state (useful for logout)
  void reset() {
    _childAgeRange = null;
    _isLoading = true;
    notifyListeners();
  }
}