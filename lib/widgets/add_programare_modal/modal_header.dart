import 'package:flutter/material.dart';

class AddProgramareModalHeader extends StatelessWidget {
  final double scale;
  final bool isEditing;
  final bool isRetroactive;
  final String? patientName;

  const AddProgramareModalHeader({
    super.key,
    required this.scale,
    required this.isEditing,
    required this.isRetroactive,
    this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          isEditing
              ? (isRetroactive ? 'Editează extra' : 'Editează programare')
              : (isRetroactive ? 'Adaugă extra' : 'Adaugă programare'),
          style: TextStyle(
            fontSize: 48 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        if (patientName != null && patientName!.isNotEmpty) ...[
          SizedBox(height: 16 * scale),
          Text(
            patientName!,
            style: TextStyle(
              fontSize: 36 * scale,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

