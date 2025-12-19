import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/widgets/add_programare_modal.dart';
import 'package:liu_stoma/widgets/custom_notification.dart';
import 'package:liu_stoma/widgets/confirm_dialog.dart';
import 'package:liu_stoma/widgets/delete_patient_dialog.dart';
import 'package:liu_stoma/services/patient_service.dart';
import 'package:liu_stoma/services/file_service.dart';

class PatientDetailsOverlays extends StatefulWidget {
  final bool showAddProgramareModal;
  final bool showRetroactiveProgramareModal;
  final bool showEditProgramareModal;
  final bool showDeletePatientConfirmation;
  final List<Programare> expiredProgramari;
  final Programare? programareToEdit;
  final Programare? programareToDelete;
  final PatientFile? fileToDelete;
  final String? notificationMessage;
  final bool? notificationIsSuccess;
  final String patientId;
  final double scale;
  final VoidCallback onRefresh;
  final Function(bool) onSetShowAddProgramareModal;
  final Function(bool) onSetShowRetroactiveProgramareModal;
  final Function(bool) onSetShowEditProgramareModal;
  final Function(bool) onSetShowDeletePatientConfirmation;
  final Function(Programare?) onSetProgramareToEdit;
  final Function(Programare?) onSetProgramareToDelete;
  final Function(PatientFile?) onSetFileToDelete;
  final Function(String?, bool?) onNotification;
  final Future<void> Function() onDeletePatient;
  final Future<void> Function(PatientFile) onDeleteFile;

  const PatientDetailsOverlays({
    super.key,
    required this.showAddProgramareModal,
    required this.showRetroactiveProgramareModal,
    required this.showEditProgramareModal,
    required this.showDeletePatientConfirmation,
    required this.expiredProgramari,
    this.programareToEdit,
    this.programareToDelete,
    this.fileToDelete,
    this.notificationMessage,
    this.notificationIsSuccess,
    required this.patientId,
    required this.scale,
    required this.onRefresh,
    required this.onSetShowAddProgramareModal,
    required this.onSetShowRetroactiveProgramareModal,
    required this.onSetShowEditProgramareModal,
    required this.onSetShowDeletePatientConfirmation,
    required this.onSetProgramareToEdit,
    required this.onSetProgramareToDelete,
    required this.onSetFileToDelete,
    required this.onNotification,
    required this.onDeletePatient,
    required this.onDeleteFile,
  });

  @override
  State<PatientDetailsOverlays> createState() => _PatientDetailsOverlaysState();
}

class _PatientDetailsOverlaysState extends State<PatientDetailsOverlays> {
  bool _showOverlapConfirmation = false;
  DateTime? _pendingAddDateTime;
  List<Procedura>? _pendingAddProceduri;
  bool? _pendingAddNotificare;
  int? _pendingAddDurata;
  double? _pendingAddTotalOverride;
  double? _pendingAddAchitat;

