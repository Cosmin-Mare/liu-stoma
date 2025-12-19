import 'package:flutter/material.dart';
import 'package:liu_stoma/utils/patient_validation.dart';
import 'package:liu_stoma/widgets/patient_modal.dart';

/// Mixin providing validation logic for patient modal fields
mixin PatientModalValidationMixin on State<PatientModal> {
  // These getters/setters must be implemented by the state class
  TextEditingController get numeController;
  TextEditingController get cnpController;
  TextEditingController get telefonController;
  TextEditingController get emailController;

  String? get numeError;
  set numeError(String? value);
  String? get cnpError;
  set cnpError(String? value);
  String? get telefonError;
  set telefonError(String? value);
  String? get emailError;
  set emailError(String? value);

  bool get numeTouched;
  bool get cnpTouched;
  bool get telefonTouched;
  bool get emailTouched;

  bool get shouldValidateAll;
  set shouldValidateAll(bool value);

  bool validateFields() {
    setState(() {
      shouldValidateAll = true;
      numeError = PatientValidation.validateName(numeController.text);
      cnpError = PatientValidation.validateCNP(cnpController.text);
      telefonError = PatientValidation.validatePhone(telefonController.text);
      emailError = PatientValidation.validateEmail(emailController.text);
    });

    return numeError == null &&
        cnpError == null &&
        telefonError == null &&
        emailError == null;
  }

  void validateFieldIfTouched(String fieldName, String value) {
    if (!shouldValidateAll) {
      if (fieldName == 'nume' && !numeTouched) return;
      if (fieldName == 'cnp' && !cnpTouched) return;
      if (fieldName == 'telefon' && !telefonTouched) return;
      if (fieldName == 'email' && !emailTouched) return;
    }

    setState(() {
      if (fieldName == 'nume') {
        numeError = PatientValidation.validateName(value);
      } else if (fieldName == 'cnp') {
        cnpError = PatientValidation.validateCNP(value);
      } else if (fieldName == 'telefon') {
        telefonError = PatientValidation.validatePhone(value);
      } else if (fieldName == 'email') {
        emailError = PatientValidation.validateEmail(value);
      }
    });
  }

  bool hasValidDataForSave() {
    final nume = numeController.text.trim();
    if (nume.isEmpty) return false;

    final numeErr = PatientValidation.validateName(nume);
    final cnpErr = cnpController.text.trim().isNotEmpty
        ? PatientValidation.validateCNP(cnpController.text.trim())
        : null;
    final telefonErr = telefonController.text.trim().isNotEmpty
        ? PatientValidation.validatePhone(telefonController.text.trim())
        : null;
    final emailErr = emailController.text.trim().isNotEmpty
        ? PatientValidation.validateEmail(emailController.text.trim())
        : null;

    return numeErr == null &&
        cnpErr == null &&
        telefonErr == null &&
        emailErr == null;
  }
}

