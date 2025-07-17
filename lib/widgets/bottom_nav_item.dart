// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../utils/colors.dart';

class BottomNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;

  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.selectedColor = AppColors.primary,
    this.unselectedColor = AppColors.textLight,
  });

  @override
  State<BottomNavItem> createState() => _BottomNavItemState();
}

class _BottomNavItemState extends State<BottomNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BottomNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  width: widget.isSelected ? 16 : 0,
                  decoration: BoxDecoration(
                    color: widget.selectedColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 6),
                
                // Icon with background circle for selected state
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? widget.selectedColor.withOpacity(0.15)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Transform.scale(
                    scale: widget.isSelected ? _scaleAnimation.value : 1.0,
                    child: Icon(
                      widget.icon,
                      color: widget.isSelected
                          ? widget.selectedColor
                          : widget.unselectedColor,
                      size: 22,
                    ),
                  ),
                ),
                
                const SizedBox(height: 2),
                
                // Label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: widget.isSelected
                        ? widget.selectedColor
                        : widget.unselectedColor,
                    fontSize: 10,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  child: Text(widget.label),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              BottomNavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
                selectedColor: AppColors.primary,
              ),
              BottomNavItem(
                icon: Icons.menu_book_outlined,
                label: 'Stories',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
                selectedColor: AppColors.brightLearners,
              ),
              BottomNavItem(
                icon: Icons.auto_awesome_outlined,
                label: 'Magic',
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
                selectedColor: AppColors.warning,
              ),
              BottomNavItem(
                icon: Icons.translate_outlined,
                label: 'Languages',
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
                selectedColor: AppColors.juniorDreamers,
              ),
              BottomNavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                isSelected: currentIndex == 4,
                onTap: () => onTap(4),
                selectedColor: AppColors.textDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}