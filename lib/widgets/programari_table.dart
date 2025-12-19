import 'package:flutter/material.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/utils/date_formatters.dart';

class ProgramariTable extends StatelessWidget {
  final List<Programare> programari;
  final double scale;
  final Function(Programare programare) onEdit;
  final Function(Programare programare) onDelete;
  final bool showDeleteButton;
  final bool showVerticalBar;

  const ProgramariTable({
    super.key,
    required this.programari,
    required this.scale,
    required this.onEdit,
    required this.onDelete,
    this.showDeleteButton = true,
    this.showVerticalBar = true,
  });

  @override
  Widget build(BuildContext context) {
    // Sort programari in reverse chronological order (newest first)
    final sortedProgramari = List<Programare>.from(programari)
      ..sort((a, b) => b.programareTimestamp.compareTo(a.programareTimestamp));

    if (sortedProgramari.isEmpty) {
      return Center(
        child: Text(
          'Nu există programări',
          style: TextStyle(
            fontSize: 32 * scale,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header row
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12 * scale),
              topRight: Radius.circular(12 * scale),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 24 * scale,
            vertical: 18 * scale,
          ),
          child: Row(
            children: [
              if (showDeleteButton) ...[
                SizedBox(
                  width: 60 * scale,
                  child: Text(
                    '',
                    style: TextStyle(
                      fontSize: 32 * scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(width: 20 * scale),
              ],
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Text(
                      'Data',
                      style: TextStyle(
                        fontSize: 32 * scale,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 24 * scale),
                    Text(
                      'Ora',
                      style: TextStyle(
                        fontSize: 32 * scale,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 7,
                child: Text(
                  'Procedură',
                  style: TextStyle(
                    fontSize: 32 * scale,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(
                width: 96 * scale,
                child: Center(
                  child: Text(
                    'Durată',
                    style: TextStyle(
                      fontSize: 28 * scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Data rows
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: sortedProgramari.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Colors.black26,
            ),
            itemBuilder: (context, index) {
              final programare = sortedProgramari[index];
              final programareDate = programare.programareTimestamp.toDate();
              final isEpochDate = programareDate.year == 1970 && 
                                  programareDate.month == 1 && 
                                  programareDate.day == 1;
              
              final bool hasNotification = programare.programareNotification == true;
              
              return Container(
                decoration: showVerticalBar ? BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: hasNotification ? Colors.green[600]! : Colors.red[600]!,
                      width: 8 * scale,
                    ),
                  ),
                ) : null,
                padding: EdgeInsets.symmetric(
                  horizontal: 24 * scale,
                  vertical: 18 * scale,
                ),
                child: Row(
                  children: [
                    // Delete button
                    if (showDeleteButton) ...[
                      SizedBox(
                        width: 60 * scale,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => onDelete(programare),
                            child: Container(
                              width: 40 * scale,
                              height: 40 * scale,
                              decoration: BoxDecoration(
                                color: Colors.red[600],
                                borderRadius: BorderRadius.circular(8 * scale),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 3 * scale,
                                ),
                              ),
                              child: Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 24 * scale,
                                weight: 900,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20 * scale),
                    ],
                    // Date + Time (clickable) - show empty if epoch date
                    Expanded(
                      flex: 5,
                      child: isEpochDate
                          ? SizedBox.shrink()
                          : MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => onEdit(programare),
                                child: Row(
                                  children: [
                                    Text(
                                      DateFormatters.formatDateShort(programare.programareTimestamp),
                                      style: TextStyle(
                                        fontSize: 28 * scale,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(width: 24 * scale),
                                    Text(
                                      DateFormatters.formatTime(programare.programareTimestamp),
                                      style: TextStyle(
                                        fontSize: 28 * scale,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    // Procedura (clickable)
                    Expanded(
                      flex: 7,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => onEdit(programare),
                          child: Text(
                            programare.programareText,
                            style: TextStyle(
                              fontSize: 28 * scale,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 96 * scale,
                      child: Center(
                        child: Text(
                          programare.durata != null ? '${programare.durata} min' : '-',
                          style: TextStyle(
                            fontSize: 28 * scale,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

