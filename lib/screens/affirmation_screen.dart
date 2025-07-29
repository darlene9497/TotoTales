// ignore_for_file: avoid_print, deprecated_member_use
import 'package:flutter_tts/flutter_tts.dart';
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
  final FlutterTts _flutterTts = FlutterTts();
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _sparkleController;
  late AnimationController _quotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _quotationAnimation;

  Affirmation? _currentAffirmation;
  bool _isLoading = false; // Changed to false for instant backup loading
  String? _error;
  bool _isUsingBackup = false;

  // Backup affirmations for instant loading
  final Map<String, Map<String, List<String>>> _backupAffirmations = {
    'Ages 3-5': {
      'self-confidence': [
        "I am brave and strong like a superhero!",
        "I can do amazing things every day!",
        "I am special and loved by everyone!",
        "I am learning and growing every day!",
        "I believe in myself and my dreams!",
      ],
      'courage': [
        "I am not afraid to try new things!",
        "I am brave like a lion!",
        "I can face any challenge with a smile!",
        "I am strong and fearless!",
        "I turn my fears into fun adventures!",
      ],
      'self-love': [
        "I love myself just the way I am!",
        "I am wonderful and unique!",
        "I deserve all the love in the world!",
        "I am precious and important!",
        "I celebrate being me every day!",
      ],
      'friendship': [
        "I am a good friend who cares!",
        "I share and play nicely with others!",
        "I make friends easily!",
        "I am kind to everyone I meet!",
        "Friends love being around me!",
      ],
      'learning': [
        "Learning is fun and exciting!",
        "I love discovering new things!",
        "My brain is growing stronger!",
        "I ask great questions!",
        "Every mistake helps me learn!",
      ],
    },
    'Ages 6-8': {
      'self-confidence': [
        "I believe in my abilities and talents!",
        "I can accomplish anything I set my mind to!",
        "I am confident in who I am becoming!",
        "I trust myself to make good choices!",
        "I am proud of my unique qualities!",
      ],
      'courage': [
        "I face challenges with determination!",
        "I am brave enough to stand up for what's right!",
        "I turn obstacles into opportunities!",
        "I have the courage to be myself!",
        "I am not afraid to make mistakes and learn!",
      ],
      'self-love': [
        "I accept and love myself completely!",
        "I treat myself with kindness and respect!",
        "I am worthy of love and happiness!",
        "I celebrate my achievements, big and small!",
        "I am enough, just as I am!",
      ],
      'friendship': [
        "I am a loyal and trustworthy friend!",
        "I attract positive friendships into my life!",
        "I communicate well with my friends!",
        "I support my friends in their dreams!",
        "I create lasting, meaningful friendships!",
      ],
      'learning': [
        "I am curious and love to explore new ideas!",
        "Every day brings new learning opportunities!",
        "I am smart and capable of understanding anything!",
        "I enjoy challenging myself academically!",
        "Learning makes me feel accomplished and proud!",
      ],
    },
    'Ages 9-12': {
      'self-confidence': [
        "I have the power to create positive change in my life!",
        "I am developing into an amazing person!",
        "I trust my instincts and inner wisdom!",
        "I am capable of handling whatever comes my way!",
        "I stand tall and speak with confidence!",
      ],
      'courage': [
        "I have the courage to pursue my dreams!",
        "I am resilient and bounce back from setbacks!",
        "I face my fears and grow stronger!",
        "I am brave enough to be different!",
        "I take on challenges as opportunities to grow!",
      ],
      'self-love': [
        "I honor my feelings and treat myself with compassion!",
        "I am learning to love and accept all parts of myself!",
        "I deserve respect from myself and others!",
        "I celebrate my progress and personal growth!",
        "I am worthy of pursuing my dreams and goals!",
      ],
      'friendship': [
        "I choose friends who support and encourage me!",
        "I am a good listener and caring friend!",
        "I build relationships based on mutual respect!",
        "I stand by my friends through good times and challenges!",
        "I attract friendships that help me grow as a person!",
      ],
      'learning': [
        "I embrace challenges as chances to expand my knowledge!",
        "I am developing critical thinking skills!",
        "I take responsibility for my learning and growth!",
        "I see education as a pathway to my future goals!",
        "I am building the foundation for my dreams through learning!",
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDailyAffirmation();
    _configureTts();
  }

  void _configureTts() {
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.7);
    _flutterTts.setPitch(1.3);
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _quotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
    _quotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _quotationController, curve: Curves.bounceOut),
    );
  }

  Affirmation _getBackupAffirmation([String? category]) {
    final ageRangeData = _backupAffirmations[widget.selectedAgeRange]!;
    final availableCategories = ageRangeData.keys.toList();

    final selectedCategory =
        category ??
        availableCategories[DateTime.now().millisecond %
            availableCategories.length];
    final categoryAffirmations = ageRangeData[selectedCategory]!;
    final selectedText =
        categoryAffirmations[DateTime.now().second %
            categoryAffirmations.length];

    return Affirmation(
      id: 'backup_${DateTime.now().millisecondsSinceEpoch}',
      text: selectedText,
      category: selectedCategory,
      ageRange: widget.selectedAgeRange,
      backgroundImageUrl:
          'assets/images/affirmation_bg_${widget.selectedAgeRange.replaceAll(' ', '_').toLowerCase()}.jpg',
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _sparkleController.dispose();
    _quotationController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyAffirmation() async {
    // Show backup immediately
    setState(() {
      _currentAffirmation = _getBackupAffirmation();
      _isUsingBackup = true;
      _isLoading = false;
    });
    _startAnimations();

    // Try to get AI affirmation in background
    try {
      final affirmation = await AffirmationsData.getDailyAffirmation(
        widget.selectedAgeRange,
      );

      if (mounted) {
        setState(() {
          _currentAffirmation = affirmation;
          _isUsingBackup = false;
        });
      }
    } catch (e) {
      // Keep using backup if AI fails
      print('AI affirmation failed, using backup: $e');
    }
  }

  Future<void> _speakAffirmation() async {
    if (_currentAffirmation != null) {
      await _flutterTts.stop();
      await _flutterTts.speak(_currentAffirmation!.text);
    }
  }

  Future<void> _refreshAffirmation() async {
    // Show backup immediately
    HapticFeedback.mediumImpact();
    setState(() {
      _currentAffirmation = _getBackupAffirmation();
      _isLoading = false;
      _isUsingBackup = true;
    });

    _fadeController.reset();
    _scaleController.reset();
    _sparkleController.reset();
    _quotationController.reset();

    _startAnimations();

    // Try to get AI affirmation in background
    try {
      final affirmation = await AffirmationsData.getRandomAffirmation(
        widget.selectedAgeRange,
      );

      if (mounted) {
        setState(() {
          _currentAffirmation = affirmation;
          _isUsingBackup = false;
        });
      }
    } catch (e) {
      // Keep using backup if AI fails
      print('AI affirmation failed, using backup: $e');
    }
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _quotationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _sparkleController.repeat(reverse: true);
    });
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
      backgroundColor: _getAgeColor().withOpacity(0.05),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(90),
        child: Container(
          padding: const EdgeInsets.only(
            top: 24,
            left: 16,
            right: 16,
            bottom: 10,
          ),
          decoration: BoxDecoration(color: Colors.transparent),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getAgeColor().withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: _getAgeColor(),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Image.asset(
              //   'assets/images/affirmation_kid.png',
              //   height: 48,
              //   width: 48,
              // ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Magical Affirmations",
                  style: GoogleFonts.comicNeue(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _getAgeColor(),
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: _getAgeColor().withOpacity(0.3),
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.auto_awesome, color: _getAgeColor(), size: 28),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _currentAffirmation == null) {
      return _buildLoadingState();
    }

    if (_error != null && _currentAffirmation == null) {
      return _buildErrorState();
    }

    return _buildAffirmationContent();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_getAgeColor()),
          ),
          const SizedBox(height: 20),
          Text(
            'Generating your magical words...',
            style: GoogleFonts.poppins(fontSize: 16, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textDark.withAlpha((0.5 * 255).toInt()),
            ),
            const SizedBox(height: 20),
            Text(
              _error!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AnimatedButton(
              text: 'Try Again',
              onPressed: _loadDailyAffirmation,
              backgroundColor: _getAgeColor(),
              icon: Icons.refresh_rounded,
              height: 50,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAffirmationContent() {
    final affirmation = _currentAffirmation!;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(affirmation.backgroundImageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getAgeColor().withOpacity(0.2),
                Colors.white.withOpacity(0.1),
                _getAgeColor().withOpacity(0.15),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Enhanced Sparkle Animation
                _buildEnhancedSparkleAnimation(),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Enhanced Quote Card
                        _buildEnhancedQuoteCard(affirmation),

                        const SizedBox(height: 40),

                        // Enhanced Action Buttons
                        _buildEnhancedActionButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSparkleAnimation() {
    return AnimatedBuilder(
      animation: _sparkleAnimation,
      builder: (context, child) {
        return SizedBox(
          height: 80,
          width: double.infinity,
          child: Stack(
            children: List.generate(8, (index) {
              final double leftPosition =
                  (MediaQuery.of(context).size.width / 8) * index;
              final double topOffset =
                  (index % 2 == 0 ? 10 : 30) + (_sparkleAnimation.value * 15);

              return Positioned(
                top: topOffset,
                left:
                    leftPosition +
                    (_sparkleAnimation.value * (index % 2 == 0 ? 10 : -10)),
                child: Transform.rotate(
                  angle:
                      _sparkleAnimation.value *
                      6.28 *
                      (index % 2 == 0 ? 1 : -1),
                  child: Opacity(
                    opacity: 0.3 + (_sparkleAnimation.value * 0.7),
                    child: Icon(
                      index % 3 == 0
                          ? Icons.auto_awesome
                          : index % 3 == 1
                          ? Icons.star
                          : Icons.diamond,
                      color: _getAgeColor(),
                      size: 16 + (_sparkleAnimation.value * 8),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedQuoteCard(Affirmation affirmation) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: _getAgeColor().withOpacity(0.2),
              blurRadius: 25,
              offset: const Offset(0, 15),
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getAgeColor().withOpacity(0.03),
                      Colors.transparent,
                      _getAgeColor().withOpacity(0.01),
                    ],
                  ),
                ),
              ),
            ),

            // Quote Content
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  // Animated Opening Quote
                  AnimatedBuilder(
                    animation: _quotationAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _quotationAnimation.value,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getAgeColor(),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.format_quote,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Main Affirmation Text
                  Text(
                    affirmation.text,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: _getTextSize(),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 25),

                  // Category and Source Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getAgeColor(),
                              _getAgeColor().withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: _getAgeColor().withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(affirmation.category),
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              affirmation.category
                                  .replaceAll('-', ' ')
                                  .toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Animated Closing Quote
                  AnimatedBuilder(
                    animation: _quotationAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _quotationAnimation.value,
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _getAgeColor().withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Transform.rotate(
                              angle: 3.14159,
                              child: Icon(
                                Icons.format_quote,
                                color: _getAgeColor(),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'self-confidence':
        return Icons.emoji_emotions;
      case 'courage':
        return Icons.shield;
      case 'self-love':
        return Icons.favorite;
      case 'friendship':
        return Icons.people;
      case 'learning':
        return Icons.school;
      default:
        return Icons.auto_awesome;
    }
  }

  Widget _buildEnhancedActionButtons() {
    return Column(
      children: [
        // Primary Action Button
        Container(
          width: double.infinity,
          height: 65,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_getAgeColor(), _getAgeColor().withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: _getAgeColor().withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(35),
              onTap: () {
                if (!_isLoading) {
                  _refreshAffirmation();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'New Magical Words',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Secondary Action Buttons Row
        Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                'Listen',
                Icons.volume_up_rounded,
                AppColors.warning,
                () {
                  if (_currentAffirmation != null) {
                    HapticFeedback.mediumImpact();
                    _speakAffirmation();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryButton(
                'Categories',
                Icons.category_outlined,
                AppColors.primary,
                _showEnhancedCategorySelector,
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSecondaryButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEnhancedCategorySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              '✨ Choose Your Affirmation Category ✨',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getAgeColor(),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 25),

            // Category Grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 2.2,
              children: _backupAffirmations[widget.selectedAgeRange]!.keys.map((
                category,
              ) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _loadAffirmationByCategory(category);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getAgeColor().withOpacity(0.1),
                          _getAgeColor().withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _getAgeColor().withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          color: _getAgeColor(),
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.replaceAll('-', ' ').toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getAgeColor(),
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAffirmationByCategory(String category) async {
    // Show backup immediately
    HapticFeedback.mediumImpact();
    setState(() {
      _currentAffirmation = _getBackupAffirmation(category);
      _isLoading = false;
      _isUsingBackup = true;
    });

    _fadeController.reset();
    _scaleController.reset();
    _sparkleController.reset();
    _quotationController.reset();

    _startAnimations();

    // Try to get AI affirmation in background
    try {
      final affirmation = await AffirmationsData.getAffirmationByCategory(
        widget.selectedAgeRange,
        category,
      );

      if (mounted) {
        setState(() {
          _currentAffirmation = affirmation;
          _isUsingBackup = false;
        });
      }
    } catch (e) {
      // Keep using backup if AI fails
      print('AI affirmation failed for category $category, using backup: $e');
    }
  }

  double _getTextSize() {
    switch (widget.selectedAgeRange) {
      case 'Ages 3-5':
        return 26;
      case 'Ages 6-8':
        return 24;
      case 'Ages 9-12':
        return 22;
      default:
        return 24;
    }
  }
}
