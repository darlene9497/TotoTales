// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toto_tales/services/language_service.dart';
import 'package:toto_tales/utils/env.dart';
import '../models/affirmation.dart';
import 'dart:math';

class GeminiService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';
  static String get _apiKey => Env.geminiApiKey;

  // Groq API
  static const String _groqBaseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static String get _groqApiKey => Env.groqApiKey;
  
  // Hugging Face API
  static const String _huggingFaceUrl = 'https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium';
  static String get _huggingFaceKey => Env.huggingFaceApiKey;
  
  // Together AI
  static const String _togetherBaseUrl = 'https://api.together.xyz/v1/chat/completions';
  static String get _togetherApiKey => Env.togetherApiKey;
  
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

  // Supported languages with their native names
  static const Map<String, String> _supportedLanguages = {
    'English': 'English',
    'Swahili': 'Kiswahili',
    'French': 'Français',
    'German': 'Deutsch',
    'Spanish': 'Español',
    'Dutch': 'Nederlands',
    'Portuguese': 'Português',
  };

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
  static String _buildPrompt(String ageRange, String category) {
    String ageContext = '';
    String examples = '';
    
    switch (ageRange) {
      case 'Ages 3-5':
        ageContext = 'very young children (ages 3-5) using simple words and concepts they understand';
        examples = 'Examples: "I am brave", "I am loved", "I can do it"';
        break;
      case 'Ages 6-8':
        ageContext = 'early elementary children (ages 6-8) with slightly more complex vocabulary';
        examples = 'Examples: "I am smart and creative", "I believe in myself", "I can solve problems"';
        break;
      case 'Ages 9-12':
        ageContext = 'older children (ages 9-12) who can understand more sophisticated concepts';
        examples = 'Examples: "I am capable of amazing things", "I learn from my mistakes", "I can make a difference"';
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
    final random = Random();
    final paragraphCount = 10 + random.nextInt(31); // 10 to 40
    
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

    // Enhanced language instruction with native language names and cultural context
    if (language != 'English') {
      String nativeLanguageName = _supportedLanguages[language] ?? language;
      languageInstruction = '''
  CRITICAL LANGUAGE REQUIREMENT: Write the ENTIRE story in $language ($nativeLanguageName).
  - Every single word, sentence, and paragraph must be in $language
  - Use proper grammar and age-appropriate vocabulary in $language
  - Include cultural elements and references appropriate for $language speakers
  - Ensure ALL dialogue, narration, and descriptions are in $language
  - Make the story culturally inclusive and relevant to $language-speaking communities
  - Use natural expressions and idioms that children who speak $language would understand
  - DO NOT mix languages - everything must be in $language only
  ''';
    } else {
      languageInstruction = 'Write the story in English with clear, age-appropriate language.';
    }

    String prompt = customPrompt ?? '''
  Create a captivating children's story for $ageContext about $theme.

  $languageInstruction

  STORY REQUIREMENTS:
  - Story should be $paragraphCount short paragraphs (each paragraph will be a page)
  - Each paragraph should describe a different scene or moment
  - Include a clear beginning, middle, and end with character development
  - Have a positive message or lesson about $theme
  - Use simple, age-appropriate language for the target age group
  - Include relatable characters that children can connect with
  - Make it culturally inclusive and appropriate for $language speakers
  - End with a happy or inspiring conclusion that reinforces the lesson
  - Ensure the entire story flows naturally in $language

  FORMAT REQUIREMENTS:
  TITLE: [Story Title in $language - make it engaging and child-friendly]
  STORY: [Complete story content in $language, divided into clear paragraphs]
  LESSON: [Main lesson or message in $language - what children learn from this story]

  LANGUAGE COMPLIANCE:
  - Title must be in $language
  - Every word of the story content must be in $language
  - Lesson must be in $language
  - NO English words should appear if $language is not English

  Remember: This story will be read by children who speak $language, so make it authentic, engaging, and culturally appropriate for them.
  ''';

    return prompt;
  }

  // Generate a cartoon/child-friendly image for a given text using Gemini
  static Future<String> generateImageForText(String text) async {
    final imagePrompt = 'Create a cartoon, child-friendly illustration for the following scene: $text';
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=$_apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [{
          'parts': [{ 'text': imagePrompt }]
        }],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 20,
          'topP': 0.9,
          'maxOutputTokens': 512,
        }
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Assume the image URL is in the first candidate's content (adjust if needed)
      final imageUrl = data['candidates'][0]['content']['parts'][0]['text'];
      return imageUrl;
    } else {
      // Fallback: return a random background
      return _getRandomBackground();
    }
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
      cleaned = '${cleaned.split('.')[0]}!';
    }
    
    // Ensure it ends with an exclamation mark
    if (!cleaned.endsWith('!')) {
      cleaned += '!';
    }
    
    return cleaned;
  }

  static Future<Map<String, dynamic>> generateStory({
    required String ageRange,
    String? language, // Make this optional
    required String theme,
    String? customPrompt,
  }) async {
    // Get the current language preference if not provided
    String selectedLanguage = language ?? await LanguageService.getCurrentLanguage();
    
    final prompt = _buildStoryPrompt(ageRange, selectedLanguage, theme, customPrompt);
    
    // Try multiple AI services in order of preference
    final services = [
      () => _generateWithGroq(prompt, selectedLanguage),
      () => _generateWithTogether(prompt, selectedLanguage),
      () => _generateWithHuggingFace(prompt, selectedLanguage),
      () => _generateFallbackStory(ageRange, selectedLanguage, theme),
    ];
    
    for (final service in services) {
      try {
        final result = await service();
        Map<String, dynamic> storyData = _formatStoryResponse(result, ageRange, selectedLanguage, theme);
        
        // Save to Firebase if user is logged in
        if (_auth.currentUser != null) {
          await _saveStoryToFirebase(storyData);
        }
        
        return storyData;
      } catch (e) {
        print('Story generation attempt failed: $e');
        continue;
      }
    }
    
    // If all services fail, return a template story
    return _generateTemplateStory(ageRange, selectedLanguage, theme);
  }

  /// Generate story using Groq API (fastest free option)
  static Future<String> _generateWithGroq(String prompt, String language) async {
    String systemPrompt = language != 'English' 
        ? 'You are a creative children\'s story writer. Create engaging, age-appropriate stories with clear moral lessons. Always write in the requested language and ensure cultural appropriateness.'
        : 'You are a creative children\'s story writer. Create engaging, age-appropriate stories with clear moral lessons.';

    final response = await http.post(
      Uri.parse(_groqBaseUrl),
      headers: {
        'Authorization': 'Bearer $_groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama3-8b-8192', // Fast and good quality
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'max_tokens': 1500,
        'temperature': 0.8,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Groq API error: ${response.statusCode}');
    }
  }

  /// Generate story using Together AI
  static Future<String> _generateWithTogether(String prompt, String language) async {
    String systemPrompt = language != 'English' 
        ? 'You are a creative children\'s story writer specializing in age-appropriate content. Write stories in the requested language with cultural sensitivity.'
        : 'You are a creative children\'s story writer specializing in age-appropriate content.';

    final response = await http.post(
      Uri.parse(_togetherBaseUrl),
      headers: {
        'Authorization': 'Bearer $_togetherApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'mistralai/Mistral-7B-Instruct-v0.1',
        'messages': [
          {
            'role': 'system',
            'content': systemPrompt,
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'max_tokens': 1200,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Together AI error: ${response.statusCode}');
    }
  }

  /// Generate story using Hugging Face
  static Future<String> _generateWithHuggingFace(String prompt, String language) async {
    final response = await http.post(
      Uri.parse(_huggingFaceUrl),
      headers: {
        'Authorization': 'Bearer $_huggingFaceKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': prompt,
        'parameters': {
          'max_length': 1000,
          'temperature': 0.8,
          'do_sample': true,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data[0]['generated_text'];
    } else {
      throw Exception('Hugging Face API error: ${response.statusCode}');
    }
  }

  // Helper to wrap _getFallbackStory for use in generateStory
  static Future<Map<String, dynamic>> _generateFallbackStory(String ageRange, String language, String theme) async {
    return _getFallbackStory(ageRange, language, theme);
  }

  // Helper to format the story response using _parseGeneratedStory
  static Map<String, dynamic> _formatStoryResponse(dynamic result, String ageRange, String language, String theme) {
    if (result is Map<String, dynamic>) {
      return result;
    } else if (result is String) {
      return _parseGeneratedStory(result, ageRange, language, theme);
    } else {
      return _getFallbackStory(ageRange, language, theme);
    }
  }

  // Simple template story if all else fails
  static Map<String, dynamic> _generateTemplateStory(String ageRange, String language, String theme) {
    Map<String, String> templateTitles = {
      'English': 'A Wonderful Adventure',
      'Swahili': 'Safari ya Ajabu',
      'French': 'Une Aventure Merveilleuse',
      'German': 'Ein Wunderbares Abenteuer',
      'Spanish': 'Una Aventura Maravillosa',
      'Dutch': 'Een Prachtig Avontuur',
      'Portuguese': 'Uma Aventura Maravilhosa',
    };

    Map<String, String> templateContents = {
      'English': 'Once upon a time, there was a wonderful adventure about $theme. The story was perfect for $ageRange children and filled with joy and learning.',
      'Swahili': 'Hapo zamani, kulikuwa na safari ya ajabu kuhusu $theme. Hadithi hii ilikuwa nzuri kwa watoto wa $ageRange na imejaa furaha na kujifunza.',
      'French': 'Il était une fois, une merveilleuse aventure sur $theme. Cette histoire était parfaite pour les enfants de $ageRange et remplie de joie et d\'apprentissage.',
      'German': 'Es war einmal ein wunderbares Abenteuer über $theme. Diese Geschichte war perfekt für Kinder im Alter von $ageRange und voller Freude und Lernen.',
      'Spanish': 'Había una vez una aventura maravillosa sobre $theme. Esta historia era perfecta para niños de $ageRange y llena de alegría y aprendizaje.',
      'Dutch': 'Er was eens een prachtig avontuur over $theme. Dit verhaal was perfect voor kinderen van $ageRange en vol vreugde en leren.',
      'Portuguese': 'Era uma vez uma aventura maravilhosa sobre $theme. Esta história era perfeita para crianças de $ageRange e cheia de alegria e aprendizado.',
    };

    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': templateTitles[language] ?? templateTitles['English']!,
      'content': templateContents[language] ?? templateContents['English']!,
      'lesson': getFallbackLesson(theme, language),
      'ageRange': ageRange,
      'language': language,
      'theme': theme,
      'createdAt': DateTime.now(),
      'backgroundImageUrl': _getRandomBackground(),
    };
  }

  static String getFallbackLesson(String theme, [String language = 'English']) {
    Map<String, Map<String, String>> lessons = {
      'English': {
        'kindness': 'Always be kind to others!',
        'friendship': 'Being a good friend makes life magical!',
        'courage': 'Be brave and face your fears!',
        'adventure': 'Every adventure teaches us something new!',
        'animals': 'Take care of animals and nature!',
        'imagination': 'Let your imagination soar!',
        'helping': 'Helping others makes the world better!',
        'sharing': 'Sharing brings happiness to everyone!',
        'nature': 'Respect and enjoy the beauty of nature!',
        'dreams': 'Dream big and believe in yourself!',
        'space': 'Explore the universe with curiosity!',
        'magic': 'Magic is everywhere if you believe!',
      },
      'Swahili': {
        'kindness': 'Daima uwe mkarimu kwa wengine!',
        'friendship': 'Kuwa rafiki mzuri hufanya maisha kuwa ya kichawi!',
        'courage': 'Uwe jasiri na ukabiliane na hofu zako!',
        'adventure': 'Kila safari inafundisha kitu kipya!',
        'animals': 'Wajali wanyamapori na mazingira!',
        'imagination': 'Acha mawazo yako yatembee angani!',
        'helping': 'Kusaidia wengine hufanya ulimwengu kuwa bora!',
        'sharing': 'Kushiriki huleta furaha kwa kila mtu!',
        'nature': 'Heshimu na furahia uzuri wa asili!',
        'dreams': 'Ota ndoto kubwa na ujiamini!',
        'space': 'Chunguza ulimwengu kwa hamu ya kujua!',
        'magic': 'Uchawi upo kila mahali ukiamini!',
      },
      'French': {
        'kindness': 'Soyez toujours gentil avec les autres!',
        'friendship': 'Être un bon ami rend la vie magique!',
        'courage': 'Soyez courageux et affrontez vos peurs!',
        'adventure': 'Chaque aventure nous apprend quelque chose de nouveau!',
        'animals': 'Prenez soin des animaux et de la nature!',
        'imagination': 'Laissez votre imagination s\'envoler!',
        'helping': 'Aider les autres rend le monde meilleur!',
        'sharing': 'Partager apporte du bonheur à tous!',
        'nature': 'Respectez et appréciez la beauté de la nature!',
        'dreams': 'Rêvez grand et croyez en vous!',
        'space': 'Explorez l\'univers avec curiosité!',
        'magic': 'La magie est partout si vous y croyez!',
      },
      'German': {
        'kindness': 'Sei immer freundlich zu anderen!',
        'friendship': 'Ein guter Freund zu sein macht das Leben magisch!',
        'courage': 'Sei mutig und stelle dich deinen Ängsten!',
        'adventure': 'Jedes Abenteuer lehrt uns etwas Neues!',
        'animals': 'Kümmere dich um Tiere und die Natur!',
        'imagination': 'Lass deine Fantasie fliegen!',
        'helping': 'Anderen zu helfen macht die Welt besser!',
        'sharing': 'Teilen bringt allen Glück!',
        'nature': 'Respektiere und genieße die Schönheit der Natur!',
        'dreams': 'Träume groß und glaube an dich!',
        'space': 'Erkunde das Universum mit Neugier!',
        'magic': 'Magie ist überall, wenn du daran glaubst!',
      },
      'Spanish': {
        'kindness': '¡Siempre sé amable con los demás!',
        'friendship': '¡Ser un buen amigo hace la vida mágica!',
        'courage': '¡Sé valiente y enfrenta tus miedos!',
        'adventure': '¡Cada aventura nos enseña algo nuevo!',
        'animals': '¡Cuida a los animales y la naturaleza!',
        'imagination': '¡Deja que tu imaginación vuele!',
        'helping': '¡Ayudar a otros hace el mundo mejor!',
        'sharing': '¡Compartir trae felicidad a todos!',
        'nature': '¡Respeta y disfruta la belleza de la naturaleza!',
        'dreams': '¡Sueña en grande y cree en ti mismo!',
        'space': '¡Explora el universo con curiosidad!',
        'magic': '¡La magia está en todas partes si crees!',
      },
      'Dutch': {
        'kindness': 'Wees altijd aardig voor anderen!',
        'friendship': 'Een goede vriend zijn maakt het leven magisch!',
        'courage': 'Wees moedig en stel je angsten onder ogen!',
        'adventure': 'Elk avontuur leert ons iets nieuws!',
        'animals': 'Zorg voor dieren en de natuur!',
        'imagination': 'Laat je verbeelding de vrije loop!',
        'helping': 'Anderen helpen maakt de wereld beter!',
        'sharing': 'Delen brengt iedereen geluk!',
        'nature': 'Respecteer en geniet van de schoonheid van de natuur!',
        'dreams': 'Droom groot en geloof in jezelf!',
        'space': 'Verken het universum met nieuwsgierigheid!',
        'magic': 'Magie is overal als je erin gelooft!',
      },
      'Portuguese': {
        'kindness': 'Seja sempre gentil com os outros!',
        'friendship': 'Ser um bom amigo torna a vida mágica!',
        'courage': 'Seja corajoso e enfrente seus medos!',
        'adventure': 'Cada aventura nos ensina algo novo!',
        'animals': 'Cuide dos animais e da natureza!',
        'imagination': 'Deixe sua imaginação voar!',
        'helping': 'Ajudar os outros torna o mundo melhor!',
        'sharing': 'Compartilhar traz felicidade para todos!',
        'nature': 'Respeite e aproveite a beleza da natureza!',
        'dreams': 'Sonhe grande e acredite em si mesmo!',
        'space': 'Explore o universo com curiosidade!',
        'magic': 'A magia está em toda parte se você acreditar!',
      },
    };

    // Get the appropriate language lessons, fallback to English if not found
    Map<String, String> languageLessons = lessons[language] ?? lessons['English']!;
    
    // Return the lesson for the theme, fallback to a default if theme not found
    return languageLessons[theme.toLowerCase()] ?? 
           languageLessons['adventure'] ?? 
           'Every day brings new adventures and learning!';
  }

  static Map<String, dynamic> _parseGeneratedStory(String generatedText, String ageRange, String language, String theme) {
    try {
      String title = '';
      String lesson = '';
      List<String> lines = generatedText.split('\n');
      List<String> storyLines = [];
      
      for (String line in lines) {
        String cleanLine = line.trim();
        if (cleanLine.startsWith('TITLE:') || cleanLine.startsWith('**TITLE:**')) {
          // Extract title, remove asterisks, 'TITLE:', and quotes
          title = cleanLine.replaceAll(RegExp(r'\*|TITLE:|:'), '').trim();
          title = title.replaceAll(RegExp(r'^["\t]|["\t]$'), '').trim();
        } else if (cleanLine.startsWith('LESSON:')) {
          lesson = cleanLine.replaceAll(RegExp(r'\*|LESSON:|:'), '').trim();
        } else if (cleanLine.isNotEmpty &&
                   !cleanLine.startsWith('PAGE') &&
                   !cleanLine.toUpperCase().contains('TITLE') &&
                   !cleanLine.toUpperCase().contains('LESSON')) {
          // Remove asterisks, markdown, and numbering
          cleanLine = cleanLine.replaceAll(RegExp(r'\*'), '').replaceAll(RegExp(r'^\d+\.\s*'), '').trim();
          // Filter out 'STORY:' or 'STORY' lines
          if (cleanLine.toLowerCase() != 'story:' && cleanLine.toLowerCase() != 'story') {
            storyLines.add(cleanLine);
          }
        }
      }
      if (title.isEmpty) {
        // Fallback: use first non-empty line as title
        title = storyLines.isNotEmpty ? storyLines.removeAt(0) : 'Untitled Story';
      }
      String story = storyLines.join('\n\n');
      if (lesson.isEmpty) {
        lesson = getFallbackLesson(theme);
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
        'pageImages': <String>[],
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
        'authorId': _auth.currentUser!.uid,
        'pageImages': storyData['pageImages'] ?? <String>[],
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
          'friendship': 'Once upon a time, there was a little bunny named Benny who loved to play. One day, he met a shy squirrel named Sam. Benny shared his toys and soon they became best friends. They played together every day and had lots of fun. The end.',
          'courage': 'Little Maya was scared of the dark. One night, she heard a tiny voice asking for help. She was brave and found a lost firefly. Maya helped the firefly find its way home, and she wasn\'t scared anymore. She felt proud and happy.',
          'kindness': 'Tommy the cat saw a bird with a hurt wing. He gently helped the bird and brought it water. Soon the bird felt better and could fly again. The bird thanked Tommy for being so kind.',
          'adventure': 'Luna found a magic door in her garden. She opened it and discovered a land full of colorful flowers and friendly butterflies. She had a wonderful adventure and made new friends.',
        },
        'Ages 6-8': {
          'friendship': 'Emma was new at school and felt lonely. During lunch, she noticed Alex sitting alone too. Emma walked over and shared her cookies. They talked about their favorite books and became great friends who helped each other every day.',
          'courage': 'Jake was nervous about his first swimming lesson. The pool looked so big! His teacher was patient and kind. Jake took a deep breath, jumped in, and discovered he loved swimming. He felt proud of being brave.',
          'kindness': 'Sarah noticed an elderly neighbor struggling with heavy bags. She asked her mom if they could help. Together, they carried the bags and even baked cookies for their neighbor. Kindness made everyone smile.',
          'adventure': 'Max discovered an old map in his attic. It led to a hidden treasure in the forest. With his friends, he followed the clues and found a chest full of beautiful stones and a note about friendship being the greatest treasure.',
        },
        'Ages 9-12': {
          'friendship': 'Sofia moved to a new city and missed her old friends. At her new school, she joined the art club and met kids who loved drawing like her. They worked on a mural together and Sofia realized she could make new friends while keeping the old ones in her heart.',
          'courage': 'Marcus wanted to enter the school talent show but was afraid of performing. He practiced his magic tricks every day. On the night of the show, he remembered all his practice and performed beautifully, earning a standing ovation and newfound confidence.',
          'kindness': 'When Lily saw classmates bullying a new student, she stood up for him. She invited him to sit with her group at lunch and helped him make friends. Her kindness created a ripple effect of acceptance in the school.',
          'adventure': 'Zoe found a mysterious key while cleaning her grandmother\'s attic. It opened a secret room filled with journals from her grandmother\'s adventures around the world. Inspired, Zoe began planning her own adventures and started learning about different cultures.',
        },
      },
      'Swahili': {
        'Ages 3-5': {
          'friendship': 'Hapo zamani, kulikuwa na sungura mdogo aitwaye Benny aliyependa kucheza. Siku moja, alikutana na kindi aitwaye Sam aliyekuwa na haya. Benny alimshirikisha vitu vyake vya kuchezea na hivi karibuni wakawa marafiki wa karibu. Walicheza pamoja kila siku.',
          'courage': 'Maya mdogo aliogopa giza. Usiku mmoja, alisikia sauti ndogo inayoomba msaada. Alikuwa na ujasiri na akakuta kimulimuli kilichopotea. Maya alimsaidia kimulimuli kurudi nyumbani, na hakuogopa tena.',
          'kindness': 'Tommy paka alimwona ndege mwenye ubawa ulioumia. Alimsaidia kwa upole na akamleta maji. Hivi karibuni ndege akahisi vizuri na akaweza kuruka tena. Ndege alimshukuru Tommy kwa wema wake.',
          'adventure': 'Luna alikuta mlango wa kichawi bustanini mwake. Aliufungua na akagundua nchi iliyojaa maua ya rangi na vipepeo wenye urafiki. Alikuwa na safari ya ajabu na akafanya marafiki wapya.',
        },
        'Ages 6-8': {
          'friendship': 'Emma alikuwa mpya shuleni na akahisi upweke. Wakati wa chakula cha mchana, alimwona Alex pia amekaa peke yake. Emma alimwendea na akamshirikisha biskuti zake. Waliongea kuhusu vitabu walivyopenda na wakawa marafiki wazuri.',
          'courage': 'Jake alikuwa na wasiwasi kuhusu somo lake la kwanza la kuogelea. Bwawa lilikuwa kubwa sana! Mwalimu wake alikuwa na uvumilivu na upole. Jake alivuta pumzi, akaruka ndani, na akagundua kuwa anapenda kuogelea.',
          'kindness': 'Sarah alimwona jirani mzee akijitahidi na mifuko mizito. Alimuuliza mama yake kama wanaweza kusaidia. Pamoja, walibeba mifuko na hata wakapika biskuti kwa jirani yao. Wema ulifanya kila mtu kutabasamu.',
          'adventure': 'Max aligundua ramani ya zamani chodani mwake. Iliongoza kwa hazina iliyofichwa msituni. Pamoja na marafiki zake, alifuata dalili na akakuta sanduku lenye mawe mazuri na ujumbe kuhusu urafiki kuwa hazina kubwa zaidi.',
        },
        'Ages 9-12': {
          'friendship': 'Sofia alihamia jiji jipya na akawawakumbuka marafiki zake wa zamani. Shule yake mpya, alijiunga na klabu ya sanaa na akakutana na watoto waliopenda mchoraji kama yeye. Walifanya kazi pamoja kwenye mchoro mkubwa na Sofia aligundua anaweza kuwa na marafiki wapya.',
          'courage': 'Marcus alitaka kushiriki katika mchezo wa talanta wa shule lakini aliogopa kuonyesha. Alifanya mazoezi ya uchawi wake kila siku. Usiku wa mchezo, alikumbuka mazoezi yake yote na akaonyesha vizuri, akapata hekima mpya.',
          'kindness': 'Lily alipowona wanafunzi wakimdhulumu mwanafunzi mpya, alisimama kwa ajili yake. Alimwalika akae na kikundi chake chakula cha mchana na akamsaidia kupata marafiki. Wema wake ulianzisha mzunguko wa kukubali shuleni.',
          'adventure': 'Zoe alikuta ufunguo wa siri alipokuwa akisafisha dari la nyanya yake. Ulifungua chumba cha siri kilichojaa madaftari ya safari za nyanya yake duniani kote. Akihamasika, Zoe alianza kupanga safari zake mwenyewe.',
        },
      },
      'French': {
        'Ages 3-5': {
          'friendship': 'Il était une fois un petit lapin nommé Benny qui adorait jouer. Un jour, il rencontra un écureuil timide nommé Sam. Benny partagea ses jouets et bientôt ils devinrent les meilleurs amis. Ils jouaient ensemble tous les jours.',
          'courage': 'La petite Maya avait peur du noir. Une nuit, elle entendit une petite voix demander de l\'aide. Elle fut courageuse et trouva une luciole perdue. Maya aida la luciole à rentrer chez elle et n\'eut plus peur.',
          'kindness': 'Tommy le chat vit un oiseau avec une aile blessée. Il aida doucement l\'oiseau et lui apporta de l\'eau. Bientôt l\'oiseau se sentit mieux et put voler à nouveau. L\'oiseau remercia Tommy pour sa gentillesse.',
          'adventure': 'Luna trouva une porte magique dans son jardin. Elle l\'ouvrit et découvrit une terre pleine de fleurs colorées et de papillons amicaux. Elle vécut une aventure merveilleuse et se fit de nouveaux amis.',
        },
        'Ages 6-8': {
          'friendship': 'Emma était nouvelle à l\'école et se sentait seule. Pendant le déjeuner, elle remarqua qu\'Alex était aussi assis seul. Emma s\'approcha et partagea ses biscuits. Ils parlèrent de leurs livres préférés et devinrent de grands amis.',
          'courage': 'Jake était nerveux pour sa première leçon de natation. La piscine semblait si grande! Son professeur était patient et gentil. Jake prit une grande respiration, sauta et découvrit qu\'il aimait nager.',
          'kindness': 'Sarah remarqua une voisine âgée qui luttait avec de lourds sacs. Elle demanda à sa mère si elles pouvaient aider. Ensemble, elles portèrent les sacs et firent même des biscuits pour leur voisine. La gentillesse fit sourire tout le monde.',
          'adventure': 'Max découvrit une vieille carte dans son grenier. Elle menait à un trésor caché dans la forêt. Avec ses amis, il suivit les indices et trouva un coffre plein de belles pierres et une note sur l\'amitié étant le plus grand trésor.',
        },
        'Ages 9-12': {
          'friendship': 'Sofia déménagea dans une nouvelle ville et ses anciens amis lui manquaient. Dans sa nouvelle école, elle rejoignit le club d\'art et rencontra des enfants qui aimaient dessiner comme elle. Ils travaillèrent ensemble sur une fresque et Sofia réalisa qu\'elle pouvait se faire de nouveaux amis.',
          'courage': 'Marcus voulait participer au spectacle de talents de l\'école mais avait peur de se produire. Il pratiqua ses tours de magie tous les jours. Le soir du spectacle, il se souvint de toute sa pratique et joua magnifiquement, gagnant une ovation debout.',
          'kindness': 'Quand Lily vit des camarades de classe intimider un nouvel élève, elle le défendit. Elle l\'invita à s\'asseoir avec son groupe au déjeuner et l\'aida à se faire des amis. Sa gentillesse créa un effet d\'entraînement d\'acceptation à l\'école.',
          'adventure': 'Zoe trouva une clé mystérieuse en nettoyant le grenier de sa grand-mère. Elle ouvrit une chambre secrète remplie de journaux des aventures de sa grand-mère autour du monde. Inspirée, Zoe commença à planifier ses propres aventures et apprit sur différentes cultures.',
        },
      },
      'German': {
        'Ages 3-5': {
          'friendship': 'Es war einmal ein kleiner Hase namens Benny, der gerne spielte. Eines Tages traf er ein schüchternes Eichhörnchen namens Sam. Benny teilte seine Spielsachen und bald wurden sie beste Freunde. Sie spielten jeden Tag zusammen und hatten viel Spaß.',
          'courage': 'Die kleine Maya hatte Angst vor der Dunkelheit. Eines Nachts hörte sie eine winzige Stimme um Hilfe bitten. Sie war mutig und fand einen verlorenen Glühwürmchen. Maya half dem Glühwürmchen nach Hause zu finden und hatte keine Angst mehr.',
          'kindness': 'Tommy die Katze sah einen Vogel mit einem verletzten Flügel. Er half dem Vogel sanft und brachte ihm Wasser. Bald fühlte sich der Vogel besser und konnte wieder fliegen. Der Vogel dankte Tommy für seine Freundlichkeit.',
          'adventure': 'Luna fand eine magische Tür in ihrem Garten. Sie öffnete sie und entdeckte ein Land voller bunter Blumen und freundlicher Schmetterlinge. Sie hatte ein wunderbares Abenteuer und fand neue Freunde.',
        },
        'Ages 6-8': {
          'friendship': 'Emma war neu in der Schule und fühlte sich einsam. Beim Mittagessen bemerkte sie, dass Alex auch allein saß. Emma ging hinüber und teilte ihre Kekse. Sie sprachen über ihre Lieblingsbücher und wurden großartige Freunde.',
          'courage': 'Jake war nervös wegen seiner ersten Schwimmstunde. Das Schwimmbecken sah so groß aus! Sein Lehrer war geduldig und freundlich. Jake holte tief Luft, sprang hinein und entdeckte, dass er das Schwimmen liebte.',
          'kindness': 'Sarah bemerkte eine ältere Nachbarin, die mit schweren Taschen kämpfte. Sie fragte ihre Mutter, ob sie helfen könnten. Zusammen trugen sie die Taschen und backten sogar Kekse für ihre Nachbarin. Freundlichkeit brachte alle zum Lächeln.',
          'adventure': 'Max entdeckte eine alte Karte auf seinem Dachboden. Sie führte zu einem versteckten Schatz im Wald. Mit seinen Freunden folgte er den Hinweisen und fand eine Truhe voller schöner Steine und eine Notiz über Freundschaft als den größten Schatz.',
        },
        'Ages 9-12': {
          'friendship': 'Sofia zog in eine neue Stadt und vermisste ihre alten Freunde. In ihrer neuen Schule trat sie dem Kunstclub bei und traf Kinder, die wie sie das Zeichnen liebten. Sie arbeiteten zusammen an einem Wandbild und Sofia erkannte, dass sie neue Freunde finden konnte.',
          'courage': 'Marcus wollte an der Schultalentshow teilnehmen, hatte aber Angst vor dem Auftreten. Er übte jeden Tag seine Zaubertricks. Am Abend der Show erinnerte er sich an all seine Übung und trat wunderschön auf, erhielt stehende Ovationen.',
          'kindness': 'Als Lily sah, wie Klassenkameraden einen neuen Schüler mobbten, verteidigte sie ihn. Sie lud ihn ein, bei ihrer Gruppe zum Mittagessen zu sitzen und half ihm, Freunde zu finden. Ihre Freundlichkeit schuf eine Welle der Akzeptanz in der Schule.',
          'adventure': 'Zoe fand einen mysteriösen Schlüssel beim Aufräumen des Dachbodens ihrer Großmutter. Er öffnete ein geheimes Zimmer voller Tagebücher von den Abenteuern ihrer Großmutter auf der ganzen Welt. Inspiriert begann Zoe ihre eigenen Abenteuer zu planen.',
        },
      },
      'Spanish': {
        'Ages 3-5': {
          'friendship': 'Había una vez un conejito llamado Benny que amaba jugar. Un día, conoció a una ardilla tímida llamada Sam. Benny compartió sus juguetes y pronto se volvieron mejores amigos. Jugaban juntos todos los días y se divertían mucho.',
          'courage': 'La pequeña Maya tenía miedo de la oscuridad. Una noche, escuchó una vocecita pidiendo ayuda. Fue valiente y encontró una luciérnaga perdida. Maya ayudó a la luciérnaga a encontrar su camino a casa y ya no tuvo miedo.',
          'kindness': 'Tommy el gato vio un pájaro con un ala herida. Ayudó gentilmente al pájaro y le trajo agua. Pronto el pájaro se sintió mejor y pudo volar de nuevo. El pájaro agradeció a Tommy por su bondad.',
          'adventure': 'Luna encontró una puerta mágica en su jardín. La abrió y descubrió una tierra llena de flores coloridas y mariposas amigables. Tuvo una aventura maravillosa e hizo nuevos amigos.',
        },
        'Ages 6-8': {
          'friendship': 'Emma era nueva en la escuela y se sentía sola. Durante el almuerzo, notó que Alex también estaba sentado solo. Emma se acercó y compartió sus galletas. Hablaron sobre sus libros favoritos y se volvieron grandes amigos.',
          'courage': 'Jake estaba nervioso por su primera lección de natación. ¡La piscina se veía tan grande! Su maestro era paciente y amable. Jake respiró profundo, saltó y descubrió que amaba nadar.',
          'kindness': 'Sarah notó a una vecina anciana luchando con bolsas pesadas. Le preguntó a su mamá si podían ayudar. Juntas cargaron las bolsas e incluso hornearon galletas para su vecina. La bondad hizo sonreír a todos.',
          'adventure': 'Max descubrió un mapa viejo en su ático. Llevaba a un tesoro escondido en el bosque. Con sus amigos, siguió las pistas y encontró un cofre lleno de piedras hermosas y una nota sobre la amistad siendo el tesoro más grande.',
        },
        'Ages 9-12': {
          'friendship': 'Sofia se mudó a una nueva ciudad y extrañaba a sus viejos amigos. En su nueva escuela, se unió al club de arte y conoció niños que amaban dibujar como ella. Trabajaron juntos en un mural y Sofia se dio cuenta de que podía hacer nuevos amigos.',
          'courage': 'Marcus quería participar en el show de talentos de la escuela pero tenía miedo de actuar. Practicó sus trucos de magia todos los días. La noche del show, recordó toda su práctica y actuó hermosamente, ganando una ovación de pie.',
          'kindness': 'Cuando Lily vio a compañeros de clase intimidando a un estudiante nuevo, lo defendió. Lo invitó a sentarse con su grupo en el almuerzo y lo ayudó a hacer amigos. Su bondad creó un efecto dominó de aceptación en la escuela.',
          'adventure': 'Zoe encontró una llave misteriosa mientras limpiaba el ático de su abuela. Abrió una habitación secreta llena de diarios de las aventuras de su abuela alrededor del mundo. Inspirada, Zoe comenzó a planear sus propias aventuras.',
        },
      },
      'Dutch': {
        'Ages 3-5': {
          'friendship': 'Er was eens een klein konijntje genaamd Benny die graag speelde. Op een dag ontmoette hij een verlegen eekhoorn genaamd Sam. Benny deelde zijn speelgoed en al snel werden ze beste vrienden. Ze speelden elke dag samen en hadden veel plezier.',
          'courage': 'Kleine Maya was bang voor het donker. Op een nacht hoorde ze een klein stemmetje om hulp vragen. Ze was dapper en vond een verdwaalde vuurvlieg. Maya help de vuurvlieg de weg naar huis te vinden en was niet meer bang.',
          'kindness': 'Tommy de kat zag een vogel met een gewonde vleugel. Hij help de vogel voorzichtig en bracht hem water. Al snel voelde de vogel zich beter en kon weer vliegen. De vogel bedankte Tommy voor zijn vriendelijkheid.',
          'adventure': 'Luna vond een magische deur in haar tuin. Ze opende hem en ontdekte een land vol kleurrijke bloemen en vriendelijke vlinders. Ze beleefde een prachtig avontuur en maakte nieuwe vrienden.',
        },
        'Ages 6-8': {
          'friendship': 'Emma was nieuw op school en voelde zich eenzaam. Tijdens de lunch zag ze dat Alex ook alleen zat. Emma liep naar hem toe en deelde haar koekjes. Ze praatten over hun favoriete boeken en werden goede vrienden.',
          'courage': 'Jake was zenuwachtig voor zijn eerste zwemles. Het zwembad zag er zo groot uit! Zijn leraar was geduldig en vriendelijk. Jake haalde diep adem, sprong erin en ontdekte dat hij van zwemmen hield.',
          'kindness': 'Sarah zag een oudere buurvrouw worstelen met zware tassen. Ze vroeg haar moeder of ze konden helpen. Samen droegen ze de tassen en bakten zelfs koekjes voor hun buurvrouw. Vriendelijkheid zorgde voor glimlachjes bij iedereen.',
          'adventure': 'Max ontdekte een oude kaart op zijn zolder. Het leidde naar een verborgen schat in het bos. Met zijn vrienden volgde hij de aanwijzingen en vond een kist vol mooie stenen en een briefje over vriendschap als de grootste schat.',
        },
        'Ages 9-12': {
          'friendship': 'Sofia verhuisde naar een nieuwe stad en miste haar oude vrienden. Op haar nieuwe school werd ze lid van de kunstclub en ontmoette kinderen die net als zij van tekenen hielden. Ze werkten samen aan een muurschildering en Sofia besefte dat ze nieuwe vrienden kon maken.',
          'courage': 'Marcus wilde meedoen aan de schooltalentenshow maar was bang om op te treden. Hij oefende elke dag zijn goocheltrucs. Op de avond van de show herinnerde hij zich al zijn oefening en trad prachtig op, wat een staande ovatie opleverde.',
          'kindness': 'Toen Lily zag dat klasgenoten een nieuwe leerling pestten, verdedigde ze hem. Ze nodigde hem uit om bij haar groep te zitten tijdens de lunch en help hem vrienden te maken. Haar vriendelijkheid zorgde voor een golf van acceptatie op school.',
          'adventure': 'Zoe vond een mysterieuze sleutel toen ze de zolder van haar oma opruimde. Het opende een geheime kamer vol dagboeken van haar oma\'s avonturen over de hele wereld. Geïnspireerd begon Zoe haar eigen avonturen te plannen.',
        },
      },
      'Portuguese': {
        'Ages 3-5': {
          'friendship': 'Era uma vez um coelhinho chamado Benny que adorava brincar. Um dia, ele conheceu um esquilo tímido chamado Sam. Benny compartilhou seus brinquedos e logo se tornaram melhores amigos. Eles brincavam juntos todos os dias e se divertiam muito.',
          'courage': 'A pequena Maya tinha medo do escuro. Uma noite, ela ouviu uma vozinha pedindo ajuda. Ela foi corajosa e encontrou um vaga-lume perdido. Maya ajudou o vaga-lume a encontrar o caminho de casa e não teve mais medo.',
          'kindness': 'Tommy o gato viu um pássaro com a asa machucada. Ele ajudou gentilmente o pássaro e trouxe água. Logo o pássaro se sentiu melhor e pôde voar novamente. O pássaro agradeceu Tommy por sua bondade.',
          'adventure': 'Luna encontrou uma porta mágica em seu jardim. Ela a abriu e descobriu uma terra cheia de flores coloridas e borboletas amigáveis. Ela teve uma aventura maravilhosa e fez novos amigos.',
        },
        'Ages 6-8': {
          'friendship': 'Emma era nova na escola e se sentia sozinha. Durante o almoço, ela notou que Alex também estava sentado sozinho. Emma se aproximou e compartilhou seus biscoitos. Eles conversaram sobre seus livros favoritos e se tornaram grandes amigos.',
          'courage': 'Jake estava nervoso sobre sua primeira aula de natação. A piscina parecia tão grande! Seu professor era paciente e gentil. Jake respirou fundo, pulou e descobriu que adorava nadar.',
          'kindness': 'Sarah notou uma vizinha idosa lutando com sacolas pesadas. Ela perguntou à sua mãe se elas poderiam ajudar. Juntas carregaram as sacolas e até fizeram biscoitos para sua vizinha. A bondade fez todos sorrirem.',
          'adventure': 'Max descobriu um mapa antigo em seu sótão. Ele levava a um tesouro escondido na floresta. Com seus amigos, ele seguiu as pistas e encontrou um baú cheio de pedras bonitas e uma nota sobre amizade sendo o maior tesouro.',
        },
        'Ages 9-12': {
          'friendship': 'Sofia se mudou para uma nova cidade e sentia falta de seus velhos amigos. Em sua nova escola, ela se juntou ao clube de arte e conheceu crianças que amavam desenhar como ela. Eles trabalharam juntos em um mural e Sofia percebeu que poderia fazer novos amigos.',
          'courage': 'Marcus queria participar do show de talentos da escola mas tinha medo de se apresentar. Ele praticou seus truques de mágica todos os dias. Na noite do show, ele se lembrou de toda sua prática e se apresentou lindamente, ganhando uma ovação de pé.',
          'kindness': 'Quando Lily viu colegas intimidando um novo aluno, ela o defendeu. Ela o convidou para sentar com seu grupo no almoço e o ajudou a fazer amigos. Sua bondade criou um efeito cascata de aceitação na escola.',
          'adventure': 'Zoe encontrou uma chave misteriosa enquanto limpava o sótão de sua avó. Ela abriu uma sala secreta cheia de diários das aventuras de sua avó ao redor do mundo. Inspirada, Zoe começou a planejar suas próprias aventuras.',
        },
      },
    };

    String selectedLanguage = fallbackStories.containsKey(language) ? language : 'English';
    String selectedAge = fallbackStories[selectedLanguage]!.containsKey(ageRange) ? ageRange : 'Ages 6-8';
    String selectedTheme = fallbackStories[selectedLanguage]![selectedAge]!.containsKey(theme) ? theme : 'friendship';
    
    String storyContent = fallbackStories[selectedLanguage]![selectedAge]![selectedTheme]!;
    
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': 'Untitled Story',
      'content': storyContent,
      'lesson': 'Every day brings new adventures and learning!',
      'ageRange': ageRange,
      'language': language,
      'theme': theme,
      'createdAt': DateTime.now(),
      'backgroundImageUrl': _getRandomBackground(),
    };
  }

  // // Generate story with AI in multiple languages
  // static Future<Map<String, dynamic>> generateStory({
  //   required String childName,
  //   required String ageRange,
  //   required String theme,
  //   required String language,
  //   String? customPrompt,
  // }) async {
  //   try {
  //     // Create language-specific prompts
  //     Map<String, String> languagePrompts = {
  //       'English': 'Create an engaging children\'s story in English',
  //       'Swahili': 'Unda hadithi ya watoto yenye kuvutia kwa Kiswahili',
  //       'French': 'Créez une histoire captivante pour enfants en français',
  //       'German': 'Erstellen Sie eine fesselnde Kindergeschichte auf Deutsch',
  //       'Spanish': 'Crea una historia infantil cautivadora en español',
  //       'Dutch': 'Maak een boeiend kinderverhaal in het Nederlands',
  //       'Portuguese': 'Crie uma história cativante para crianças em português',
  //     };

  //     String basePrompt = languagePrompts[language] ?? languagePrompts['English']!;
      
  //     String prompt = '''
  //     $basePrompt for $ageRange about $theme. 
  //     Main character name: $childName
      
  //     Requirements:
  //     - Write entirely in $language
  //     - Age-appropriate vocabulary and concepts for $ageRange
  //     - Story length: 150-300 words for Ages 3-5, 300-500 words for Ages 6-8, 500-800 words for Ages 9-12
  //     - Include a clear moral lesson about $theme
  //     - Make the story engaging and educational
  //     - Use simple sentence structure appropriate for the age group
  //     ${customPrompt != null ? 'Additional requirements: $customPrompt' : ''}
      
  //     Format your response as JSON with these fields:
  //     {
  //       "title": "Story title in $language",
  //       "content": "Full story text in $language",
  //       "lesson": "Moral lesson in $language"
  //     }
  //     ''';

  //     final model = GenerativeModel(
  //       model: 'gemini-1.5-flash-latest',
  //       apiKey: _apiKey,
  //       generationConfig: GenerationConfig(
  //         temperature: 0.8,
  //         topK: 40,
  //         topP: 0.95,
  //         maxOutputTokens: 1000,
  //       ),
  //     );

  //     final content = [Content.text(prompt)];
  //     final response = await model.generateContent(content);
      
  //     if (response.text != null) {
  //       try {
  //         // Clean the response text to extract JSON
  //         String cleanResponse = response.text!.trim();
  //         if (cleanResponse.startsWith('```json')) {
  //           cleanResponse = cleanResponse.replaceFirst('```json', '').replaceFirst('```', '');
  //         }
  //         if (cleanResponse.startsWith('```')) {
  //           cleanResponse = cleanResponse.replaceFirst('```', '').replaceFirst('```', '');
  //         }
          
  //         final Map<String, dynamic> storyData = json.decode(cleanResponse);
          
  //         // Create the complete story object
  //         Map<String, dynamic> story = {
  //           'id': DateTime.now().millisecondsSinceEpoch.toString(),
  //           'title': storyData['title'] ?? 'Generated Story',
  //           'content': storyData['content'] ?? '',
  //           'lesson': storyData['lesson'] ?? 'Every story teaches us something new!',
  //           'ageRange': ageRange,
  //           'language': language,
  //           'theme': theme,
  //           'createdAt': DateTime.now(),
  //           'backgroundImageUrl': _getRandomBackground(),
  //         };

  //         // Save to Firebase if user is logged in
  //         if (_auth.currentUser != null) {
  //           await _saveStoryToFirebase(story);
  //         }

  //         return story;
  //       } catch (e) {
  //         print('Error parsing AI response: $e');
  //         return _getFallbackStory(ageRange, language, theme);
  //       }
  //     } else {
  //       return _getFallbackStory(ageRange, language, theme);
  //     }
  //   } catch (e) {
  //     print('Error generating story: $e');
  //     return _getFallbackStory(ageRange, language, theme);
  //   }
  // }

  // Save story to Firebase
  // static Future<void> _saveStoryToFirebase(Map<String, dynamic> story) async {
  //   try {
  //     if (_auth.currentUser == null) return;

  //     await _firestore
  //         .collection('users')
  //         .doc(_auth.currentUser!.uid)
  //         .collection('stories')
  //         .doc(story['id'])
  //         .set({
  //       'title': story['title'],
  //       'content': story['content'],
  //       'lesson': story['lesson'],
  //       'ageRange': story['ageRange'],
  //       'language': story['language'],
  //       'theme': story['theme'],
  //       'backgroundImageUrl': story['backgroundImageUrl'],
  //       'createdAt': story['createdAt'],
  //     });
  //   } catch (e) {
  //     print('Error saving story to Firebase: $e');
  //   }
  // }

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

  // Helper method to check if two dates are the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}
