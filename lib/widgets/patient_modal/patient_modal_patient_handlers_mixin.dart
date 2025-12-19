import 'dart:async';
import 'package:flutter/material.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/utils/patient_validation.dart';
import 'package:liu_stoma/services/patient_service.dart';
import 'package:liu_stoma/widgets/patient_modal.dart';

/// Mixin providing patient save/delete handling logic
mixin PatientModalPatientHandlersMixin on State<PatientModal> {
  // These getters/setters must be implemented by the state class
  TextEditingController get numeController;
  TextEditingController get cnpController;
  TextEditingController get telefonController;
  TextEditingController get emailController;
  TextEditingController get descriereController;

  bool get showDeletePatientConfirmation;
  set showDeletePatientConfirmation(bool value);

  bool get showAddProgramareModal;
  set showAddProgramareModal(bool value);

  bool get showRetroactiveProgramareModal;
  set showRetroactiveProgramareModal(bool value);

  bool get showEditProgramareModal;
  set showEditProgramareModal(bool value);

  bool get showHistoryModal;
  set showHistoryModal(bool value);

  bool get showFilesModal;
  set showFilesModal(bool value);

  bool get showOverlapConfirmation;
  set showOverlapConfirmation(bool value);

  Programare? get programareToEdit;
  set programareToEdit(Programare? value);

  Programare? get programareToDelete;
  set programareToDelete(Programare? value);

  String? get notificationMessage;
  set notificationMessage(String? value);

  bool? get notificationIsSuccess;
  set notificationIsSuccess(bool? value);

  Timer? get autoSaveTimer;
  set autoSaveTimer(Timer? value);

  bool get hasUnsavedChanges;
  set hasUnsavedChanges(bool value);

  String? get createdPatientId;
  set createdPatientId(String? value);

  String? getEffectivePatientId();
  bool isEffectivelyAddMode();
  bool validateFields();
  VoidCallback get onAddProgramareCallback;
  VoidCallback get onCloseCallback;

  void showDeletePatientConfirmationDialog() {
    setState(() {
      showDeletePatientConfirmation = true;
    });
  }

  Future<void> deletePatient() async {
    final patientId = getEffectivePatientId();
    if (patientId == null) return;

    setState(() {
      showDeletePatientConfirmation = false;
    });

    final result = await PatientService.deletePatient(
      patientId: patientId,
    );

    if (result.success) {
      if (mounted) {
        setState(() {
          showAddProgramareModal = false;
          showRetroactiveProgramareModal = false;
          showEditProgramareModal = false;
          showHistoryModal = false;
          showFilesModal = false;
          showOverlapConfirmation = false;
          programareToEdit = null;
          programareToDelete = null;
          notificationMessage = null;
          notificationIsSuccess = null;
        });
        onCloseCallback();
      }
    } else {
      setState(() {
        notificationMessage =
            result.errorMessage ?? 'Eroare la ștergerea pacientului';
        notificationIsSuccess = false;
      });
    }
  }

  Future<void> savePatientDataManually() async {
    if (!validateFields()) {
      return;
    }

    if (isEffectivelyAddMode()) {
      autoSaveTimer?.cancel();

      final result = await PatientService.addPatient(
        nume: numeController.text,
        cnp: cnpController.text,
        telefon: telefonController.text,
        email: emailController.text,
        descriere: descriereController.text,
      );

      if (mounted) {
        setState(() {
          if (result.success && result.data != null) {
            createdPatientId = result.data;
            hasUnsavedChanges = false;
            notificationMessage = 'Pacient salvat cu succes!';
            notificationIsSuccess = true;
          } else {
            notificationMessage = result.errorMessage ?? 'Eroare la salvare';
            notificationIsSuccess = false;
          }
        });

        if (result.success && result.data != null) {
          onAddProgramareCallback();
        }
      }
    } else {
      await _autoSavePatientDataForManualSave();
    }
  }

  Future<void> _autoSavePatientDataForManualSave() async {
    final patientId = getEffectivePatientId();
    if (patientId == null) return;
    if (!hasUnsavedChanges) return;

    autoSaveTimer?.cancel();

    final result = await PatientService.savePatientData(
      patientId: patientId,
      nume: numeController.text,
      cnp: cnpController.text,
      telefon: telefonController.text,
      email: emailController.text,
      descriere: descriereController.text,
    );

    if (mounted) {
      setState(() {
        hasUnsavedChanges = false;
        if (result.success) {
          notificationMessage = 'Datele au fost salvate automat';
          notificationIsSuccess = true;
        } else {
          notificationMessage =
              result.errorMessage ?? 'Eroare la salvare automată';
          notificationIsSuccess = false;
        }
      });

      if (result.success) {
        onAddProgramareCallback();
      }
    }
  }

  Future<void> savePatientDataOnClose() async {
    if (!validateFields()) {
      return;
    }

    if (widget.isAddMode) {
      final result = await PatientService.addPatient(
        nume: numeController.text,
        cnp: cnpController.text,
        telefon: telefonController.text,
        email: emailController.text,
        descriere: descriereController.text,
      );

      if (mounted) {
        setState(() {
          if (result.success) {
            notificationMessage = 'Pacient adăugat cu succes!';
            notificationIsSuccess = true;
          } else {
            notificationMessage = result.errorMessage ?? 'Eroare la adăugare';
            notificationIsSuccess = false;
          }
        });

        if (result.success) {
          onAddProgramareCallback();
        }
      }
    }
  }

  Future<void> savePatientDataOnCloseSilent() async {
    final numeErr = PatientValidation.validateName(numeController.text);
    final cnpErr = PatientValidation.validateCNP(cnpController.text);
    final telefonErr = PatientValidation.validatePhone(telefonController.text);
    final emailErr = PatientValidation.validateEmail(emailController.text);

    if (numeErr != null ||
        cnpErr != null ||
        telefonErr != null ||
        emailErr != null) {
      return;
    }

    final patientId = getEffectivePatientId();
    if (patientId == null) {
      final result = await PatientService.addPatient(
        nume: numeController.text,
        cnp: cnpController.text,
        telefon: telefonController.text,
        email: emailController.text,
        descriere: descriereController.text,
      );
      if (result.success && result.data != null) {
        createdPatientId = result.data;
      }
    } else {
      await PatientService.savePatientData(
        patientId: patientId,
        nume: numeController.text,
        cnp: cnpController.text,
        telefon: telefonController.text,
        email: emailController.text,
        descriere: descriereController.text,
      );
    }
  }
}

