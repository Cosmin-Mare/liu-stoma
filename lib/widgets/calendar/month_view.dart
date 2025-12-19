import 'package:flutter/material.dart';
import 'package:liu_stoma/models/programare.dart';

class MonthView extends StatelessWidget {
  final List<DateTime> days;
  final List<Map<String, dynamic>> allProgramari;
  final double scale;
  final List<String> months;
  final List<String> weekdays;
  final DateTime currentDate;
  final Function(DateTime day)? onDayTap;

  const MonthView({
    super.key,
    required this.days,
    required this.allProgramari,
    required this.scale,
    required this.months,
    required this.weekdays,
    required this.currentDate,
    this.onDayTap,
  });

  List<Map<String, dynamic>> _getProgramariForDay(DateTime day) {
    return allProgramari.where((item) {
      final programare = item['programare'] as Programare;
      final programareDate = programare.programareTimestamp.toDate();
      return programareDate.year == day.year &&
          programareDate.month == day.month &&
          programareDate.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8 * scale,
        mainAxisSpacing: 8 * scale,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final dayProgramari = _getProgramariForDay(day);
        final isToday = day.year == DateTime.now().year &&
            day.month == DateTime.now().month &&
            day.day == DateTime.now().day;
        final isCurrentMonth = day.month == currentDate.month;

        return _AnimatedDayCell(
          day: day,
          dayProgramari: dayProgramari,
          isToday: isToday,
          isCurrentMonth: isCurrentMonth,
          scale: scale,
          onTap: () => onDayTap?.call(day),
        );
      },
    );
  }
}

class _AnimatedDayCell extends StatefulWidget {
  final DateTime day;
  final List<Map<String, dynamic>> dayProgramari;
  final bool isToday;
  final bool isCurrentMonth;
  final double scale;
  final VoidCallback? onTap;

  const _AnimatedDayCell({
    required this.day,
    required this.dayProgramari,
    required this.isToday,
    required this.isCurrentMonth,
    required this.scale,
    this.onTap,
  });

  @override
  State<_AnimatedDayCell> createState() => _AnimatedDayCellState();
}

class _AnimatedDayCellState extends State<_AnimatedDayCell> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isToday 
        ? const Color(0xffB2CEFF).withOpacity(0.3) 
        : Colors.white;
    final hoverColor = widget.isToday
        ? const Color(0xffB2CEFF).withOpacity(0.5)
        : Colors.grey[100]!;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0),
          duration: Duration(milliseconds: _isPressed ? 80 : 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: _isPressed ? hoverColor : (_isHovered ? hoverColor : baseColor),
              borderRadius: BorderRadius.circular(12 * widget.scale),
              border: Border.all(
                color: _isHovered || _isPressed 
                    ? Colors.black 
                    : (widget.isToday ? Colors.black : Colors.black26),
                width: (_isHovered || _isPressed || widget.isToday) 
                    ? 4 * widget.scale 
                    : 2 * widget.scale,
              ),
              boxShadow: _isHovered && !_isPressed
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8 * widget.scale,
                        offset: Offset(0, 4 * widget.scale),
                      ),
                    ]
                  : null,
            ),
            padding: EdgeInsets.all(8 * widget.scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.day.day}',
                  style: TextStyle(
                    fontSize: 24 * widget.scale,
                    fontWeight: widget.isToday ? FontWeight.w900 : FontWeight.w700,
                    color: widget.isCurrentMonth ? Colors.black : Colors.black54,
                  ),
                ),
                SizedBox(height: 4 * widget.scale),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.dayProgramari.length > 3 ? 3 : widget.dayProgramari.length,
                    itemBuilder: (context, idx) {
                      final item = widget.dayProgramari[idx];
                      final programare = item['programare'] as Programare;
                      final programareTime = programare.programareTimestamp.toDate();
                      final timeStr = '${programareTime.hour.toString().padLeft(2, '0')}:${programareTime.minute.toString().padLeft(2, '0')}';
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 4 * widget.scale),
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * widget.scale,
                          vertical: 4 * widget.scale,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffB2CEFF),
                          borderRadius: BorderRadius.circular(6 * widget.scale),
                          border: Border.all(
                            color: Colors.black,
                            width: 2 * widget.scale,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 14 * widget.scale,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              programare.displayText,
                              style: TextStyle(
                                fontSize: 16 * widget.scale,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (widget.dayProgramari.length > 3)
                  Text(
                    '+${widget.dayProgramari.length - 3}',
                    style: TextStyle(
                      fontSize: 18 * widget.scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
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
