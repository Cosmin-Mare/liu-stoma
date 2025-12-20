import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/services/patient_service.dart';
import 'package:liu_stoma/widgets/common/simple_time_picker.dart';
import 'package:liu_stoma/widgets/common/modal_wrapper.dart';
import 'package:liu_stoma/widgets/common/procedura_entry.dart';
import 'package:liu_stoma/widgets/common/proceduri_section.dart';
import 'package:liu_stoma/utils/design_constants.dart';
import 'package:liu_stoma/widgets/confirm_dialog.dart';
import 'package:liu_stoma/widgets/custom_notification.dart';
import 'common/date_picker_theme.dart';
import 'add_programare_modal/modal_buttons.dart';
import 'add_programare_modal/form_fields.dart';
import 'add_programare_modal/modal_header.dart';

class AddProgramareModal extends StatefulWidget {
  final double scale;
  final VoidCallback onClose;
  final Function(List<Procedura> proceduri, Timestamp timestamp, bool notificare, int? durata, double? totalOverride, double achitat, String? patientId) onSave;
  final VoidCallback? onDelete;
  final Function(String errorMessage)? onValidationError;
  final Programare? initialProgramare;
  final bool isRetroactive;
  final String? patientName;
  final bool shouldCloseAfterSave;
  /// Patient ID for autosave functionality (only used when editing existing programare)
  final String? patientId;
  /// Callback when autosave completes (success, message)
  final Function(bool success, String message)? onAutoSave;
  final DateTime? initialDateTime;
  const AddProgramareModal({
    super.key,
    required this.scale,
    required this.onClose,
    required this.onSave,
    this.onDelete,
    this.onValidationError,
    this.initialProgramare,
    this.isRetroactive = false,
    this.patientName,
    this.shouldCloseAfterSave = true,
    this.patientId,
    this.onAutoSave,
    this.initialDateTime,
  });

  @override
  State<AddProgramareModal> createState() => _AddProgramareModalState();
}

class _AddProgramareModalState extends State<AddProgramareModal> {
  late final List<ProceduraEntry> _proceduraEntries;
  late final TextEditingController _durataController;
  late final TextEditingController _totalOverrideController;
  late final TextEditingController _achitatController;
  late DateTime _selectedDateTime;
  late bool _notificare;
  bool _useTotalOverride = false;
  bool _isPaymentExpanded = false;
  
  // Autosave
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isAutoSaving = false;
  String? _notificationMessage;
  bool? _notificationIsSuccess;
  
  // Original state (for cancel/revert functionality)
  List<Procedura>? _originalProceduri;
  int? _originalDurata;
  double? _originalTotalOverride;
  double? _originalAchitat;
  DateTime? _originalDateTime;
  bool? _originalNotificare;

  String? _patientId;

