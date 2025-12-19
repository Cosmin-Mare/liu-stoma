import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/widgets/programari_table.dart';
import 'package:liu_stoma/widgets/common/animated_close_button.dart';

class PatientHistoryModal extends StatefulWidget {
  final double scale;
  final List<Programare> expiredProgramari;
  final Function(Programare) onEdit;
  final Function(Programare) onDelete;
  final VoidCallback onClose;
  final VoidCallback onAddConsultation;

  const PatientHistoryModal({
    super.key,
    required this.scale,
    required this.expiredProgramari,
    required this.onEdit,
    required this.onDelete,
    required this.onClose,
    required this.onAddConsultation,
  });

  @override
  State<PatientHistoryModal> createState() => _PatientHistoryModalState();
}

class _PatientHistoryModalState extends State<PatientHistoryModal> {
  bool _retroactiveButtonHovering = false;
  bool _retroactiveButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          behavior: HitTestBehavior.opaque,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32 * widget.scale),
                      border: Border.all(
                        color: Colors.black,
                        width: 7 * widget.scale,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20 * widget.scale,
                          offset: Offset(0, 10 * widget.scale),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(40 * widget.scale),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Istoric consultații',
                                style: TextStyle(
                                  fontSize: 48 * widget.scale,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              AnimatedCloseButton(
                                onTap: widget.onClose,
                                scale: widget.scale,
                                iconSize: 36,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40 * widget.scale),
                            child: ProgramariTable(
                              programari: widget.expiredProgramari,
                              scale: widget.scale,
                              onEdit: widget.onEdit,
                              onDelete: widget.onDelete,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40 * widget.scale),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: MouseRegion(
                              onEnter: (_) {
                                if (!_retroactiveButtonHovering) {
                                  setState(() => _retroactiveButtonHovering = true);
                                }
                              },
                              onExit: (_) {
                                if (_retroactiveButtonHovering) {
                                  setState(() => _retroactiveButtonHovering = false);
                                }
                              },
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTapDown: (_) {
                                  if (!_retroactiveButtonPressed) {
                                    setState(() => _retroactiveButtonPressed = true);
                                  }
                                },
                                onTapUp: (_) {
                                  if (_retroactiveButtonPressed) {
                                    setState(() => _retroactiveButtonPressed = false);
                                  }
                                  widget.onAddConsultation();
                                },
                                onTapCancel: () {
                                  if (_retroactiveButtonPressed) {
                                    setState(() => _retroactiveButtonPressed = false);
                                  }
                                },
                                child: AnimatedScale(
                                  scale: _retroactiveButtonPressed ? 0.97 : (_retroactiveButtonHovering ? 1.02 : 1.0),
                                  alignment: Alignment.center,
                                  duration: const Duration(milliseconds: 160),
                                  curve: Curves.easeOutCubic,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    curve: Curves.easeOutCubic,
                                    decoration: BoxDecoration(
                                      color: Colors.orange[600],
                                      borderRadius: BorderRadius.circular(20 * widget.scale),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 6 * widget.scale,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(_retroactiveButtonPressed ? 0.5 : (_retroactiveButtonHovering ? 0.6 : 0.4)),
                                          blurRadius: _retroactiveButtonPressed ? 6 * widget.scale : (_retroactiveButtonHovering ? 12 * widget.scale : 8 * widget.scale),
                                          offset: Offset(0, _retroactiveButtonPressed ? 4 * widget.scale : (_retroactiveButtonHovering ? 8 * widget.scale : 6 * widget.scale)),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 40 * widget.scale,
                                      vertical: 20 * widget.scale,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline,
                                          size: 48 * widget.scale,
                                          color: Colors.white,
                                          weight: 900,
                                        ),
                                        SizedBox(width: 16 * widget.scale),
                                        Text(
                                          'Adaugă consultație',
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
                            ),
                          ),
                        ),
                        SizedBox(height: 40 * widget.scale),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

