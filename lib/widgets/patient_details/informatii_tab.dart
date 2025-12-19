import 'package:flutter/material.dart';
import 'package:liu_stoma/widgets/editable_field.dart';
import 'package:liu_stoma/utils/patient_validation.dart';
import 'package:liu_stoma/services/patient_service.dart';

class InformatiiTab extends StatefulWidget {
  final TextEditingController numeController;
  final TextEditingController cnpController;
  final TextEditingController telefonController;
  final TextEditingController emailController;
  final TextEditingController descriereController;
  final FocusNode numeFocusNode;
  final FocusNode cnpFocusNode;
  final FocusNode telefonFocusNode;
  final String? patientId;
  final double scale;
  final Function(String?, bool?) onNotification;
  final VoidCallback? onDeletePatient;
  final Function(String)? onPatientCreated; // Callback with new patient ID

  const InformatiiTab({
    super.key,
    required this.numeController,
    required this.cnpController,
    required this.telefonController,
    required this.emailController,
    required this.descriereController,
    required this.numeFocusNode,
    required this.cnpFocusNode,
    required this.telefonFocusNode,
    this.patientId,
    required this.scale,
    required this.onNotification,
    this.onDeletePatient,
    this.onPatientCreated,
  });

  bool get isAddMode => patientId == null;

  @override
  State<InformatiiTab> createState() => _InformatiiTabState();
}

class _InformatiiTabState extends State<InformatiiTab> {
  String? _numeError;
  String? _cnpError;
  String? _telefonError;
  String? _emailError;
  bool _numeTouched = false;
  bool _cnpTouched = false;
  bool _telefonTouched = false;
  bool _emailTouched = false;
  bool _shouldValidateAll = false;

  bool _validateFields() {
    setState(() {
      _shouldValidateAll = true;
      _numeError = PatientValidation.validateName(widget.numeController.text);
      _cnpError = PatientValidation.validateCNP(widget.cnpController.text);
      _telefonError = PatientValidation.validatePhone(widget.telefonController.text);
      _emailError = PatientValidation.validateEmail(widget.emailController.text);
    });

    return _numeError == null && _cnpError == null && _telefonError == null && _emailError == null;
  }

  void _validateFieldIfTouched(String fieldName, String value) {
    if (!_shouldValidateAll) {
      if (fieldName == 'nume' && !_numeTouched) return;
      if (fieldName == 'cnp' && !_cnpTouched) return;
      if (fieldName == 'telefon' && !_telefonTouched) return;
      if (fieldName == 'email' && !_emailTouched) return;
    }

    setState(() {
      if (fieldName == 'nume') {
        _numeError = PatientValidation.validateName(value);
      } else if (fieldName == 'cnp') {
        _cnpError = PatientValidation.validateCNP(value);
      } else if (fieldName == 'telefon') {
        _telefonError = PatientValidation.validatePhone(value);
      } else if (fieldName == 'email') {
        _emailError = PatientValidation.validateEmail(value);
      }
    });
  }

  Future<void> _savePatientData() async {
    if (!_validateFields()) {
      widget.onNotification('Te rugăm să corectezi erorile din formular', false);
      return;
    }

    if (widget.isAddMode && widget.patientId != null) {
      // In add mode, patient already exists, just update it
      final result = await PatientService.savePatientData(
        patientId: widget.patientId!,
        nume: widget.numeController.text,
        cnp: widget.cnpController.text,
        telefon: widget.telefonController.text,
        email: widget.emailController.text,
        descriere: widget.descriereController.text,
      );

      widget.onNotification(
        result.success
            ? 'Pacient salvat cu succes!'
            : (result.errorMessage ?? 'Eroare la salvare'),
        result.success,
      );

      if (result.success && widget.onPatientCreated != null && widget.patientId != null) {
        widget.onPatientCreated!(widget.patientId!);
      }
    } else if (widget.patientId != null) {
      // Update existing patient
      final result = await PatientService.savePatientData(
        patientId: widget.patientId!,
        nume: widget.numeController.text,
        cnp: widget.cnpController.text,
        telefon: widget.telefonController.text,
        email: widget.emailController.text,
        descriere: widget.descriereController.text,
      );

      widget.onNotification(
        result.success
            ? 'Datele pacientului au fost actualizate cu succes!'
            : (result.errorMessage ?? 'Eroare la salvare'),
        result.success,
      );
    }
  }

