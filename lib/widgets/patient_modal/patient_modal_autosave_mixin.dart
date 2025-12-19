import 'dart:async';
import 'package:flutter/material.dart';
import 'package:liu_stoma/utils/patient_validation.dart';
import 'package:liu_stoma/services/patient_service.dart';
import 'package:liu_stoma/widgets/patient_modal.dart';

/// Mixin providing autosave logic for patient modal
mixin PatientModalAutosaveMixin on State<PatientModal> {
  // These getters/setters must be implemented by the state class
  TextEditingController get numeController;
  TextEditingController get cnpController;
  TextEditingController get telefonController;
  TextEditingController get emailController;
  TextEditingController get descriereController;

  String? get numeError;
  String? get cnpError;
  String? get telefonError;
  String? get emailError;

  Timer? get autoSaveTimer;
  set autoSaveTimer(Timer? value);

  bool get hasUnsavedChanges;
  set hasUnsavedChanges(bool value);

  String? get createdPatientId;
  set createdPatientId(String? value);

  String? get notificationMessage;
  set notificationMessage(String? value);

  bool? get notificationIsSuccess;
  set notificationIsSuccess(bool? value);

  String? getEffectivePatientId();
  bool hasValidDataForSave();
  bool validateFields();
  VoidCallback get onAddProgramareCallback;

  void resetAutoSaveTimer() {
    autoSaveTimer?.cancel();
    hasUnsavedChanges = true;

    autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        if (getEffectivePatientId() != null) {
          autoSavePatientData();
        } else {
          autoSavePatientDataAddMode();
        }
      }
    });
  }

  Future<void> autoSavePatientData() async {
    final patientId = getEffectivePatientId();
    if (patientId == null) return;
    if (!hasUnsavedChanges) return;

    autoSaveTimer?.cancel();

    if (numeError == null &&
        cnpError == null &&
        telefonError == null &&
        emailError == null) {
      if (!validateFields()) {
        return;
      }

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
            notificationMessage = result.errorMessage ?? 'Eroare la salvare automată';
            notificationIsSuccess = false;
          }
        });

        if (result.success) {
          onAddProgramareCallback();
        }
      }
    }
  }

  Future<void> autoSavePatientDataAddMode() async {
    if (!hasValidDataForSave()) return;

    autoSaveTimer?.cancel();

    if (!validateFields()) {
      return;
    }

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
          notificationMessage = 'Pacient creat automat';
          notificationIsSuccess = true;
        } else {
          notificationMessage = result.errorMessage ?? 'Eroare la creare automată';
          notificationIsSuccess = false;
        }
      });

      if (result.success && result.data != null) {
        onAddProgramareCallback();
      }
    }
  }

  Future<void> autoSavePatientDataSilent() async {
    final patientId = getEffectivePatientId();
    if (patientId == null) {
      if (!hasValidDataForSave()) return;

      final numeErr = PatientValidation.validateName(numeController.text);
      final cnpErr = cnpController.text.trim().isNotEmpty
          ? PatientValidation.validateCNP(cnpController.text.trim())
          : null;
      final telefonErr = telefonController.text.trim().isNotEmpty
          ? PatientValidation.validatePhone(telefonController.text.trim())
          : null;
      final emailErr = emailController.text.trim().isNotEmpty
          ? PatientValidation.validateEmail(emailController.text.trim())
          : null;

      if (numeErr != null ||
          cnpErr != null ||
          telefonErr != null ||
          emailErr != null) {
        return;
      }

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
      return;
    }

    if (!hasUnsavedChanges) return;

    if (numeError == null &&
        cnpError == null &&
        telefonError == null &&
        emailError == null) {
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

