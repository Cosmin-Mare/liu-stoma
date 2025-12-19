import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/services/patient_service.dart';
import 'package:liu_stoma/widgets/confirm_dialog.dart';
import 'package:liu_stoma/widgets/custom_notification.dart';
import 'package:liu_stoma/widgets/common/simple_time_picker.dart';
import 'package:liu_stoma/widgets/programare_details/simple_date_picker.dart';
import 'package:liu_stoma/widgets/programare_details/date_time_form_fields.dart';
import 'package:liu_stoma/widgets/programare_details/action_buttons.dart';

class ProgramareDetailsPage extends StatefulWidget {
  final Programare? programare;
  final String patientId;
  final double scale;
  final bool isConsultatie;
  final Function(String message, bool isSuccess)? onNotification;

  const ProgramareDetailsPage({
    super.key,
    this.programare,
    required this.patientId,
    required this.scale,
    required this.isConsultatie,
    this.onNotification,
  });

  @override
  State<ProgramareDetailsPage> createState() => _ProgramareDetailsPageState();
}

class _ProgramareDetailsPageState extends State<ProgramareDetailsPage> {
  late final TextEditingController _proceduraController;
  late final TextEditingController _durataController;
  late DateTime _selectedDateTime;
  late bool _notificare;
  bool _dateSkipped = false;
  
  bool _saveButtonPressed = false;
  bool _deleteButtonPressed = false;
  bool _dateButtonPressed = false;
  bool _timeButtonPressed = false;
  bool _skipDateButtonPressed = false;
  bool _notificareButtonPressed = false;
  
  bool _showDeleteConfirmation = false;
  String? _notificationMessage;
  bool? _notificationIsSuccess;

  @override
  void initState() {
    super.initState();
    if (widget.programare != null) {
      _proceduraController = TextEditingController(text: widget.programare!.programareText);
      _durataController = TextEditingController(
        text: widget.programare!.durata != null 
            ? widget.programare!.durata.toString() 
            : '',
      );
      final programareDate = widget.programare!.programareTimestamp.toDate();
      final isEpochDate = programareDate.year == 1970 && 
                         programareDate.month == 1 && 
                         programareDate.day == 1;
      
      if (isEpochDate && widget.isConsultatie) {
        _selectedDateTime = DateTime(1970, 1, 1, 0, 0);
        _dateSkipped = true;
      } else {
        _selectedDateTime = programareDate;
        _dateSkipped = false;
      }
      _notificare = widget.programare!.programareNotification;
    } else {
      // Adding new programare/consultatie
      _proceduraController = TextEditingController();
      _durataController = TextEditingController();
      _selectedDateTime = DateTime.now();
      _dateSkipped = false;
      _notificare = false;
    }
  }

