// ignore_for_file: deprecated_member_use

import 'dart:math' show cos, sin;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'package:toto_tales/widgets/age_category_card.dart';
import '../widgets/bottom_nav_item.dart';
import 'story_library_screen.dart';
import 'affirmation_screen.dart';
import 'language_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? registeredAgeRange; // Add this to receive the child's registered age
  
  const HomeScreen({super.key, this.registeredAgeRange});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _starsController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _starsAnimation;
  int _currentIndex = 0;
  
  // Default age range if not provided (you might want to handle this differently)
  String get childAgeRange => widget.registeredAgeRange ?? '3-5';

  @override
  void initState() {
    super.initState();
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _starsController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
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
    
    _starsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _starsController,
      curve: Curves.linear,
    ));
    
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  // Helper method to check if an age category is enabled
  bool _isAgeRangeEnabled(String ageRange) {
    return ageRange == childAgeRange;
  }

  // Show dialog when locked card is tapped
  void _showLockedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lock,
                color: AppColors.textMedium,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Age Restricted',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: Text(
            'This age category is not available for you. Ask your parent to change your age range in your profile if needed.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textMedium,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brightLearners,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with animated stars
          Container(
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
          ),
          
          // Animated stars
          AnimatedBuilder(
            animation: _starsAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: StarsPainter(_starsAnimation.value),
                size: Size.infinite,
              );
            },
          ),
          
          // Main content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
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
                  
                  // Centered cards with equal spacing
                  Expanded(
                    child: Center(
                      child: AnimationLimiter(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                emoji: '🌟',
                                title: AppConstants.littleExplorers,
                                ageRange: AppConstants.littleExplorersAge,
                                description: AppConstants.littleExplorersDescription,
                                primaryColor: AppColors.littleExplorers,
                                secondaryColor: AppColors.littleExplorersDark,
                                onTap: _isAgeRangeEnabled('3-5')
                                    ? () => _navigateToStoryLibrary('3-5')
                                    : _showLockedDialog,
                              ),
                              SizedBox(height: 20),
                              AgeCategoryCard(
                                emoji: '📚',
                                title: AppConstants.brightLearners,
                                ageRange: AppConstants.brightLearnersAge,
                                description: AppConstants.brightLearnersDescription,
                                primaryColor: AppColors.brightLearners,
                                secondaryColor: AppColors.brightLearnersDark,
                                onTap: _isAgeRangeEnabled('6-8')
                                    ? () => _navigateToStoryLibrary('6-8')
                                    : _showLockedDialog,
                              ),
                              SizedBox(height: 20),
                              AgeCategoryCard(
                                emoji: '🎭',
                                title: AppConstants.juniorDreamers,
                                ageRange: AppConstants.juniorDreamersAge,
                                description: AppConstants.juniorDreamersDescription,
                                primaryColor: AppColors.juniorDreamers,
                                secondaryColor: AppColors.juniorDreamersDark,
                                onTap: _isAgeRangeEnabled('9-12')
                                    ? () => _navigateToStoryLibrary('9-12')
                                    : _showLockedDialog,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _handleNavigation(index);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Text(
            'Hello, Little Reader 👋',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 5),
          Text(
            'Pick Your Story Zone',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textMedium,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        // Already on home screen
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryLibraryScreen(selectedAgeRange: childAgeRange),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AffirmationScreen(selectedAgeRange: _getAgeRangeDisplay(childAgeRange)),
          ),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LanguageScreen()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
        break;
    }
  }

  void _navigateToStoryLibrary(String ageRange) {
    // Convert short form to long form for navigation
    String displayAgeRange;
    switch (ageRange) {
      case '3-5':
        displayAgeRange = 'Ages 3-5';
        break;
      case '6-8':
        displayAgeRange = 'Ages 6-8';
        break;
      case '9-12':
        displayAgeRange = 'Ages 9-12';
        break;
      default:
        displayAgeRange = 'Ages 6-8';
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryLibraryScreen(selectedAgeRange: displayAgeRange),
      ),
    );
  }

  // Helper method to convert age range to display format
  String _getAgeRangeDisplay(String ageRange) {
    switch (ageRange) {
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
}

// Keep the existing StarsPainter class unchanged
class StarsPainter extends CustomPainter {
  final double animation;

  StarsPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    final smallStarPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    final sparkPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw multiple stars at different positions
    final stars = [
      {'x': 0.15, 'y': 0.2, 'size': 8.0, 'speed': 1.0},
      {'x': 0.8, 'y': 0.15, 'size': 6.0, 'speed': 0.8},
      {'x': 0.25, 'y': 0.45, 'size': 4.0, 'speed': 1.2},
      {'x': 0.75, 'y': 0.4, 'size': 5.0, 'speed': 0.9},
      {'x': 0.9, 'y': 0.6, 'size': 7.0, 'speed': 1.1},
      {'x': 0.1, 'y': 0.7, 'size': 5.0, 'speed': 0.7},
      {'x': 0.6, 'y': 0.8, 'size': 6.0, 'speed': 1.3},
      {'x': 0.4, 'y': 0.25, 'size': 4.0, 'speed': 1.0},
    ];

    for (var star in stars) {
      final x = size.width * (star['x'] as double);
      final y = size.height * (star['y'] as double);
      final starSize = star['size'] as double;
      final speed = star['speed'] as double;
      
      // Calculate rotation based on animation and speed
      final rotation = animation * speed * 2 * 3.14159;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      
      // Draw star shape
      _drawStar(canvas, starSize > 6 ? paint : smallStarPaint, starSize);
      
      // Add sparkle effect for larger stars
      if (starSize > 6) {
        _drawSparkle(canvas, sparkPaint, starSize * 1.5);
      }
      
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double size) {
    final path = Path();
    final double radius = size;
    final double innerRadius = radius * 0.4;
    
    for (int i = 0; i < 5; i++) {
      final double angle = (i * 2 * 3.14159) / 5 - 3.14159 / 2;
      final double innerAngle = ((i + 0.5) * 2 * 3.14159) / 5 - 3.14159 / 2;
      
      final double x = radius * cos(angle);
      final double y = radius * sin(angle);
      final double innerX = innerRadius * cos(innerAngle);
      final double innerY = innerRadius * sin(innerAngle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }

  void _drawSparkle(Canvas canvas, Paint paint, double size) {
    // Draw cross sparkle
    canvas.drawLine(Offset(-size/2, 0), Offset(size/2, 0), paint);
    canvas.drawLine(Offset(0, -size/2), Offset(0, size/2), paint);
    
    // Draw diagonal sparkle
    final diagonalSize = size * 0.7;
    canvas.drawLine(Offset(-diagonalSize/2, -diagonalSize/2), 
                   Offset(diagonalSize/2, diagonalSize/2), paint);
    canvas.drawLine(Offset(-diagonalSize/2, diagonalSize/2), 
                   Offset(diagonalSize/2, -diagonalSize/2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}