import 'package:flutter/material.dart';

/// Animated back button with scale animation on press
class AnimatedBackButton extends StatefulWidget {
  final VoidCallback onTap;
  final double scale;
  final bool isMobile;
  final String label;

  const AnimatedBackButton({
    super.key,
    required this.onTap,
    required this.scale,
    this.isMobile = false,
    this.label = 'Înapoi',
  });

  @override
  State<AnimatedBackButton> createState() => _AnimatedBackButtonState();
}

class _AnimatedBackButtonState extends State<AnimatedBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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
    final iconSize = widget.isMobile ? 48 * widget.scale : 28 * widget.scale;
    final fontSize = widget.isMobile ? 48 * widget.scale : 28 * widget.scale;
    final horizontalPadding = widget.isMobile ? 36 * widget.scale : 20 * widget.scale;
    final verticalPadding = widget.isMobile ? 24 * widget.scale : 12 * widget.scale;
    final borderRadius = widget.isMobile ? 20 * widget.scale : 20 * widget.scale;
    final borderWidth = widget.isMobile ? 4 * widget.scale : 4 * widget.scale;

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
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                decoration: BoxDecoration(
                  color: _isPressed
                      ? Colors.grey[300]
                      : (_isHovered ? Colors.grey[100] : Colors.white),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.black,
                    width: borderWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isPressed ? 0.2 : (_isHovered ? 0.5 : 0.4)),
                      blurRadius: _isPressed ? 4 * widget.scale : (_isHovered ? 10 * widget.scale : 8 * widget.scale),
                      offset: Offset(0, _isPressed ? 3 * widget.scale : (_isHovered ? 7 * widget.scale : 6 * widget.scale)),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      size: iconSize,
                      color: Colors.black,
                    ),
                    SizedBox(width: 12 * widget.scale),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

