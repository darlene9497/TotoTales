import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/animated_button.dart';
import '../models/user.dart';
import '../screens/language_screen.dart';
import '../screens/login_screen.dart'; // Add this import

class ProfileScreen extends StatefulWidget {
  final User? user;

  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Sample user data - replace with actual user data
  late User currentUser;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with sample data or provided user
    currentUser = widget.user ?? User(
      id: '1',
      name: 'Little Explorer',
      selectedAgeRange: '3-5',
      preferredLanguage: 'English',
      isPremium: false,
      completedStories: ['1', '2', '3'],
      lastActive: DateTime.now(),
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _getAgeRangeDisplayName(String ageRange) {
    switch (ageRange) {
      case '3-5':
        return AppConstants.littleExplorers;
      case '6-8':
        return AppConstants.brightLearners;
      case '9-12':
        return AppConstants.juniorDreamers;
      default:
        return 'Unknown';
    }
  }

  Color _getAgeRangeColor(String ageRange) {
    switch (ageRange) {
      case '3-5':
        return AppColors.littleExplorers;
      case '6-8':
        return AppColors.brightLearners;
      case '9-12':
        return AppColors.juniorDreamers;
      default:
        return AppColors.primary;
    }
  }

  void _showAgeRangeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Change Age Range',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAgeRangeOption('3-5', AppConstants.littleExplorers, AppColors.littleExplorers),
              const SizedBox(height: 8),
              _buildAgeRangeOption('6-8', AppConstants.brightLearners, AppColors.brightLearners),
              const SizedBox(height: 8),
              _buildAgeRangeOption('9-12', AppConstants.juniorDreamers, AppColors.juniorDreamers),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.textMedium,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAgeRangeOption(String ageRange, String name, Color color) {
    final isSelected = currentUser.selectedAgeRange == ageRange;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          currentUser = User(
            id: currentUser.id,
            name: currentUser.name,
            selectedAgeRange: ageRange,
            preferredLanguage: currentUser.preferredLanguage,
            isPremium: currentUser.isPremium,
            completedStories: currentUser.completedStories,
            lastActive: currentUser.lastActive,
          );
        });
        Navigator.of(context).pop();
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha((0.1 * 255).toInt()) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Ages $ageRange',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LanguageScreen(
          selectedLanguage: currentUser.preferredLanguage,
          onLanguageSelected: (language) {
            setState(() {
              currentUser = User(
                id: currentUser.id,
                name: currentUser.name,
                selectedAgeRange: currentUser.selectedAgeRange,
                preferredLanguage: language,
                isPremium: currentUser.isPremium,
                completedStories: currentUser.completedStories,
                lastActive: currentUser.lastActive,
              );
            });
          },
        ),
      ),
    );
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.stars_rounded,
                color: AppColors.premiumGold,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'TotoTales Premium',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlock the full TotoTales experience:',
                style: GoogleFonts.poppins(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...AppConstants.premiumFeatures.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: GoogleFonts.poppins(
                          color: AppColors.textMedium,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.premiumGold.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.premiumGold.withAlpha((0.3 * 255).toInt()),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_offer_rounded,
                      color: AppColors.premiumGold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Special Offer: \$4.99/month',
                      style: GoogleFonts.poppins(
                        color: AppColors.premiumGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe Later',
                style: GoogleFonts.poppins(
                  color: AppColors.textMedium,
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
              ),
              child: Text(
                'Upgrade Now',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handlePremiumUpgrade() {
    // TODO: Implement premium upgrade logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Premium upgrade coming soon!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppColors.premiumGold,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLogoutBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              // Logout icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 40,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Sign Out',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'Are you sure you want to sign out? You\'ll need to sign in again to access your stories.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _handleLogout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Sign Out',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }

  void _handleLogout() {
    // TODO: Implement logout logic (clear user data, tokens, etc.)
    
    // Navigate to login screen and remove all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundYellow,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            color: AppColors.textDark,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: AnimationLimiter(
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _getAgeRangeColor(currentUser.selectedAgeRange).withAlpha((0.1 * 255).toInt()),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getAgeRangeColor(currentUser.selectedAgeRange),
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              currentUser.name.isNotEmpty ? currentUser.name.substring(0, 1).toUpperCase() : '?',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _getAgeRangeColor(currentUser.selectedAgeRange),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentUser.name,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getAgeRangeColor(currentUser.selectedAgeRange).withAlpha((0.1 * 255).toInt()),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getAgeRangeDisplayName(currentUser.selectedAgeRange),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getAgeRangeColor(currentUser.selectedAgeRange),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Stats Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reading Progress',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.menu_book_rounded,
                                label: 'Stories Read',
                                value: '${currentUser.completedStories.length}',
                                color: AppColors.brightLearners,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.star_rounded,
                                label: 'Level',
                                value: _getReadingLevel(),
                                color: AppColors.premiumGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.calendar_today_rounded,
                                label: 'Reading Days',
                                value: '${_getReadingDays()}',
                                color: AppColors.littleExplorers,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.language_rounded,
                                label: 'Language',
                                value: currentUser.preferredLanguage,
                                color: AppColors.juniorDreamers,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Settings Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSettingsItem(
                          icon: Icons.cake_rounded,
                          title: 'Change Age Range',
                          subtitle: 'Currently: ${_getAgeRangeDisplayName(currentUser.selectedAgeRange)}',
                          onTap: _showAgeRangeDialog,
                        ),
                        const Divider(height: 1),
                        _buildSettingsItem(
                          icon: Icons.language_rounded,
                          title: 'Language',
                          subtitle: 'Currently: ${currentUser.preferredLanguage}',
                          onTap: _showLanguageSelector,
                        ),
                        const Divider(height: 1),
                        _buildSettingsItem(
                          icon: Icons.stars_rounded,
                          title: 'Premium Features',
                          subtitle: currentUser.isPremium ? 'Premium Active' : 'Upgrade for more content',
                          onTap: _showPremiumDialog,
                          trailing: currentUser.isPremium 
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.premiumGold.withAlpha((0.1 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'PREMIUM',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.premiumGold,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: AppColors.textMedium,
                                ),
                        ),
                        const Divider(height: 1),
                        _buildSettingsItem(
                          icon: Icons.logout_rounded,
                          title: 'Sign Out',
                          subtitle: 'Sign out of your account',
                          onTap: _showLogoutBottomSheet,
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Premium Upgrade Button (if not premium)
                  if (!currentUser.isPremium)
                    AnimatedButton(
                      text: 'Upgrade to Premium',
                      onPressed: _showPremiumDialog,
                      backgroundColor: AppColors.premiumGold,
                      textColor: Colors.white,
                      icon: Icons.stars_rounded,
                    ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha((0.3 * 255).toInt()),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ?? Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getReadingLevel() {
    final storiesRead = currentUser.completedStories.length;
    if (storiesRead < 5) return 'Beginner';
    if (storiesRead < 15) return 'Explorer';
    if (storiesRead < 30) return 'Adventurer';
    return 'Master';
  }

  int _getReadingDays() {
    // Calculate days since first activity (mock calculation)
    final daysSinceJoined = DateTime.now().difference(currentUser.lastActive).inDays;
    return daysSinceJoined > 0 ? daysSinceJoined : 1;
  }
}