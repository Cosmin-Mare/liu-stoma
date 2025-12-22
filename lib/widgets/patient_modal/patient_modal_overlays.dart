import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/widgets/add_programare_modal.dart';
import 'package:liu_stoma/widgets/confirm_dialog.dart';
import 'package:liu_stoma/widgets/custom_notification.dart';
import 'package:liu_stoma/widgets/delete_patient_dialog.dart';
import 'package:liu_stoma/widgets/patient_files_modal.dart';
import 'package:liu_stoma/widgets/patient_modal/patient_history_modal.dart';

class PatientModalOverlays extends StatelessWidget {
  final double scale;
  final bool isAddMode;
  final String? patientId;
  final bool showAddProgramareModal;
  final bool showRetroactiveProgramareModal;
  final bool showEditProgramareModal;
  final bool showHistoryModal;
  final bool showFilesModal;
  final bool showDeletePatientConfirmation;
  final bool showOverlapConfirmation;
  final Programare? programareToEdit;
  final Programare? programareToDelete;
  final List<Programare> expiredProgramari;
  final DateTime? pendingAddDateTime;
  final List<Procedura>? pendingAddProceduri;
  final bool? pendingAddNotificare;
  final int? pendingAddDurata;
  final String? pendingAddPatientId;
  final String? notificationMessage;
  final bool? notificationIsSuccess;
  final VoidCallback onCloseAddProgramareModal;
  final VoidCallback onCloseRetroactiveProgramareModal;
  final VoidCallback onCloseEditProgramareModal;
  final VoidCallback onCloseHistoryModal;
  final VoidCallback onCloseFilesModal;
  final Function(String) onValidationError;
  final Function(List<Procedura>, Timestamp, bool, int?, double?, double, String?) onSaveAddProgramare;
  final Function(List<Procedura>, Timestamp, bool, int?, double?, double, String?) onSaveRetroactiveProgramare;
  final Function(List<Procedura>, Timestamp, bool, int?, double?, double, String?) onSaveEditProgramare;
  final Function(Programare) onEditProgramare;
  final Function(Programare) onDeleteProgramare;
  final VoidCallback onCancelDeleteProgramare;
  final VoidCallback onAddConsultation;
  final VoidCallback onDeletePatient;
  final VoidCallback onCancelDeletePatient;
  final VoidCallback onConfirmOverlap;
  final VoidCallback onCancelOverlap;
  final VoidCallback onDismissNotification;
  final VoidCallback onAddProgramare;

  const PatientModalOverlays({
    super.key,
    required this.scale,
    required this.isAddMode,
    this.patientId,
    required this.showAddProgramareModal,
    required this.showRetroactiveProgramareModal,
    required this.showEditProgramareModal,
    required this.showHistoryModal,
    required this.showFilesModal,
    required this.showDeletePatientConfirmation,
    required this.showOverlapConfirmation,
    this.programareToEdit,
    this.programareToDelete,
    required this.expiredProgramari,
    this.pendingAddDateTime,
    this.pendingAddProceduri,
    this.pendingAddNotificare,
    this.pendingAddDurata,
    this.pendingAddPatientId,
    this.notificationMessage,
    this.notificationIsSuccess,
    required this.onCloseAddProgramareModal,
    required this.onCloseRetroactiveProgramareModal,
    required this.onCloseEditProgramareModal,
    required this.onCloseHistoryModal,
    required this.onCloseFilesModal,
    required this.onValidationError,
    required this.onSaveAddProgramare,
    required this.onSaveRetroactiveProgramare,
    required this.onSaveEditProgramare,
    required this.onEditProgramare,
    required this.onDeleteProgramare,
    required this.onCancelDeleteProgramare,
    required this.onAddConsultation,
    required this.onDeletePatient,
    required this.onCancelDeletePatient,
    required this.onConfirmOverlap,
    required this.onCancelOverlap,
    required this.onDismissNotification,
    required this.onAddProgramare,
  });

