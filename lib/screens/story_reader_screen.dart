import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/story.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/animated_button.dart';

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

  @override
  Widget build(BuildContext context) {
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
          widget.story.title,
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
                    'Page ${_currentPage + 1} of ${widget.story.pages.length}',
                    style: GoogleFonts.poppins(
                      color: AppColors.textMedium,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / widget.story.pages.length,
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
                itemCount: widget.story.pages.length,
                itemBuilder: (context, index) {
                  final page = widget.story.pages[index];
                  return SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            // Story Image
                            Expanded(
                              flex: 3,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  image: DecorationImage(
                                    image: AssetImage(page.imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Story Text
                            Expanded(
                              flex: 2,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                child: SingleChildScrollView(
                                  child: Text(
                                    page.text,
                                    style: GoogleFonts.poppins(
                                      fontSize: _getTextSize(),
                                      color: AppColors.textDark,
                                      height: 1.6,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Navigation Buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous Button
                  AnimatedButton(
                    text: 'Previous',
                    onPressed: _currentPage > 0 ? _previousPage : () {},
                    backgroundColor: _currentPage > 0 
                        ? AppColors.textMedium 
                        : AppColors.textLight,
                    icon: Icons.arrow_back_ios_rounded,
                    width: 120,
                    height: 50,
                  ),
                  
                  // Page Indicator Dots
                  Row(
                    children: List.generate(
                      widget.story.pages.length.clamp(0, 5),
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _currentPage ? 12 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? AppColors.primary
                              : AppColors.textLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  // Next Button
                  AnimatedButton(
                    text: _currentPage < widget.story.pages.length - 1 ? 'Next' : 'Finish',
                    onPressed: _currentPage < widget.story.pages.length - 1 
                        ? _nextPage 
                        : () => Navigator.of(context).pop(),
                    backgroundColor: AppColors.primary,
                    icon: _currentPage < widget.story.pages.length - 1
                        ? Icons.arrow_forward_ios_rounded
                        : Icons.check_circle_rounded,
                    width: 120,
                    height: 50,
                  ),
                ],
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