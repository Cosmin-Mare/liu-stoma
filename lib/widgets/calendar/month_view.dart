import 'package:flutter/material.dart';
import 'package:liu_stoma/models/programare.dart';

class MonthView extends StatelessWidget {
  final List<DateTime> days;
  final List<Map<String, dynamic>> allProgramari;
  final double scale;
  final List<String> months;
  final List<String> weekdays;
  final DateTime currentDate;

  const MonthView({
    super.key,
    required this.days,
    required this.allProgramari,
    required this.scale,
    required this.months,
    required this.weekdays,
    required this.currentDate,
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

        return Container(
          decoration: BoxDecoration(
            color: isToday ? const Color(0xffB2CEFF).withOpacity(0.3) : Colors.white,
            borderRadius: BorderRadius.circular(12 * scale),
            border: Border.all(
              color: isToday ? Colors.black : Colors.black26,
              width: isToday ? 4 * scale : 2 * scale,
            ),
          ),
          padding: EdgeInsets.all(8 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 24 * scale,
                  fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                  color: isCurrentMonth ? Colors.black : Colors.black54,
                ),
              ),
              SizedBox(height: 4 * scale),
              Expanded(
                child: ListView.builder(
                  itemCount: dayProgramari.length > 3 ? 3 : dayProgramari.length,
                  itemBuilder: (context, idx) {
                    final item = dayProgramari[idx];
                    final programare = item['programare'] as Programare;
                    final programareTime = programare.programareTimestamp.toDate();
                    final timeStr = '${programareTime.hour.toString().padLeft(2, '0')}:${programareTime.minute.toString().padLeft(2, '0')}';
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 4 * scale),
                      padding: EdgeInsets.symmetric(
                        horizontal: 6 * scale,
                        vertical: 4 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffB2CEFF),
                        borderRadius: BorderRadius.circular(6 * scale),
                        border: Border.all(
                          color: Colors.black,
                          width: 2 * scale,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 14 * scale,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            programare.programareText,
                            style: TextStyle(
                              fontSize: 16 * scale,
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
              if (dayProgramari.length > 3)
                Text(
                  '+${dayProgramari.length - 3}',
                  style: TextStyle(
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

