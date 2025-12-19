import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/services/patient_service.dart';
import 'package:liu_stoma/widgets/confirm_dialog.dart';
import 'package:liu_stoma/widgets/custom_notification.dart';
import 'package:liu_stoma/widgets/common/simple_time_picker.dart';
import 'package:liu_stoma/widgets/common/procedura_entry.dart';
import 'package:liu_stoma/widgets/programare_details/simple_date_picker.dart';
import 'package:liu_stoma/widgets/programare_details/date_time_form_fields.dart';
import 'package:liu_stoma/widgets/programare_details/action_buttons.dart';
import 'package:liu_stoma/widgets/common/proceduri_section.dart';

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
  late final List<ProceduraEntry> _proceduraEntries;
  late final TextEditingController _durataController;
  late final TextEditingController _totalOverrideController;
  late final TextEditingController _achitatController;
  late DateTime _selectedDateTime;
  late bool _notificare;
  bool _dateSkipped = false;
  bool _useTotalOverride = false;
  
  bool _saveButtonPressed = false;
  bool _deleteButtonPressed = false;
  bool _dateButtonPressed = false;
  bool _timeButtonPressed = false;
  bool _skipDateButtonPressed = false;
  bool _notificareButtonPressed = false;
  
  bool _showDeleteConfirmation = false;
  String? _notificationMessage;
  bool? _notificationIsSuccess;
  
  // Autosave
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isAutoSaving = false;
  
  // Cancel button
  bool _cancelButtonPressed = false;
  
  // Original state (for cancel/revert functionality)
  List<Procedura>? _originalProceduri;
  int? _originalDurata;
  double? _originalTotalOverride;
  double? _originalAchitat;
  DateTime? _originalDateTime;
  bool? _originalNotificare;

  @override
  void initState() {
    super.initState();
    if (widget.programare != null) {
      // Initialize from existing proceduri
      if (widget.programare!.proceduri.isNotEmpty) {
        _proceduraEntries = widget.programare!.proceduri.map((p) => ProceduraEntry(
          nume: p.nume,
          cost: p.cost,
          multiplicator: p.multiplicator,
        )).toList();
      } else {
        // Fallback to empty entry
        _proceduraEntries = [ProceduraEntry()];
      }
      
      _durataController = TextEditingController(
        text: widget.programare!.durata != null 
            ? widget.programare!.durata.toString() 
            : '',
      );
      
      // Initialize total override and achitat
      _useTotalOverride = widget.programare!.totalOverride != null;
      _totalOverrideController = TextEditingController(
        text: widget.programare!.totalOverride?.toString() ?? '',
      );
      _achitatController = TextEditingController(
        text: widget.programare!.achitat > 0 
            ? widget.programare!.achitat.toString() 
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
      
      // Store original state for cancel/revert functionality
      _originalProceduri = widget.programare!.proceduri.map((p) => Procedura(
        nume: p.nume,
        cost: p.cost,
        multiplicator: p.multiplicator,
      )).toList();
      _originalDurata = widget.programare!.durata;
      _originalTotalOverride = widget.programare!.totalOverride;
      _originalAchitat = widget.programare!.achitat;
      _originalDateTime = _selectedDateTime;
      _originalNotificare = _notificare;
    } else {
      // Adding new programare/consultatie
      _proceduraEntries = [ProceduraEntry()];
      _durataController = TextEditingController();
      _totalOverrideController = TextEditingController();
      _achitatController = TextEditingController();
      _selectedDateTime = DateTime.now();
      _dateSkipped = false;
      _notificare = false;
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    for (var entry in _proceduraEntries) {
      entry.dispose();
    }
    _durataController.dispose();
    _totalOverrideController.dispose();
    _achitatController.dispose();
    super.dispose();
  }
  
  /// Returns true if we're editing an existing programare (not adding new)
  bool get _isEditMode => widget.programare != null;
  
  /// Reset the autosave timer - call this whenever data changes
  void _resetAutoSaveTimer() {
    if (!_isEditMode) return; // Only autosave when editing existing programare
    
    _autoSaveTimer?.cancel();
    _hasUnsavedChanges = true;
    
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_isAutoSaving) {
        _autoSave();
      }
    });
  }
  
  /// Perform autosave
  Future<void> _autoSave() async {
    if (!_isEditMode || !_hasUnsavedChanges || _isAutoSaving) return;
    
    // Validate at least one valid procedura
    final validProceduri = _proceduraEntries
        .where((e) => e.isValid)
        .map((e) => e.toProcedura())
        .toList();
    
    if (validProceduri.isEmpty) return; // Don't autosave if no valid proceduri
    
    setState(() {
      _isAutoSaving = true;
    });
    
    final timestamp = Timestamp.fromDate(_selectedDateTime);
    final notificareValue = widget.isConsultatie ? false : _notificare;
    
    // Parse durata - default to 60 minutes if empty or invalid
    final durataText = _durataController.text.trim();
    int durata = 60;
    if (durataText.isNotEmpty) {
      durata = int.tryParse(durataText) ?? 60;
    }
    
    // Parse total override (only if enabled)
    double? totalOverride;
    if (_useTotalOverride && _totalOverrideController.text.trim().isNotEmpty) {
      totalOverride = double.tryParse(_totalOverrideController.text.trim());
    }
    
    // Parse achitat
    final achitat = double.tryParse(_achitatController.text.trim()) ?? 0.0;
    
    final result = await PatientService.updateProgramare(
      patientId: widget.patientId,
      oldProgramare: widget.programare!,
      proceduri: validProceduri,
      timestamp: timestamp,
      notificare: notificareValue,
      durata: durata,
      totalOverride: totalOverride,
      achitat: achitat,
    );
    
    if (mounted) {
      setState(() {
        _isAutoSaving = false;
        _hasUnsavedChanges = false;
        if (result.success) {
          _notificationMessage = 'Salvat automat';
          _notificationIsSuccess = true;
        } else {
          _notificationMessage = result.errorMessage ?? 'Eroare la salvare automată';
          _notificationIsSuccess = false;
        }
      });
    }
  }
  
  /// Called when any field changes - triggers autosave timer reset
  void _onFieldChanged() {
    setState(() {}); // Update UI (for total calculations)
    _resetAutoSaveTimer();
  }
  
  /// Save on exit - called when closing the page
  Future<void> _saveOnExit() async {
    if (!_isEditMode || !_hasUnsavedChanges) return;
    
    _autoSaveTimer?.cancel();
    
    // Validate at least one valid procedura
    final validProceduri = _proceduraEntries
        .where((e) => e.isValid)
        .map((e) => e.toProcedura())
        .toList();
    
    if (validProceduri.isEmpty) return;
    
    final timestamp = Timestamp.fromDate(_selectedDateTime);
    final notificareValue = widget.isConsultatie ? false : _notificare;
    
    final durataText = _durataController.text.trim();
    int durata = 60;
    if (durataText.isNotEmpty) {
      durata = int.tryParse(durataText) ?? 60;
    }
    
    double? totalOverride;
    if (_useTotalOverride && _totalOverrideController.text.trim().isNotEmpty) {
      totalOverride = double.tryParse(_totalOverrideController.text.trim());
    }
    
    final achitat = double.tryParse(_achitatController.text.trim()) ?? 0.0;
    
    await PatientService.updateProgramare(
      patientId: widget.patientId,
      oldProgramare: widget.programare!,
      proceduri: validProceduri,
      timestamp: timestamp,
      notificare: notificareValue,
      durata: durata,
      totalOverride: totalOverride,
      achitat: achitat,
    );
  }

  void _addProcedura() {
    setState(() {
      _proceduraEntries.add(ProceduraEntry());
    });
    _resetAutoSaveTimer();
  }

  void _removeProcedura(int index) {
    if (_proceduraEntries.length > 1) {
      setState(() {
        _proceduraEntries[index].dispose();
        _proceduraEntries.removeAt(index);
      });
      _resetAutoSaveTimer();
    }
  }

  double get _totalCost => calculateTotalCost(_proceduraEntries);

  double get _effectiveTotal {
    if (_useTotalOverride && _totalOverrideController.text.trim().isNotEmpty) {
      return double.tryParse(_totalOverrideController.text.trim()) ?? _totalCost;
    }
    return _totalCost;
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
      _resetAutoSaveTimer();
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
      _resetAutoSaveTimer();
    }
  }

  Future<void> _handleSave() async {
    // Cancel any pending autosave
    _autoSaveTimer?.cancel();
    
    // If editing and no unsaved changes (autosave already saved), just close
    if (_isEditMode && !_hasUnsavedChanges) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }
    
    // Validate at least one valid procedura
    final validProceduri = _proceduraEntries
        .where((e) => e.isValid)
        .map((e) => e.toProcedura())
        .toList();
    
    if (validProceduri.isEmpty) {
      setState(() {
        _notificationMessage = 'Vă rugăm să introduceți cel puțin o procedură';
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
    
    // Parse total override (only if enabled)
    double? totalOverride;
    if (_useTotalOverride && _totalOverrideController.text.trim().isNotEmpty) {
      totalOverride = double.tryParse(_totalOverrideController.text.trim());
    }
    
    // Parse achitat
    final achitat = double.tryParse(_achitatController.text.trim()) ?? 0.0;
    
    final result = widget.programare == null
        ? await PatientService.addProgramare(
            patientId: widget.patientId,
            proceduri: validProceduri,
            timestamp: timestamp,
            notificare: notificareValue,
            durata: durata,
            totalOverride: totalOverride,
            achitat: achitat,
          )
        : await PatientService.updateProgramare(
            patientId: widget.patientId,
            oldProgramare: widget.programare!,
            proceduri: validProceduri,
            timestamp: timestamp,
            notificare: notificareValue,
            durata: durata,
            totalOverride: totalOverride,
            achitat: achitat,
          );

    if (mounted) {
      String message;
      bool isSuccess;
      
      if (result.success) {
        if (widget.programare == null) {
          message = widget.isConsultatie 
              ? 'Extra adăugat cu succes!' 
              : 'Programare adăugată cu succes!';
        } else {
          message = widget.isConsultatie 
              ? 'Extra actualizat cu succes!' 
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
            ? 'Extra șters cu succes!' 
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
  
  Future<void> _handleCancel() async {
    if (!_isEditMode || _originalProceduri == null) return;
    
    // Cancel any pending autosave
    _autoSaveTimer?.cancel();
    
    // Build the current programare state (what's in the DB after autosaves)
    final currentProceduri = _proceduraEntries
        .where((e) => e.isValid)
        .map((e) => e.toProcedura())
        .toList();
    final currentTimestamp = Timestamp.fromDate(_selectedDateTime);
    final currentNotificare = widget.isConsultatie ? false : _notificare;
    final currentDurataText = _durataController.text.trim();
    int currentDurata = 60;
    if (currentDurataText.isNotEmpty) {
      currentDurata = int.tryParse(currentDurataText) ?? 60;
    }
    double? currentTotalOverride;
    if (_useTotalOverride && _totalOverrideController.text.trim().isNotEmpty) {
      currentTotalOverride = double.tryParse(_totalOverrideController.text.trim());
    }
    final currentAchitat = double.tryParse(_achitatController.text.trim()) ?? 0.0;
    
    // Create a programare representing current DB state (after autosaves)
    final currentProgramare = Programare(
      proceduri: currentProceduri.isEmpty ? [Procedura(nume: '', cost: 0, multiplicator: 1)] : currentProceduri,
      programareTimestamp: currentTimestamp,
      programareNotification: currentNotificare,
      durata: currentDurata,
      totalOverride: currentTotalOverride,
      achitat: currentAchitat,
    );
    
    // Save the original state to Firestore (revert any autosaved changes)
    final timestamp = Timestamp.fromDate(_originalDateTime!);
    final notificareValue = widget.isConsultatie ? false : _originalNotificare!;
    
    final result = await PatientService.updateProgramare(
      patientId: widget.patientId,
      oldProgramare: currentProgramare,
      proceduri: _originalProceduri!,
      timestamp: timestamp,
      notificare: notificareValue,
      durata: _originalDurata ?? 60,
      totalOverride: _originalTotalOverride,
      achitat: _originalAchitat ?? 0.0,
    );
    
    if (mounted) {
      if (result.success) {
        setState(() {
          _notificationMessage = 'Modificări anulate';
          _notificationIsSuccess = true;
        });
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      } else {
        setState(() {
          _notificationMessage = result.errorMessage ?? 'Eroare la anulare';
          _notificationIsSuccess = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isAutoSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // Save unsaved changes on exit
          await _saveOnExit();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            widget.programare == null
                ? (widget.isConsultatie ? 'Adaugă extra' : 'Adaugă programare')
                : (widget.isConsultatie ? 'Detalii extra' : 'Detalii programare'),
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
            onPressed: () async {
              await _saveOnExit();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
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
                _buildPatientName(),
                // Date and Time section
                if (!widget.isConsultatie || !_dateSkipped) ...[
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
                      _resetAutoSaveTimer();
                    },
                    onTapCancel: () => setState(() => _skipDateButtonPressed = false),
                    isPressed: _skipDateButtonPressed,
                  ),
                  SizedBox(height: 30 * widget.scale),
                  if (_dateSkipped)
                    DateSkippedInfo(scale: widget.scale),
                  SizedBox(height: 30 * widget.scale),
                ],
                
                // Procedures section using consolidated widgets with mobile font scale
                ProceduriSection(
                  scale: widget.scale,
                  fontScale: 1.7, // Mobile-optimized font scale
                  proceduraEntries: _proceduraEntries,
                  useTotalOverride: _useTotalOverride,
                  totalOverrideController: _totalOverrideController,
                  achitatController: _achitatController,
                  onAddProcedura: _addProcedura,
                  onRemoveProcedura: _removeProcedura,
                  onTotalOverrideToggle: () {
                    setState(() {
                      _useTotalOverride = !_useTotalOverride;
                      if (!_useTotalOverride) {
                        _totalOverrideController.clear();
                      }
                    });
                    _resetAutoSaveTimer();
                  },
                  onAchitaComplet: () {
                    setState(() {
                      _achitatController.text = _effectiveTotal.toStringAsFixed(0);
                    });
                    _resetAutoSaveTimer();
                  },
                  onFieldChanged: _onFieldChanged,
                  isMobile: true,
                ),
                
                SizedBox(height: 30 * widget.scale),
                // Durata input
                _buildDurataInput(),
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
                      _resetAutoSaveTimer();
                    },
                    onTapCancel: () => setState(() => _notificareButtonPressed = false),
                    isPressed: _notificareButtonPressed,
                  ),
                if (!widget.isConsultatie) SizedBox(height: 40 * widget.scale),
                if (widget.isConsultatie) SizedBox(height: 40 * widget.scale),
                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
          // Overlays
          if (_showDeleteConfirmation)
            ConfirmDialog(
              title: 'Confirmă ștergerea',
              message: widget.isConsultatie 
                  ? 'Ești sigură că vrei să ștergi acest extra?' 
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
      ),
    );
  }

  Widget _buildPatientName() {
    return StreamBuilder<DocumentSnapshot>(
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
    );
  }

  Widget _buildDurataInput() {
    return Container(
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
        onChanged: (_) => _onFieldChanged(),
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
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
        // Cancel button (only show when editing existing programare)
        if (widget.programare != null) ...[
          Expanded(
            child: CancelButton(
              scale: widget.scale,
              onTapDown: () => setState(() => _cancelButtonPressed = true),
              onTapUp: () {
                setState(() => _cancelButtonPressed = false);
                _handleCancel();
              },
              onTapCancel: () => setState(() => _cancelButtonPressed = false),
              isPressed: _cancelButtonPressed,
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
    );
  }
}
