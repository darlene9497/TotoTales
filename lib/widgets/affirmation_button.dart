import 'package:flutter/material.dart';

class AffirmationButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Duration duration;
  final double scaleFactor;
  
  const AffirmationButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.duration = const Duration(milliseconds: 150),
    this.scaleFactor = 0.95,
  }) : super(key: key);
  
  @override
  State<AffirmationButton> createState() => _AffirmationButtonState();
}

class _AffirmationButtonState extends State<AffirmationButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
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
  
  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }
  
  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }
  
  void _onTapCancel() {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}