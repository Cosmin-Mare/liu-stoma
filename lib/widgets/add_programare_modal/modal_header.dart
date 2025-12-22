import 'package:flutter/material.dart';
import 'package:liu_stoma/pacienti_page.dart';
import 'package:liu_stoma/widgets/add_programare_modal/form_fields.dart';

class AddProgramareModalHeader extends StatefulWidget {
  final double scale;
  final bool isEditing;
  final bool isRetroactive;
  final String? patientName;
  final String? patientId;
  final Function(String patientId) onPatientIdChange;
  const AddProgramareModalHeader({
    super.key,
    required this.scale,
    required this.isEditing,
    required this.isRetroactive,
    this.patientId,
    this.patientName,
    required this.onPatientIdChange,
  });

  @override
  State<AddProgramareModalHeader> createState() => _AddProgramareModalHeaderState();
}

class _AddProgramareModalHeaderState extends State<AddProgramareModalHeader> {
  bool _patientPickerButtonHovering = false;
  bool _patientPickerButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.isEditing
              ? (widget.isRetroactive ? 'Editează extra' : 'Editează programare')
              : (widget.isRetroactive ? 'Adaugă extra' : 'Adaugă programare'),
          style: TextStyle(
            fontSize: 48 * widget.scale,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.patientName != null && widget.patientName!.isNotEmpty) ...[
          SizedBox(height: 16 * widget.scale),
          Text(
            widget.patientName!,
            style: TextStyle(
              fontSize: 36 * widget.scale,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ]
        else ...[
          PatientPickerButton(
            patientId: widget.patientId ?? '',
            isHovering: _patientPickerButtonHovering,
            isPressed: _patientPickerButtonPressed,
            onHoverEnter: () {
              if (!_patientPickerButtonHovering) {
                setState(() => _patientPickerButtonHovering = true);
              }
            },
            onHoverExit: () {
              if (_patientPickerButtonHovering) {
                setState(() => _patientPickerButtonHovering = false);
              }
            },
            onTapDown: () {
              if (!_patientPickerButtonPressed) {
                setState(() => _patientPickerButtonPressed = true);
              }
            },
            onTapUp: () {
              if (_patientPickerButtonPressed) {
                setState(() => _patientPickerButtonPressed = false);
              }
            },
            onTapCancel: () {
              if (_patientPickerButtonPressed) {
                setState(() => _patientPickerButtonPressed = false);
              }
            },
            scale: widget.scale,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PacientiPage(isSelectionPage: true)),
              ).then((result) {
                if (result != null) {
                  widget.onPatientIdChange(result as String);
                }
              });
            },
          ),
          SizedBox(height: 16 * widget.scale),
        ],
      ],
    );
  }
}

