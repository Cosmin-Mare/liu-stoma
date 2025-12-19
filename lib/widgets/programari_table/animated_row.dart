import 'package:flutter/material.dart';

/// Animated row widget used in desktop programari table.
/// Shows hover and press animations.
class AnimatedRow extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double scale;
  final bool showVerticalBar;
  final bool hasNotification;

  const AnimatedRow({
    super.key,
    required this.onTap,
    required this.child,
    required this.scale,
    required this.showVerticalBar,
    required this.hasNotification,
  });

  @override
  State<AnimatedRow> createState() => _AnimatedRowState();
}

class _AnimatedRowState extends State<AnimatedRow> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
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
          scale: _isPressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              color: (_isPressed || _isHovered) 
                  ? Colors.grey[100] 
                  : Colors.transparent,
              border: widget.showVerticalBar ? Border(
                left: BorderSide(
                  color: widget.hasNotification ? Colors.green[600]! : Colors.red[600]!,
                  width: 8 * widget.scale,
                ),
              ) : null,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 24 * widget.scale,
              vertical: 18 * widget.scale,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

