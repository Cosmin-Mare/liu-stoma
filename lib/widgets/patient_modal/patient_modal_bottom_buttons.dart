import 'package:flutter/material.dart';
import 'package:liu_stoma/widgets/patient_modal/action_button.dart';

class PatientModalBottomButtons extends StatelessWidget {
  final double scale;
  final bool isAddMode;
  final bool hasHistory;
  final VoidCallback? onSave;
  final VoidCallback onDelete;
  final VoidCallback onHistory;
  final VoidCallback onFiles;

  const PatientModalBottomButtons({
    super.key,
    required this.scale,
    required this.isAddMode,
    required this.hasHistory,
    this.onSave,
    required this.onDelete,
    required this.onHistory,
    required this.onFiles,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 40 * scale,
        vertical: 20 * scale,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Save button (for add mode)
          if (isAddMode && onSave != null)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                child: ActionButton(
                  scale: scale,
                  text: 'Salvează',
                  icon: Icons.save,
                  color: Colors.green[600]!,
                  onTap: onSave!,
                  iconSize: 36 * scale,
                  fontSize: 28 * scale,
                ),
              ),
            ),
          // Delete button
          if (!isAddMode)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                child: ActionButton(
                  scale: scale,
                  text: 'Șterge pacient',
                  icon: Icons.delete_outline,
                  color: Colors.red[600]!,
                  onTap: onDelete,
                  iconSize: 36 * scale,
                  fontSize: 28 * scale,
                ),
              ),
            ),
          // History button
          if (!isAddMode && hasHistory)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                child: ActionButton(
                  scale: scale,
                  text: 'Istoric',
                  icon: Icons.history,
                  color: Colors.blue[600]!,
                  onTap: onHistory,
                  iconSize: 32 * scale,
                  fontSize: 24 * scale,
                ),
              ),
            ),
          // Files button
          if (!isAddMode)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10 * scale),
                child: ActionButton(
                  scale: scale,
                  text: 'Fișiere',
                  icon: Icons.folder_outlined,
                  color: Colors.purple[600]!,
                  onTap: onFiles,
                  iconSize: 28 * scale,
                  fontSize: 22 * scale,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

