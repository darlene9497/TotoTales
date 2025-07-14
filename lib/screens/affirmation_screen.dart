import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/affirmation.dart';
import '../data/affirmations_data.dart';
import '../utils/colors.dart';
import '../widgets/animated_button.dart';

class AffirmationScreen extends StatefulWidget {
  final String selectedAgeRange;

  const AffirmationScreen({super.key, required this.selectedAgeRange});

  @override
  State<AffirmationScreen> createState() => _AffirmationScreenState();
}

class _AffirmationScreenState extends State<AffirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _sparkleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _sparkleAnimation;
  
  late Affirmation _currentAffirmation;
  int _currentBackgroundIndex = 0;
  
  final List<String> _backgroundImages = [
    'assets/images/backgrounds/rainbow_sky.png',
    'assets/images/backgrounds/starry_night.png',
    'assets/images/backgrounds/sunny_field.png',
    'assets/images/backgrounds/flower_garden.png',
    'assets/images/backgrounds/ocean_waves.png',
  ];

  @override
  void initState() {
    super.initState();
    _currentAffirmation = AffirmationsData.getRandomAffirmation(widget.selectedAgeRange);
    _currentBackgroundIndex = DateTime.now().millisecondsSinceEpoch % _backgroundImages.length;
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
    
    _startAnimations();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _sparkleController.repeat(reverse: true);
    });
  }

  void _refreshAffirmation() {
    setState(() {
      _currentAffirmation = AffirmationsData.getRandomAffirmation(widget.selectedAgeRange);
      _currentBackgroundIndex = (_currentBackgroundIndex + 1) % _backgroundImages.length;
    });
    
    _fadeController.reset();
    _scaleController.reset();
    _sparkleController.reset();
    
    HapticFeedback.mediumImpact();
    _startAnimations();
  }

  Color _getAgeColor() {
    switch (widget.selectedAgeRange) {
      case 'Ages 3-5':
        return AppColors.littleExplorers;
      case 'Ages 6-8':
        return AppColors.brightLearners;
      case 'Ages 9-12':
        return AppColors.juniorDreamers;
      default:
        return AppColors.primary;
    }
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
        "Today's Magical Words",
        style: GoogleFonts.poppins(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          onPressed: _refreshAffirmation,
        ),
      ],
    ),
    body: FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_backgroundImages[_currentBackgroundIndex]),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getAgeColor().withAlpha((0.3 * 255).toInt()),
                _getAgeColor().withAlpha((0.1 * 255).toInt()),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Sparkle Animation
                AnimatedBuilder(
                  animation: _sparkleAnimation,
                  builder: (context, child) {
                    return SizedBox(
                      height: 100,
                      child: Stack(
                        children: List.generate(5, (index) {
                          return Positioned(
                            top: 20 + (index * 15.0),
                            left: 50 + (index * 60.0) + (_sparkleAnimation.value * 20),
                            child: Opacity(
                              opacity: _sparkleAnimation.value,
                              child: Icon(
                                Icons.auto_awesome,
                                color: AppColors.warning,
                                size: 24 - (index * 2),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),

                // Main Card and Buttons
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 30),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: _getAgeColor().withAlpha((0.3 * 255).toInt()),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Top Decoration
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: _getAgeColor(),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(30),
                                      topRight: Radius.circular(30),
                                    ),
                                  ),
                                  child: Center(
                                    child: AnimatedBuilder(
                                      animation: _sparkleController,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: 1.0 + (_sparkleAnimation.value * 0.2),
                                          child: const Icon(
                                            Icons.auto_awesome,
                                            color: Colors.white,
                                            size: 48,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                // Affirmation Text
                                Padding(
                                  padding: const EdgeInsets.all(30),
                                  child: Column(
                                    children: [
                                      Text(
                                        _currentAffirmation.text,
                                        style: GoogleFonts.poppins(
                                          fontSize: _getTextSize(),
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _getAgeColor().withAlpha((0.1 * 255).toInt()),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _currentAffirmation.category.toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _getAgeColor(),
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Action Buttons
                        AnimatedButton(
                          text: 'New Magical Words',
                          onPressed: _refreshAffirmation,
                          backgroundColor: _getAgeColor(),
                          icon: Icons.refresh_rounded,
                          height: 60,
                        ),
                        const SizedBox(height: 16),
                        AnimatedButton(
                          text: 'Say It Out Loud!',
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Say: "${_currentAffirmation.text}"'),
                                backgroundColor: _getAgeColor(),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          backgroundColor: AppColors.warning,
                          icon: Icons.volume_up_rounded,
                          height: 60,
                        ),
                        const SizedBox(height: 30),
                      ],
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

  double _getTextSize() {
    switch (widget.selectedAgeRange) {
      case 'Ages 3-5':
        return 24;
      case 'Ages 6-8':
        return 22;
      case 'Ages 9-12':
        return 20;
      default:
        return 22;
    }
  }
}