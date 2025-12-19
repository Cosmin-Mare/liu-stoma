import 'dart:ui';
import 'package:flutter/material.dart';

class PatientLongPressMenu extends StatefulWidget {
  final double scale;
  final double cardScale;
  final Offset position;
  final VoidCallback onAddProgramare;
  final VoidCallback onDelete;
  final VoidCallback onClose;
  final Offset? cardPosition;
  final Size? cardSize;

  const PatientLongPressMenu({
    super.key,
    required this.scale,
    required this.cardScale,
    required this.position,
    required this.onAddProgramare,
    required this.onDelete,
    required this.onClose,
    this.cardPosition,
    this.cardSize,
  });

  @override
  State<PatientLongPressMenu> createState() => _PatientLongPressMenuState();
}

class _PatientLongPressMenuState extends State<PatientLongPressMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _blurFadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _blurFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = widget.scale;
    final position = widget.position;
    final menuWidth = 500.0 * scale; // Increased width
    final menuItemHeight = 100.0 * scale; // Increased height
    final spacing = 10.0 * scale; // Spacing between menu and card
    final menuHeight = menuItemHeight * 2 + 20 * scale; // 2 items + padding

    // Position menu below the card (position is bottom center of card)
    double left = position.dx - menuWidth / 2;
    double top = position.dy + spacing; // Place below the card

    // Ensure menu stays within screen bounds horizontally
    if (left < 20 * scale) {
      left = 20 * scale;
    } else if (left + menuWidth > screenWidth - 20 * scale) {
      left = screenWidth - menuWidth - 20 * scale;
    }

    // If menu would go off screen at bottom, show it above the card instead
    if (top + menuHeight > screenHeight - 20 * scale) {
      // Position above the card (position.dy is bottom of card, so subtract menu height)
      top = position.dy - menuHeight - spacing;
      // Make sure it doesn't go off top either
      if (top < 20 * scale) {
        top = 20 * scale;
      }
    } else if (top < 20 * scale) {
      top = 20 * scale;
    }

    return Stack(
      children: [
        // Blurred overlay with card area excluded
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.translucent,
            child: FadeTransition(
              opacity: _blurFadeAnimation,
              child: ClipPath(
                clipper: widget.cardPosition != null && widget.cardSize != null
                    ? _CardExclusionClipper(
                        cardPosition: widget.cardPosition!,
                        cardSize: widget.cardSize!,
                        cardScale: widget.cardScale,
                      )
                    : null,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: Colors.black.withOpacity(0.15),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Menu positioned below card with scale animation
        Positioned(
          left: left,
          top: top,
          child: ScaleTransition(
            scale: _scaleAnimation,
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping menu
              behavior: HitTestBehavior.opaque,
              child: Container(
                    width: menuWidth,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24 * scale),
                      border: Border.all(
                        color: Colors.black,
                        width: 7 * scale,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 25 * scale,
                          offset: Offset(0, 15 * scale),
                          spreadRadius: 3 * scale,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10 * scale,
                          offset: Offset(0, 5 * scale),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMenuItem(
                          text: 'Adaugă programare',
                          color: Colors.black,
                          onTap: widget.onAddProgramare,
                          scale: scale,
                          height: menuItemHeight,
                        ),
                        Container(
                          height: 1,
                          color: Colors.black.withOpacity(0.2),
                          margin: EdgeInsets.symmetric(horizontal: 10 * scale),
                        ),
                        _buildMenuItem(
                          text: 'Șterge',
                          color: Colors.red,
                          onTap: widget.onDelete,
                          scale: scale,
                          height: menuItemHeight,
                        ),
                      ],
                    ),
                  ),
                ),
            ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String text,
    required Color color,
    required VoidCallback onTap,
    required double scale,
    required double height,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap();
        },
        borderRadius: BorderRadius.circular(24 * scale),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 12 * scale),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 50 * scale,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardExclusionClipper extends CustomClipper<Path> {
  final Offset cardPosition;
  final Size cardSize;
  final double cardScale;
  final double selectedScale = 1.05; // Card scales to 1.05 when selected

  _CardExclusionClipper({
    required this.cardPosition,
    required this.cardSize,
    required this.cardScale,
  });

  @override
  Path getClip(Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Scale the card size and position to account for the card's scale animation
    final scaledWidth = cardSize.width * selectedScale;
    final scaledHeight = cardSize.height * selectedScale;
    final centerX = cardPosition.dx + cardSize.width / 2;
    final centerY = cardPosition.dy + cardSize.height / 2;
    
    // Create a hole for the card area, centered on the original card position
    final cardRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: scaledWidth,
      height: scaledHeight,
    );
    
    // Use PathOperation.difference to cut out the card area
    final cardPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        cardRect,
        Radius.circular(24 * cardScale * selectedScale), // Scale border radius too
      ));
    
    return Path.combine(
      PathOperation.difference,
      path,
      cardPath,
    );
  }

  @override
  bool shouldReclip(_CardExclusionClipper oldClipper) {
    return oldClipper.cardPosition != cardPosition ||
        oldClipper.cardSize != cardSize;
  }
}

