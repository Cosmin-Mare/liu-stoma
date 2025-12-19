import 'package:flutter/material.dart';

class SimpleDatePicker extends StatefulWidget {
  final double scale;
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const SimpleDatePicker({
    super.key,
    required this.scale,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<SimpleDatePicker> createState() => _SimpleDatePickerState();
}

class _SimpleDatePickerState extends State<SimpleDatePicker> with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  late DateTime _displayedMonth; // The month currently being displayed
  bool _cancelButtonPressed = false;
  bool _confirmButtonPressed = false;
  
  late AnimationController _swipeController;
  late Animation<double> _swipeAnimation;
  double _dragOffset = 0.0;
  double _baseDragOffset = 0.0;
  bool _isSwitchingMonth = false;
  double? _containerWidth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    // Start from current month (or initial date if it's in the future)
    final now = DateTime.now();
    _displayedMonth = DateTime(
      _selectedDate.isAfter(now) ? _selectedDate.year : now.year,
      _selectedDate.isAfter(now) ? _selectedDate.month : now.month,
      1,
    );
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _swipeAnimation = CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  DateTime _getPreviousMonth(DateTime month) {
    if (month.month == 1) {
      return DateTime(month.year - 1, 12, 1);
    } else {
      return DateTime(month.year, month.month - 1, 1);
    }
  }

  DateTime _getNextMonth(DateTime month) {
    if (month.month == 12) {
      return DateTime(month.year + 1, 1, 1);
    } else {
      return DateTime(month.year, month.month + 1, 1);
    }
  }

  void _previousMonth() {
    if (_swipeController.isAnimating) return;
    setState(() {
      _displayedMonth = _getPreviousMonth(_displayedMonth);
    });
  }

  void _nextMonth() {
    if (_swipeController.isAnimating) return;
    setState(() {
      _displayedMonth = _getNextMonth(_displayedMonth);
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    // Stop any ongoing animation immediately
    if (_swipeController.isAnimating) {
      _swipeController.stop(canceled: true);
      _swipeController.reset();
      _isSwitchingMonth = false;
    }
    // Reset drag offset to start fresh
    _baseDragOffset = 0.0;
    _dragOffset = 0.0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Make sure animation is stopped during drag
    if (_swipeController.isAnimating) {
      _swipeController.stop(canceled: true);
      _swipeController.reset();
    }
    
    setState(() {
      // Accumulate drag offset from the start
      _dragOffset += details.delta.dx;
      
      // Limit drag offset to prevent over-scrolling
      final maxDrag = _containerWidth ?? 300;
      if (_dragOffset > maxDrag) {
        _dragOffset = maxDrag;
      } else if (_dragOffset < -maxDrag) {
        _dragOffset = -maxDrag;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_swipeController.isAnimating) return;
    
    final velocity = details.velocity.pixelsPerSecond.dx;
    final minOffsetForSwitch = 15.0; // Very small threshold - 15 pixels
    final velocityThreshold = 100.0; // Only use velocity if it's significant
    
    DateTime? newMonth;
    bool shouldSwitch = false;
    
    // Prioritize offset over velocity - any meaningful offset should switch
    final hasSignificantOffset = _dragOffset.abs() > minOffsetForSwitch;
    final hasSignificantVelocity = velocity.abs() > velocityThreshold;
    
    if (hasSignificantOffset || hasSignificantVelocity) {
      // Determine direction - use offset if it exists, otherwise use velocity
      bool swipeRight;
      if (hasSignificantOffset) {
        // Use offset direction (works for slow swipes)
        swipeRight = _dragOffset > 0;
      } else {
        // Use velocity direction (for fast flicks)
        swipeRight = velocity > 0;
      }
      
      if (swipeRight) {
        // Swipe right - go to previous month
        newMonth = _getPreviousMonth(_displayedMonth);
        shouldSwitch = true;
      } else {
        // Swipe left - go to next month
        newMonth = _getNextMonth(_displayedMonth);
        shouldSwitch = true;
      }
    }
    
    final startOffset = _dragOffset;
    
    if (shouldSwitch && newMonth != null) {
      // Switch months - animate to completion
      setState(() {
        _baseDragOffset = startOffset;
        _isSwitchingMonth = true;
      });
      
      _swipeController.forward().then((_) {
        if (mounted) {
          setState(() {
            _displayedMonth = newMonth!;
            _dragOffset = 0.0;
            _baseDragOffset = 0.0;
            _isSwitchingMonth = false;
            _swipeController.reset();
          });
        }
      });
    } else {
      // No movement or too small - snap back to center
      setState(() {
        _dragOffset = 0.0;
        _baseDragOffset = 0.0;
      });
    }
  }

  double _getCurrentOffset() {
    final startOffset = _baseDragOffset;
    final containerWidth = _containerWidth ?? 300;
    
    if (_isSwitchingMonth) {
      // Switching months - animate to full screen width
      final targetOffset = startOffset > 0 ? containerWidth : -containerWidth;
      return startOffset + (targetOffset - startOffset) * _swipeAnimation.value;
    } else {
      // Returning to center
      return startOffset * (1 - _swipeAnimation.value);
    }
  }

  Widget _buildCalendarStack(double offset, double containerWidth) {
    DateTime? transMonth;
    if (offset > 0) {
      transMonth = _getPreviousMonth(_displayedMonth);
    } else if (offset < 0) {
      transMonth = _getNextMonth(_displayedMonth);
    }
    
    return SizedBox(
      width: containerWidth,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Transition month (shown during swipe)
          if (transMonth != null && offset != 0)
            Transform.translate(
              offset: Offset(
                offset > 0 
                    ? -containerWidth + offset
                    : containerWidth + offset,
                0,
              ),
              child: SizedBox(
                width: containerWidth,
                child: _buildCalendarGrid(transMonth, containerWidth),
              ),
            ),
          // Current month
          Transform.translate(
            offset: Offset(offset, 0),
            child: SizedBox(
              width: containerWidth,
              child: _buildCalendarGrid(_displayedMonth, containerWidth),
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime?> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    
    // Get the weekday of the first day (1 = Monday, 7 = Sunday)
    int firstWeekday = firstDay.weekday;
    
    List<DateTime?> days = [];
    
    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstWeekday; i++) {
      days.add(null); // Placeholder
    }
    
    // Add all days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      days.add(DateTime(month.year, month.month, day));
    }
    
    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: double.infinity,
          maxHeight: 1000 * widget.scale,
        ),
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
        child: Padding(
          padding: EdgeInsets.all(40 * widget.scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Month navigation header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _previousMonth,
                    child: Container(
                      padding: EdgeInsets.all(10 * widget.scale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20 * widget.scale),
                        border: Border.all(
                          color: Colors.black,
                          width: 5 * widget.scale,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 48 * widget.scale,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _getMonthYearText(_displayedMonth),
                      style: TextStyle(
                        fontSize: 64 * widget.scale,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  GestureDetector(
                    onTap: _nextMonth,
                    child: Container(
                      padding: EdgeInsets.all(10 * widget.scale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20 * widget.scale),
                        border: Border.all(
                          color: Colors.black,
                          width: 5 * widget.scale,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 48 * widget.scale,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20 * widget.scale),
              // Weekday headers
              Row(
                children: ['L', 'M', 'M', 'J', 'V', 'S', 'D'].map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 48 * widget.scale,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 15 * widget.scale),
              // Calendar grid with swipe support
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (_containerWidth == null) {
                      _containerWidth = constraints.maxWidth;
                    }
                    
                    final containerWidth = constraints.maxWidth;
                    
                    return ClipRect(
                      child: GestureDetector(
                        onHorizontalDragStart: _onHorizontalDragStart,
                        onHorizontalDragUpdate: _onHorizontalDragUpdate,
                        onHorizontalDragEnd: _onHorizontalDragEnd,
                        child: Builder(
                          builder: (context) {
                            // Use AnimatedBuilder only when animating, otherwise use direct offset
                            if (_swipeController.isAnimating) {
                              return AnimatedBuilder(
                                animation: _swipeAnimation,
                                builder: (context, child) {
                                  final offset = _getCurrentOffset();
                                  return _buildCalendarStack(offset, containerWidth);
                                },
                              );
                            } else {
                              // During dragging, use raw offset directly
                              return _buildCalendarStack(_dragOffset, containerWidth);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 10 * widget.scale),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _cancelButtonPressed = true),
                      onTapUp: (_) {
                        setState(() => _cancelButtonPressed = false);
                        Navigator.of(context).pop();
                      },
                      onTapCancel: () => setState(() => _cancelButtonPressed = false),
                      child: AnimatedScale(
                        scale: _cancelButtonPressed ? 0.97 : 1.0,
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 40 * widget.scale,
                            vertical: 20 * widget.scale,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(28 * widget.scale),
                            border: Border.all(
                              color: Colors.black,
                              width: 6 * widget.scale,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 8 * widget.scale,
                                offset: Offset(0, 6 * widget.scale),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Anulează',
                              style: TextStyle(
                                fontSize: 40 * widget.scale,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20 * widget.scale),
                  Expanded(
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _confirmButtonPressed = true),
                      onTapUp: (_) {
                        setState(() => _confirmButtonPressed = false);
                        Navigator.of(context).pop(_selectedDate);
                      },
                      onTapCancel: () => setState(() => _confirmButtonPressed = false),
                      child: AnimatedScale(
                        scale: _confirmButtonPressed ? 0.97 : 1.0,
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 40 * widget.scale,
                            vertical: 20 * widget.scale,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(28 * widget.scale),
                            border: Border.all(
                              color: Colors.black,
                              width: 6 * widget.scale,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 8 * widget.scale,
                                offset: Offset(0, 6 * widget.scale),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Confirmă',
                              style: TextStyle(
                                fontSize: 40 * widget.scale,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime month, double width) {
    return SizedBox(
      width: width,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 8 * widget.scale,
          mainAxisSpacing: 8 * widget.scale,
          childAspectRatio: 1.2,
        ),
        itemCount: _getDaysInMonth(month).length,
        itemBuilder: (context, index) {
          final date = _getDaysInMonth(month)[index];
          if (date == null) {
            return const SizedBox.shrink();
          }

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final dateOnly = DateTime(date.year, date.month, date.day);
          
          // Check if date is in the past
          final isPast = dateOnly.isBefore(today);
          
          // Check if date is selected (only highlight if it's the current displayed month)
          final isSelected = month.year == _displayedMonth.year &&
              month.month == _displayedMonth.month &&
              _selectedDate.year == date.year &&
              _selectedDate.month == date.month &&
              _selectedDate.day == date.day;
          
          return GestureDetector(
            onTap: isPast ? null : () {
              setState(() {
                _selectedDate = date;
                // If selecting a date in transition month, update displayed month
                if (month.year != _displayedMonth.year || month.month != _displayedMonth.month) {
                  _displayedMonth = DateTime(date.year, date.month, 1);
                  _dragOffset = 0.0;
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.green[600]
                    : (isPast ? Colors.grey[200] : Colors.white),
                borderRadius: BorderRadius.circular(20 * widget.scale),
                border: Border.all(
                  color: Colors.black,
                  width: 4 * widget.scale,
                ),
              ),
              child: Center(
                child: Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: 44 * widget.scale,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isPast ? Colors.grey[400] : Colors.black),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getMonthYearText(DateTime date) {
    final monthNames = [
      'Ianuarie', 'Februarie', 'Martie', 'Aprilie',
      'Mai', 'Iunie', 'Iulie', 'August',
      'Septembrie', 'Octombrie', 'Noiembrie', 'Decembrie'
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }
}

