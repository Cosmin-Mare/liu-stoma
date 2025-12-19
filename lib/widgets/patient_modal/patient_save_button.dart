import 'package:flutter/material.dart';

class PatientSaveButton extends StatefulWidget {
  final double scale;
  final VoidCallback onTap;

  const PatientSaveButton({
    super.key,
    required this.scale,
    required this.onTap,
  });

  @override
  State<PatientSaveButton> createState() => _PatientSaveButtonState();
}

class _PatientSaveButtonState extends State<PatientSaveButton> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: MouseRegion(
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
                color: Colors.green[600],
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
                horizontal: 40 * widget.scale,
                vertical: 18 * widget.scale,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.save_outlined,
                    size: 32 * widget.scale,
                    color: Colors.white,
                    weight: 900,
                  ),
                  SizedBox(width: 12 * widget.scale),
                  Flexible(
                    child: Text(
                      'Salvează',
                      style: TextStyle(
                        fontSize: 26 * widget.scale,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

