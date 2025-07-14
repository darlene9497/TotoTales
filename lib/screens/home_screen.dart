import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'package:tototales/widgets/age_category_card.dart';
import '../widgets/bottom_nav_item.dart';
import 'story_library_screen.dart';
import 'affirmation_screen.dart';
import 'language_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundYellow,
              AppColors.backgroundYellowLight,
              AppColors.backgroundYellowDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: SingleChildScrollView(
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
                  
                  SizedBox(height: 30),
                  
                  // Age Categories
                  AnimationLimiter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 500),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: widget,
                          ),
                        ),
                        children: [
                          AgeCategoryCard(
                            emoji: '🍼',
                            title: AppConstants.littleExplorers,
                            ageRange: AppConstants.littleExplorersAge,
                            description: AppConstants.littleExplorersDescription,
                            primaryColor: AppColors.littleExplorers,
                            secondaryColor: AppColors.littleExplorersDark,
                            onTap: () => _navigateToStoryLibrary('3-5'),
                          ),
                          SizedBox(height: 20),
                          AgeCategoryCard(
                            emoji: '🎈',
                            title: AppConstants.brightLearners,
                            ageRange: AppConstants.brightLearnersAge,
                            description: AppConstants.brightLearnersDescription,
                            primaryColor: AppColors.brightLearners,
                            secondaryColor: AppColors.brightLearnersDark,
                            onTap: () => _navigateToStoryLibrary('6-8'),
                          ),
                          SizedBox(height: 20),
                          AgeCategoryCard(
                            emoji: '📖',
                            title: AppConstants.juniorDreamers,
                            ageRange: AppConstants.juniorDreamersAge,
                            description: AppConstants.juniorDreamersDescription,
                            primaryColor: AppColors.juniorDreamers,
                            secondaryColor: AppColors.juniorDreamersDark,
                            onTap: () => _navigateToStoryLibrary('9-12'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Bottom Navigation
                  _buildBottomNavigation(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Little Reader! 👋',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Pick Your Story Zone!',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.person_outline,
              size: 28,
              color: AppColors.textDark,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BottomNavItem(
            icon: Icons.auto_stories,
            label: 'Stories',
            isSelected: _currentIndex == 0,
            onTap: () {
              setState(() => _currentIndex = 0);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StoryLibraryScreen()),
              );
            },
          ),
          BottomNavItem(
            icon: Icons.star_rounded,
            label: 'Affirmations',
            isSelected: _currentIndex == 1,
            onTap: () {
              setState(() => _currentIndex = 1);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AffirmationScreen(selectedAgeRange: 'Ages 3-5')),
              );
            },
          ),
          BottomNavItem(
            icon: Icons.language,
            label: 'Language',
            isSelected: _currentIndex == 2,
            onTap: () {
              setState(() => _currentIndex = 2);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LanguageScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToStoryLibrary(String ageRange) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryLibraryScreen(selectedAgeRange: ageRange),
      ),
    );
  }
}