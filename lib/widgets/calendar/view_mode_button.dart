import 'package:flutter/material.dart';
import 'package:liu_stoma/widgets/calendar/calendar_view_mode.dart';

class ViewModeButton extends StatelessWidget {
  final String label;
  final CalendarViewMode mode;
  final CalendarViewMode currentMode;
  final double scale;
  final VoidCallback onTap;
  final bool isMobile;

  const ViewModeButton({
    super.key,
    required this.label,
    required this.mode,
    required this.currentMode,
    required this.scale,
    required this.onTap,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentMode == mode;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 36 * scale : 20 * scale,
            vertical: isMobile ? 24 * scale : 12 * scale,
          ),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xffB2CEFF) : Colors.white,
            borderRadius: BorderRadius.circular(20 * scale),
            border: Border.all(
              color: Colors.black,
              width: 4 * scale,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 48 * scale : 28 * scale,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