  @override
  void dispose() {
    _proceduraController.dispose();
    _durataController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) => SimpleDatePicker(
        scale: widget.scale,
        initialDate: _selectedDateTime,
        firstDate: widget.isConsultatie ? DateTime(1900, 1, 1) : DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      ),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final result = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => SimpleTimePicker(
        scale: widget.scale,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        isMobileLayout: true,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          result.hour,
          result.minute,
        );
      });
    }
  }

  Future<void> _handleSave() async {
    if (_proceduraController.text.trim().isEmpty) {
      setState(() {
        _notificationMessage = 'Vă rugăm să introduceți o procedură';
        _notificationIsSuccess = false;
      });
      return;
    }
    
    final timestamp = Timestamp.fromDate(_selectedDateTime);
    final notificareValue = widget.isConsultatie ? false : _notificare;
    
    // Parse durata - default to 60 minutes if empty or invalid
    final durataText = _durataController.text.trim();
    int durata = 60; // Default to 60 minutes
    if (durataText.isNotEmpty) {
      durata = int.tryParse(durataText) ?? 60; // Use 60 if parse fails
    }
    
    final result = widget.programare == null
        ? await PatientService.addProgramare(
            patientId: widget.patientId,
            procedura: _proceduraController.text.trim(),
            timestamp: timestamp,
            notificare: notificareValue,
            durata: durata,
          )
        : await PatientService.updateProgramare(
            patientId: widget.patientId,
            oldProgramare: widget.programare!,
            procedura: _proceduraController.text.trim(),
            timestamp: timestamp,
            notificare: notificareValue,
            durata: durata,
          );

    if (mounted) {
      String message;
      bool isSuccess;
      
      if (result.success) {
        if (widget.programare == null) {
          message = widget.isConsultatie 
              ? 'Consultație adăugată cu succes!' 
              : 'Programare adăugată cu succes!';
        } else {
          message = widget.isConsultatie 
              ? 'Consultație actualizată cu succes!' 
              : 'Programare actualizată cu succes!';
        }
        isSuccess = true;
      } else {
        message = result.errorMessage ?? (widget.programare == null ? 'Eroare la adăugare' : 'Eroare la actualizare');
        isSuccess = false;
      }

      // Show notification in parent if callback provided, otherwise show locally
      if (widget.onNotification != null) {
        widget.onNotification!(message, isSuccess);
        if (result.success) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
      } else {
        setState(() {
          _notificationMessage = message;
          _notificationIsSuccess = isSuccess;
        });

        if (result.success) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
      }
    }
  }

  Future<void> _handleDelete() async {
    if (widget.programare == null) return;
    
    setState(() {
      _showDeleteConfirmation = false;
    });

    final result = await PatientService.deleteProgramare(
      patientId: widget.patientId,
      programare: widget.programare!,
    );

    if (mounted) {
      String message;
      bool isSuccess;
      
      if (result.success) {
        message = widget.isConsultatie 
            ? 'Consultație ștearsă cu succes!' 
            : 'Programare ștearsă cu succes!';
        isSuccess = true;
      } else {
        message = result.errorMessage ?? 'Eroare la ștergere';
        isSuccess = false;
      }

      // Show notification in parent if callback provided, otherwise show locally
      if (widget.onNotification != null) {
        widget.onNotification!(message, isSuccess);
        if (result.success) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
      } else {
        setState(() {
          _notificationMessage = message;
          _notificationIsSuccess = isSuccess;
        });

        if (result.success) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.programare == null
              ? (widget.isConsultatie ? 'Adaugă consultație' : 'Adaugă programare')
              : (widget.isConsultatie ? 'Detalii consultație' : 'Detalii programare'),
          style: TextStyle(
            fontSize: 60 * widget.scale,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 60 * widget.scale),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(24 * widget.scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Patient name below title
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('patients')
                      .doc(widget.patientId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final patientData = snapshot.data!.data() as Map<String, dynamic>;
                      final patientName = patientData['nume'] as String? ?? '';
                      if (patientName.isNotEmpty) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 24 * widget.scale),
                          child: Text(
                            patientName,
                            style: TextStyle(
                              fontSize: 60 * widget.scale,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        );
                      }
                    }
                    return SizedBox.shrink();
                  },
                ),
                // Date and Time section
                if (!widget.isConsultatie || !_dateSkipped) ...[
                  // Date picker
                  DatePickerButton(
                    selectedDateTime: _selectedDateTime,
                    scale: widget.scale,
                    onTapDown: () => setState(() => _dateButtonPressed = true),
                    onTapUp: () {
                      setState(() => _dateButtonPressed = false);
                      _selectDate();
                    },
                    onTapCancel: () => setState(() => _dateButtonPressed = false),
                    isPressed: _dateButtonPressed,
                  ),
                  SizedBox(height: 20 * widget.scale),
                  // Time picker
                  TimePickerButton(
                    selectedDateTime: _selectedDateTime,
                    scale: widget.scale,
                    onTapDown: () => setState(() => _timeButtonPressed = true),
                    onTapUp: () {
                      setState(() => _timeButtonPressed = false);
                      _selectTime();
                    },
                    onTapCancel: () => setState(() => _timeButtonPressed = false),
                    isPressed: _timeButtonPressed,
                  ),
                  SizedBox(height: 30 * widget.scale),
                ],
                // Skip date option for consultations
                if (widget.isConsultatie) ...[
                  SkipDateCheckbox(
                    dateSkipped: _dateSkipped,
                    scale: widget.scale,
                    onTapDown: () => setState(() => _skipDateButtonPressed = true),
                    onTapUp: () {
                      setState(() {
                        _skipDateButtonPressed = false;
                        _dateSkipped = !_dateSkipped;
                        if (_dateSkipped) {
                          _selectedDateTime = DateTime(1970, 1, 1, 0, 0);
                        } else {
                          _selectedDateTime = DateTime.now();
                        }
                      });
                    },
                    onTapCancel: () => setState(() => _skipDateButtonPressed = false),
                    isPressed: _skipDateButtonPressed,
                  ),
                  SizedBox(height: 30 * widget.scale),
                  if (_dateSkipped)
                    DateSkippedInfo(scale: widget.scale),
                  SizedBox(height: 30 * widget.scale),
                ],
                // Procedura input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(36 * widget.scale),
                    border: Border.all(
                      color: Colors.black,
                      width: 5 * widget.scale,
                    ),
                  ),
                  child: TextField(
                    controller: _proceduraController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(
                      fontSize: 48 * widget.scale,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Procedură',
                      hintStyle: TextStyle(
                        fontSize: 48 * widget.scale,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 24 * widget.scale,
                        vertical: 30 * widget.scale,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30 * widget.scale),
                // Durata input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(36 * widget.scale),
                    border: Border.all(
                      color: Colors.black,
                      width: 5 * widget.scale,
                    ),
                  ),
                  child: TextField(
                    controller: _durataController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(
                      fontSize: 48 * widget.scale,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Durată (minute)',
                      hintStyle: TextStyle(
                        fontSize: 48 * widget.scale,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 24 * widget.scale,
                        vertical: 30 * widget.scale,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30 * widget.scale),
                // Notificare checkbox (only for regular programari)
                if (!widget.isConsultatie)
                  NotificareCheckbox(
                    notificare: _notificare,
                    scale: widget.scale,
                    onTapDown: () => setState(() => _notificareButtonPressed = true),
                    onTapUp: () {
                      setState(() {
                        _notificareButtonPressed = false;
                        _notificare = !_notificare;
                      });
                    },
                    onTapCancel: () => setState(() => _notificareButtonPressed = false),
                    isPressed: _notificareButtonPressed,
                  ),
                if (!widget.isConsultatie) SizedBox(height: 40 * widget.scale),
                if (widget.isConsultatie) SizedBox(height: 40 * widget.scale),
                // Action buttons
                Row(
                  children: [
                    // Delete button (only show when editing existing programare)
                    if (widget.programare != null) ...[
                      Expanded(
                        child: DeleteButton(
                          scale: widget.scale,
                          onTapDown: () => setState(() => _deleteButtonPressed = true),
                          onTapUp: () {
                            setState(() {
                              _deleteButtonPressed = false;
                              _showDeleteConfirmation = true;
                            });
                          },
                          onTapCancel: () => setState(() => _deleteButtonPressed = false),
                          isPressed: _deleteButtonPressed,
                        ),
                      ),
                      SizedBox(width: 20 * widget.scale),
                    ],
                    // Save button
                    Expanded(
                      child: SaveButton(
                        scale: widget.scale,
                        onTapDown: () => setState(() => _saveButtonPressed = true),
                        onTapUp: () {
                          setState(() => _saveButtonPressed = false);
                          _handleSave();
                        },
                        onTapCancel: () => setState(() => _saveButtonPressed = false),
                        isPressed: _saveButtonPressed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Overlays
          if (_showDeleteConfirmation)
            ConfirmDialog(
              title: 'Confirmă ștergerea',
              message: widget.isConsultatie 
                  ? 'Ești sigură că vrei să ștergi această consultație?' 
                  : 'Ești sigură că vrei să ștergi această programare?',
              confirmText: 'Șterge',
              cancelText: 'Anulează',
              scale: widget.scale,
              onConfirm: _handleDelete,
              onCancel: () {
                setState(() {
                  _showDeleteConfirmation = false;
                });
              },
            ),
          if (_notificationMessage != null && _notificationIsSuccess != null)
            CustomNotification(
              message: _notificationMessage!,
              isSuccess: _notificationIsSuccess!,
              scale: widget.scale,
              onDismiss: () {
                setState(() {
                  _notificationMessage = null;
                  _notificationIsSuccess = null;
                });
              },
            ),
        ],
      ),
    );
  }
}