  @override
  void initState() {
    super.initState();
    if (widget.initialProgramare != null) {
      print('[AddProgramareModal] Initializing with existing programare');
      print('[AddProgramareModal] initialProgramare.durata: ${widget.initialProgramare!.durata} (type: ${widget.initialProgramare!.durata.runtimeType})');
      
      // Initialize from existing proceduri
      if (widget.initialProgramare!.proceduri.isNotEmpty) {
        _proceduraEntries = widget.initialProgramare!.proceduri.map((p) => ProceduraEntry(
          nume: p.nume,
          cost: p.cost,
          multiplicator: p.multiplicator,
        )).toList();
      } else {
        // Fallback to empty entry
        _proceduraEntries = [ProceduraEntry()];
      }
      
      final durataText = widget.initialProgramare!.durata != null 
          ? widget.initialProgramare!.durata.toString() 
          : '';
      print('[AddProgramareModal] Setting durata controller text to: "$durataText"');
      _durataController = TextEditingController(text: durataText);
      
      // Initialize total override and achitat
      _useTotalOverride = widget.initialProgramare!.totalOverride != null;
      _totalOverrideController = TextEditingController(
        text: widget.initialProgramare!.totalOverride?.toString() ?? '',
      );
      _achitatController = TextEditingController(
        text: widget.initialProgramare!.achitat > 0 
            ? widget.initialProgramare!.achitat.toString() 
            : '',
      );
      // Expand payment section if there's any payment info
      _isPaymentExpanded = widget.initialProgramare!.achitat > 0 || 
                           widget.initialProgramare!.totalOverride != null;
      
      final programareDate = widget.initialProgramare!.programareTimestamp.toDate();
      final isEpochDate = programareDate.year == 1970 && 
                         programareDate.month == 1 && 
                         programareDate.day == 1;
      
      if (isEpochDate && widget.isRetroactive) {
        _selectedDateTime = DateTime(1970, 1, 1, 0, 0);
        _dateSkipped = true;
      } else {
        _selectedDateTime = programareDate;
        _dateSkipped = false;
      }
      _notificare = widget.initialProgramare!.programareNotification;
      
      // Store original state for cancel/revert functionality
      _originalProceduri = widget.initialProgramare!.proceduri.map((p) => Procedura(
        nume: p.nume,
        cost: p.cost,
        multiplicator: p.multiplicator,
      )).toList();
      _originalDurata = widget.initialProgramare!.durata;
      _originalTotalOverride = widget.initialProgramare!.totalOverride;
      _originalAchitat = widget.initialProgramare!.achitat;
      _originalDateTime = _selectedDateTime;
      _originalNotificare = _notificare;
    } else {
      print('[AddProgramareModal] Initializing for new programare');
      _proceduraEntries = []; // Start with no proceduri
      _durataController = TextEditingController();
      _totalOverrideController = TextEditingController();
      _achitatController = TextEditingController();
      final now = DateTime.now();
      _selectedDateTime = widget.initialDateTime ?? DateTime(now.year, now.month, now.day, now.hour, 0);
      _notificare = false;
      _dateSkipped = false;
    }
  }
  
