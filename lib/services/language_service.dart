// services/language_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LanguageService {
  static const String _selectedLanguageKey = 'selected_language';
  static const String _selectedLanguageCodeKey = 'selected_language_code';
  static const String _languageDisplayNameKey = 'language_display_name';
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Language mappings
  static const Map<String, String> _languageCodes = {
    'English': 'en',
    'Swahili': 'sw',
    'French': 'fr',
    'German': 'de',
    'Spanish': 'es',
    'Dutch': 'nl',
    'Portuguese': 'pt',
  };

  static const Map<String, String> _languageNames = {
    'English': 'English',
    'Swahili': 'Kiswahili',
    'French': 'Français',
    'German': 'Deutsch',
    'Spanish': 'Español',
    'Dutch': 'Nederlands',
    'Portuguese': 'Português',
  };

  // Save language preference
  static Future<bool> saveLanguagePreference(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = _languageCodes[language] ?? 'en';
      final displayName = _languageNames[language] ?? language;
      
      // Save to SharedPreferences
      await prefs.setString(_selectedLanguageKey, language);
      await prefs.setString(_selectedLanguageCodeKey, languageCode);
      await prefs.setString(_languageDisplayNameKey, displayName);
      
      // Save to Firebase if user is logged in
      if (_auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({
          'selectedLanguage': language,
          'selectedLanguageCode': languageCode,
          'selectedLanguageDisplayName': displayName,
          'languageUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      return true;
    } catch (e) {
      print('Error saving language preference: $e');
      return false;
    }
  }

  // Get current language preference
  static Future<String> getCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedLanguage = prefs.getString(_selectedLanguageKey);
      
      // If no local preference, check Firebase
      if (savedLanguage == null && _auth.currentUser != null) {
        try {
          DocumentSnapshot userDoc = await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .get();
          
          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            savedLanguage = userData['selectedLanguage'] as String?;
            
            // Save to local preferences for faster access
            if (savedLanguage != null) {
              await prefs.setString(_selectedLanguageKey, savedLanguage);
              final languageCode = _languageCodes[savedLanguage] ?? 'en';
              await prefs.setString(_selectedLanguageCodeKey, languageCode);
            }
          }
        } catch (e) {
          print('Error fetching language from Firebase: $e');
        }
      }
      
      return savedLanguage ?? 'English'; // Default to English
    } catch (e) {
      print('Error getting current language: $e');
      return 'English';
    }
  }

  // Get current language code for API calls
  static Future<String> getCurrentLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedCode = prefs.getString(_selectedLanguageCodeKey);
      
      if (savedCode == null) {
        final language = await getCurrentLanguage();
        savedCode = _languageCodes[language] ?? 'en';
        await prefs.setString(_selectedLanguageCodeKey, savedCode);
      }
      
      return savedCode;
    } catch (e) {
      print('Error getting current language code: $e');
      return 'en';
    }
  }

  // Get display name for current language
  static Future<String> getCurrentLanguageDisplayName() async {
    try {
      final language = await getCurrentLanguage();
      return _languageNames[language] ?? language;
    } catch (e) {
      print('Error getting language display name: $e');
      return 'English';
    }
  }

  // Get language code from language name
  static String getLanguageCode(String language) {
    return _languageCodes[language] ?? 'en';
  }

  // Get language name from code
  static String getLanguageName(String code) {
    return _languageCodes.entries
        .firstWhere((entry) => entry.value == code, orElse: () => const MapEntry('English', 'en'))
        .key;
  }

  // Check if language is supported
  static bool isLanguageSupported(String language) {
    return _languageCodes.containsKey(language);
  }

  // Get all supported languages
  static List<String> getSupportedLanguages() {
    return _languageCodes.keys.toList();
  }
}