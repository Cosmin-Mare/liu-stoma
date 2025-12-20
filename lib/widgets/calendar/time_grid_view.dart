import 'package:flutter/material.dart';
import 'package:liu_stoma/models/programare.dart';

class TimeGridView extends StatefulWidget {
  final List<DateTime> days;
  final List<Map<String, dynamic>> allProgramari;
  final double scale;
  final List<String> months;
  final List<String> weekdays;
  final DateTime currentDate;
  final Function(Programare programare, String patientId)? onProgramareTap;
  final bool isMobile;
  final Function(String message, bool isSuccess)? onNotification;
  final Function(DateTime dateTime)? onAddProgramareTap;

  const TimeGridView({
    super.key,
    required this.days,
    required this.allProgramari,
    required this.scale,
    required this.months,
    required this.weekdays,
    required this.currentDate,
    this.onProgramareTap,
    this.isMobile = false,
    this.onNotification,
    this.onAddProgramareTap,
  });

  @override
  State<TimeGridView> createState() => TimeGridViewState();

  static TimeGridViewState? of(BuildContext context) {
    return context.findAncestorStateOfType<TimeGridViewState>();
  }
}

class TimeGridViewState extends State<TimeGridView> {
  late ScrollController _scrollController;
  bool _hasScrolledToDefault = false;
  final Set<String> _hoveredProgramari = {};

