// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AgeCategoryCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String ageRange;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback? onTap;
  final VoidCallback? onLockedTap;
  final bool isEnabled;

  const AgeCategoryCard({
    Key? key,
    required this.emoji,
    required this.title,
    required this.ageRange,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    this.onTap,
    this.onLockedTap,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : onLockedTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isEnabled
                ? [primaryColor, secondaryColor]
                : [
                    primaryColor.withOpacity(0.3),
                    secondaryColor.withOpacity(0.3),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      emoji,
                      style: TextStyle(
                        fontSize: 32,
                        color: isEnabled ? Colors.white : Colors.white.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isEnabled ? Colors.white : Colors.white.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ageRange,
                            style: TextStyle(
                              fontSize: 14,
                              color: isEnabled 
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: isEnabled 
                        ? Colors.white.withOpacity(0.9)
                        : Colors.white.withOpacity(0.4),
                    height: 1.4,
                  ),
                ),
              ],
            ),
            
            // Lock icon overlay for disabled cards
            if (!isEnabled)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                ),
              ),
              
            // Subtle overlay for disabled state
            if (!isEnabled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}