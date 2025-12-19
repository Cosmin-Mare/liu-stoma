import 'package:flutter/material.dart';

/// Animated card widget used in mobile programari table.
/// Shows press animation and elevation changes.
class AnimatedCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double scale;
  final bool hasNotification;

  const AnimatedCard({
    super.key,
    required this.onTap,
    required this.child,
    required this.scale,
    required this.hasNotification,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: _isPressed ? 100 : 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16 * widget.scale),
          border: Border.all(
            color: Colors.black,
            width: 3 * widget.scale,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isPressed ? 0.05 : 0.1),
              blurRadius: (_isPressed ? 4 : 8) * widget.scale,
              offset: Offset(0, (_isPressed ? 2 : 4) * widget.scale),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

