import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DatePickerButton extends StatelessWidget {
  final DateTime selectedDateTime;
  final double scale;
  final VoidCallback onTap;
  final bool isHovering;
  final bool isPressed;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  const DatePickerButton({
    super.key,
    required this.selectedDateTime,
    required this.scale,
    required this.onTap,
    required this.isHovering,
    required this.isPressed,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
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
    return MouseRegion(
      onEnter: (_) => onHoverEnter(),
      onExit: (_) => onHoverExit(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => onTapDown(),
        onTapUp: (_) {
          onTapUp();
          onTap();
        },
        onTapCancel: onTapCancel,
        child: AnimatedScale(
          scale: isPressed ? 0.97 : (isHovering ? 1.02 : 1.0),
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: 24 * scale,
              vertical: 20 * scale,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28 * scale),
              border: Border.all(
                color: Colors.black,
                width: 5 * scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isPressed ? 0.5 : (isHovering ? 0.6 : 0.4)),
                  blurRadius: isPressed ? 6 * scale : (isHovering ? 12 * scale : 8 * scale),
                  offset: Offset(0, isPressed ? 4 * scale : (isHovering ? 8 * scale : 6 * scale)),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 32 * scale,
                  color: Colors.black,
                  weight: 900,
                ),
                SizedBox(width: 16 * scale),
                Expanded(
                  child: Text(
                    _formatDate(selectedDateTime),
                    style: TextStyle(
                      fontSize: 32 * scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 32 * scale,
                  color: Colors.black,
                  weight: 900,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TimePickerButton extends StatelessWidget {
  final DateTime selectedDateTime;
  final double scale;
  final VoidCallback onTap;
  final bool isHovering;
  final bool isPressed;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  const TimePickerButton({
    super.key,
    required this.selectedDateTime,
    required this.scale,
    required this.onTap,
    required this.isHovering,
    required this.isPressed,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHoverEnter(),
      onExit: (_) => onHoverExit(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => onTapDown(),
        onTapUp: (_) {
          onTapUp();
          onTap();
        },
        onTapCancel: onTapCancel,
        child: AnimatedScale(
          scale: isPressed ? 0.97 : (isHovering ? 1.02 : 1.0),
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: 24 * scale,
              vertical: 20 * scale,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28 * scale),
              border: Border.all(
                color: Colors.black,
                width: 5 * scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isPressed ? 0.5 : (isHovering ? 0.6 : 0.4)),
                  blurRadius: isPressed ? 6 * scale : (isHovering ? 12 * scale : 8 * scale),
                  offset: Offset(0, isPressed ? 4 * scale : (isHovering ? 8 * scale : 6 * scale)),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 32 * scale,
                  color: Colors.black,
                  weight: 900,
                ),
                SizedBox(width: 16 * scale),
                Expanded(
                  child: Text(
                    _formatTime(selectedDateTime),
                    style: TextStyle(
                      fontSize: 32 * scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 32 * scale,
                  color: Colors.black,
                  weight: 900,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PatientPickerButton extends StatelessWidget {
  final String patientId;
  final double scale;
  final VoidCallback onTap;
  final bool isHovering;
  final bool isPressed;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  const PatientPickerButton({
    super.key,
    required this.patientId,
    required this.scale,
    required this.onTap,
    required this.isHovering,
    required this.isPressed,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  Future<String> _formatPatientName(String patientId) async {
    if (patientId.isEmpty) return 'Selectează un pacient';
    return await FirebaseFirestore.instance.collection('patients').doc(patientId).get().then((DocumentSnapshot<Map<String, dynamic>> value) => value.data()?['nume'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHoverEnter(),
      onExit: (_) => onHoverExit(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => onTapDown(),
        onTapUp: (_) {
          onTapUp();
          onTap();
        },
        onTapCancel: onTapCancel,
        child: AnimatedScale(
          scale: isPressed ? 0.97 : (isHovering ? 1.02 : 1.0),
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: 24 * scale,
              vertical: 20 * scale,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28 * scale),
              border: Border.all(
                color: Colors.black,
                width: 5 * scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isPressed ? 0.5 : (isHovering ? 0.6 : 0.4)),
                  blurRadius: isPressed ? 6 * scale : (isHovering ? 12 * scale : 8 * scale),
                  offset: Offset(0, isPressed ? 4 * scale : (isHovering ? 8 * scale : 6 * scale)),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  size: 32 * scale,
                  color: Colors.black,
                  weight: 900,
                ),
                SizedBox(width: 16 * scale),
                Expanded(
                  child: FutureBuilder<String>(
                    future: _formatPatientName(patientId),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? 'Selectează un pacient',
                        style: TextStyle(
                          fontSize: 32 * scale,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      );
                    },
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 32 * scale,
                  color: Colors.black,
                  weight: 900,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProceduraTextField extends StatelessWidget {
  final TextEditingController controller;
  final double scale;

  const ProceduraTextField({
    super.key,
    required this.controller,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.translucent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28 * scale),
          border: Border.all(
            color: Colors.black,
            width: 5 * scale,
          ),
        ),
        child: TextField(
          controller: controller,
          autofocus: false,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          enableInteractiveSelection: true,
          style: TextStyle(
            fontSize: 32 * scale,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Procedură',
            hintStyle: TextStyle(
              fontSize: 32 * scale,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 24 * scale,
              vertical: 20 * scale,
            ),
          ),
        ),
      ),
    );
  }
}

class DurataTextField extends StatelessWidget {
  final TextEditingController controller;
  final double scale;

  const DurataTextField({
    super.key,
    required this.controller,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.translucent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28 * scale),
          border: Border.all(
            color: Colors.black,
            width: 5 * scale,
          ),
        ),
        child: TextField(
          controller: controller,
          autofocus: false,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          enableInteractiveSelection: true,
          style: TextStyle(
            fontSize: 32 * scale,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Durată (minute)',
            hintStyle: TextStyle(
              fontSize: 32 * scale,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 24 * scale,
              vertical: 20 * scale,
            ),
          ),
        ),
      ),
    );
  }
}

class NotificareCheckbox extends StatelessWidget {
  final bool notificare;
  final double scale;
  final VoidCallback onTap;

  const NotificareCheckbox({
    super.key,
    required this.notificare,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 20 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28 * scale),
            border: Border.all(
              color: Colors.black,
              width: 5 * scale,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40 * scale,
                height: 40 * scale,
                decoration: BoxDecoration(
                  color: notificare ? Colors.green[600] : Colors.white,
                  borderRadius: BorderRadius.circular(12 * scale),
                  border: Border.all(
                    color: Colors.black,
                    width: 4 * scale,
                  ),
                ),
                child: notificare
                    ? Icon(
                        Icons.check,
                        size: 28 * scale,
                        color: Colors.white,
                        weight: 900,
                      )
                    : null,
              ),
              SizedBox(width: 16 * scale),
              Text(
                'Notificare',
                style: TextStyle(
                  fontSize: 32 * scale,
                  fontWeight: FontWeight.w600,
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

class SkipDateCheckbox extends StatelessWidget {
  final bool dateSkipped;
  final double scale;
  final VoidCallback onTap;

  const SkipDateCheckbox({
    super.key,
    required this.dateSkipped,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        onEnter: (_) {},
        onExit: (_) {},
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 20 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28 * scale),
            border: Border.all(
              color: Colors.black,
              width: 5 * scale,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50 * scale,
                height: 50 * scale,
                decoration: BoxDecoration(
                  color: dateSkipped ? Colors.orange[600] : Colors.white,
                  borderRadius: BorderRadius.circular(16 * scale),
                  border: Border.all(
                    color: Colors.black,
                    width: 5 * scale,
                  ),
                ),
                child: dateSkipped
                    ? Icon(
                        Icons.check,
                        size: 36 * scale,
                        color: Colors.white,
                        weight: 900,
                      )
                    : null,
              ),
              SizedBox(width: 20 * scale),
              Text(
                'Fără dată',
                style: TextStyle(
                  fontSize: 36 * scale,
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
            size: 32 * scale,
            color: Colors.orange[800],
          ),
          SizedBox(width: 16 * scale),
          Expanded(
            child: Text(
              'Consultația va fi adăugată în istoric fără dată.',
              style: TextStyle(
                fontSize: 28 * scale,
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

