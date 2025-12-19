import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:liu_stoma/models/programare.dart';

class PatientCard extends StatefulWidget {
  final String patientId;
  final String nume;
  final int? varsta;
  final List<Programare> programari;
  final String Function(Timestamp) formatTimestamp;
  final double scale;
  final VoidCallback onTap;
  final Function(Offset menuPosition, Offset cardPosition, Size cardSize)? onLongPress;
  final bool isSelected;

  const PatientCard({
    super.key,
    required this.patientId,
    required this.nume,
    required this.varsta,
    required this.programari,
    required this.formatTimestamp,
    required this.scale,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  @override
  State<PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<PatientCard> {
  bool _hovering = false;

  void _setHover(bool value) {
    if (_hovering == value) return;
    setState(() => _hovering = value);
  }

  @override
  Widget build(BuildContext context) {
    final cardPadding = 24.0 * widget.scale;
    final borderWidth = 7.0 * widget.scale;

    // Find the closest future programare (if any)
    Programare? closestFutureProgramare;
    if (widget.programari.isNotEmpty) {
      final now = DateTime.now();
      final futureProgramari = widget.programari
          .where(
            (p) => p.programareTimestamp.toDate().isAfter(now),
          )
          .toList();

      if (futureProgramari.isNotEmpty) {
        futureProgramari.sort(
          (a, b) => a.programareTimestamp.compareTo(b.programareTimestamp),
        );
        closestFutureProgramare = futureProgramari.first;
      }
    }

    // Calculate total remaining payment across all programari
    final totalRestDePlata = widget.programari.fold<double>(
      0.0,
      (sum, p) => sum + (p.restDePlata > 0 ? p.restDePlata : 0),
    );

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPressStart: widget.onLongPress != null
            ? (details) {
                final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                if (renderBox != null) {
                  final cardPosition = renderBox.localToGlobal(Offset.zero);
                  final cardSize = renderBox.size;
                  // Use the bottom center of the card as the menu position (menu will appear below)
                  final menuPosition = cardPosition + Offset(cardSize.width / 2, cardSize.height);
                  widget.onLongPress!(menuPosition, cardPosition, cardSize);
                }
              }
            : null,
        child: AnimatedScale(
          scale: widget.isSelected 
              ? 1.05 
              : (_hovering ? 1.02 : 1.0),
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24 * widget.scale),
              border: Border.all(
                color: Colors.black,
                width: borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(widget.isSelected ? 0.8 : (_hovering ? 0.7 : 0.5)),
                  blurRadius: widget.isSelected ? 15 * widget.scale : (_hovering ? 8 * widget.scale : 3 * widget.scale),
                  offset: Offset(0, widget.isSelected ? 15 * widget.scale : (_hovering ? 10 * widget.scale : 6 * widget.scale)),
                  spreadRadius: widget.isSelected ? 2 * widget.scale : 0,
                ),
              ],
            ),
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.nume,
                        style: TextStyle(
                          fontSize: 36 * widget.scale,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (widget.varsta != null && widget.varsta! > 0) ...[
                      SizedBox(width: 12 * widget.scale),
                      Text(
                        '${widget.varsta} ani',
                        style: TextStyle(
                          fontSize: 30 * widget.scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
                if (totalRestDePlata > 0) ...[
                  SizedBox(height: 8 * widget.scale),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10 * widget.scale,
                      vertical: 4 * widget.scale,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.red[400]!, Colors.red[600]!],
                      ),
                      borderRadius: BorderRadius.circular(8 * widget.scale),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pending,
                          size: 18 * widget.scale,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4 * widget.scale),
                        Text(
                          'Datorie: ${totalRestDePlata.toStringAsFixed(0)} RON',
                          style: TextStyle(
                            fontSize: 20 * widget.scale,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (closestFutureProgramare != null) ...[
                  SizedBox(height: 12 * widget.scale),
                  Text(
                    '${closestFutureProgramare.displayText} - ${widget.formatTimestamp(closestFutureProgramare.programareTimestamp)}',
                    style: TextStyle(
                      fontSize: 28 * widget.scale,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    softWrap: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