  Future<void> _updateProgramare(Programare oldProgramare, List<Procedura> proceduri, Timestamp timestamp, bool notificare, int? durata, double? totalOverride, double achitat) async {
    final result = await PatientService.updateProgramare(
      patientId: widget.patientId,
      oldProgramare: oldProgramare,
      proceduri: proceduri,
      timestamp: timestamp,
      notificare: notificare,
      durata: durata,
      totalOverride: totalOverride,
      achitat: achitat,
    );

    widget.onSetShowEditProgramareModal(false);
    widget.onSetProgramareToEdit(null);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (result.success) {
        widget.onNotification('Programare actualizată cu succes!', true);
      } else {
        widget.onNotification(result.errorMessage ?? 'Eroare la actualizare', false);
      }
    });
  }

  Future<void> _deleteProgramare(Programare programare) async {
    widget.onSetProgramareToDelete(null);

    final result = await PatientService.deleteProgramare(
      patientId: widget.patientId,
      programare: programare,
    );

    if (result.success) {
      final isConsultatie = widget.expiredProgramari.any((p) =>
        p.displayText == programare.displayText &&
        p.programareTimestamp == programare.programareTimestamp &&
        p.programareNotification == programare.programareNotification
      );
      widget.onNotification(
        isConsultatie 
            ? 'Extra șters cu succes!' 
            : 'Programare ștearsă cu succes!',
        true,
      );
    } else {
      widget.onNotification(result.errorMessage ?? 'Eroare la ștergere', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.showAddProgramareModal)
          AddProgramareModal(
            scale: widget.scale,
            shouldCloseAfterSave: false, // Don't auto-close, we'll close it after overlap confirmation
            onClose: () {
              widget.onSetShowAddProgramareModal(false);
            },
            onValidationError: (String errorMessage) {
              widget.onNotification(errorMessage, false);
            },
            onSave: (List<Procedura> proceduri, Timestamp timestamp, bool notificare, int? durata, double? totalOverride, double achitat) async {
              // Check for overlaps before saving - check against ALL appointments from ALL patients
              final newDateTime = timestamp.toDate();
              // Ensure durata defaults to 60 minutes if null
              final durataValue = durata ?? 60;
              
              // Skip overlap check for consultations without dates (epoch date)
              final isDateSkipped = newDateTime.year == 1970 && 
                                    newDateTime.month == 1 && 
                                    newDateTime.day == 1;
              
              final hasOverlap = !isDateSkipped && await PatientService.checkOverlapWithAllAppointments(
                newDateTime: newDateTime,
                newDurata: durataValue,
              );
              
              if (hasOverlap) {
                setState(() {
                  _pendingAddDateTime = newDateTime;
                  _pendingAddProceduri = proceduri;
                  _pendingAddNotificare = notificare;
                  _pendingAddDurata = durataValue;
                  _pendingAddTotalOverride = totalOverride;
                  _pendingAddAchitat = achitat;
                  _showOverlapConfirmation = true;
                });
                // Modal stays open - will close after user confirms overlap
              } else {
                // No overlap, save and close immediately
                final result = await PatientService.addProgramare(
                  patientId: widget.patientId,
                  proceduri: proceduri,
                  timestamp: timestamp,
                  notificare: notificare,
                  durata: durataValue,
                  totalOverride: totalOverride,
                  achitat: achitat,
                );

                if (result.success) {
                  widget.onNotification('Programare adăugată cu succes!', true);
                  widget.onSetShowAddProgramareModal(false);
                } else {
                  widget.onNotification(result.errorMessage ?? 'Eroare la salvare', false);
                }
              }
            },
          ),
        // Overlap Confirmation Dialog for adding
        if (_showOverlapConfirmation)
          ConfirmDialog(
            title: 'Confirmă suprapunerea',
            message: 'Această programare se suprapune cu o altă programare. Ești sigură că vrei să continui?',
            confirmText: 'Salvează',
            cancelText: 'Anulează',
            scale: widget.scale,
            onConfirm: () async {
              if (_pendingAddDateTime != null && 
                  _pendingAddProceduri != null && 
                  _pendingAddNotificare != null) {
                final timestamp = Timestamp.fromDate(_pendingAddDateTime!);
                // Ensure durata defaults to 60 minutes if null
                final durataValue = _pendingAddDurata ?? 60;
                final result = await PatientService.addProgramare(
                  patientId: widget.patientId,
                  proceduri: _pendingAddProceduri!,
                  timestamp: timestamp,
                  notificare: _pendingAddNotificare!,
                  durata: durataValue,
                  totalOverride: _pendingAddTotalOverride,
                  achitat: _pendingAddAchitat ?? 0.0,
                );

                setState(() {
                  _showOverlapConfirmation = false;
                  _pendingAddDateTime = null;
                  _pendingAddProceduri = null;
                  _pendingAddNotificare = null;
                  _pendingAddDurata = null;
                  _pendingAddTotalOverride = null;
                  _pendingAddAchitat = null;
                });

                if (result.success) {
                  widget.onNotification('Programare adăugată cu succes!', true);
                  widget.onSetShowAddProgramareModal(false);
                } else {
                  widget.onNotification(result.errorMessage ?? 'Eroare la salvare', false);
                }
              }
            },
            onCancel: () {
              // Just close the overlap confirmation, keep the add modal open
              setState(() {
                _showOverlapConfirmation = false;
                _pendingAddDateTime = null;
                _pendingAddProceduri = null;
                _pendingAddNotificare = null;
                _pendingAddDurata = null;
                _pendingAddTotalOverride = null;
                _pendingAddAchitat = null;
              });
            },
          ),
        if (widget.showRetroactiveProgramareModal)
          AddProgramareModal(
            scale: widget.scale,
            isRetroactive: true,
            onClose: () {
              widget.onSetShowRetroactiveProgramareModal(false);
            },
            onValidationError: (String errorMessage) {
              widget.onNotification(errorMessage, false);
            },
            onSave: (List<Procedura> proceduri, Timestamp timestamp, bool notificare, int? durata, double? totalOverride, double achitat) async {
              final result = await PatientService.addProgramare(
                patientId: widget.patientId,
                proceduri: proceduri,
                timestamp: timestamp,
                notificare: notificare,
                durata: durata,
                totalOverride: totalOverride,
                achitat: achitat,
              );

              if (result.success) {
                widget.onNotification('Extra adăugat cu succes!', true);
                widget.onSetShowRetroactiveProgramareModal(false);
              } else {
                widget.onNotification(result.errorMessage ?? 'Eroare la salvare', false);
              }
            },
          ),
        if (widget.showEditProgramareModal && widget.programareToEdit != null)
          AddProgramareModal(
            scale: widget.scale,
            initialProgramare: widget.programareToEdit,
            patientId: widget.patientId, // Enable autosave
            isRetroactive: () {
              final isFromHistory = widget.expiredProgramari.any((p) =>
                p.displayText == widget.programareToEdit!.displayText &&
                p.programareTimestamp == widget.programareToEdit!.programareTimestamp &&
                p.programareNotification == widget.programareToEdit!.programareNotification
              );

              if (isFromHistory) return true;

              final programareDate = widget.programareToEdit!.programareTimestamp.toDate();
              return programareDate.year == 1970 && 
                     programareDate.month == 1 && 
                     programareDate.day == 1;
            }(),
            onClose: () {
              widget.onSetShowEditProgramareModal(false);
              widget.onSetProgramareToEdit(null);
            },
            onValidationError: (String errorMessage) {
              widget.onNotification(errorMessage, false);
            },
            onSave: (List<Procedura> proceduri, Timestamp timestamp, bool notificare, int? durata, double? totalOverride, double achitat) async {
              // Ensure durata defaults to 60 minutes if null
              final durataValue = durata ?? 60;
              await _updateProgramare(widget.programareToEdit!, proceduri, timestamp, notificare, durataValue, totalOverride, achitat);
            },
            onDelete: () async {
              await _deleteProgramare(widget.programareToEdit!);
              widget.onSetShowEditProgramareModal(false);
              widget.onSetProgramareToEdit(null);
            },
          ),
        if (widget.showDeletePatientConfirmation)
          DeletePatientDialog(
            scale: widget.scale,
            onCancel: () {
              widget.onSetShowDeletePatientConfirmation(false);
            },
            onConfirm: widget.onDeletePatient,
          ),
        if (widget.programareToDelete != null)
          ConfirmDialog(
            title: 'Confirmă ștergerea',
            message: () {
              final isConsultatie = widget.expiredProgramari.any((p) =>
                p.displayText == widget.programareToDelete!.displayText &&
                p.programareTimestamp == widget.programareToDelete!.programareTimestamp &&
                p.programareNotification == widget.programareToDelete!.programareNotification
              );
              return isConsultatie 
                  ? 'Ești sigură că vrei să ștergi acest extra?' 
                  : 'Ești sigură că vrei să ștergi această programare?';
            }(),
            confirmText: 'Șterge',
            cancelText: 'Anulează',
            scale: widget.scale,
            onConfirm: () {
              _deleteProgramare(widget.programareToDelete!);
            },
            onCancel: () {
              widget.onSetProgramareToDelete(null);
            },
          ),
        if (widget.fileToDelete != null)
          ConfirmDialog(
            title: 'Confirmă ștergerea',
            message: 'Ești sigură că vrei să ștergi fișierul "${widget.fileToDelete!.name}"?',
            confirmText: 'Șterge',
            cancelText: 'Anulează',
            scale: widget.scale,
            onConfirm: () {
              widget.onDeleteFile(widget.fileToDelete!);
            },
            onCancel: () {
              widget.onSetFileToDelete(null);
            },
          ),
        if (widget.notificationMessage != null && widget.notificationIsSuccess != null)
          CustomNotification(
            message: widget.notificationMessage!,
            isSuccess: widget.notificationIsSuccess!,
            scale: widget.scale,
            onDismiss: () {
              widget.onNotification(null, null);
            },
          ),
      ],
    );
  }
}