  bool _isRetroactive(Programare programare) {
    final isFromHistory = expiredProgramari.any((p) =>
      p.displayText == programare.displayText &&
      p.programareTimestamp == programare.programareTimestamp &&
      p.programareNotification == programare.programareNotification
    );
    
    if (isFromHistory) return true;
    
    final programareDate = programare.programareTimestamp.toDate();
    return programareDate.year == 1970 && 
           programareDate.month == 1 && 
           programareDate.day == 1;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Add Programare Modal overlay
        if (showAddProgramareModal && !isAddMode)
          AddProgramareModal(
            scale: scale,
            shouldCloseAfterSave: false,
            patientId: patientId,
            onClose: onCloseAddProgramareModal,
            onValidationError: onValidationError,
            onSave: onSaveAddProgramare,
          ),
        // Overlap Confirmation Dialog
       
        // Delete patient confirmation dialog
        if (showDeletePatientConfirmation)
          DeletePatientDialog(
            scale: scale,
            onCancel: onCancelDeletePatient,
            onConfirm: onDeletePatient,
          ),
        // Files Modal overlay
        if (showFilesModal && !isAddMode && patientId != null)
          PatientFilesModal(
            patientId: patientId!,
            scale: scale,
            onClose: onCloseFilesModal,
          ),
        // History Modal overlay
        if (showHistoryModal && !isAddMode)
          PatientHistoryModal(
            scale: scale,
            expiredProgramari: expiredProgramari,
            onEdit: onEditProgramare,
            onDelete: onDeleteProgramare,
            onClose: onCloseHistoryModal,
            onAddConsultation: onAddConsultation,
          ),
        // Add Retroactive Programare Modal overlay
        if (showRetroactiveProgramareModal && !isAddMode)
          AddProgramareModal(
            scale: scale,
            isRetroactive: true,
            shouldCloseAfterSave: false,
            onClose: onCloseRetroactiveProgramareModal,
            onValidationError: onValidationError,
            onSave: onSaveRetroactiveProgramare,
          ),
        // Edit Programare Modal overlay
        if (showEditProgramareModal && programareToEdit != null && !isAddMode)
          AddProgramareModal(
            scale: scale,
            initialProgramare: programareToEdit,
            patientId: patientId, // Enable autosave
            isRetroactive: _isRetroactive(programareToEdit!),
            onClose: onCloseEditProgramareModal,
            onValidationError: onValidationError,
            onSave: onSaveEditProgramare,
            onDelete: () => onDeleteProgramare(programareToEdit!),
          ),
        // Delete programare confirmation dialog
        if (programareToDelete != null)
          ConfirmDialog(
            title: 'Confirmă ștergerea',
            message: () {
              final isConsultatie = expiredProgramari.any((p) =>
                p.displayText == programareToDelete!.displayText &&
                p.programareTimestamp == programareToDelete!.programareTimestamp &&
                p.programareNotification == programareToDelete!.programareNotification
              );
              return isConsultatie 
                  ? 'Ești sigură că vrei să ștergi acest extra?' 
                  : 'Ești sigură că vrei să ștergi această programare?';
            }(),
            confirmText: 'Șterge',
            cancelText: 'Anulează',
            scale: scale,
            onConfirm: () => onDeleteProgramare(programareToDelete!),
            onCancel: onCancelDeleteProgramare,
          ),
        if (showOverlapConfirmation)
        ConfirmDialog(
          title: 'Confirmă suprapunerea',
          message: 'Această programare se suprapune cu o altă programare. Ești sigură că vrei să continui?',
          confirmText: 'Salvează',
          cancelText: 'Anulează',
          scale: scale,
          onConfirm: onConfirmOverlap,
          onCancel: onCancelOverlap,
        ),
        // Custom notification
        if (notificationMessage != null && notificationIsSuccess != null)
          CustomNotification(
            message: notificationMessage!,
            isSuccess: notificationIsSuccess!,
            scale: scale,
            onDismiss: onDismissNotification,
          ),
      ],
    );
  }
}
