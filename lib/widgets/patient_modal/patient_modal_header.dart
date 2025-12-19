import 'package:flutter/material.dart';

class PatientModalHeader extends StatefulWidget {
  final double scale;
  final String title;
  final VoidCallback onClose;

  const PatientModalHeader({
    super.key,
    required this.scale,
    required this.title,
    required this.onClose,
  });

  @override
  State<PatientModalHeader> createState() => _PatientModalHeaderState();
}

class _PatientModalHeaderState extends State<PatientModalHeader> {
  bool _closeButtonHovering = false;
  bool _closeButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 40 * widget.scale,
        left: 40 * widget.scale,
        right: 40 * widget.scale,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: 48 * widget.scale,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 20 * widget.scale),
          MouseRegion(
            onEnter: (_) {
              if (!_closeButtonHovering) {
                setState(() => _closeButtonHovering = true);
              }
            },
            onExit: (_) {
              if (_closeButtonHovering) {
                setState(() => _closeButtonHovering = false);
              }
            },
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTapDown: (_) {
                if (!_closeButtonPressed) {
                  setState(() => _closeButtonPressed = true);
                }
              },
              onTapUp: (_) {
                if (_closeButtonPressed) {
                  setState(() => _closeButtonPressed = false);
                }
                widget.onClose();
              },
              onTapCancel: () {
                if (_closeButtonPressed) {
                  setState(() => _closeButtonPressed = false);
                }
              },
              child: AnimatedScale(
                scale: _closeButtonPressed ? 0.95 : (_closeButtonHovering ? 1.05 : 1.0),
                alignment: Alignment.center,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  width: 80 * widget.scale,
                  height: 80 * widget.scale,
                  decoration: BoxDecoration(
                    color: _closeButtonHovering ? Colors.red[600] : Colors.red[500],
                    borderRadius: BorderRadius.circular(40 * widget.scale),
                    border: Border.all(
                      color: Colors.black,
                      width: 4 * widget.scale,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(_closeButtonPressed ? 0.3 : (_closeButtonHovering ? 0.5 : 0.3)),
                        blurRadius: _closeButtonPressed ? 6 * widget.scale : (_closeButtonHovering ? 10 * widget.scale : 6 * widget.scale),
                        offset: Offset(0, _closeButtonPressed ? 3 * widget.scale : (_closeButtonHovering ? 5 * widget.scale : 3 * widget.scale)),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    size: 48 * widget.scale,
                    color: Colors.white,
                    weight: 900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

