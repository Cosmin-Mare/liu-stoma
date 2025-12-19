import 'package:flutter/material.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/widgets/programari_table.dart';
import 'package:liu_stoma/pages/programare_details_page.dart';

class ProgramariTab extends StatelessWidget {
  final List<Programare> activeProgramari;
  final String patientId;
  final double scale;
  final VoidCallback onRefresh;
  final Function(String message, bool isSuccess)? onNotification;

  const ProgramariTab({
    super.key,
    required this.activeProgramari,
    required this.patientId,
    required this.scale,
    required this.onRefresh,
    this.onNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(24 * scale),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(44 * scale),
                border: Border.all(
                  color: Colors.black,
                  width: 7 * scale,
                ),
              ),
              child: ProgramariTable(
                programari: activeProgramari,
                scale: scale * 1.8,
                showDeleteButton: false,
                showVerticalBar: true,
                onEdit: (Programare programare) async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProgramareDetailsPage(
                        programare: programare,
                        patientId: patientId,
                        scale: scale,
                        isConsultatie: false,
                        onNotification: onNotification,
                      ),
                    ),
                  );
                  if (result == true) {
                    onRefresh();
                  }
                },
                onDelete: (Programare programare) {
                  // Delete handled by parent
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(24 * scale),
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProgramareDetailsPage(
                    programare: null,
                    patientId: patientId,
                    scale: scale,
                    isConsultatie: false,
                    onNotification: onNotification,
                  ),
                ),
              );
              if (result == true) {
                onRefresh();
              }
            },
            icon: Icon(Icons.add_circle_outline, size: 72 * scale),
            label: Text(
              'Adaugă programare',
              style: TextStyle(
                fontSize: 54 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 60 * scale,
                vertical: 36 * scale,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(36 * scale),
                side: BorderSide(color: Colors.black, width: 6 * scale),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

