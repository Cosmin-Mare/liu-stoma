import 'package:flutter/material.dart';

class PacientiButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final Color? baseColor;
  final Color? hoverColor;
  final Color? pressedColor;

  const PacientiButton({
    super.key,
    required this.label,
    this.onPressed,
    this.fontSize = 120,
    this.horizontalPadding = 96,
    this.verticalPadding = 36,
    this.baseColor,
    this.hoverColor,
    this.pressedColor,
  });

  @override
  State<PacientiButton> createState() => _PacientiButtonState();
}

class _PacientiButtonState extends State<PacientiButton> {
  bool _hovering = false;
  bool _pressed = false;

  void _setHover(bool value) {
    if (_hovering == value) return;
    setState(() => _hovering = value);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final defaultBaseColor = const Color(0xffB2CEFF);
    final defaultHoverColor = const Color(0xffCFE1FF);
    final defaultPressedColor = const Color(0xff8FAFEE);
    
    final baseColor = widget.baseColor ?? defaultBaseColor;
    final hoverColor = widget.hoverColor ?? defaultHoverColor;
    final pressedColor = widget.pressedColor ?? defaultPressedColor;

    final background = _pressed
        ? pressedColor
        : _hovering
            ? hoverColor
            : baseColor;

    final shadowOffset = _pressed
        ? const Offset(4, 4)
        : _hovering
            ? const Offset(8, 8)
            : const Offset(10, 10);

    final borderColor =
        _pressed ? Colors.black : (_hovering ? Colors.black87 : Colors.black);

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) {
          _setPressed(false);
          widget.onPressed?.call();
        },
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : (_hovering ? 1.02 : 1.0),
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.horizontalPadding,
              vertical: widget.verticalPadding,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: borderColor,
                width: 8,
              ),
              boxShadow: [
                const BoxShadow(
                  color: Color(0xaa000000),
                  offset: Offset(0, 0), // will be overridden below
                  blurRadius: 0,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xaa000000),
                  offset: shadowOffset,
                  blurRadius: 0, // hard, crisp shadow
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


