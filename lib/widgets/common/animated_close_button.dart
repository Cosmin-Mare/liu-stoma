import 'package:flutter/material.dart';

/// Animated close button with scale animation on press
class AnimatedCloseButton extends StatefulWidget {
  final VoidCallback onTap;
  final double scale;
  final double iconSize;

  const AnimatedCloseButton({
    super.key,
    required this.onTap,
    required this.scale,
    this.iconSize = 36,
  });

  @override
  State<AnimatedCloseButton> createState() => _AnimatedCloseButtonState();
}

class _AnimatedCloseButtonState extends State<AnimatedCloseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25, // 90 degrees (0.25 * 2π)
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = (widget.iconSize + 16) * widget.scale;
    
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 3.14159 * 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    color: _isPressed
                        ? Colors.red[700]
                        : (_isHovered ? Colors.red[600] : Colors.red[500]),
                    borderRadius: BorderRadius.circular(buttonSize / 2),
                    border: Border.all(
                      color: Colors.black,
                      width: 3 * widget.scale,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(_isPressed ? 0.3 : (_isHovered ? 0.5 : 0.3)),
                        blurRadius: _isPressed ? 4 * widget.scale : (_isHovered ? 8 * widget.scale : 4 * widget.scale),
                        offset: Offset(0, _isPressed ? 2 * widget.scale : (_isHovered ? 4 * widget.scale : 2 * widget.scale)),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    size: widget.iconSize * widget.scale,
                    color: Colors.white,
                    weight: 900,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

