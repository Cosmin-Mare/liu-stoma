import 'package:flutter/material.dart';
import 'package:liu_stoma/utils/design_constants.dart';

/// Reusable button with hover and press state animations
class InteractiveButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final double scale;
  final Color color;
  final bool fullWidth;
  final IconData? icon;

  const InteractiveButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.scale,
    required this.color,
    this.fullWidth = false,
    this.icon,
  });

  @override
  State<InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<InteractiveButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!_isHovering) {
          setState(() => _isHovering = true);
        }
      },
      onExit: (_) {
        if (_isHovering) {
          setState(() => _isHovering = false);
        }
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) {
          if (!_isPressed) {
            setState(() => _isPressed = true);
          }
        },
        onTapUp: (_) {
          if (_isPressed) {
            setState(() => _isPressed = false);
          }
        },
        onTap: () {
          if (_isPressed) {
            setState(() => _isPressed = false);
          }
          widget.onTap();
        },
        onTapCancel: () {
          if (_isPressed) {
            setState(() => _isPressed = false);
          }
        },
        child: AnimatedScale(
          scale: DesignConstants.buttonScale(
            isPressed: _isPressed,
            isHovering: _isHovering,
          ),
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: widget.fullWidth ? double.infinity : null,
            decoration: DesignConstants.buttonDecoration(
              scale: widget.scale,
              color: widget.color,
              isPressed: _isPressed,
              isHovering: _isHovering,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: DesignConstants.buttonPaddingHorizontal(widget.scale),
              vertical: DesignConstants.buttonPaddingVertical(widget.scale),
            ),
            child: Row(
              mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 32 * widget.scale,
                    color: Colors.white,
                    weight: 900,
                  ),
                  SizedBox(width: 16 * widget.scale),
                ],
                Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32 * widget.scale,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

