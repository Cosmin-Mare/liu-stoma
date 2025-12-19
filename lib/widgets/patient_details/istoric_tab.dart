import 'package:flutter/material.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/widgets/programari_table.dart';
import 'package:liu_stoma/pages/programare_details_page.dart';

class IstoricTab extends StatelessWidget {
  final List<Programare> expiredProgramari;
  final String patientId;
  final double scale;
  final VoidCallback onRefresh;
  final Function(String message, bool isSuccess)? onNotification;

  const IstoricTab({
    super.key,
    required this.expiredProgramari,
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
            child: expiredProgramari.isEmpty
                ? Center(
                    child: Text(
                      'Nu există consultații în istoric',
                      style: TextStyle(
                        fontSize: 51 * scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28 * scale),
                      border: Border.all(
                        color: Colors.black,
                        width: 3 * scale,
                      ),
                    ),
                    child: ProgramariTable(
                      programari: expiredProgramari,
                      scale: scale * 1.8,
                      showDeleteButton: false,
                      showVerticalBar: false,
                      onEdit: (Programare programare) async {
                        final isConsultatie = expiredProgramari.any((p) =>
                          p.programareText == programare.programareText &&
                          p.programareTimestamp == programare.programareTimestamp &&
                          p.programareNotification == programare.programareNotification
                        );
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProgramareDetailsPage(
                              programare: programare,
                              patientId: patientId,
                              scale: scale,
                              isConsultatie: isConsultatie,
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
                    isConsultatie: true,
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
              'Adaugă consultație',
              style: TextStyle(
                fontSize: 54 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 60 * scale,
                vertical: 36 * scale,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(36 * scale),
                side: BorderSide(color: Colors.black, width: 7 * scale),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

