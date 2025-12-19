import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/widgets/common/simple_time_picker.dart';
import 'package:liu_stoma/widgets/common/modal_wrapper.dart';
import 'package:liu_stoma/utils/design_constants.dart';
import 'package:liu_stoma/widgets/confirm_dialog.dart';
import 'add_programare_modal/date_picker_theme.dart';
import 'add_programare_modal/modal_buttons.dart';
import 'add_programare_modal/form_fields.dart';
import 'add_programare_modal/modal_header.dart';

class AddProgramareModal extends StatefulWidget {
  final double scale;
  final VoidCallback onClose;
  final Function(String procedura, Timestamp timestamp, bool notificare, int? durata) onSave;
  final VoidCallback? onDelete;
  final Function(String errorMessage)? onValidationError;
  final Programare? initialProgramare;
  final bool isRetroactive;
  final String? patientName;
  final bool shouldCloseAfterSave;

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
  });

  @override
  State<AddProgramareModal> createState() => _AddProgramareModalState();
}

class _AddProgramareModalState extends State<AddProgramareModal> {
  late final TextEditingController _proceduraController;
  late final TextEditingController _durataController;
  late DateTime _selectedDateTime;
  late bool _notificare;

  @override
  void initState() {
    super.initState();
    if (widget.initialProgramare != null) {
      print('[AddProgramareModal] Initializing with existing programare');
      print('[AddProgramareModal] initialProgramare.durata: ${widget.initialProgramare!.durata} (type: ${widget.initialProgramare!.durata.runtimeType})');
      _proceduraController = TextEditingController(text: widget.initialProgramare!.programareText);
      final durataText = widget.initialProgramare!.durata != null 
          ? widget.initialProgramare!.durata.toString() 
          : '';
      print('[AddProgramareModal] Setting durata controller text to: "$durataText"');
      _durataController = TextEditingController(text: durataText);
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
    } else {
      print('[AddProgramareModal] Initializing for new programare');
      _proceduraController = TextEditingController();
      _durataController = TextEditingController();
      _selectedDateTime = DateTime.now();
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
      firstDate: widget.isRetroactive ? DateTime(1900, 1, 1) : DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    }
  }

  void _handleSave() {
    print('[AddProgramareModal] Save button clicked');
    print('[AddProgramareModal] Procedura: ${_proceduraController.text.trim()}');
    print('[AddProgramareModal] DateTime: $_selectedDateTime');
    print('[AddProgramareModal] Notificare: $_notificare');
    print('[AddProgramareModal] Date skipped: $_dateSkipped');
    
    if (_proceduraController.text.trim().isEmpty) {
      print('[AddProgramareModal] Validation failed: Procedura is empty');
      if (widget.onValidationError != null) {
        widget.onValidationError!('Vă rugăm să introduceți o procedură');
      }
      return;
    }
    
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
    
    widget.onSave(
      _proceduraController.text.trim(),
      timestamp,
      notificareValue,
      durata,
    );
    print('[AddProgramareModal] onSave callback called with durata: $durata');
    
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
    _proceduraController.dispose();
    _durataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalWrapper(
      onClose: widget.onClose,
      scale: widget.scale,
      width: MediaQuery.of(context).size.width * 0.8,
      constraints: BoxConstraints(
        maxWidth: 1200 * widget.scale,
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
                      ),
                      SizedBox(height: 25 * widget.scale),
                      // Date picker (shown for both, but optional for retroactive)
                      if (!widget.isRetroactive || !_dateSkipped)
                        Row(
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
                          // Time picker
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
                      ),
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
                          },
                        ),
                        SizedBox(height: 20 * widget.scale),
                        if (_dateSkipped) DateSkippedInfo(scale: widget.scale),
                        if (_dateSkipped) SizedBox(height: 20 * widget.scale),
                      ],
                      // Procedura input
                      ProceduraTextField(
                        controller: _proceduraController,
                        scale: widget.scale,
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
                          },
                        ),
                      if (!widget.isRetroactive) SizedBox(height: 25 * widget.scale),
                      if (widget.isRetroactive) SizedBox(height: 25 * widget.scale),
                      // Buttons
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final availableWidth = constraints.maxWidth;
                          // Estimate button widths (padding + text + borders)
                          final estimatedButtonWidth = 200 * widget.scale;
                          final hasDeleteButton = widget.initialProgramare != null && widget.onDelete != null;
                          final totalButtonsWidth = (hasDeleteButton ? 3 : 2) * estimatedButtonWidth;
                          final needsWrapping = totalButtonsWidth > availableWidth;

                          if (needsWrapping) {
                            // Stack buttons vertically on small screens
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (hasDeleteButton) ...[
                                  ModalDeleteButton(
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
                                  ),
                                  SizedBox(height: 15 * widget.scale),
                                ],
                                ModalCancelButton(
                                  scale: widget.scale,
                                  onTap: widget.onClose,
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
                                ),
                                SizedBox(height: 15 * widget.scale),
                                ModalSaveButton(
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
                                ),
                              ],
                            );
                          } else {
                            // Original horizontal layout for larger screens
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Delete button (only shown when editing)
                                if (hasDeleteButton)
                                  Flexible(
                                    child: ModalDeleteButton(
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
                                    ),
                                  )
                                else
                                  const Spacer(),
                                SizedBox(width: 20 * widget.scale),
                                Flexible(
                                  child: ModalCancelButton(
                                    scale: widget.scale,
                                    onTap: widget.onClose,
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
                                  ),
                                ),
                                SizedBox(width: 20 * widget.scale),
                                Flexible(
                                  child: ModalSaveButton(
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
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
