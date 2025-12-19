import 'package:flutter/material.dart';
import 'package:liu_stoma/widgets/editable_field.dart';

class PatientInfoForm extends StatelessWidget {
  final double scale;
  final TextEditingController numeController;
  final TextEditingController cnpController;
  final TextEditingController telefonController;
  final TextEditingController emailController;
  final TextEditingController descriereController;
  final FocusNode numeFocusNode;
  final FocusNode cnpFocusNode;
  final FocusNode telefonFocusNode;
  final String? numeError;
  final String? cnpError;
  final String? telefonError;
  final String? emailError;
  final bool numeTouched;
  final bool cnpTouched;
  final bool telefonTouched;
  final bool emailTouched;
  final bool shouldValidateAll;
  final Function(String) onNumeChanged;
  final Function(String) onCnpChanged;
  final Function(String) onTelefonChanged;
  final Function(String) onEmailChanged;
  final Function(String)? onDescriereChanged;

  const PatientInfoForm({
    super.key,
    required this.scale,
    required this.numeController,
    required this.cnpController,
    required this.telefonController,
    required this.emailController,
    required this.descriereController,
    required this.numeFocusNode,
    required this.cnpFocusNode,
    required this.telefonFocusNode,
    this.numeError,
    this.cnpError,
    this.telefonError,
    this.emailError,
    required this.numeTouched,
    required this.cnpTouched,
    required this.telefonTouched,
    required this.emailTouched,
    required this.shouldValidateAll,
    required this.onNumeChanged,
    required this.onCnpChanged,
    required this.onTelefonChanged,
    required this.onEmailChanged,
    this.onDescriereChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(
          color: Colors.black,
          width: 5 * scale,
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(30 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EditableField(
              label: 'Nume',
              controller: numeController,
              scale: scale,
              keyboardType: TextInputType.name,
              focusNode: numeFocusNode,
              textCapitalization: TextCapitalization.words,
              errorText: (numeTouched || shouldValidateAll) ? numeError : null,
              onChanged: onNumeChanged,
            ),
            SizedBox(height: 20 * scale),
            EditableField(
              label: 'CNP',
              controller: cnpController,
              scale: scale,
              keyboardType: TextInputType.number,
              errorText: (cnpTouched || shouldValidateAll) ? cnpError : null,
              onChanged: onCnpChanged,
              focusNode: cnpFocusNode,
            ),
            SizedBox(height: 20 * scale),
            EditableField(
              label: 'Nr. telefon',
              controller: telefonController,
              scale: scale,
              keyboardType: TextInputType.phone,
              errorText: (telefonTouched || shouldValidateAll) ? telefonError : null,
              onChanged: onTelefonChanged,
              focusNode: telefonFocusNode,
            ),
            SizedBox(height: 20 * scale),
            EditableField(
              label: 'Email',
              controller: emailController,
              scale: scale,
              keyboardType: TextInputType.emailAddress,
              errorText: (emailTouched || shouldValidateAll) ? emailError : null,
              onChanged: onEmailChanged,
            ),
            SizedBox(height: 20 * scale),
            EditableField(
              label: 'Descriere',
              controller: descriereController,
              scale: scale,
              keyboardType: TextInputType.multiline,
              maxLines: 8,
              onChanged: onDescriereChanged,
            ),
          ],
        ),
      ),
    );
  }
}

