import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AgeCategoryCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String ageRange;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback onTap;

  const AgeCategoryCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.ageRange,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onTap,
  });

  @override
  _AgeCategoryCardState createState() => _AgeCategoryCardState();
}

class _AgeCategoryCardState extends State<AgeCategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 8.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.primaryColor,
                    widget.secondaryColor,
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(AppConstants.cardBorderRadius),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withAlpha((0.3 * 255).toInt()),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha((0.1 * 255).toInt()),
                      ),
                    ),
                  ),
                  // Content
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emoji
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.2 * 255).toInt()),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            widget.emoji,
                            style: TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),

                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              widget.ageRange,
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    Colors.white.withAlpha((0.9 * 255).toInt()),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              widget.description,
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    Colors.white.withAlpha((0.8 * 255).toInt()),
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Arrow icon
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
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
