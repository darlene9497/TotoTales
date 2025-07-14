import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/story_card.dart';
import '../data/stories_data.dart';
import '../models/story.dart';
import 'story_reader_screen.dart';

class StoryLibraryScreen extends StatefulWidget {
  final String? selectedAgeRange;

  const StoryLibraryScreen({super.key, this.selectedAgeRange});

  @override
  _StoryLibraryScreenState createState() => _StoryLibraryScreenState();
}

class _StoryLibraryScreenState extends State<StoryLibraryScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;

  String _selectedLanguage = 'English';
  String _sortBy = 'New';
  String _selectedAgeRange = 'All';
  List<Story> _filteredStories = [];

  @override
  void initState() {
    super.initState();
    
    _selectedAgeRange = widget.selectedAgeRange ?? 'All';
    
    _headerController = AnimationController(
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
    
    _filterStories();
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  void _filterStories() {
    setState(() {
      _filteredStories = StoriesData.stories.where((story) {
        bool matchesLanguage = story.language == _selectedLanguage;
        bool matchesAge = _selectedAgeRange == 'All' || story.ageRange == _selectedAgeRange;
        return matchesLanguage && matchesAge;
      }).toList();
      
      // Sort stories
      if (_sortBy == 'New') {
        _filteredStories.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      } else if (_sortBy == 'Popular') {
        _filteredStories.sort((a, b) => b.popularity.compareTo(a.popularity));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              AnimatedBuilder(
                animation: _headerController,
                builder: (context, child) {
                  return SlideTransition(
                    position: _headerSlideAnimation,
                    child: FadeTransition(
                      opacity: _headerFadeAnimation,
                      child: _buildHeader(),
                    ),
                  );
                },
              ),
              
              // Filters
              _buildFilters(),
              
              // Stories Grid
              Expanded(
                child: _filteredStories.isEmpty
                    ? _buildEmptyState()
                    : AnimationLimiter(
                        child: GridView.builder(
                          padding: EdgeInsets.all(AppConstants.defaultPadding),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                          itemCount: _filteredStories.length,
                          itemBuilder: (context, index) {
                            return AnimationConfiguration.staggeredGrid(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              columnCount: 2,
                              child: ScaleAnimation(
                                child: FadeInAnimation(
                                  child: StoryCard(
                                    story: _filteredStories[index],
                                    onTap: () => _navigateToStoryReader(_filteredStories[index]),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.textDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Story Library 📚',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  _selectedAgeRange == 'All' 
                      ? 'All ages' 
                      : 'Ages $_selectedAgeRange',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                  items: AppConstants.freeLanguages.map((String language) {
                    return DropdownMenuItem<String>(
                      value: language,
                      child: Row(
                        children: [
                          Text(AppConstants.languages[language]!),
                          SizedBox(width: 8),
                          Text(language),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLanguage = newValue;
                      });
                      _filterStories();
                    }
                  },
                ),
              ),
            ),
          ),
          SizedBox(width: 15),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                items: ['New', 'Popular'].map((String sort) {
                  return DropdownMenuItem<String>(
                    value: sort,
                    child: Text(sort),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _sortBy = newValue;
                    });
                    _filterStories();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textMedium,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Try changing your filters or check back later for new stories!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToStoryReader(Story story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryReaderScreen(story: story),
      ),
    );
  }
}