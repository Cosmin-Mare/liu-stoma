import 'package:flutter/material.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/widgets/programari_table.dart';

class PatientAppointmentsSection extends StatefulWidget {
  final double scale;
  final bool isAddMode;
  final List<Programare> activeProgramari;
  final Function(Programare) onEdit;
  final Function(Programare) onDelete;
  final VoidCallback onAddProgramare;
  final VoidCallback onAddExtra;

  const PatientAppointmentsSection({
    super.key,
    required this.scale,
    required this.isAddMode,
    required this.activeProgramari,
    required this.onEdit,
    required this.onDelete,
    required this.onAddProgramare,
    required this.onAddExtra,
  });

  @override
  State<PatientAppointmentsSection> createState() => _PatientAppointmentsSectionState();
}

class _PatientAppointmentsSectionState extends State<PatientAppointmentsSection> {
  bool _addButtonHovering = false;
  bool _addButtonPressed = false;
  bool _extraButtonHovering = false;
  bool _extraButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 20 * widget.scale),
          child: Text(
            'Programări',
            style: TextStyle(
              fontSize: 40 * widget.scale,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20 * widget.scale),
              border: Border.all(
                color: Colors.black,
                width: 5 * widget.scale,
              ),
            ),
            child: widget.isAddMode
                ? Center(
                    child: Text(
                      'Nu există programări pentru un pacient nou',
                      style: TextStyle(
                        fontSize: 32 * widget.scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ProgramariTable(
                    programari: widget.activeProgramari,
                    scale: widget.scale,
                    onEdit: widget.onEdit,
                    onDelete: widget.onDelete,
                  ),
          ),
        ),
        if (!widget.isAddMode) ...[
          SizedBox(height: 20 * widget.scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              MouseRegion(
                onEnter: (_) {
                  if (!_addButtonHovering) {
                    setState(() => _addButtonHovering = true);
                  }
                },
                onExit: (_) {
                  if (_addButtonHovering) {
                    setState(() => _addButtonHovering = false);
                  }
                },
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTapDown: (_) {
                    if (!_addButtonPressed) {
                      setState(() => _addButtonPressed = true);
                    }
                  },
                  onTapUp: (_) {
                    if (_addButtonPressed) {
                      setState(() => _addButtonPressed = false);
                    }
                    widget.onAddProgramare();
                  },
                  onTapCancel: () {
                    if (_addButtonPressed) {
                      setState(() => _addButtonPressed = false);
                    }
                  },
                  child: AnimatedScale(
                    scale: _addButtonPressed ? 0.97 : (_addButtonHovering ? 1.02 : 1.0),
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
                            color: Colors.black.withOpacity(_addButtonPressed ? 0.5 : (_addButtonHovering ? 0.6 : 0.4)),
                            blurRadius: _addButtonPressed ? 6 * widget.scale : (_addButtonHovering ? 12 * widget.scale : 8 * widget.scale),
                            offset: Offset(0, _addButtonPressed ? 4 * widget.scale : (_addButtonHovering ? 8 * widget.scale : 6 * widget.scale)),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 28 * widget.scale,
                        vertical: 18 * widget.scale,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 36 * widget.scale,
                            color: Colors.white,
                            weight: 900,
                          ),
                          SizedBox(width: 12 * widget.scale),
                          Text(
                            'Adaugă programare',
                            style: TextStyle(
                              fontSize: 24 * widget.scale,
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
              SizedBox(width: 16 * widget.scale),
              MouseRegion(
                onEnter: (_) {
                  if (!_extraButtonHovering) {
                    setState(() => _extraButtonHovering = true);
                  }
                },
                onExit: (_) {
                  if (_extraButtonHovering) {
                    setState(() => _extraButtonHovering = false);
                  }
                },
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTapDown: (_) {
                    if (!_extraButtonPressed) {
                      setState(() => _extraButtonPressed = true);
                    }
                  },
                  onTapUp: (_) {
                    if (_extraButtonPressed) {
                      setState(() => _extraButtonPressed = false);
                    }
                    widget.onAddExtra();
                  },
                  onTapCancel: () {
                    if (_extraButtonPressed) {
                      setState(() => _extraButtonPressed = false);
                    }
                  },
                  child: AnimatedScale(
                    scale: _extraButtonPressed ? 0.97 : (_extraButtonHovering ? 1.02 : 1.0),
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
                            color: Colors.black.withOpacity(_extraButtonPressed ? 0.5 : (_extraButtonHovering ? 0.6 : 0.4)),
                            blurRadius: _extraButtonPressed ? 6 * widget.scale : (_extraButtonHovering ? 12 * widget.scale : 8 * widget.scale),
                            offset: Offset(0, _extraButtonPressed ? 4 * widget.scale : (_extraButtonHovering ? 8 * widget.scale : 6 * widget.scale)),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 28 * widget.scale,
                        vertical: 18 * widget.scale,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 36 * widget.scale,
                            color: Colors.white,
                            weight: 900,
                          ),
                          SizedBox(width: 12 * widget.scale),
                          Text(
                            'Adaugă extra',
                            style: TextStyle(
                              fontSize: 24 * widget.scale,
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
            ],
          ),
        ],
      ],
    );
  }
}

