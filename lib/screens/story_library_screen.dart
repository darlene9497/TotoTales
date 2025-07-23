// ignore_for_file: deprecated_member_use, avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../models/story.dart';
import '../services/profile_service.dart';
import 'story_reader_screen.dart';
import '../services/gemini_service.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class StoryLibraryScreen extends StatefulWidget {
  final String? selectedAgeRange;

  const StoryLibraryScreen({super.key, this.selectedAgeRange});

  @override
  _StoryLibraryScreenState createState() => _StoryLibraryScreenState();
}

class _StoryLibraryScreenState extends State<StoryLibraryScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _fabController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _fabScaleAnimation;

  String _selectedAgeRange = 'All';
  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String _selectedLanguage = 'English';
  Set<String> _savedStoryIds = {};
  Set<String> _completedStoryIds = {};
  final List<String> _backgrounds = List.generate(20, (i) => 'assets/images/story_bgs/bg${i + 1}.jpg');
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _selectedAgeRange = widget.selectedAgeRange ?? 'All';
    _initializeAnimations();
    _loadStories();
    _loadUserData();
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
    
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutBack,
    ));
    
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeIn,
    ));

    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));

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
    setState(() { _isLoading = true; });
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not logged in. Cannot load stories.');
        setState(() { _isLoading = false; });
        return;
      }

      final storiesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stories');

      final snapshot = await storiesRef.get();
      _stories = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['createdAt'] is String) {
          data['createdAt'] = DateTime.tryParse(data['createdAt']) ?? DateTime.now();
        }
        return data;
      }).toList();

    } catch (e) {
      print('Error loading stories: $e');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _loadUserData() async {
    try {
      // Load favorite and completed story IDs
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

  Future<void> _generateInitialStories() async {
    setState(() { _isGenerating = true; });
    _stories.clear();
    
    final userAge = _selectedAgeRange == 'All' ? 'Ages 6-8' : _selectedAgeRange;
    final themes = ['friendship', 'courage', 'kindness', 'adventure', 'animals'];
    
    for (final theme in themes) {
      try {
        // Generate story content
        final story = await GeminiService.generateStory(
          ageRange: userAge,
          language: _selectedLanguage,
          theme: theme,
        );
        
        // Assign a random background image from assets
        final coverImage = _backgrounds[_random.nextInt(_backgrounds.length)];
        story['coverImageUrl'] = coverImage;
        story['pageImages'] = [];
        _stories.add(story);
        
        // Save incrementally and update UI
        await _saveStories();
        if (mounted) setState(() {});
        
      } catch (e) {
        print('Error generating story: $e');
        // Add a fallback story with reliable images
        _stories.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': 'The Magic ${theme.substring(0, 1).toUpperCase()}${theme.substring(1)} Story',
          'theme': theme,
          'ageRange': userAge,
          'language': _selectedLanguage,
          'content': 'A wonderful story about $theme that teaches valuable lessons.',
          'lesson': 'Learn about the importance of $theme',
          'createdAt': DateTime.now(),
          'popularity': 0,
          'coverImageUrl': _backgrounds[_random.nextInt(_backgrounds.length)],
          'pageImages': [],
        });
        if (mounted) setState(() {});
      }
    }
    
    setState(() { _isGenerating = false; });
  }

  Future<void> _generateNewStory() async {
    setState(() { _isGenerating = true; });
    
    final userAge = _selectedAgeRange == 'All' ? 'Ages 6-8' : _selectedAgeRange;
    final themes = ['friendship', 'courage', 'kindness', 'adventure', 'imagination', 
                  'helping', 'sharing', 'animals', 'nature', 'dreams', 'space', 'magic'];
    final theme = (themes..shuffle()).first;
    
    try {
      final story = await GeminiService.generateStory(
        ageRange: userAge,
        language: _selectedLanguage,
        theme: theme,
      );
      
      // Assign a random background image from assets
      final coverImage = _backgrounds[_random.nextInt(_backgrounds.length)];
      story['coverImageUrl'] = coverImage;
      _stories.insert(0, story);
      await _saveStories();
      
    } catch (e) {
      // Create fallback story with reliable image
      final fallbackStory = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': 'The Amazing ${theme.substring(0, 1).toUpperCase()}${theme.substring(1)} Adventure',
        'theme': theme,
        'ageRange': userAge,
        'language': _selectedLanguage,
        'content': 'Once upon a time, there was a wonderful adventure about $theme...',
        'lesson': 'This story teaches us about $theme',
        'createdAt': DateTime.now(),
        'popularity': 0,
        'coverImageUrl': _backgrounds[_random.nextInt(_backgrounds.length)],
        'pageImages': [],
      };
      
      _stories.insert(0, fallbackStory);
      await _saveStories();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Story created with fallback content'),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      setState(() { _isGenerating = false; });
    }
  }
  
  Future<void> _saveStories() async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in. Cannot save stories.');
      return;
    }

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
      
      // Show loading state
      setState(() {
        if (isFavorited) {
          _savedStoryIds.remove(story.id);
        } else {
          _savedStoryIds.add(story.id);
        }
      });
      
      final success = await ProfileService.toggleFavorite(story);
      
      if (!success) {
        // Revert the optimistic update if it failed
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
            content: Text(isFavorited ? 'Story removed from favorites' : 'Story saved to favorites'),
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

  Future<void> _markStoryAsCompleted(String storyId, Map<String, dynamic> storyData) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundYellow,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _buildStoryGrid(),
        ],
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.backgroundYellow,
      elevation: 0,
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: SlideTransition(
          position: _headerSlideAnimation,
          child: FadeTransition(
            opacity: _headerFadeAnimation,
            child: Container(
              padding: EdgeInsets.fromLTRB(80, 40, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Story Library',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.book, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        '${_stories.length} magical stories',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

    // Filter stories by age range unless 'All'
    List<Map<String, dynamic>> filteredStories = _selectedAgeRange == 'All'
        ? _stories
        : _stories.where((story) => story['ageRange'] == _selectedAgeRange).toList();

    if (filteredStories.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState());
    }

    return SliverPadding(
      padding: EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Label for current filter
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              _selectedAgeRange == 'All'
                  ? 'Showing: All Stories'
                  : 'Showing: Ages $_selectedAgeRange',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // The grid
          SizedBox(
            height: 20,
          ),
          // The actual grid
          SizedBox(
            height: 500, // You may want to make this dynamic
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: filteredStories.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _buildStoryCard(filteredStories[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    final isSaved = _savedStoryIds.contains(story['id']);
    final isCompleted = _completedStoryIds.contains(story['id']);
    final coverImage = story['coverImageUrl'] ?? _backgrounds[_random.nextInt(_backgrounds.length)];
    
    return GestureDetector(
      onTap: () => _navigateToStoryReader(_mapToStory(story)),
      child: Container(
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
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          coverImage,
                          fit: BoxFit.cover,
                        ),
                        // Completed overlay
                        if (isCompleted)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                            ),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'COMPLETED',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          story['title'] ?? 'Untitled Story',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        _buildStoryTag(
                          _formatThemeName(story['theme'] ?? 'General'), 
                          isTheme: true
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                    isSaved ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isSaved ? AppColors.primary : AppColors.textMedium,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Helper method to format theme names nicely
  String _formatThemeName(String theme) {
    return theme.split('').first.toUpperCase() + theme.substring(1).toLowerCase();
  }

  // Update the _buildStoryTag method (keep only one version for themes):
  Widget _buildStoryTag(String text, {bool isTheme = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isTheme ? AppColors.primary.withOpacity(0.1) : AppColors.backgroundYellow,
        borderRadius: BorderRadius.circular(8),
        border: isTheme ? Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ) : null,
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
              'Try adjusting your filters or create a new story!',
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
    final images = data['pageImages'] is List ? List<String>.from(data['pageImages']) : <String>[];
    return Story(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      language: data['language'] ?? 'English',
      ageRange: data['ageRange'] ?? 'Ages 6-8',
      category: data['theme'] ?? 'General',
      coverImageUrl: data['coverImageUrl'] ?? '',
      description: data['lesson'] ?? '',
      dateAdded: data['createdAt'] is DateTime ? data['createdAt'] : DateTime.now(),
      popularity: data['popularity'] ?? 0,
      pages: _splitStoryToPages(data['content'] ?? '', images),
    );
  }

  List<StoryPage> _splitStoryToPages(String content, List<String> images) {
    final paragraphs = content.split(RegExp(r'\n+'))
        .where((p) {
          final clean = p.trim().toLowerCase();
          // Remove lines like 'page 1:', 'page 2', 'story:', etc.
          return clean.isNotEmpty &&
                 !RegExp(r'^page\s*\d+:?$', caseSensitive: false).hasMatch(clean) &&
                 clean != 'story:' && clean != 'story';
        })
        .toList();
    return List.generate(paragraphs.length, (i) => StoryPage(
      pageNumber: i + 1,
      imageUrl: i < images.length ? images[i] : '',
      text: paragraphs[i],
    ));
  }

  void _navigateToStoryReader(Story story) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => StoryReaderScreen(story: story),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
      ),
    );

    // If the story was completed, mark it as such
    if (result == 'completed') {
      final storyData = _stories.firstWhere(
        (s) => s['id'] == story.id,
        orElse: () => <String, dynamic>{},
      );
      if (storyData.isNotEmpty) {
        await _markStoryAsCompleted(story.id, storyData);
      }
    }
  }
}