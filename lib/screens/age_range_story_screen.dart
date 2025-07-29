// ignore_for_file: unnecessary_cast, avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toto_tales/services/language_service.dart';
import '../utils/colors.dart';
import '../models/story.dart';
import '../services/profile_service.dart';
import 'story_reader_screen.dart';
import '../services/gemini_service.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class AgeRangeStoryScreen extends StatefulWidget {
  final String ageRange;
  final String? screenTitle;
  const AgeRangeStoryScreen({
    Key? key,
    required this.ageRange,
    this.screenTitle,
  }) : super(key: key);

  @override
  _AgeRangeStoryScreenState createState() => _AgeRangeStoryScreenState();
}

class _AgeRangeStoryScreenState extends State<AgeRangeStoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _fabController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _fabScaleAnimation;

  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String _selectedLanguage = 'English';
  final List<String> _backgrounds = List.generate(
    20,
    (i) => 'assets/images/story_bgs/bg${i + 1}.jpg',
  );
  final Random _random = Random();
  Set<String> _savedStoryIds = {};
  Set<String> _completedStoryIds = {};

  Future<void> _loadUserData() async {
    try {
      final favoriteIds = await ProfileService.getFavoriteStoryIds();
      final completedIds = await ProfileService.getCompletedStoryIds();
      setState(() {
        _savedStoryIds = favoriteIds;
        _completedStoryIds = completedIds;
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentLanguage();
    _loadStories();
    _loadUserData();
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final currentLanguage = await LanguageService.getCurrentLanguage();
      setState(() {
        _selectedLanguage = currentLanguage;
      });
    } catch (e) {
      print('Error loading current language: $e');
      setState(() {
        _selectedLanguage = 'English'; // Fallback
      });
    }
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
        );
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeIn));
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );
    _headerController.forward();
    Future.delayed(Duration(milliseconds: 500), () {
      _fabController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final storiesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stories');
      final snapshot = await storiesRef.get();
      _stories = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['createdAt'] is String) {
              data['createdAt'] =
                  DateTime.tryParse(data['createdAt']) ?? DateTime.now();
            }
            return data;
          })
          .where((story) => story['ageRange'] == widget.ageRange)
          .toList();
    } catch (e) {
      print('Error loading stories: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateNewStory() async {
    setState(() {
      _isGenerating = true;
    });

    // Get current language preference
    final currentLanguage = await LanguageService.getCurrentLanguage();
    setState(() {
      _selectedLanguage = currentLanguage;
    });

    final userAge = widget.ageRange;
    final themes = [
      'friendship',
      'courage',
      'kindness',
      'adventure',
      'imagination',
      'helping',
      'sharing',
      'animals',
      'nature',
      'dreams',
      'space',
      'magic',
    ];
    final theme = (themes..shuffle()).first;

    try {
      final story = await GeminiService.generateStory(
        ageRange: userAge,
        language: _selectedLanguage, // Use current language preference
        theme: theme,
      );

      // Assign a random background image from assets
      final coverImage = _backgrounds[_random.nextInt(_backgrounds.length)];
      story['coverImageUrl'] = coverImage;
      _stories.insert(0, story);
      await _saveStories();

      // Show success message with language info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New story created in $_selectedLanguage!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      // Create fallback story with current language
      final fallbackStory = _createFallbackStory(
        theme,
        userAge,
        _selectedLanguage,
      );
      _stories.insert(0, fallbackStory);
      await _saveStories();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Story created in $_selectedLanguage (fallback content)',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // Helper method to create fallback story
  Map<String, dynamic> _createFallbackStory(
    String theme,
    String userAge,
    String language,
  ) {
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title':
          'The Amazing ${theme.substring(0, 1).toUpperCase()}${theme.substring(1)} Adventure',
      'theme': theme,
      'ageRange': userAge,
      'language': language, // Use current language
      'content':
          'Once upon a time, there was a wonderful adventure about $theme...',
      'lesson': 'This story teaches us about $theme',
      'createdAt': DateTime.now(),
      'popularity': 0,
      'coverImageUrl': _backgrounds[_random.nextInt(_backgrounds.length)],
      'pageImages': [],
    };
  }

  Future<void> _saveStories() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final storiesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('stories');
    for (final story in _stories) {
      final storyRef = storiesRef.doc(story['id']);
      await storyRef.set(story, SetOptions(merge: true));
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> storyData) async {
    try {
      final story = _mapToStory(storyData);
      final isFavorited = _savedStoryIds.contains(story.id);
      setState(() {
        if (isFavorited) {
          _savedStoryIds.remove(story.id);
        } else {
          _savedStoryIds.add(story.id);
        }
      });
      final success = await ProfileService.toggleFavorite(story);
      if (!success) {
        setState(() {
          if (isFavorited) {
            _savedStoryIds.add(story.id);
          } else {
            _savedStoryIds.remove(story.id);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving story. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorited
                  ? 'Story removed from favorites'
                  : 'Story saved to favorites',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving story. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markStoryAsCompleted(
    String storyId,
    Map<String, dynamic> storyData,
  ) async {
    try {
      final story = _mapToStory(storyData);
      final success = await ProfileService.markAsCompleted(story);

      if (success) {
        setState(() {
          _completedStoryIds.add(storyId);
        });
      }
    } catch (e) {
      print('Error marking story as completed: $e');
    }
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: SlideTransition(
          position: _headerSlideAnimation,
          child: FadeTransition(
            opacity: _headerFadeAnimation,
            child: Container(
              padding: EdgeInsets.fromLTRB(80, 40, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/hello.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade100,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow.shade200,
                            blurRadius: 8,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.screenTitle ?? _getGreeting(widget.ageRange),
                        style: GoogleFonts.comicNeue(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting(String ageRange) {
    switch (ageRange) {
      case 'Ages 3-5':
        return 'Little Explorer';
      case 'Ages 6-8':
        return 'Bright Learner';
      case 'Ages 9-12':
        return 'Junior Dreamer';
      default:
        return 'Adventurer';
    }
  }

  Widget _buildStoryGrid() {
    if (_isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 20),
                Text(
                  'Loading magical stories...',
                  style: GoogleFonts.poppins(color: AppColors.textMedium),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_stories.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState());
    }
    return SliverPadding(
      padding: EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 375),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(child: _buildStoryCard(_stories[index])),
            ),
          ),
          childCount: _stories.length,
        ),
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    final isSaved = _savedStoryIds.contains(story['id']);
    final isCompleted = _completedStoryIds.contains(story['id']);
    final coverImage =
        story['coverImageUrl'] ??
        _backgrounds[_random.nextInt(_backgrounds.length)];

    return GestureDetector(
      onTap: () => _navigateToStoryReader(_mapToStory(story)),
      child: Container(
        height: 270,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.asset(
                    coverImage,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 120,
                  ),
                ),
                // Completion tag in the center
                if (isCompleted)
                  Positioned(
                    top: 35,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'COMPLETED',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildLanguageFlag(story['language'] ?? 'English'),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(story),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        isSaved
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: isSaved
                            ? AppColors.primary
                            : AppColors.textMedium,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text(
                story['title'] ?? 'Untitled Story',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: _buildStoryTag(
                _formatThemeName(story['theme'] ?? 'General'),
                isTheme: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageFlag(String language) {
    final flagMap = {
      'English': '🇬🇧',
      'Swahili': '🇰🇪',
      'French': '🇫🇷',
      'German': '🇩🇪',
      'Dutch': '🇳🇱',
      'Spanish': '🇪🇸',
      'Portuguese': '🇵🇹',
    };
    return Text(flagMap[language] ?? '🏳️', style: TextStyle(fontSize: 18));
  }

  String _formatThemeName(String theme) {
    return theme.split('').first.toUpperCase() +
        theme.substring(1).toLowerCase();
  }

  Widget _buildStoryTag(String text, {bool isTheme = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isTheme
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.backgroundYellow,
        borderRadius: BorderRadius.circular(8),
        border: isTheme
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: isTheme ? AppColors.primary : AppColors.textMedium,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 80,
              color: AppColors.textLight,
            ),
            SizedBox(height: 20),
            Text(
              'No stories found',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textMedium,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Try creating a new story',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Story _mapToStory(Map<String, dynamic> data) {
    final images = data['pageImages'] is List
        ? List<String>.from(data['pageImages'])
        : <String>[];
    return Story(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      language: data['language'] ?? 'English',
      ageRange: data['ageRange'] ?? 'Ages 6-8',
      category: data['theme'] ?? 'General',
      coverImageUrl: data['coverImageUrl'] ?? '',
      description: data['lesson'] ?? '',
      dateAdded: data['createdAt'] is DateTime
          ? data['createdAt']
          : DateTime.now(),
      popularity: data['popularity'] ?? 0,
      pages: _splitStoryToPages(data['content'] ?? '', images),
    );
  }

  List<StoryPage> _splitStoryToPages(String content, List<String> images) {
    final paragraphs = content.split(RegExp(r'\n+')).where((p) {
      final clean = p.trim().toLowerCase();
      return clean.isNotEmpty &&
          !RegExp(r'^page\s*\d+:?$', caseSensitive: false).hasMatch(clean) &&
          clean != 'story:' &&
          clean != 'story';
    }).toList();
    return List.generate(
      paragraphs.length,
      (i) => StoryPage(
        pageNumber: i + 1,
        imageUrl: i < images.length ? images[i] : '',
        text: paragraphs[i],
      ),
    );
  }

  void _navigateToStoryReader(Story story) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StoryReaderScreen(story: story)),
    );
    // If the story was completed, mark it as such and reload user data
    if (result == 'completed') {
      final storyData = _stories.firstWhere(
        (s) => s['id'] == story.id,
        orElse: () => <String, dynamic>{},
      );
      if (storyData.isNotEmpty) {
        await _markStoryAsCompleted(story.id, storyData);
        // Reload user data to update the UI
        await _loadUserData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundYellow,
      body: CustomScrollView(
        slivers: [_buildSliverAppBar(), _buildStoryGrid()],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: _isGenerating ? null : _generateNewStory,
          backgroundColor: AppColors.primary,
          icon: _isGenerating
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(Icons.auto_stories, color: Colors.white),
          label: Text(
            _isGenerating ? 'Creating...' : 'New Story',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
