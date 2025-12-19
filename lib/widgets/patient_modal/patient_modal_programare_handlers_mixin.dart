import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/services/patient_service.dart';
import 'package:liu_stoma/widgets/patient_modal.dart';

/// Mixin providing programare (appointment) handling logic
mixin PatientModalProgramareHandlersMixin on State<PatientModal> {
  // These getters/setters must be implemented by the state class
  bool get showAddProgramareModal;
  set showAddProgramareModal(bool value);

  bool get showRetroactiveProgramareModal;
  set showRetroactiveProgramareModal(bool value);

  bool get showEditProgramareModal;
  set showEditProgramareModal(bool value);

  Programare? get programareToEdit;
  set programareToEdit(Programare? value);

  Programare? get programareToDelete;
  set programareToDelete(Programare? value);

  List<Programare> get expiredProgramari;

  bool get showOverlapConfirmation;
  set showOverlapConfirmation(bool value);

  DateTime? get pendingAddDateTime;
  set pendingAddDateTime(DateTime? value);

  String? get pendingAddProcedura;
  set pendingAddProcedura(String? value);

  bool? get pendingAddNotificare;
  set pendingAddNotificare(bool? value);

  int? get pendingAddDurata;
  set pendingAddDurata(int? value);

  String? get pendingAddPatientId;
  set pendingAddPatientId(String? value);

  String? get notificationMessage;
  set notificationMessage(String? value);

  bool? get notificationIsSuccess;
  set notificationIsSuccess(bool? value);

  String? getEffectivePatientId();
  VoidCallback get onAddProgramareCallback;

  void showDeleteConfirmation(Programare programare) {
    setState(() {
      programareToDelete = programare;
    });
  }

  Future<void> deleteProgramare(Programare programare) async {
    final patientId = getEffectivePatientId();
    if (patientId == null) return;

    final isConsultatie = expiredProgramari.any((p) =>
        p.programareText == programare.programareText &&
        p.programareTimestamp == programare.programareTimestamp &&
        p.programareNotification == programare.programareNotification);

    setState(() {
      programareToDelete = null;
    });

    final result = await PatientService.deleteProgramare(
      patientId: patientId,
      programare: programare,
    );

    setState(() {
      if (result.success) {
        notificationMessage = isConsultatie
            ? 'Consultație ștearsă cu succes!'
            : 'Programare ștearsă cu succes!';
        notificationIsSuccess = true;
      } else {
        notificationMessage = result.errorMessage ?? 'Eroare la ștergere';
        notificationIsSuccess = false;
      }
    });

    if (result.success) {
      onAddProgramareCallback();
    }
  }

  Future<void> handleSaveAddProgramare(
      String procedura, Timestamp timestamp, bool notificare, int? durata) async {
    final patientId = getEffectivePatientId();
    if (patientId == null) return;

    final newDateTime = timestamp.toDate();
    final durataValue = durata ?? 60;

    final hasOverlap = await PatientService.checkOverlapWithAllAppointments(
      newDateTime: newDateTime,
      newDurata: durataValue,
    );

    if (hasOverlap) {
      setState(() {
        pendingAddDateTime = newDateTime;
        pendingAddProcedura = procedura;
        pendingAddNotificare = notificare;
        pendingAddDurata = durataValue;
        pendingAddPatientId = patientId;
        showOverlapConfirmation = true;
      });
    } else {
      final result = await PatientService.addProgramare(
        patientId: patientId,
        procedura: procedura,
        timestamp: timestamp,
        notificare: notificare,
        durata: durataValue,
      );

      setState(() {
        if (result.success) {
          notificationMessage = 'Programare adăugată cu succes!';
          notificationIsSuccess = true;
          showAddProgramareModal = false;
        } else {
          notificationMessage = result.errorMessage ?? 'Eroare la salvare';
          notificationIsSuccess = false;
        }
      });

      if (result.success) {
        onAddProgramareCallback();
      }
    }
  }

  Future<void> handleSaveRetroactiveProgramare(
      String procedura, Timestamp timestamp, bool notificare, int? durata) async {
    final patientId = getEffectivePatientId();
    if (patientId == null) return;

    final newDateTime = timestamp.toDate();
    final durataValue = durata ?? 60;

    final isDateSkipped = newDateTime.year == 1970 &&
        newDateTime.month == 1 &&
        newDateTime.day == 1;

    final hasOverlap = !isDateSkipped &&
        await PatientService.checkOverlapWithAllAppointments(
          newDateTime: newDateTime,
          newDurata: durataValue,
        );

    if (hasOverlap) {
      setState(() {
        pendingAddDateTime = newDateTime;
        pendingAddProcedura = procedura;
        pendingAddNotificare = notificare;
        pendingAddDurata = durataValue;
        pendingAddPatientId = patientId;
        showOverlapConfirmation = true;
      });
    } else {
      final result = await PatientService.addProgramare(
        patientId: patientId,
        procedura: procedura,
        timestamp: timestamp,
        notificare: notificare,
        durata: durataValue,
      );

      setState(() {
        if (result.success) {
          notificationMessage = 'Consultație adăugată cu succes!';
          notificationIsSuccess = true;
          showRetroactiveProgramareModal = false;
        } else {
          notificationMessage = result.errorMessage ?? 'Eroare la salvare';
          notificationIsSuccess = false;
        }
      });

      if (result.success) {
        onAddProgramareCallback();
      }
    }
  }

  Future<void> handleSaveEditProgramare(
      String procedura, Timestamp timestamp, bool notificare, int? durata) async {
    print('[PatientModal] handleSaveEditProgramare called');
    print('[PatientModal] Received durata: $durata (type: ${durata.runtimeType})');
    print('[PatientModal] programareToEdit: ${programareToEdit?.programareText}');
    print('[PatientModal] programareToEdit.durata: ${programareToEdit?.durata}');

    final programareToEditLocal = programareToEdit;
    final patientId = getEffectivePatientId();

    if (programareToEditLocal == null) {
      print('[PatientModal] ERROR: programareToEdit is null at start of function');
      setState(() {
        notificationMessage = 'Eroare: Programarea nu a fost găsită';
        notificationIsSuccess = false;
      });
      return;
    }

    if (patientId == null) {
      print('[PatientModal] ERROR: patientId is null');
      setState(() {
        notificationMessage = 'Eroare: ID-ul pacientului lipsește';
        notificationIsSuccess = false;
      });
      return;
    }

    final editedDateTime = timestamp.toDate();
    final durataValue = durata ?? 60;
    print('[PatientModal] durataValue after default: $durataValue');

    final isDateSkipped = editedDateTime.year == 1970 &&
        editedDateTime.month == 1 &&
        editedDateTime.day == 1;

    print('[PatientModal] Checking overlap...');
    final hasOverlap = !isDateSkipped &&
        await PatientService.checkOverlapWithAllAppointments(
          newDateTime: editedDateTime,
          newDurata: durataValue,
          excludePatientId: patientId,
          excludeProgramare: programareToEditLocal,
        );
    print('[PatientModal] Has overlap: $hasOverlap');

    if (hasOverlap) {
      setState(() {
        pendingAddDateTime = editedDateTime;
        pendingAddProcedura = procedura;
        pendingAddNotificare = notificare;
        pendingAddDurata = durataValue;
        pendingAddPatientId = patientId;
        showOverlapConfirmation = true;
      });
    } else {
      print('[PatientModal] No overlap, calling updateProgramare with durataValue: $durataValue');
      await updateProgramare(
          programareToEditLocal, procedura, timestamp, notificare, durataValue);
    }
  }

  Future<void> handleOverlapConfirmation() async {
    print('[PatientModal] handleOverlapConfirmation called');
    print('[PatientModal] pendingAddDurata: $pendingAddDurata');
    print('[PatientModal] programareToEdit: ${programareToEdit?.programareText}');

    final pendingDateTime = pendingAddDateTime;
    final pendingProcedura = pendingAddProcedura;
    final pendingNotificare = pendingAddNotificare;
    final pendingPatientId = pendingAddPatientId;
    final pendingDurata = pendingAddDurata;
    final programareToEditLocal = programareToEdit;

    if (pendingDateTime != null &&
        pendingProcedura != null &&
        pendingNotificare != null &&
        pendingPatientId != null) {
      final timestamp = Timestamp.fromDate(pendingDateTime);
      final durataValue = pendingDurata ?? 60;
      print('[PatientModal] durataValue after default: $durataValue');

      if (programareToEditLocal != null) {
        print('[PatientModal] Updating programare after overlap confirmation');
        await updateProgramare(
          programareToEditLocal,
          pendingProcedura,
          timestamp,
          pendingNotificare,
          durataValue,
        );
      } else {
        print('[PatientModal] Adding new programare after overlap confirmation');
        final result = await PatientService.addProgramare(
          patientId: pendingPatientId,
          procedura: pendingProcedura,
          timestamp: timestamp,
          notificare: pendingNotificare,
          durata: durataValue,
        );

        setState(() {
          if (result.success) {
            notificationMessage = showRetroactiveProgramareModal
                ? 'Consultație adăugată cu succes!'
                : 'Programare adăugată cu succes!';
            notificationIsSuccess = true;
            showAddProgramareModal = false;
            showRetroactiveProgramareModal = false;
          } else {
            notificationMessage = result.errorMessage ?? 'Eroare la salvare';
            notificationIsSuccess = false;
          }
        });

        if (result.success) {
          onAddProgramareCallback();
        }
      }

      setState(() {
        showOverlapConfirmation = false;
        pendingAddDateTime = null;
        pendingAddProcedura = null;
        pendingAddNotificare = null;
        pendingAddDurata = null;
        pendingAddPatientId = null;
      });
    }
  }

  void handleCancelOverlap() {
    setState(() {
      showOverlapConfirmation = false;
      pendingAddDateTime = null;
      pendingAddProcedura = null;
      pendingAddNotificare = null;
      pendingAddDurata = null;
      pendingAddPatientId = null;
    });
  }

  Future<void> updateProgramare(Programare oldProgramare, String procedura,
      Timestamp timestamp, bool notificare, int? durata) async {
    print('[PatientModal] updateProgramare called');
    print('[PatientModal] oldProgramare.durata: ${oldProgramare.durata}');
    print('[PatientModal] durata parameter: $durata');

    final patientId = getEffectivePatientId();
    if (patientId == null) {
      print('[PatientModal] Early return: patientId is null');
      return;
    }

    print('[PatientModal] Calling PatientService.updateProgramare...');
    final result = await PatientService.updateProgramare(
      patientId: patientId,
      oldProgramare: oldProgramare,
      procedura: procedura,
      timestamp: timestamp,
      notificare: notificare,
      durata: durata,
    );
    print('[PatientModal] PatientService.updateProgramare result: success=${result.success}');

    setState(() {
      showEditProgramareModal = false;
      programareToEdit = null;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          if (result.success) {
            notificationMessage = 'Programare actualizată cu succes!';
            notificationIsSuccess = true;
          } else {
            notificationMessage = result.errorMessage ?? 'Eroare la actualizare';
            notificationIsSuccess = false;
          }
        });
      }
    });

    if (result.success) {
      onAddProgramareCallback();
    }
  }
}

