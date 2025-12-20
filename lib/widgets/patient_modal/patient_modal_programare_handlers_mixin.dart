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

  List<Procedura>? get pendingAddProceduri;
  set pendingAddProceduri(List<Procedura>? value);

  bool? get pendingAddNotificare;
  set pendingAddNotificare(bool? value);

  int? get pendingAddDurata;
  set pendingAddDurata(int? value);

  double? get pendingAddTotalOverride;
  set pendingAddTotalOverride(double? value);

  double? get pendingAddAchitat;
  set pendingAddAchitat(double? value);

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
        p.displayText == programare.displayText &&
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
            ? 'Extra șters cu succes!'
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
      List<Procedura> proceduri, Timestamp timestamp, bool notificare, int? durata, double? totalOverride, double achitat, String? patientId) async {
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
        pendingAddProceduri = proceduri;
        pendingAddNotificare = notificare;
        pendingAddDurata = durataValue;
        pendingAddTotalOverride = totalOverride;
        pendingAddAchitat = achitat;
        pendingAddPatientId = patientId;
        showOverlapConfirmation = true;
      });
    } else {
      final result = await PatientService.addProgramare(
        patientId: patientId,
        proceduri: proceduri,
        timestamp: timestamp,
        notificare: notificare,
        durata: durataValue,
        totalOverride: totalOverride,
        achitat: achitat,
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
      List<Procedura> proceduri, Timestamp timestamp, bool notificare, int? durata, double? totalOverride, double achitat, String? patientId) async {
    final patientIdLocal = getEffectivePatientId() ?? patientId;
    if (patientIdLocal == null) return;

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
        pendingAddProceduri = proceduri;
        pendingAddNotificare = notificare;
        pendingAddDurata = durataValue;
        pendingAddTotalOverride = totalOverride;
        pendingAddAchitat = achitat;
        pendingAddPatientId = patientIdLocal;
        showOverlapConfirmation = true;
      });
    } else {
      final result = await PatientService.addProgramare(
        patientId: patientIdLocal,
        proceduri: proceduri,
        timestamp: timestamp,
        notificare: notificare,
        durata: durataValue,
        totalOverride: totalOverride,
        achitat: achitat,
      );

      setState(() {
        if (result.success) {
          notificationMessage = 'Extra adăugat cu succes!';
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
      List<Procedura> proceduri, Timestamp timestamp, bool notificare, int? durata, double? totalOverride, double achitat, String? patientId) async {
    print('[PatientModal] handleSaveEditProgramare called');
    print('[PatientModal] Received durata: $durata (type: ${durata.runtimeType})');
    print('[PatientModal] programareToEdit: ${programareToEdit?.displayText}');
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
        pendingAddProceduri = proceduri;
        pendingAddNotificare = notificare;
        pendingAddDurata = durataValue;
        pendingAddTotalOverride = totalOverride;
        pendingAddAchitat = achitat;
        pendingAddPatientId = patientId;
        showOverlapConfirmation = true;
      });
    } else {
      print('[PatientModal] No overlap, calling updateProgramare with durataValue: $durataValue');
      await updateProgramare(
          programareToEditLocal, proceduri, timestamp, notificare, durataValue, totalOverride, achitat);
    }
  }

  Future<void> handleOverlapConfirmation() async {
    print('[PatientModal] handleOverlapConfirmation called');
    print('[PatientModal] pendingAddDurata: $pendingAddDurata');
    print('[PatientModal] programareToEdit: ${programareToEdit?.displayText}');

    final pendingDateTime = pendingAddDateTime;
    final pendingProceduri = pendingAddProceduri;
    final pendingNotificare = pendingAddNotificare;
    final pendingPatientId = pendingAddPatientId;
    final pendingDurata = pendingAddDurata;
    final pendingTotalOverride = pendingAddTotalOverride;
    final pendingAchitat = pendingAddAchitat ?? 0.0;
    final programareToEditLocal = programareToEdit;

    if (pendingDateTime != null &&
        pendingProceduri != null &&
        pendingNotificare != null &&
        pendingPatientId != null) {
      final timestamp = Timestamp.fromDate(pendingDateTime);
      final durataValue = pendingDurata ?? 60;
      print('[PatientModal] durataValue after default: $durataValue');

      if (programareToEditLocal != null) {
        print('[PatientModal] Updating programare after overlap confirmation');
        await updateProgramare(
          programareToEditLocal,
          pendingProceduri,
          timestamp,
          pendingNotificare,
          durataValue,
          pendingTotalOverride,
          pendingAchitat,
        );
      } else {
        print('[PatientModal] Adding new programare after overlap confirmation');
        final result = await PatientService.addProgramare(
          patientId: pendingPatientId,
          proceduri: pendingProceduri,
          timestamp: timestamp,
          notificare: pendingNotificare,
          durata: durataValue,
          totalOverride: pendingTotalOverride,
          achitat: pendingAchitat,
        );

        setState(() {
          if (result.success) {
            notificationMessage = showRetroactiveProgramareModal
                ? 'Extra adăugat cu succes!'
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
        pendingAddProceduri = null;
        pendingAddNotificare = null;
        pendingAddDurata = null;
        pendingAddTotalOverride = null;
        pendingAddAchitat = null;
        pendingAddPatientId = null;
      });
    }
  }

  void handleCancelOverlap() {
    setState(() {
      showOverlapConfirmation = false;
      pendingAddDateTime = null;
      pendingAddProceduri = null;
      pendingAddNotificare = null;
      pendingAddDurata = null;
      pendingAddTotalOverride = null;
      pendingAddAchitat = null;
      pendingAddPatientId = null;
    });
  }

  Future<void> updateProgramare(Programare oldProgramare, List<Procedura> proceduri,
      Timestamp timestamp, bool notificare, int? durata, double? totalOverride, double achitat) async {
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
      proceduri: proceduri,
      timestamp: timestamp,
      notificare: notificare,
      durata: durata,
      totalOverride: totalOverride,
      achitat: achitat,
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
