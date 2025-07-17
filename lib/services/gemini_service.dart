import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/affirmation.dart';

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';
  static const String _apiKey = 'AIzaSyBsNrGGEhqeSjwRtOrKexX0NPTqc3MqEL4'; // Replace with your actual API key
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const List<String> _categories = [
    'courage', 'self-love', 'learning', 'friendship', 'health',
    'intelligence', 'problem-solving', 'kindness', 'confidence', 'growth',
    'potential', 'responsibility', 'resilience', 'leadership', 'impact'
  ];
  
  static const List<String> _backgroundImages = [
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

  // Get user's age range from Firebase
  static Future<String> _getUserAgeRange() async {
    try {
      if (_auth.currentUser == null) return 'Ages 6-8';
      
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['childAge'] ?? 'Ages 6-8';
      }
    } catch (e) {
      print('Error getting user age range: $e');
    }
    return 'Ages 6-8';
  }

  // Generate and save affirmation to Firebase
  static Future<Affirmation> generateAffirmation(String ageRange, {String? category}) async {
    try {
      final selectedCategory = category ?? _categories[DateTime.now().millisecondsSinceEpoch % _categories.length];
      
      final prompt = _buildPrompt(ageRange, selectedCategory);
      
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': prompt
            }]
          }],
          'generationConfig': {
            'temperature': 0.9,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 100,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedText = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Clean up the generated text
        final cleanText = _cleanAffirmationText(generatedText);
        
        final affirmation = Affirmation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: cleanText,
          ageRange: ageRange,
          category: selectedCategory,
          backgroundImageUrl: _getRandomBackground(),
        );

        // Save to Firebase if user is logged in
        if (_auth.currentUser != null) {
          await _saveAffirmationToFirebase(affirmation);
        }

        return affirmation;
      } else {
        throw Exception('Failed to generate affirmation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating affirmation: $e');
      // Return a fallback affirmation if API fails
      return _getFallbackAffirmation(ageRange, category ?? 'confidence');
    }
  }

  // Save affirmation to Firebase
  static Future<void> _saveAffirmationToFirebase(Affirmation affirmation) async {
    try {
      if (_auth.currentUser == null) return;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('affirmations')
          .doc(affirmation.id)
          .set({
        'text': affirmation.text,
        'ageRange': affirmation.ageRange,
        'category': affirmation.category,
        'backgroundImageUrl': affirmation.backgroundImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'viewed': false,
      });

      // Update user's daily affirmation streak
      await _updateAffirmationStreak();
    } catch (e) {
      print('Error saving affirmation to Firebase: $e');
    }
  }

  // Update user's affirmation streak
  static Future<void> _updateAffirmationStreak() async {
    try {
      if (_auth.currentUser == null) return;

      DocumentReference userRef = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);
        
        if (snapshot.exists) {
          Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
          int currentStreak = userData['dailyAffirmationStreak'] ?? 0;
          
          // Check if user has already viewed affirmation today
          Timestamp? lastAffirmationDate = userData['lastAffirmationDate'];
          DateTime now = DateTime.now();
          
          if (lastAffirmationDate == null || 
              !_isSameDay(lastAffirmationDate.toDate(), now)) {
            // First affirmation today, increment streak
            transaction.update(userRef, {
              'dailyAffirmationStreak': currentStreak + 1,
              'lastAffirmationDate': FieldValue.serverTimestamp(),
            });
          }
        }
      });
    } catch (e) {
      print('Error updating affirmation streak: $e');
    }
  }

  // Get user's affirmation history
  static Future<List<Affirmation>> getUserAffirmationHistory() async {
    try {
      if (_auth.currentUser == null) return [];

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('affirmations')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Affirmation(
          id: doc.id,
          text: data['text'] ?? '',
          ageRange: data['ageRange'] ?? 'Ages 6-8',
          category: data['category'] ?? 'confidence',
          backgroundImageUrl: data['backgroundImageUrl'] ?? _backgroundImages[0],
        );
      }).toList();
    } catch (e) {
      print('Error getting affirmation history: $e');
      return [];
    }
  }

  // Get today's affirmation
  static Future<Affirmation?> getTodayAffirmation() async {
    try {
      if (_auth.currentUser == null) return null;

      // Get user's age range
      String ageRange = await _getUserAgeRange();
      
      // Check if user already has an affirmation for today
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      DateTime endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('affirmations')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Return existing affirmation
        DocumentSnapshot doc = querySnapshot.docs.first;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Affirmation(
          id: doc.id,
          text: data['text'] ?? '',
          ageRange: data['ageRange'] ?? ageRange,
          category: data['category'] ?? 'confidence',
          backgroundImageUrl: data['backgroundImageUrl'] ?? _backgroundImages[0],
        );
      } else {
        // Generate new affirmation for today
        return await generateAffirmation(ageRange);
      }
    } catch (e) {
      print('Error getting today\'s affirmation: $e');
      return null;
    }
  }

  // Generate AI-powered story
  static Future<Map<String, dynamic>> generateStory({
    required String ageRange,
    required String language,
    required String theme,
    String? customPrompt,
  }) async {
    try {
      final prompt = _buildStoryPrompt(ageRange, language, theme, customPrompt);
      
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': prompt
            }]
          }],
          'generationConfig': {
            'temperature': 0.8,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1000,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedText = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Parse the generated story
        final storyData = _parseGeneratedStory(generatedText, ageRange, language, theme);
        
        // Save to Firebase if user is logged in
        if (_auth.currentUser != null) {
          await _saveStoryToFirebase(storyData);
        }
        
        return storyData;
      } else {
        throw Exception('Failed to generate story: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating story: $e');
      return _getFallbackStory(ageRange, language, theme);
    }
  }

  // Helper method to check if two dates are the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  static String _buildPrompt(String ageRange, String category) {
    String ageContext = '';
    String examples = '';
    
    switch (ageRange) {
      case 'Ages 3-5':
        ageContext = 'very young children (ages 3-5) using simple words and concepts they understand';
        examples = 'Examples: "I am brave!", "I am loved!", "I can do it!"';
        break;
      case 'Ages 6-8':
        ageContext = 'early elementary children (ages 6-8) with slightly more complex vocabulary';
        examples = 'Examples: "I am smart and creative!", "I believe in myself!", "I can solve problems!"';
        break;
      case 'Ages 9-12':
        ageContext = 'older children (ages 9-12) who can understand more sophisticated concepts';
        examples = 'Examples: "I am capable of amazing things!", "I learn from my mistakes!", "I can make a difference!"';
        break;
    }

    return '''
Create a positive affirmation for $ageContext.
The affirmation should be about: $category
Requirements:
- Must be exactly one sentence
- Should be positive and empowering
- Use age-appropriate language
- Start with "I am" or "I can" or "I will"
- Keep it short and memorable
- Make it inspiring and child-friendly

$examples

Generate only the affirmation text, nothing else.
''';
  }

  static String _buildStoryPrompt(String ageRange, String language, String theme, String? customPrompt) {
    String ageContext = '';
    String languageInstruction = '';
    
    switch (ageRange) {
      case 'Ages 3-5':
        ageContext = 'very young children (ages 3-5) with simple vocabulary, short sentences, and basic concepts';
        break;
      case 'Ages 6-8':
        ageContext = 'early elementary children (ages 6-8) with growing vocabulary and slightly longer sentences';
        break;
      case 'Ages 9-12':
        ageContext = 'older children (ages 9-12) who can handle more complex vocabulary and story structures';
        break;
    }

    if (language != 'English') {
      languageInstruction = 'Write the story in $language. Use proper grammar and age-appropriate vocabulary in $language.';
    }

    String prompt = customPrompt ?? '''
Create a short, engaging story for $ageContext about $theme.
$languageInstruction

Requirements:
- Story should be 3-5 short paragraphs
- Include a clear beginning, middle, and end
- Have a positive message or lesson
- Use simple, age-appropriate language
- Include relatable characters
- Make it culturally inclusive
- End with a happy or inspiring conclusion

Format the response as:
TITLE: [Story Title]
STORY: [Story content in paragraphs]
LESSON: [Main lesson or message]
''';

    return prompt;
  }

  static String _cleanAffirmationText(String text) {
    // Remove any extra formatting, quotes, or explanations
    String cleaned = text.trim();
    
    // Remove quotes if present
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    if (cleaned.startsWith("'") && cleaned.endsWith("'")) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    
    // Take only the first sentence if multiple sentences
    if (cleaned.contains('.')) {
      cleaned = cleaned.split('.')[0] + '!';
    }
    
    // Ensure it ends with an exclamation mark
    if (!cleaned.endsWith('!')) {
      cleaned += '!';
    }
    
    return cleaned;
  }

  static Map<String, dynamic> _parseGeneratedStory(String generatedText, String ageRange, String language, String theme) {
    try {
      String title = '';
      String story = '';
      String lesson = '';
      
      List<String> lines = generatedText.split('\n');
      
      for (String line in lines) {
        line = line.trim();
        if (line.startsWith('TITLE:')) {
          title = line.substring(6).trim();
        } else if (line.startsWith('STORY:')) {
          story = line.substring(6).trim();
        } else if (line.startsWith('LESSON:')) {
          lesson = line.substring(7).trim();
        } else if (story.isNotEmpty && !line.startsWith('LESSON:')) {
          // Continue building story content
          story += '\n\n' + line;
        }
      }
      
      // If parsing failed, use the entire text as story
      if (title.isEmpty || story.isEmpty) {
        title = 'A Special Story';
        story = generatedText;
        lesson = 'Every day brings new adventures and learning!';
      }
      
      return {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'content': story,
        'lesson': lesson,
        'ageRange': ageRange,
        'language': language,
        'theme': theme,
        'createdAt': DateTime.now(),
        'backgroundImageUrl': _getRandomBackground(),
      };
    } catch (e) {
      print('Error parsing story: $e');
      return _getFallbackStory(ageRange, language, theme);
    }
  }

  static Future<void> _saveStoryToFirebase(Map<String, dynamic> storyData) async {
    try {
      if (_auth.currentUser == null) return;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('stories')
          .doc(storyData['id'])
          .set({
        'title': storyData['title'],
        'content': storyData['content'],
        'lesson': storyData['lesson'],
        'ageRange': storyData['ageRange'],
        'language': storyData['language'],
        'theme': storyData['theme'],
        'backgroundImageUrl': storyData['backgroundImageUrl'],
        'createdAt': FieldValue.serverTimestamp(),
        'isCustomGenerated': true,
      });
    } catch (e) {
      print('Error saving story to Firebase: $e');
    }
  }

  static String _getRandomBackground() {
    return _backgroundImages[DateTime.now().millisecondsSinceEpoch % _backgroundImages.length];
  }

  static Affirmation _getFallbackAffirmation(String ageRange, String category) {
    Map<String, Map<String, String>> fallbacks = {
      'Ages 3-5': {
        'courage': 'I am brave like a lion!',
        'self-love': 'I am special and loved!',
        'learning': 'I love to learn new things!',
        'friendship': 'I am a good friend!',
        'confidence': 'I can do it!',
      },
      'Ages 6-8': {
        'courage': 'I am brave and can face any challenge!',
        'self-love': 'I am amazing just the way I am!',
        'learning': 'I love learning and growing every day!',
        'friendship': 'I am kind and make great friends!',
        'confidence': 'I believe in myself and my abilities!',
      },
      'Ages 9-12': {
        'courage': 'I have the courage to try new things!',
        'self-love': 'I am unique and that makes me special!',
        'learning': 'I am curious and love discovering new things!',
        'friendship': 'I am a loyal and caring friend!',
        'confidence': 'I am capable of achieving great things!',
      },
    };

    String fallbackText = fallbacks[ageRange]?[category] ?? 'I am amazing and capable!';
    
    return Affirmation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: fallbackText,
      ageRange: ageRange,
      category: category,
      backgroundImageUrl: _getRandomBackground(),
    );
  }

  static Map<String, dynamic> _getFallbackStory(String ageRange, String language, String theme) {
    Map<String, Map<String, Map<String, String>>> fallbackStories = {
      'English': {
        'Ages 3-5': {
          'friendship': 'Once upon a time, there was a little bunny named Benny who loved to play. One day, he met a shy squirrel named Sam. Benny shared his toys and soon they became best friends. They played together every day and had lots of fun.',
          'courage': 'Little Maya was scared of the dark. One night, she heard a tiny voice asking for help. She was brave and found a lost firefly. Maya helped the firefly find its way home, and she wasn\'t scared anymore.',
        },
        'Ages 6-8': {
          'friendship': 'Emma was new at school and felt lonely. During lunch, she noticed Alex sitting alone too. Emma walked over and shared her cookies. They talked about their favorite books and became great friends.',
          'courage': 'Jake was nervous about his first swimming lesson. The pool looked so big! His teacher was patient and kind. Jake took a deep breath, jumped in, and discovered he loved swimming.',
        },
        'Ages 9-12': {
          'friendship': 'Sofia moved to a new city and missed her old friends. At her new school, she joined the art club and met kids who loved drawing like her. They worked on a mural together and Sofia realized she could make new friends while keeping the old ones in her heart.',
          'courage': 'Marcus wanted to enter the school talent show but was afraid of performing. He practiced his magic tricks every day. On the night of the show, he remembered all his practice and performed beautifully, earning a standing ovation.',
        },
      },
      'Swahili': {
        'Ages 3-5': {
          'friendship': 'Hapo zamani, kulikuwa na sungura mdogo aitwaye Benny aliyependa kucheza. Siku moja, alikutana na kindi aitwaye Sam aliyekuwa na haya. Benny alimshirikisha vitu vyake vya kuchezea na hivi karibuni wakawa marafiki wa karibu.',
          'courage': 'Maya mdogo aliogopa giza. Usiku mmoja, alisikia sauti ndogo inayoomba msaada. Alikuwa na ujasiri na akakuta kimulimuli kilichopotea. Maya alimsaidia kimulimuli kurudi nyumbani.',
        },
      },
      'French': {
        'Ages 3-5': {
          'friendship': 'Il était une fois un petit lapin nommé Benny qui adorait jouer. Un jour, il rencontra un écureuil timide nommé Sam. Benny partagea ses jouets et bientôt ils devinrent les meilleurs amis.',
          'courage': 'La petite Maya avait peur du noir. Une nuit, elle entendit une petite voix demander de l\'aide. Elle fut courageuse et trouva une luciole perdue. Maya aida la luciole à rentrer chez elle.',
        },
      },
    };

    String selectedLanguage = fallbackStories.containsKey(language) ? language : 'English';
    String selectedAge = fallbackStories[selectedLanguage]!.containsKey(ageRange) ? ageRange : 'Ages 6-8';
    String selectedTheme = fallbackStories[selectedLanguage]![selectedAge]!.containsKey(theme) ? theme : 'friendship';
    
    String storyContent = fallbackStories[selectedLanguage]![selectedAge]![selectedTheme]!;
    
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': 'A Special Story',
      'content': storyContent,
      'lesson': 'Every day brings new adventures and learning!',
      'ageRange': ageRange,
      'language': language,
      'theme': theme,
      'createdAt': DateTime.now(),
      'backgroundImageUrl': _getRandomBackground(),
    };
  }

  // Get user's generated stories
  static Future<List<Map<String, dynamic>>> getUserStories() async {
    try {
      if (_auth.currentUser == null) return [];

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('stories')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Untitled Story',
          'content': data['content'] ?? '',
          'lesson': data['lesson'] ?? '',
          'ageRange': data['ageRange'] ?? 'Ages 6-8',
          'language': data['language'] ?? 'English',
          'theme': data['theme'] ?? 'friendship',
          'backgroundImageUrl': data['backgroundImageUrl'] ?? _backgroundImages[0],
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      print('Error getting user stories: $e');
      return [];
    }
  }
}