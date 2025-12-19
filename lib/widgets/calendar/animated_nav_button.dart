import 'package:flutter/material.dart';

class AnimatedNavButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final EdgeInsetsGeometry? padding;
  final bool isMobile;

  const AnimatedNavButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.scale,
    this.padding,
    this.isMobile = false,
  });

  @override
  State<AnimatedNavButton> createState() => _AnimatedNavButtonState();
}

class _AnimatedNavButtonState extends State<AnimatedNavButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const baseColor = Colors.white;
    final hoverColor = Colors.grey[100]!;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : (_isHovered ? 1.03 : 1.0),
          duration: Duration(milliseconds: _isPressed ? 80 : 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            padding: widget.padding ?? EdgeInsets.all(widget.isMobile ? 24 * widget.scale : 12 * widget.scale),
            decoration: BoxDecoration(
              color: _isPressed ? hoverColor : (_isHovered ? hoverColor : baseColor),
              borderRadius: BorderRadius.circular(20 * widget.scale),
              border: Border.all(
                color: Colors.black,
                width: 4 * widget.scale,
              ),
              boxShadow: _isHovered && !_isPressed
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8 * widget.scale,
                        offset: Offset(0, 4 * widget.scale),
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