  DateTime? _timeSlotHovered;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Scroll to 08:00 after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasScrolledToDefault) {
        _scrollToDefault();
      }
    });
  }

  @override
  void didUpdateWidget(TimeGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset scroll position when days change (swiping to new day/week)
    if (oldWidget.days != widget.days && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToDefault(updateFlag: false);
      });
    }
  }

  void _scrollToDefault({bool updateFlag = true}) {
    if (_scrollController.hasClients) {
      final hourHeight = widget.isMobile ? 140.0 : 80.0;
      const defaultScrollHour = 0;
      final scrollOffset = defaultScrollHour * hourHeight * widget.scale;
      _scrollController.jumpTo(scrollOffset);
      if (updateFlag) {
        setState(() {
          _hasScrolledToDefault = true;
        });
      }
    }
  }

  void scrollToTime(DateTime time) {
    if (_scrollController.hasClients) {
      final hourHeight = widget.isMobile ? 140.0 : 80.0;
      const startHour = 9;
      final hours = time.hour + time.minute / 60.0;
      final scrollOffset = (hours - startHour) * hourHeight * widget.scale;
      // Scroll to slightly before the time to show some context
      final adjustedOffset = (scrollOffset - 40 * widget.scale).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        adjustedOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getProgramariForDay(DateTime day) {
    return widget.allProgramari.where((item) {
      final programare = item['programare'] as Programare;
      final programareDate = programare.programareTimestamp.toDate();
      return programareDate.year == day.year &&
          programareDate.month == day.month &&
          programareDate.day == day.day;
    }).toList();
  }

  double _getTimePosition(DateTime time, double hourHeight) {
    final hours = time.hour + time.minute / 60.0;
    return hours * hourHeight;
  }

  double _getDurationHeight(int? durata, double hourHeight) {
    if (durata == null) return hourHeight; // Default 60 minutes
    return (durata / 60.0) * hourHeight;
  }

  // Calculate start time in minutes from midnight
  int _getStartMinutes(DateTime time) {
    return time.hour * 60 + time.minute;
  }

  // Calculate end time in minutes from midnight
  int _getEndMinutes(DateTime time, int? durata) {
    final durationMinutes = durata ?? 60;
    return _getStartMinutes(time) + durationMinutes;
  }

  // Check if two time ranges overlap
  bool _eventsOverlap(int start1, int end1, int start2, int end2) {
    return start1 < end2 && start2 < end1;
  }

  // Group overlapping events together
  List<List<Map<String, dynamic>>> _groupOverlappingEvents(
      List<Map<String, dynamic>> events, double hourHeight) {
    if (events.isEmpty) return [];

    // Create a list with start/end times and index
    final eventData = events.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final programare = item['programare'] as Programare;
      final programareTime = programare.programareTimestamp.toDate();
      final startMinutes = _getStartMinutes(programareTime);
      final endMinutes = _getEndMinutes(programareTime, programare.durata);

      return {
        'index': index,
        'item': item,
        'start': startMinutes,
        'end': endMinutes,
      };
    }).toList();

    // Sort by start time
    eventData.sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));

    // Group overlapping events
    final List<List<Map<String, dynamic>>> groups = [];
    final List<bool> processed = List.filled(eventData.length, false);

    for (int i = 0; i < eventData.length; i++) {
      if (processed[i]) continue;

      final group = <Map<String, dynamic>>[eventData[i]];
      processed[i] = true;

      // Find all events that overlap with any event in this group
      bool foundNew;
      do {
        foundNew = false;
        for (int j = 0; j < eventData.length; j++) {
          if (processed[j]) continue;

          // Check if this event overlaps with any event in the group
          for (var groupEvent in group) {
            final groupStart = groupEvent['start'] as int;
            final groupEnd = groupEvent['end'] as int;
            final currentStart = eventData[j]['start'] as int;
            final currentEnd = eventData[j]['end'] as int;

            if (_eventsOverlap(groupStart, groupEnd, currentStart, currentEnd)) {
              group.add(eventData[j]);
              processed[j] = true;
              foundNew = true;
              break;
            }
          }
        }
      } while (foundNew);

      groups.add(group);
    }

    return groups;
  }

  // Get color for an event in an overlap group
  Color _getEventColor(int indexInGroup, int groupSize) {
    if (groupSize > 1) {
      // If there are overlaps, make the first one red
      if (indexInGroup == 0) {
        return Colors.red.shade400;
      }
      // Vary blue color for others
      final blueShades = [
        const Color(0xffB2CEFF), // Original blue
        const Color(0xff9BB8FF), // Slightly darker
        const Color(0xff85A2FF), // Even darker
        const Color(0xff6F8CFF), // More darker
        const Color(0xff5976FF), // Darkest
      ];
      return blueShades[indexInGroup % blueShades.length];
    }
    // No overlap, use original blue
    return const Color(0xffB2CEFF);
  }

  @override
  Widget build(BuildContext context) {
    const startHour = 9;
    const endHour = 20;
    final hourHeight = widget.isMobile ? 200.0 : 80.0;
    final halfHourHeight = hourHeight / 2;
    final totalHeight = (endHour - startHour) * hourHeight * widget.scale;

    return Column(
      children: [
        // Day headers row
        Row(
          children: [
            SizedBox(width: widget.isMobile ? 110 * widget.scale : 90 * widget.scale), // Space for time column
            ...widget.days.map((day) {
              final isToday = day.year == DateTime.now().year &&
                  day.month == DateTime.now().month &&
                  day.day == DateTime.now().day;
              final isCurrentMonth = day.month == widget.currentDate.month;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4 * widget.scale),
                  padding: EdgeInsets.symmetric(vertical: 12 * widget.scale, horizontal: 8 * widget.scale),
                  decoration: BoxDecoration(
                    color: isToday ? const Color(0xffB2CEFF) : Colors.white,
                    borderRadius: BorderRadius.circular(16 * widget.scale),
                    border: Border.all(
                      color: Colors.black,
                      width: 4 * widget.scale,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.weekdays[day.weekday - 1],
                        style: TextStyle(
                          fontSize: widget.isMobile ? 32 * widget.scale : 24 * widget.scale,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4 * widget.scale),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: widget.isMobile ? 42 * widget.scale : 32 * widget.scale,
                          fontWeight: FontWeight.w900,
                          color: isToday ? Colors.black : (isCurrentMonth ? Colors.black : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
        SizedBox(height: 8 * widget.scale),
        // Scrollable time grid
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Container(
              height: totalHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time column
                  SizedBox(
                    width: widget.isMobile ? 110 * widget.scale : 90 * widget.scale,
                    child: Column(
                      children: [
                        ...List.generate((endHour - startHour) * 2, (index) {
                          final hour = startHour + (index ~/ 2);
                          final isHalfHour = index % 2 == 1;
                          if (isHalfHour) {
                            return Container(
                              height: halfHourHeight * widget.scale,
                            );
                          }
                          final isFirstHour = index == 0;
                          return Container(
                            height: halfHourHeight * widget.scale,
                            decoration: isFirstHour ? null : BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.black26,
                                  width: 1 * widget.scale,
                                ),
                              ),
                            ),
                            alignment: Alignment.topRight,
                            padding: EdgeInsets.only(right: 8 * widget.scale, top: 4 * widget.scale),
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: TextStyle(
                                fontSize: widget.isMobile ? 30 * widget.scale : 24 * widget.scale,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  SizedBox(width: 10 * widget.scale),
                  // Days columns
                  Expanded(
                    child: Row(
                      children: widget.days.map((day) {
                        final dayProgramari = _getProgramariForDay(day);

                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 4 * widget.scale),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.black,
                                width: 3 * widget.scale,
                              ),
                              borderRadius: BorderRadius.circular(12 * widget.scale),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12 * widget.scale),
                              child: SizedBox(
                                height: totalHeight,
                                child: Container(
                                  color: Colors.white,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Stack(
                                    children: [
                                      // Time slots with half-hour markers
                                      Positioned.fill(
                                        child: Column(
                                          children: List.generate((endHour - startHour) * 2, (index) {
                                            final isHalfHour = index % 2 == 1;
                                            final isLast = index == (endHour - startHour) * 2 - 1;
                                            // Bottom border of hour slot is at half-hour mark (thin)
                                            // Bottom border of half-hour slot is at hour mark (thick)
                                            return Expanded(
                                              child: 
                                              GestureDetector(
                                                onTap: () async {
                                                    widget.onAddProgramareTap?.call(DateTime(
                                                    day.year,
                                                    day.month,
                                                    day.day,
                                                    startHour + (index ~/ 2), index % 2 == 1 ? 30 : 0,
                                                  )) ?? DateTime.now();
                                                },
                                                  child: 
                                                  MouseRegion(
                                                    onHover: (_) => setState(() => _timeSlotHovered = DateTime(day.year, day.month, day.day, startHour + (index ~/ 2), index % 2 == 1 ? 30 : 0)),
                                                    onExit: (_) => setState(() => _timeSlotHovered = null),
                                                    child:
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          color: _timeSlotHovered == DateTime(day.year, day.month, day.day, startHour + (index ~/ 2), index % 2 == 1 ? 30 : 0) ? Colors.grey[200]! : Colors.white,
                                                          border: isLast ? null : Border(
                                                            bottom: BorderSide(
                                                              color: isHalfHour ? Colors.black26 : Colors.black12,
                                                              width: isHalfHour ? 1 * widget.scale : 0.5 * widget.scale,
                                                            ),
                                                          ),
                                                        ),
                                                    ),
                                                  )
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                      // Programari
                                      ...() {
                                        // Group overlapping events
                                        final overlapGroups = _groupOverlappingEvents(dayProgramari, hourHeight * widget.scale);
                                        final List<Widget> eventWidgets = [];
                                        final containerWidth = constraints.maxWidth;

                                        for (var group in overlapGroups) {
                                          final groupSize = group.length;
                                          // Calculate width: container width minus padding, divided by group size
                                          final containerPadding = 8 * widget.scale; // left + right margins
                                          final availableWidth = containerWidth - containerPadding;
                                          final eventWidth = availableWidth / groupSize - (2 * widget.scale); // spacing between events
                                          final spacing = 2 * widget.scale;

                                          for (int i = 0; i < group.length; i++) {
                                            final eventData = group[i];
                                            final item = eventData['item'] as Map<String, dynamic>;
                                            final programare = item['programare'] as Programare;
                                            final patientName = item['patientName'] as String;
                                            final programareTime = programare.programareTimestamp.toDate();
                                            final startPosition = _getTimePosition(programareTime, hourHeight * widget.scale);
                                            final height = _getDurationHeight(programare.durata, hourHeight * widget.scale);
                                            final leftOffset = 4 * widget.scale + (eventWidth + spacing) * i;
                                            final eventColor = _getEventColor(i, groupSize);
                                            final programareKey = '${programare.programareTimestamp}_${programare.displayText}_${item['patientId']}';
                                            final isHovered = _hoveredProgramari.contains(programareKey);

                                            eventWidgets.add(
                                              Positioned(
                                                top: startPosition - (startHour * hourHeight * widget.scale),
                                                left: leftOffset,
                                                width: eventWidth,
                                                height: height,
                                                child: GestureDetector(
                                                  onTap: widget.onProgramareTap != null
                                                      ? () => widget.onProgramareTap!(programare, item['patientId'] as String)
                                                      : null,
                                                  child: MouseRegion(
                                                    cursor: widget.onProgramareTap != null
                                                        ? SystemMouseCursors.click
                                                        : SystemMouseCursors.basic,
                                                    onEnter: widget.onProgramareTap != null
                                                        ? (_) {
                                                            setState(() {
                                                              _hoveredProgramari.add(programareKey);
                                                            });
                                                          }
                                                        : null,
                                                    onExit: widget.onProgramareTap != null
                                                        ? (_) {
                                                            setState(() {
                                                              _hoveredProgramari.remove(programareKey);
                                                            });
                                                          }
                                                        : null,
                                                    child: AnimatedScale(
                                                      scale: isHovered ? 1.03 : 1.0,
                                                      duration: const Duration(milliseconds: 200),
                                                      curve: Curves.easeOutCubic,
                                                      child: AnimatedContainer(
                                                        duration: const Duration(milliseconds: 200),
                                                        curve: Curves.easeOutCubic,
                                                        padding: EdgeInsets.all(4 * widget.scale),
                                                        decoration: BoxDecoration(
                                                          color: eventColor,
                                                          borderRadius: BorderRadius.circular(8 * widget.scale),
                                                          border: Border.all(
                                                            color: Colors.black,
                                                            width: isHovered ? 3.5 * widget.scale : 3 * widget.scale,
                                                          ),
                                                          boxShadow: isHovered
                                                              ? [
                                                                  BoxShadow(
                                                                    color: Colors.black.withOpacity(0.3),
                                                                    blurRadius: 8 * widget.scale,
                                                                    offset: Offset(0, 4 * widget.scale),
                                                                  ),
                                                                ]
                                                              : null,
                                                        ),
                                                      child: LayoutBuilder(
                                                    builder: (context, constraints) {
                                                      final availableHeight = constraints.maxHeight;
                                                      final isVeryShort = availableHeight < 45 * widget.scale;
                                                      final isShort = availableHeight < 60 * widget.scale;
                                                      
                                                      // Use Row layout for very short appointments
                                                      if (isVeryShort) {
                                                        return Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Text(
                                                            '${programareTime.hour.toString().padLeft(2, '0')}:${programareTime.minute.toString().padLeft(2, '0')}',
                                                            style: TextStyle(
                                                              fontSize: widget.isMobile ? 26 * widget.scale : 16 * widget.scale,
                                                              fontWeight: FontWeight.w700,
                                                              color: Colors.black,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          SizedBox(width: 8 * widget.scale),
                                                          Flexible(
                                                            child: Text(
                                                              programare.displayText,
                                                              style: TextStyle(
                                                                fontSize: widget.isMobile ? 26 * widget.scale : 16 * widget.scale,
                                                                fontWeight: FontWeight.w600,
                                                                color: Colors.black,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          ],
                                                        );
                                                      }
                                                      
                                                      // Use Column layout for normal appointments
                                                      return Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        mainAxisSize: MainAxisSize.max,
                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            '${programareTime.hour.toString().padLeft(2, '0')}:${programareTime.minute.toString().padLeft(2, '0')}',
                                                            style: TextStyle(
                                                              fontSize: widget.isMobile ? 32 * widget.scale : 20 * widget.scale,
                                                              fontWeight: FontWeight.w700,
                                                              color: Colors.black,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        SizedBox(height: 4 * widget.scale),
                                                        Flexible(
                                                          child: Text(
                                                            programare.displayText,
                                                            style: TextStyle(
                                                              fontSize: widget.isMobile 
                                                                  ? (isShort ? 28 * widget.scale : 34 * widget.scale)
                                                                  : (isShort ? 18 * widget.scale : 22 * widget.scale),
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.black,
                                                            ),
                                                            maxLines: isShort ? 1 : 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        if (height > 50 * widget.scale) ...[
                                                          SizedBox(height: 4 * widget.scale),
                                                          Flexible(
                                                            child: Text(
                                                              patientName,
                                                              style: TextStyle(
                                                                fontSize: widget.isMobile ? 28 * widget.scale : 18 * widget.scale,
                                                                fontWeight: FontWeight.w500,
                                                                color: Colors.black87,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                        if (programare.durata != null && height > 60 * widget.scale)
                                                          Padding(
                                                            padding: EdgeInsets.only(top: 4 * widget.scale),
                                                            child: Text(
                                                              '${programare.durata} min',
                                                              style: TextStyle(
                                                                fontSize: widget.isMobile ? 26 * widget.scale : 16 * widget.scale,
                                                                fontWeight: FontWeight.w500,
                                                                color: Colors.black54,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            );
                                          }
                                        }
                                        return eventWidgets;
                                      }(),
                                      
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

