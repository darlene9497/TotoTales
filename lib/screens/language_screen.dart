import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toto_tales/services/language_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/animated_button.dart';

class LanguageScreen extends StatefulWidget {
  final String? selectedLanguage;
  final Function(String)? onLanguageSelected;

  const LanguageScreen({super.key, this.selectedLanguage, this.onLanguageSelected});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String? _selectedLanguage;
  final bool _isPremium = false; // This should come from user model
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _loadSavedLanguage();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Load saved language preference
  Future<void> _loadSavedLanguage() async {
    try {
      final savedLanguage = await LanguageService.getCurrentLanguage();
      if (_selectedLanguage == null) {
        setState(() {
          _selectedLanguage = savedLanguage;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved language: $e');
    }
  }

  void _selectLanguage(String language) async {
    if (_isLoading) return;
    
    setState(() {
      _selectedLanguage = language;
      _isLoading = true;
    });
    
    HapticFeedback.selectionClick();
    
    // Save the preference using the new service
    final success = await LanguageService.saveLanguagePreference(language);
    
    if (success) {
      // Show success message with enhanced styling
      _showLanguageChangedSnackBar(language);
      
      // Call the callback if provided
      if (widget.onLanguageSelected != null) {
        widget.onLanguageSelected!(language);
      }
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Failed to save language preference',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  void _showLanguageChangedSnackBar(String language) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.2 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Language Updated Successfully',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'All new stories will now be generated in $language',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withAlpha((0.9 * 255).toInt()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _getLanguageColor(language),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _isLanguageFree(String language) {
    return AppConstants.freeLanguages.contains(language);
  }

  Color _getLanguageColor(String language) {
    switch (language) {
      case 'English':
        return AppColors.englishBlue;
      case 'Swahili':
        return AppColors.swahiliGreen;
      case 'French':
        return AppColors.frenchPurple;
      case 'German':
        return const Color(0xFF1E3A8A);
      case 'Spanish':
        return const Color(0xFFDC2626);
      case 'Dutch':
        return const Color(0xFFEA580C);
      default:
        return AppColors.premiumGold;
    }
  }

  void _showPremiumDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.premiumGold.withAlpha((0.1 * 255).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.premiumGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Premium Language',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlock this language and get access to:',
                style: GoogleFonts.poppins(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              ...AppConstants.premiumFeatures.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: GoogleFonts.poppins(
                          color: AppColors.textMedium,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe Later',
                style: GoogleFonts.poppins(
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handlePremiumUpgrade();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.premiumGold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upgrade, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Upgrade Now',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _handlePremiumUpgrade() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Premium upgrade coming soon!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.premiumGold,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _continueWithLanguage() {
    if (_selectedLanguage == null) return;
    
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_selectedLanguage);
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
          'Choose Your Language',
          style: GoogleFonts.poppins(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.translate_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'What language would you like to read in?',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stories will be generated in your selected language',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Language Grid
            Expanded(
              child: AnimationLimiter(
                child: GridView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: AppConstants.languages.length,
                  itemBuilder: (context, index) {
                    final language = AppConstants.languages.keys.elementAt(index);
                    final flag = AppConstants.languages[language]!;
                    final isFree = _isLanguageFree(language);
                    final isSelected = _selectedLanguage == language;
                    final canSelect = isFree || _isPremium;
                    
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      duration: const Duration(milliseconds: 500),
                      columnCount: 2,
                      child: ScaleAnimation(
                        child: FadeInAnimation(
                          child: LanguageCard(
                            language: language,
                            flag: flag,
                            isSelected: isSelected,
                            isFree: isFree,
                            canSelect: canSelect,
                            color: _getLanguageColor(language),
                            isLoading: _isLoading && isSelected,
                            onTap: () => canSelect ? _selectLanguage(language) : _showPremiumDialog(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Premium Banner
            if (!_isPremium)
              Container(
                margin: const EdgeInsets.all(AppConstants.defaultPadding),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.premiumGold.withAlpha((0.15 * 255).toInt()),
                      AppColors.premiumGold.withAlpha((0.05 * 255).toInt()),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.premiumGold.withAlpha((0.3 * 255).toInt()),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.premiumGold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unlock All Languages',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Generate stories in German, Dutch, Spanish & more!',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedButton(
                      text: 'Upgrade',
                      onPressed: _showPremiumDialog,
                      backgroundColor: AppColors.premiumGold,
                      width: 80,
                      height: 36,
                    ),
                  ],
                ),
              ),
            
            // Continue Button
            if (_selectedLanguage != null)
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: AnimatedButton(
                  text: 'Continue with $_selectedLanguage',
                  onPressed: _continueWithLanguage,
                  backgroundColor: AppColors.primary,
                  width: double.infinity,
                  height: 56,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LanguageCard extends StatefulWidget {
  final String language;
  final String flag;
  final bool isSelected;
  final bool isFree;
  final bool canSelect;
  final bool isLoading;
  final Color color;
  final VoidCallback onTap;

  const LanguageCard({
    super.key,
    required this.language,
    required this.flag,
    required this.isSelected,
    required this.isFree,
    required this.canSelect,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<LanguageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isLoading) {
      _scaleController.reverse();
      widget.onTap();
    }
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.canSelect ? Colors.white : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                border: Border.all(
                  color: widget.isSelected ? widget.color : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isSelected 
                        ? widget.color.withAlpha((0.3 * 255).toInt()) 
                        : AppColors.shadowLight,
                    blurRadius: widget.isSelected ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Main content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.flag,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.language,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.canSelect ? AppColors.textDark : AppColors.textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.isFree)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'FREE',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Loading indicator
                  if (widget.isLoading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Premium lock icon
                  if (!widget.isFree && !widget.canSelect)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.premiumGold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.premiumGold.withAlpha((0.3 * 255).toInt()),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  
                  // Selection indicator
                  if (widget.isSelected && !widget.isLoading)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: widget.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withAlpha((0.3 * 255).toInt()),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}