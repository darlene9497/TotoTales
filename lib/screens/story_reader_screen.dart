// ignore_for_file: deprecated_member_use, avoid_print
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/story.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/animated_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../services/profile_service.dart';

Future<void> markStoryCompleted(Map<String, dynamic> story) async {
  final user = fb_auth.FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final completed = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('completed_stories');
  await completed.doc(story['id']).set({
    'completedAt': FieldValue.serverTimestamp(),
    ...story,
  });
}

class StoryReaderScreen extends StatefulWidget {
  final Story story;

  const StoryReaderScreen({super.key, required this.story});

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _currentPage = 0;
  bool _isReading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < widget.story.pages.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: AppConstants.pageTransitionDuration),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: AppConstants.pageTransitionDuration),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _toggleReading() {
    setState(() {
      _isReading = !_isReading;
    });
    HapticFeedback.selectionClick();
  }

  /// Build fallback image widget with theme-based styling
  Widget _buildFallbackImage(StoryPage page) {
    // Try to determine theme from story category or use default
    final theme = widget.story.category.toLowerCase();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getThemeGradient(theme),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getThemeIcon(theme),
            size: 64,
            color: AppColors.primary.withOpacity(0.8),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _getImageDescription(page.text, theme),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Page ${page.pageNumber}',
            style: GoogleFonts.poppins(
              color: AppColors.textMedium,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Get theme-based gradient colors
  List<Color> _getThemeGradient(String theme) {
    switch (theme) {
      case 'friendship':
        return [
          Colors.pink.withOpacity(0.1),
          Colors.orange.withOpacity(0.1),
        ];
      case 'courage':
        return [
          Colors.red.withOpacity(0.1),
          Colors.orange.withOpacity(0.1),
        ];
      case 'kindness':
        return [
          Colors.green.withOpacity(0.1),
          Colors.blue.withOpacity(0.1),
        ];
      case 'adventure':
        return [
          Colors.purple.withOpacity(0.1),
          Colors.indigo.withOpacity(0.1),
        ];
      case 'animals':
        return [
          Colors.brown.withOpacity(0.1),
          Colors.green.withOpacity(0.1),
        ];
      case 'imagination':
      case 'magic':
        return [
          Colors.purple.withOpacity(0.1),
          Colors.pink.withOpacity(0.1),
        ];
      case 'space':
        return [
          Colors.indigo.withOpacity(0.1),
          Colors.purple.withOpacity(0.1),
        ];
      case 'nature':
        return [
          Colors.green.withOpacity(0.1),
          Colors.teal.withOpacity(0.1),
        ];
      default:
        return [
          AppColors.primary.withOpacity(0.15),
          AppColors.backgroundYellow.withOpacity(0.5),
        ];
    }
  }

  /// Get theme-based icon
  IconData _getThemeIcon(String theme) {
    switch (theme) {
      case 'friendship':
        return Icons.people;
      case 'courage':
        return Icons.shield;
      case 'kindness':
        return Icons.favorite;
      case 'adventure':
        return Icons.explore;
      case 'animals':
        return Icons.pets;
      case 'imagination':
      case 'magic':
        return Icons.auto_fix_high;
      case 'space':
        return Icons.rocket_launch;
      case 'nature':
        return Icons.eco;
      case 'helping':
        return Icons.handshake;
      case 'sharing':
        return Icons.share;
      case 'dreams':
        return Icons.nights_stay;
      default:
        return Icons.auto_stories;
    }
  }

  /// Generate descriptive text based on page content and theme
  String _getImageDescription(String pageText, String theme) {
    // Create a simple description based on the theme and story content
    final descriptions = {
      'friendship': 'Friends playing together',
      'courage': 'A brave adventure',
      'kindness': 'Helping others with care',
      'adventure': 'An exciting journey',
      'animals': 'Animals in their habitat',
      'imagination': 'A magical world',
      'magic': 'Enchanted moments',
      'space': 'Among the stars',
      'nature': 'Beautiful landscapes',
      'helping': 'Lending a helping hand',
      'sharing': 'Sharing with others',
      'dreams': 'Dream-like scenes',
    };

    return descriptions[theme] ?? 'A wonderful story moment';
  }

  @override
  Widget build(BuildContext context) {
    // Prepare pages: first = title, last = lesson, middle = story
    final List<_StoryReaderPage> pages = [];
    // First page: title only
    pages.add(_StoryReaderPage(
      type: _StoryReaderPageType.title,
      text: widget.story.title,
    ));
    // Story pages
    for (int i = 0; i < widget.story.pages.length; i++) {
      final page = widget.story.pages[i];
      pages.add(_StoryReaderPage(
        type: _StoryReaderPageType.story,
        text: page.text,
      ));
    }
    // Last page: lesson
    pages.add(_StoryReaderPage(
      type: _StoryReaderPageType.lesson,
      text: widget.story.description.isNotEmpty ? widget.story.description : 'Every day brings new adventures and learning!',
    ));

    // List of asset backgrounds
    final List<String> backgrounds = List.generate(20, (i) => 'assets/images/story_bgs/bg${i + 1}.jpg');

    String appBarTitle = widget.story.title;
    if (appBarTitle.trim().isEmpty) {
      appBarTitle = 'Untitled Story';
    }
    return Scaffold(
      backgroundColor: AppColors.backgroundYellow,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          appBarTitle,
          style: GoogleFonts.poppins(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isReading ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: AppColors.primary,
              size: 28,
            ),
            onPressed: _toggleReading,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Progress Indicator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Page ${_currentPage + 1} of ${pages.length}',
                    style: GoogleFonts.poppins(
                      color: AppColors.textMedium,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / pages.length,
                      backgroundColor: AppColors.cardGray,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            // Story Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  final bgImage = backgrounds[index % backgrounds.length];
                  return SlideTransition(
                    position: _slideAnimation,
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        width: 420,
                        constraints: BoxConstraints(maxWidth: 500),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              // Background image
                              Positioned.fill(
                                child: Image.asset(
                                  bgImage,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Overlay
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withOpacity(0.35),
                                ),
                              ),
                              // Story text
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Builder(
                                    builder: (context) {
                                      if (page.type == _StoryReaderPageType.title) {
                                        return Text(
                                          page.text,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 6,
                                                color: Colors.black.withOpacity(0.5),
                                                offset: Offset(1, 2),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else if (page.type == _StoryReaderPageType.lesson) {
                                        return Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.emoji_objects, color: Colors.white, size: 40, shadows: [Shadow(blurRadius: 6, color: Colors.black.withOpacity(0.5))]),
                                            SizedBox(height: 16),
                                            Text(
                                              'Lesson:',
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 6,
                                                    color: Colors.black.withOpacity(0.5),
                                                    offset: Offset(1, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              page.text,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                color: Colors.white,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 6,
                                                    color: Colors.black.withOpacity(0.5),
                                                    offset: Offset(1, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      } else {
                                        return Text(
                                          page.text,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.white,
                                            height: 1.6,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 6,
                                                color: Colors.black.withOpacity(0.5),
                                                offset: Offset(1, 2),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                              // Navigation arrows and dots at the bottom
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 28, shadows: [Shadow(blurRadius: 6, color: Colors.black.withOpacity(0.5))]),
                                      onPressed: index > 0 ? () => _pageController.previousPage(duration: Duration(milliseconds: 350), curve: Curves.easeInOut) : null,
                                    ),
                                    SizedBox(width: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(
                                        pages.length,
                                        (dotIdx) => Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 3),
                                          width: dotIdx == index ? 12 : 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: dotIdx == index ? Colors.white : Colors.white.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(4),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    index < pages.length - 1
                                      ? IconButton(
                                          icon: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 28, shadows: [Shadow(blurRadius: 6, color: Colors.black.withOpacity(0.5))]),
                                          onPressed: () => _pageController.nextPage(duration: Duration(milliseconds: 350), curve: Curves.easeInOut),
                                        )
                                      : IconButton(
                                          icon: Icon(Icons.check_circle, color: Colors.green, size: 32, shadows: [Shadow(blurRadius: 6, color: Colors.black.withOpacity(0.5))]),
                                          onPressed: () async {
                                            await ProfileService.markAsCompleted(widget.story);
                                            Navigator.pop(context, 'completed');
                                          },
                                        ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getTextSize() {
    switch (widget.story.ageRange) {
      case 'Ages 3-5':
        return 18;
      case 'Ages 6-8':
        return 16;
      case 'Ages 9-12':
        return 14;
      default:
        return 16;
    }
  }
}

// Helper class for page type
enum _StoryReaderPageType { title, story, lesson }
class _StoryReaderPage {
  final _StoryReaderPageType type;
  final String text;
  _StoryReaderPage({required this.type, required this.text});
}