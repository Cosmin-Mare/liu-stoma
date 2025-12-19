import 'package:flutter/material.dart';

class ActionButton extends StatefulWidget {
  final double scale;
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double? iconSize;
  final double? fontSize;

  const ActionButton({
    super.key,
    required this.scale,
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
    this.iconSize,
    this.fontSize,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!_hovering) {
          setState(() => _hovering = true);
        }
      },
      onExit: (_) {
        if (_hovering) {
          setState(() => _hovering = false);
        }
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) {
          if (!_pressed) {
            setState(() => _pressed = true);
          }
        },
        onTapUp: (_) {
          if (_pressed) {
            setState(() => _pressed = false);
          }
          widget.onTap();
        },
        onTapCancel: () {
          if (_pressed) {
            setState(() => _pressed = false);
          }
        },
        child: AnimatedScale(
          scale: _pressed ? 0.97 : (_hovering ? 1.02 : 1.0),
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(20 * widget.scale),
              border: Border.all(
                color: Colors.black,
                width: 6 * widget.scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_pressed ? 0.5 : (_hovering ? 0.6 : 0.4)),
                  blurRadius: _pressed ? 5 * widget.scale : (_hovering ? 10 * widget.scale : 7 * widget.scale),
                  offset: Offset(0, _pressed ? 3 * widget.scale : (_hovering ? 6 * widget.scale : 4 * widget.scale)),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 24 * widget.scale,
              vertical: 18 * widget.scale,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: widget.iconSize ?? 32 * widget.scale,
                  color: Colors.white,
                  weight: 900,
                ),
                SizedBox(width: 10 * widget.scale),
                Flexible(
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: widget.fontSize ?? 28 * widget.scale,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

