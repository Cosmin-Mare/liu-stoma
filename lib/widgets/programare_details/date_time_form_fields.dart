import 'package:flutter/material.dart';

class DatePickerButton extends StatelessWidget {
  final DateTime selectedDateTime;
  final double scale;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;
  final bool isPressed;

  const DatePickerButton({
    super.key,
    required this.selectedDateTime,
    required this.scale,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.isPressed,
  });

  String _formatDate(DateTime dateTime) {
    final months = [
      'ianuarie', 'februarie', 'martie', 'aprilie', 'mai', 'iunie',
      'iulie', 'august', 'septembrie', 'octombrie', 'noiembrie', 'decembrie'
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        scale: isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 30 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36 * scale),
            border: Border.all(
              color: Colors.black,
              width: 5 * scale,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 8 * scale,
                offset: Offset(0, 6 * scale),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 48 * scale,
                color: Colors.black,
                weight: 900,
              ),
              SizedBox(width: 20 * scale),
              Expanded(
                child: Text(
                  _formatDate(selectedDateTime),
                  style: TextStyle(
                    fontSize: 48 * scale,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 48 * scale,
                color: Colors.black,
                weight: 900,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimePickerButton extends StatelessWidget {
  final DateTime selectedDateTime;
  final double scale;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;
  final bool isPressed;

  const TimePickerButton({
    super.key,
    required this.selectedDateTime,
    required this.scale,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.isPressed,
  });

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        scale: isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 30 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36 * scale),
            border: Border.all(
              color: Colors.black,
              width: 5 * scale,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 8 * scale,
                offset: Offset(0, 6 * scale),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 48 * scale,
                color: Colors.black,
                weight: 900,
              ),
              SizedBox(width: 20 * scale),
              Expanded(
                child: Text(
                  _formatTime(selectedDateTime),
                  style: TextStyle(
                    fontSize: 48 * scale,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 48 * scale,
                color: Colors.black,
                weight: 900,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SkipDateCheckbox extends StatelessWidget {
  final bool dateSkipped;
  final double scale;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;
  final bool isPressed;

  const SkipDateCheckbox({
    super.key,
    required this.dateSkipped,
    required this.scale,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.isPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        scale: isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 30 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36 * scale),
            border: Border.all(
              color: Colors.black,
              width: 5 * scale,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60 * scale,
                height: 60 * scale,
                decoration: BoxDecoration(
                  color: dateSkipped ? Colors.orange[600] : Colors.white,
                  borderRadius: BorderRadius.circular(24 * scale),
                  border: Border.all(
                    color: Colors.black,
                    width: 5 * scale,
                  ),
                ),
                child: dateSkipped
                    ? Icon(
                        Icons.check,
                        size: 42 * scale,
                        color: Colors.white,
                        weight: 900,
                      )
                    : null,
              ),
              SizedBox(width: 20 * scale),
              Text(
                'Fără dată',
                style: TextStyle(
                  fontSize: 48 * scale,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DateSkippedInfo extends StatelessWidget {
  final double scale;

  const DateSkippedInfo({
    super.key,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24 * scale),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(28 * scale),
        border: Border.all(
          color: Colors.orange[300]!,
          width: 3 * scale,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 48 * scale,
            color: Colors.orange[800],
          ),
          SizedBox(width: 16 * scale),
          Expanded(
            child: Text(
              'Consultația va fi salvată în istoric fără dată.',
              style: TextStyle(
                fontSize: 36 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.orange[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificareCheckbox extends StatelessWidget {
  final bool notificare;
  final double scale;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;
  final bool isPressed;

  const NotificareCheckbox({
    super.key,
    required this.notificare,
    required this.scale,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.isPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        scale: isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 30 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36 * scale),
            border: Border.all(
              color: Colors.black,
              width: 5 * scale,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60 * scale,
                height: 60 * scale,
                decoration: BoxDecoration(
                  color: notificare ? Colors.green[600] : Colors.white,
                  borderRadius: BorderRadius.circular(20 * scale),
                  border: Border.all(
                    color: Colors.black,
                    width: 4 * scale,
                  ),
                ),
                child: notificare
                    ? Icon(
                        Icons.check,
                        size: 42 * scale,
                        color: Colors.white,
                        weight: 900,
                      )
                    : null,
              ),
              SizedBox(width: 20 * scale),
              Text(
                'Notificare',
                style: TextStyle(
                  fontSize: 48 * scale,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