  void resetValidation() {
    setState(() {
      _numeTouched = false;
      _cnpTouched = false;
      _telefonTouched = false;
      _emailTouched = false;
      _shouldValidateAll = false;
      _numeError = null;
      _cnpError = null;
      _telefonError = null;
      _emailError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24 * widget.scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EditableField(
            label: 'Nume',
            controller: widget.numeController,
            scale: widget.scale,
            keyboardType: TextInputType.name,
            focusNode: widget.numeFocusNode,
            textCapitalization: TextCapitalization.words,
            errorText: (_numeTouched || _shouldValidateAll) ? _numeError : null,
            onChanged: (value) {
              setState(() {
                _numeTouched = true;
              });
              _validateFieldIfTouched('nume', value);
            },
          ),
          SizedBox(height: 20 * widget.scale),
          EditableField(
            label: 'CNP',
            controller: widget.cnpController,
            scale: widget.scale,
            keyboardType: TextInputType.number,
            errorText: (_cnpTouched || _shouldValidateAll) ? _cnpError : null,
            onChanged: (value) {
              setState(() {
                _cnpTouched = true;
              });
              _validateFieldIfTouched('cnp', value);
            },
            focusNode: widget.cnpFocusNode,
          ),
          SizedBox(height: 20 * widget.scale),
          EditableField(
            label: 'Nr. telefon',
            controller: widget.telefonController,
            scale: widget.scale,
            keyboardType: TextInputType.phone,
            errorText: (_telefonTouched || _shouldValidateAll) ? _telefonError : null,
            onChanged: (value) {
              setState(() {
                _telefonTouched = true;
              });
              _validateFieldIfTouched('telefon', value);
            },
            focusNode: widget.telefonFocusNode,
          ),
          SizedBox(height: 20 * widget.scale),
          EditableField(
            label: 'Email',
            controller: widget.emailController,
            scale: widget.scale,
            keyboardType: TextInputType.emailAddress,
            errorText: (_emailTouched || _shouldValidateAll) ? _emailError : null,
            onChanged: (value) {
              setState(() {
                _emailTouched = true;
              });
              _validateFieldIfTouched('email', value);
            },
          ),
          SizedBox(height: 20 * widget.scale),
          EditableField(
            label: 'Descriere',
            controller: widget.descriereController,
            scale: widget.scale,
            keyboardType: TextInputType.multiline,
            maxLines: 8,
          ),
          SizedBox(height: 30 * widget.scale),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _savePatientData,
                icon: Icon(Icons.save, size: 72 * widget.scale),
                label: Text(
                  widget.isAddMode ? 'Adaugă pacient' : 'Salvează',
                  style: TextStyle(
                    fontSize: 54 * widget.scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: 36 * widget.scale,
                    horizontal: 60 * widget.scale,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(36 * widget.scale),
                    side: BorderSide(color: Colors.black, width: 7 * widget.scale),
                  ),
                ),
              ),
              if (!widget.isAddMode && widget.onDeletePatient != null) ...[
                SizedBox(height: 16 * widget.scale),
                ElevatedButton.icon(
                  onPressed: widget.onDeletePatient,
                  icon: Icon(Icons.delete, size: 72 * widget.scale),
                  label: Text(
                    'Șterge pacient',
                    style: TextStyle(
                      fontSize: 54 * widget.scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 36 * widget.scale),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36 * widget.scale),
                      side: BorderSide(color: Colors.black, width: 7 * widget.scale),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