  bool _saveButtonHovering = false;
  bool _saveButtonPressed = false;
  bool _cancelButtonHovering = false;
  bool _cancelButtonPressed = false;
  bool _deleteButtonHovering = false;
  bool _deleteButtonPressed = false;
  bool _dateButtonHovering = false;
  bool _dateButtonPressed = false;
  bool _timeButtonHovering = false;
  bool _timeButtonPressed = false;
  bool _dateSkipped = false;

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return DatePickerThemeHelper.buildDatePickerTheme(context, widget.scale, child!);
      },
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

  void _addProcedura() {
    setState(() {
      _proceduraEntries.add(ProceduraEntry());
    });
    _resetAutoSaveTimer();
  }

  void _addConsultation() {
    setState(() {
      _proceduraEntries.add(ProceduraEntry(nume: 'Consult', cost: 0));
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

  void _handleSave() {
    print('[AddProgramareModal] Save button clicked');
    print('[AddProgramareModal] DateTime: $_selectedDateTime');
    print('[AddProgramareModal] Notificare: $_notificare');
    print('[AddProgramareModal] Date skipped: $_dateSkipped');
    
    // Cancel any pending autosave
    _autoSaveTimer?.cancel();
    
    // If editing and no unsaved changes (autosave already saved), just close
    if (_isEditMode && !_hasUnsavedChanges) {
      print('[AddProgramareModal] No unsaved changes, closing without save');
      widget.onClose();
      return;
    }
    
    // Get valid proceduri (can be empty - will be filled in later)
    final validProceduri = _proceduraEntries
        .where((e) => e.isValid)
        .map((e) => e.toProcedura())
        .toList();
    
    final timestamp = Timestamp.fromDate(_selectedDateTime);
    print('[AddProgramareModal] Calling onSave callback with timestamp: $timestamp');
    
    // For retroactive consultations, always set notificare to false
    final notificareValue = widget.isRetroactive ? false : _notificare;
    
    // Parse durata - default to 60 minutes if empty or invalid
    final durataText = _durataController.text.trim();
    print('[AddProgramareModal] Durata text from controller: "$durataText"');
    print('[AddProgramareModal] Initial programare durata: ${widget.initialProgramare?.durata}');
    int durata = 60; // Default to 60 minutes
    if (durataText.isNotEmpty) {
      durata = int.tryParse(durataText) ?? 60; // Use 60 if parse fails
    }
    print('[AddProgramareModal] Parsed durata value: $durata (type: ${durata.runtimeType})');
    
    // Parse total override (only if enabled)
    double? totalOverride;
    if (_useTotalOverride && _totalOverrideController.text.trim().isNotEmpty) {
      totalOverride = double.tryParse(_totalOverrideController.text.trim());
    }
    
    // Parse achitat
    final achitat = double.tryParse(_achitatController.text.trim()) ?? 0.0;
    
    if (_patientId == null) {
      setState(() {
        _notificationMessage = 'Nu a fost selectat niciun pacient';
        _notificationIsSuccess = false;
      });
      return;
    }

    widget.onSave(
      validProceduri,
      timestamp,
      notificareValue,
      durata,
      totalOverride,
      achitat,
      _patientId,
    );
    print('[AddProgramareModal] onSave callback called with ${validProceduri.length} proceduri, durata: $durata, totalOverride: $totalOverride, achitat: $achitat');
    
    // Only close the modal if shouldCloseAfterSave is true
    // This allows the parent to control when to close (e.g., after overlap confirmation)
    if (widget.shouldCloseAfterSave) {
      print('[AddProgramareModal] Closing modal');
      widget.onClose();
    } else {
      print('[AddProgramareModal] Keeping modal open (parent will close it)');
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Șterge Programare',
        message: 'Sunteți sigur că doriți să ștergeți această programare?',
        confirmText: 'Șterge',
        cancelText: 'Anulează',
        scale: widget.scale,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirmed == true && widget.onDelete != null) {
      widget.onDelete!();
      widget.onClose();
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
  bool get _isEditMode => widget.initialProgramare != null && widget.patientId != null;
  
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
    
    // Get valid proceduri (can be empty)
    final validProceduri = _proceduraEntries
        .where((e) => e.isValid)
        .map((e) => e.toProcedura())
        .toList();
    
    setState(() {
      _isAutoSaving = true;
    });
    
    final timestamp = Timestamp.fromDate(_selectedDateTime);
    final notificareValue = widget.isRetroactive ? false : _notificare;
    
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
    
    final result = await _performAutoSave(
      validProceduri,
      timestamp,
      notificareValue,
      durata,
      totalOverride,
      achitat,
    );
    
    if (mounted) {
      setState(() {
        _isAutoSaving = false;
        _hasUnsavedChanges = false;
        _notificationMessage = result ? 'Salvat automat' : 'Eroare la salvare automată';
        _notificationIsSuccess = result;
      });
      
      widget.onAutoSave?.call(result, result ? 'Salvat automat' : 'Eroare la salvare automată');
    }
  }
  
  Future<bool> _performAutoSave(
    List<Procedura> proceduri,
    Timestamp timestamp,
    bool notificare,
    int durata,
    double? totalOverride,
    double achitat,
  ) async {
    // Use PatientService directly for autosave to avoid triggering overlap checks
    if (widget.patientId == null || widget.initialProgramare == null) return false;
    
    final result = await PatientService.updateProgramare(
      patientId: widget.patientId!,
      oldProgramare: widget.initialProgramare!,
      proceduri: proceduri,
      timestamp: timestamp,
      notificare: notificare,
      durata: durata,
      totalOverride: totalOverride,
      achitat: achitat,
    );
    
    return result.success;
  }
  
  /// Called when any field changes - triggers autosave timer reset
  void _onFieldChanged() {
    setState(() {}); // Update UI (for total calculations)
    _resetAutoSaveTimer();
  }
  
  /// Close the modal and save current changes (clicking outside, X button, etc.)
  Future<void> _handleClose() async {
    _autoSaveTimer?.cancel();
    
    // Save current state if editing
    if (_isEditMode && _hasUnsavedChanges) {
      final validProceduri = _proceduraEntries
          .where((e) => e.isValid)
          .map((e) => e.toProcedura())
          .toList();
      
      final timestamp = Timestamp.fromDate(_selectedDateTime);
      final notificareValue = widget.isRetroactive ? false : _notificare;
      
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
      
      if (widget.patientId != null && widget.initialProgramare != null) {
        await PatientService.updateProgramare(
          patientId: widget.patientId!,
          oldProgramare: widget.initialProgramare!,
          proceduri: validProceduri,
          timestamp: timestamp,
          notificare: notificareValue,
          durata: durata,
          totalOverride: totalOverride,
          achitat: achitat,
        );
      }
    }
    
    widget.onClose();
  }
  
  /// Cancel and revert to original state (only for "Anulează" button)
  Future<void> _handleCancel() async {
    // Cancel any pending autosave
    _autoSaveTimer?.cancel();
    
    // If editing, revert to original state in Firestore
    if (_isEditMode && _originalProceduri != null) {
      final timestamp = Timestamp.fromDate(_originalDateTime!);
      final notificareValue = widget.isRetroactive ? false : _originalNotificare!;
      
      // Build a programare that represents what's currently in the DB (after autosaves)
      final currentProceduri = _proceduraEntries
          .where((e) => e.isValid)
          .map((e) => e.toProcedura())
          .toList();
      final currentTimestamp = Timestamp.fromDate(_selectedDateTime);
      final currentNotificare = widget.isRetroactive ? false : _notificare;
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
      
      await PatientService.updateProgramare(
        patientId: widget.patientId!,
        oldProgramare: currentProgramare,
        proceduri: _originalProceduri!,
        timestamp: timestamp,
        notificare: notificareValue,
        durata: _originalDurata ?? 60,
        totalOverride: _originalTotalOverride,
        achitat: _originalAchitat ?? 0.0,
      );
    }
    widget.onClose();
  }

  double get _totalCost => calculateTotalCost(_proceduraEntries);

  double get _effectiveTotal {
    if (_useTotalOverride && _totalOverrideController.text.trim().isNotEmpty) {
      return double.tryParse(_totalOverrideController.text.trim()) ?? _totalCost;
    }
    return _totalCost;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Stack(
      children: [
        ModalWrapper(
          onClose: _handleClose,
          scale: widget.scale,
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxWidth: 1400 * widget.scale,
            minHeight: 500 * widget.scale,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(DesignConstants.modalPadding(widget.scale)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AddProgramareModalHeader(
                    scale: widget.scale,
                    isEditing: widget.initialProgramare != null,
                    isRetroactive: widget.isRetroactive,
                    patientName: widget.patientName,
                    onPatientIdChange: setPatientId,
                    patientId: _patientId,
                  ),
                  SizedBox(height: 25 * widget.scale),
                  // Date picker
                  if (!widget.isRetroactive || !_dateSkipped)
                    _buildDateTimePickers(isMobile),
                  if (!widget.isRetroactive || !_dateSkipped) SizedBox(height: 20 * widget.scale),
                  if (widget.isRetroactive) ...[
                    SkipDateCheckbox(
                      dateSkipped: _dateSkipped,
                      scale: widget.scale,
                      onTap: () {
                        setState(() {
                          _dateSkipped = !_dateSkipped;
                          if (_dateSkipped) {
                            _selectedDateTime = DateTime(1970, 1, 1, 0, 0);
                          } else {
                            _selectedDateTime = DateTime.now();
                          }
                        });
                        _resetAutoSaveTimer();
                      },
                    ),
                    SizedBox(height: 20 * widget.scale),
                    if (_dateSkipped) DateSkippedInfo(scale: widget.scale),
                    if (_dateSkipped) SizedBox(height: 20 * widget.scale),
                  ],
                  
                  // Proceduri section using shared component
                  ProceduriSection(
                    scale: widget.scale,
                    proceduraEntries: _proceduraEntries,
                    useTotalOverride: _useTotalOverride,
                    totalOverrideController: _totalOverrideController,
                    achitatController: _achitatController,
                    onAddProcedura: _addProcedura,
                    onAddConsult: _addConsultation,
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
                    isMobile: isMobile,
                    isPaymentExpanded: _isPaymentExpanded,
                    onPaymentExpandToggle: () {
                      setState(() {
                        _isPaymentExpanded = !_isPaymentExpanded;
                      });
                    },
                    showEmptyState: true,
                  ),
                  
                  SizedBox(height: 20 * widget.scale),
                  // Durata input
                  DurataTextField(
                    controller: _durataController,
                    scale: widget.scale,
                  ),
                  SizedBox(height: 20 * widget.scale),
                  // Notificare checkbox (only for regular programari, not for consultations)
                  if (!widget.isRetroactive)
                    NotificareCheckbox(
                      notificare: _notificare,
                      scale: widget.scale,
                      onTap: () {
                        setState(() {
                          _notificare = !_notificare;
                        });
                        _resetAutoSaveTimer();
                      },
                    ),
                  if (!widget.isRetroactive) SizedBox(height: 25 * widget.scale),
                  if (widget.isRetroactive) SizedBox(height: 25 * widget.scale),
                  // Buttons
                  _buildActionButtons(isMobile),
                ],
              ),
            ),
          ),
        ),
        // Autosave notification overlay
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
    );
  }

  Widget _buildDateTimePickers(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          DatePickerButton(
            selectedDateTime: _selectedDateTime,
            scale: widget.scale,
            onTap: _selectDate,
            isHovering: _dateButtonHovering,
            isPressed: _dateButtonPressed,
            onHoverEnter: () {
              if (!_dateButtonHovering) {
                setState(() => _dateButtonHovering = true);
              }
            },
            onHoverExit: () {
              if (_dateButtonHovering) {
                setState(() => _dateButtonHovering = false);
              }
            },
            onTapDown: () {
              if (!_dateButtonPressed) {
                setState(() => _dateButtonPressed = true);
              }
            },
            onTapUp: () {
              if (_dateButtonPressed) {
                setState(() => _dateButtonPressed = false);
              }
            },
            onTapCancel: () {
              if (_dateButtonPressed) {
                setState(() => _dateButtonPressed = false);
              }
            },
          ),
          SizedBox(height: 12 * widget.scale),
          TimePickerButton(
            selectedDateTime: _selectedDateTime,
            scale: widget.scale,
            onTap: _selectTime,
            isHovering: _timeButtonHovering,
            isPressed: _timeButtonPressed,
            onHoverEnter: () {
              if (!_timeButtonHovering) {
                setState(() => _timeButtonHovering = true);
              }
            },
            onHoverExit: () {
              if (_timeButtonHovering) {
                setState(() => _timeButtonHovering = false);
              }
            },
            onTapDown: () {
              if (!_timeButtonPressed) {
                setState(() => _timeButtonPressed = true);
              }
            },
            onTapUp: () {
              if (_timeButtonPressed) {
                setState(() => _timeButtonPressed = false);
              }
            },
            onTapCancel: () {
              if (_timeButtonPressed) {
                setState(() => _timeButtonPressed = false);
              }
            },
          ),
        ],
      );
    }
    
    return Row(
      children: [
        Expanded(
          child: DatePickerButton(
            selectedDateTime: _selectedDateTime,
            scale: widget.scale,
            onTap: _selectDate,
            isHovering: _dateButtonHovering,
            isPressed: _dateButtonPressed,
            onHoverEnter: () {
              if (!_dateButtonHovering) {
                setState(() => _dateButtonHovering = true);
              }
            },
            onHoverExit: () {
              if (_dateButtonHovering) {
                setState(() => _dateButtonHovering = false);
              }
            },
            onTapDown: () {
              if (!_dateButtonPressed) {
                setState(() => _dateButtonPressed = true);
              }
            },
            onTapUp: () {
              if (_dateButtonPressed) {
                setState(() => _dateButtonPressed = false);
              }
            },
            onTapCancel: () {
              if (_dateButtonPressed) {
                setState(() => _dateButtonPressed = false);
              }
            },
          ),
        ),
        SizedBox(width: 20 * widget.scale),
        Expanded(
          child: TimePickerButton(
            selectedDateTime: _selectedDateTime,
            scale: widget.scale,
            onTap: _selectTime,
            isHovering: _timeButtonHovering,
            isPressed: _timeButtonPressed,
            onHoverEnter: () {
              if (!_timeButtonHovering) {
                setState(() => _timeButtonHovering = true);
              }
            },
            onHoverExit: () {
              if (_timeButtonHovering) {
                setState(() => _timeButtonHovering = false);
              }
            },
            onTapDown: () {
              if (!_timeButtonPressed) {
                setState(() => _timeButtonPressed = true);
              }
            },
            onTapUp: () {
              if (_timeButtonPressed) {
                setState(() => _timeButtonPressed = false);
              }
            },
            onTapCancel: () {
              if (_timeButtonPressed) {
                setState(() => _timeButtonPressed = false);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    final hasDeleteButton = widget.initialProgramare != null && widget.onDelete != null;
    
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasDeleteButton) ...[
            _buildDeleteButton(),
            SizedBox(height: 15 * widget.scale),
          ],
          _buildCancelButton(),
          SizedBox(height: 15 * widget.scale),
          _buildSaveButton(),
        ],
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final estimatedButtonWidth = 200 * widget.scale;
        final totalButtonsWidth = (hasDeleteButton ? 3 : 2) * estimatedButtonWidth;
        final needsWrapping = totalButtonsWidth > availableWidth;

        if (needsWrapping) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasDeleteButton) ...[
                _buildDeleteButton(),
                SizedBox(height: 15 * widget.scale),
              ],
              _buildCancelButton(),
              SizedBox(height: 15 * widget.scale),
              _buildSaveButton(),
            ],
          );
        }
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (hasDeleteButton)
              Flexible(child: _buildDeleteButton())
            else
              const Spacer(),
            SizedBox(width: 20 * widget.scale),
            Flexible(child: _buildCancelButton()),
            SizedBox(width: 20 * widget.scale),
            Flexible(child: _buildSaveButton()),
          ],
        );
      },
    );
  }

  Widget _buildDeleteButton() {
    return ModalDeleteButton(
      scale: widget.scale,
      onTap: _handleDelete,
      isHovering: _deleteButtonHovering,
      isPressed: _deleteButtonPressed,
      onHoverEnter: () {
        if (!_deleteButtonHovering) {
          setState(() => _deleteButtonHovering = true);
        }
      },
      onHoverExit: () {
        if (_deleteButtonHovering) {
          setState(() => _deleteButtonHovering = false);
        }
      },
      onTapDown: () {
        if (!_deleteButtonPressed) {
          setState(() => _deleteButtonPressed = true);
        }
      },
      onTapUp: () {
        if (_deleteButtonPressed) {
          setState(() => _deleteButtonPressed = false);
        }
      },
      onTapCancel: () {
        if (_deleteButtonPressed) {
          setState(() => _deleteButtonPressed = false);
        }
      },
    );
  }

  Widget _buildCancelButton() {
    return ModalCancelButton(
      scale: widget.scale,
      onTap: _handleCancel,
      isHovering: _cancelButtonHovering,
      isPressed: _cancelButtonPressed,
      onHoverEnter: () {
        if (!_cancelButtonHovering) {
          setState(() => _cancelButtonHovering = true);
        }
      },
      onHoverExit: () {
        if (_cancelButtonHovering) {
          setState(() => _cancelButtonHovering = false);
        }
      },
      onTapDown: () {
        if (!_cancelButtonPressed) {
          setState(() => _cancelButtonPressed = true);
        }
      },
      onTapUp: () {
        if (_cancelButtonPressed) {
          setState(() => _cancelButtonPressed = false);
        }
      },
      onTapCancel: () {
        if (_cancelButtonPressed) {
          setState(() => _cancelButtonPressed = false);
        }
      },
    );
  }
  
  void setPatientId(String patientId) {
    setState(() {
      _patientId = patientId;
    });
  }

  Widget _buildSaveButton() {
    return ModalSaveButton(
      scale: widget.scale,
      onTap: _handleSave,
      isHovering: _saveButtonHovering,
      isPressed: _saveButtonPressed,
      onHoverEnter: () {
        if (!_saveButtonHovering) {
          setState(() => _saveButtonHovering = true);
        }
      },
      onHoverExit: () {
        if (_saveButtonHovering) {
          setState(() => _saveButtonHovering = false);
        }
      },
      onTapDown: () {
        if (!_saveButtonPressed) {
          setState(() => _saveButtonPressed = true);
        }
      },
      onTapUp: () {
        if (_saveButtonPressed) {
          setState(() => _saveButtonPressed = false);
        }
      },
      onTapCancel: () {
        if (_saveButtonPressed) {
          setState(() => _saveButtonPressed = false);
        }
      },
    );
  }
}
