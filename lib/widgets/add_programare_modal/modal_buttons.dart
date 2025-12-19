import 'package:flutter/material.dart';

class ModalSaveButton extends StatelessWidget {
  final double scale;
  final VoidCallback onTap;
  final bool isHovering;
  final bool isPressed;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  const ModalSaveButton({
    super.key,
    required this.scale,
    required this.onTap,
    required this.isHovering,
    required this.isPressed,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHoverEnter(),
      onExit: (_) => onHoverExit(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => onTapDown(),
        onTapUp: (_) {
          onTapUp();
          onTap();
        },
        onTapCancel: onTapCancel,
        child: AnimatedScale(
          scale: isPressed ? 0.97 : (isHovering ? 1.02 : 1.0),
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: Colors.green[600],
              borderRadius: BorderRadius.circular(28 * scale),
              border: Border.all(
                color: Colors.black,
                width: 6 * scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isPressed ? 0.5 : (isHovering ? 0.6 : 0.4)),
                  blurRadius: isPressed ? 6 * scale : (isHovering ? 12 * scale : 8 * scale),
                  offset: Offset(0, isPressed ? 4 * scale : (isHovering ? 8 * scale : 6 * scale)),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 40 * scale,
              vertical: 20 * scale,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Salvează',
                style: TextStyle(
                  fontSize: 32 * scale,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ModalCancelButton extends StatelessWidget {
  final double scale;
  final VoidCallback onTap;
  final bool isHovering;
  final bool isPressed;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  const ModalCancelButton({
    super.key,
    required this.scale,
    required this.onTap,
    required this.isHovering,
    required this.isPressed,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHoverEnter(),
      onExit: (_) => onHoverExit(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => onTapDown(),
        onTapUp: (_) {
          onTapUp();
          onTap();
        },
        onTapCancel: onTapCancel,
        child: AnimatedScale(
          scale: isPressed ? 0.97 : (isHovering ? 1.02 : 1.0),
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(28 * scale),
              border: Border.all(
                color: Colors.black,
                width: 6 * scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isPressed ? 0.5 : (isHovering ? 0.6 : 0.4)),
                  blurRadius: isPressed ? 6 * scale : (isHovering ? 12 * scale : 8 * scale),
                  offset: Offset(0, isPressed ? 4 * scale : (isHovering ? 8 * scale : 6 * scale)),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 40 * scale,
              vertical: 20 * scale,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Anulează',
                style: TextStyle(
                  fontSize: 32 * scale,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ModalDeleteButton extends StatelessWidget {
  final double scale;
  final VoidCallback onTap;
  final bool isHovering;
  final bool isPressed;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  const ModalDeleteButton({
    super.key,
    required this.scale,
    required this.onTap,
    required this.isHovering,
    required this.isPressed,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHoverEnter(),
      onExit: (_) => onHoverExit(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => onTapDown(),
        onTapUp: (_) {
          onTapUp();
          onTap();
        },
        onTapCancel: onTapCancel,
        child: AnimatedScale(
          scale: isPressed ? 0.97 : (isHovering ? 1.02 : 1.0),
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: Colors.red[600],
              borderRadius: BorderRadius.circular(28 * scale),
              border: Border.all(
                color: Colors.black,
                width: 6 * scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isPressed ? 0.5 : (isHovering ? 0.6 : 0.4)),
                  blurRadius: isPressed ? 6 * scale : (isHovering ? 12 * scale : 8 * scale),
                  offset: Offset(0, isPressed ? 4 * scale : (isHovering ? 8 * scale : 6 * scale)),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 40 * scale,
              vertical: 20 * scale,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Șterge',
                style: TextStyle(
                  fontSize: 32 * scale,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

