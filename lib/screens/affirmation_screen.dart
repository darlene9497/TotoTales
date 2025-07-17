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

class _AffirmationScreenState extends State<AffirmationScreen> with TickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _sparkleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _sparkleAnimation;
  
  Affirmation? _currentAffirmation;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDailyAffirmation();
    _configureTts();
  }

  void _configureTts() {
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.7); // Adjust for child-friendliness
    _flutterTts.setPitch(1.1);
  }

  void _setupAnimations() {
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
  }

  void _handleError(dynamic error) {
    String errorMessage;
    
    if (error.toString().contains('429')) {
      errorMessage = 'Too many requests. Please wait a moment and try again.';
    } else if (error.toString().contains('permission-denied')) {
      errorMessage = 'Authentication required. Please sign in again.';
    } else if (error.toString().contains('network')) {
      errorMessage = 'Network error. Please check your internet connection.';
    } else {
      errorMessage = 'Something went wrong. Please try again.';
    }
    
    setState(() {
      _error = errorMessage;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyAffirmation() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final affirmation = await AffirmationsData.getDailyAffirmation(widget.selectedAgeRange);
      
      if (mounted) {
        setState(() {
          _currentAffirmation = affirmation;
          _isLoading = false;
        });
        _startAnimations();
      }
    } catch (e) {
      if (mounted) {
        _handleError(e);
      }
    }
  }

  Future<void> _speakAffirmation() async {
    if (_currentAffirmation != null) {
      await _flutterTts.stop();
      await _flutterTts.speak(_currentAffirmation!.text);
    }
  }

  Future<void> _refreshAffirmation() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      HapticFeedback.mediumImpact();
      
      final affirmation = await AffirmationsData.getRandomAffirmation(widget.selectedAgeRange);
      
      if (mounted) {
        setState(() {
          _currentAffirmation = affirmation;
          _isLoading = false;
        });
        
        _fadeController.reset();
        _scaleController.reset();
        _sparkleController.reset();
        
        _startAnimations();
      }
    } catch (e) {
      if (mounted) {
        _handleError(e);
      }
    }
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scaleController.forward();
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
        centerTitle: true
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
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textDark,
            ),
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
                _buildSparkleAnimation(),
                
                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Affirmation Card
                        _buildAffirmationCard(affirmation),
                        
                        // Action Buttons
                        _buildActionButtons(),
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

  Widget _buildSparkleAnimation() {
    return AnimatedBuilder(
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
    );
  }

  Widget _buildAffirmationCard(Affirmation affirmation) {
    return ScaleTransition(
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
                    affirmation.text,
                    style: GoogleFonts.poppins(
                      fontSize: _getTextSize(),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getAgeColor().withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          affirmation.category.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getAgeColor(),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.smart_toy_outlined,
                        size: 16,
                        color: _getAgeColor(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        AnimatedButton(
          text: 'New Magical Words',
          onPressed: () {
            if (!_isLoading) {
              _refreshAffirmation();
            }
          },
          backgroundColor: _getAgeColor(),
          icon: Icons.refresh_rounded,
          height: 60,
        ),
        const SizedBox(height: 16),
        AnimatedButton(
          text: 'Say It Out Loud!',
          onPressed: () {
            if (_currentAffirmation != null) {
              HapticFeedback.mediumImpact();
              _speakAffirmation();
            }
          },
          backgroundColor: AppColors.warning,
          icon: Icons.volume_up_rounded,
          height: 60,
        ),
        const SizedBox(height: 16),
        AnimatedButton(
          text: 'Choose Category',
          onPressed: _showCategorySelector,
          backgroundColor: AppColors.primary,
          icon: Icons.category_outlined,
          height: 60,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Affirmation Category',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AffirmationsData.getAvailableCategories().map((category) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _loadAffirmationByCategory(category);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getAgeColor().withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getAgeColor().withAlpha((0.3 * 255).toInt()),
                      ),
                    ),
                    child: Text(
                      category.replaceAll('-', ' ').toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getAgeColor(),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAffirmationByCategory(String category) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final affirmation = await AffirmationsData.getAffirmationByCategory(
        widget.selectedAgeRange, 
        category
      );
      
      if (mounted) {
        setState(() {
          _currentAffirmation = affirmation;
          _isLoading = false;
        });
        
        _fadeController.reset();
        _scaleController.reset();
        _sparkleController.reset();
        
        _startAnimations();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to generate affirmation for $category. Please try again.';
          _isLoading = false;
        });
      }
    }
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