import 'dart:async';
import 'package:flutter/material.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/widgets/patient_modal/patient_info_form.dart';
import 'package:liu_stoma/widgets/patient_modal/patient_modal_header.dart';
import 'package:liu_stoma/widgets/patient_modal/patient_appointments_section.dart';
import 'package:liu_stoma/widgets/patient_modal/patient_modal_bottom_buttons.dart';
import 'package:liu_stoma/widgets/patient_modal/patient_modal_overlays.dart';
import 'package:liu_stoma/widgets/patient_modal/patient_modal_validation_mixin.dart';
import 'package:liu_stoma/widgets/patient_modal/patient_modal_autosave_mixin.dart';
import 'package:liu_stoma/widgets/patient_modal/patient_modal_programare_handlers_mixin.dart';
import 'package:liu_stoma/widgets/patient_modal/patient_modal_patient_handlers_mixin.dart';
import 'package:liu_stoma/widgets/common/modal_wrapper.dart';
import 'package:liu_stoma/utils/patient_parser.dart';
import 'package:liu_stoma/utils/patient_validation.dart';
import 'package:liu_stoma/services/patient_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModal extends StatefulWidget {
  final String? patientName;
  final String? patientId;
  final String? initialCnp;
  final String? initialTelefon;
  final List<Programare> programari;
  final double scale;
  final VoidCallback onClose;
  final VoidCallback onAddProgramare;

  const PatientModal({
    super.key,
    this.patientName,
    this.patientId,
    this.initialCnp,
    this.initialTelefon,
    this.programari = const [],
    required this.scale,
    required this.onClose,
    required this.onAddProgramare,
  });

  bool get isAddMode => patientId == null;

  @override
  State<PatientModal> createState() => _PatientModalState();
}

class _PatientModalState extends State<PatientModal>
    with
        PatientModalValidationMixin,
        PatientModalAutosaveMixin,
        PatientModalProgramareHandlersMixin,
        PatientModalPatientHandlersMixin {
  // Modal visibility flags
  bool _showAddProgramareModal = false;
  bool _showRetroactiveProgramareModal = false;
  bool _showEditProgramareModal = false;
  bool _showHistoryModal = false;
  bool _showFilesModal = false;
  bool _showDeletePatientConfirmation = false;
  bool _showOverlapConfirmation = false;

  // Programare state
  List<Programare> _expiredProgramari = [];
  Programare? _programareToEdit;
  Programare? _programareToDelete;

  // Pending overlap confirmation state
  DateTime? _pendingAddDateTime;
  String? _pendingAddProcedura;
  bool? _pendingAddNotificare;
  int? _pendingAddDurata;
  String? _pendingAddPatientId;

  // Notification state
  String? _notificationMessage;
  bool? _notificationIsSuccess;

  // Form controllers
  late TextEditingController _numeController;
  late TextEditingController _cnpController;
  late TextEditingController _telefonController;
  late TextEditingController _emailController;
  late TextEditingController _descriereController;

  // Focus nodes
  late FocusNode _numeFocusNode;
  late FocusNode _cnpFocusNode;
  late FocusNode _telefonFocusNode;

  // Validation state
  String? _numeError;
  String? _cnpError;
  String? _telefonError;
  String? _emailError;
  bool _numeTouched = false;
  bool _cnpTouched = false;
  bool _telefonTouched = false;
  bool _emailTouched = false;
  bool _shouldValidateAll = false;

  // Auto-save state
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  String? _createdPatientId;
  String? _lastInitializedDataHash;

  // ============ Mixin interface implementations ============

  // Validation mixin
  @override
  TextEditingController get numeController => _numeController;
  @override
  TextEditingController get cnpController => _cnpController;
  @override
  TextEditingController get telefonController => _telefonController;
  @override
  TextEditingController get emailController => _emailController;
  @override
  TextEditingController get descriereController => _descriereController;

  @override
  String? get numeError => _numeError;
  @override
  set numeError(String? value) => _numeError = value;
  @override
  String? get cnpError => _cnpError;
  @override
  set cnpError(String? value) => _cnpError = value;
  @override
  String? get telefonError => _telefonError;
  @override
  set telefonError(String? value) => _telefonError = value;
  @override
  String? get emailError => _emailError;
  @override
  set emailError(String? value) => _emailError = value;

  @override
  bool get numeTouched => _numeTouched;
  @override
  bool get cnpTouched => _cnpTouched;
  @override
  bool get telefonTouched => _telefonTouched;
  @override
  bool get emailTouched => _emailTouched;

  @override
  bool get shouldValidateAll => _shouldValidateAll;
  @override
  set shouldValidateAll(bool value) => _shouldValidateAll = value;

  // Autosave mixin
  @override
  Timer? get autoSaveTimer => _autoSaveTimer;
  @override
  set autoSaveTimer(Timer? value) => _autoSaveTimer = value;

  @override
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  @override
  set hasUnsavedChanges(bool value) => _hasUnsavedChanges = value;

  @override
  String? get createdPatientId => _createdPatientId;
  @override
  set createdPatientId(String? value) => _createdPatientId = value;

  @override
  String? get notificationMessage => _notificationMessage;
  @override
  set notificationMessage(String? value) => _notificationMessage = value;

  @override
  bool? get notificationIsSuccess => _notificationIsSuccess;
  @override
  set notificationIsSuccess(bool? value) => _notificationIsSuccess = value;

  @override
  VoidCallback get onAddProgramareCallback => widget.onAddProgramare;

  @override
  VoidCallback get onCloseCallback => widget.onClose;

  // Programare handlers mixin
  @override
  bool get showAddProgramareModal => _showAddProgramareModal;
  @override
  set showAddProgramareModal(bool value) => _showAddProgramareModal = value;

  @override
  bool get showRetroactiveProgramareModal => _showRetroactiveProgramareModal;
  @override
  set showRetroactiveProgramareModal(bool value) =>
      _showRetroactiveProgramareModal = value;

  @override
  bool get showEditProgramareModal => _showEditProgramareModal;
  @override
  set showEditProgramareModal(bool value) => _showEditProgramareModal = value;

  @override
  Programare? get programareToEdit => _programareToEdit;
  @override
  set programareToEdit(Programare? value) => _programareToEdit = value;

  @override
  Programare? get programareToDelete => _programareToDelete;
  @override
  set programareToDelete(Programare? value) => _programareToDelete = value;

  @override
  List<Programare> get expiredProgramari => _expiredProgramari;

  @override
  bool get showOverlapConfirmation => _showOverlapConfirmation;
  @override
  set showOverlapConfirmation(bool value) => _showOverlapConfirmation = value;

  @override
  DateTime? get pendingAddDateTime => _pendingAddDateTime;
  @override
  set pendingAddDateTime(DateTime? value) => _pendingAddDateTime = value;

  @override
  String? get pendingAddProcedura => _pendingAddProcedura;
  @override
  set pendingAddProcedura(String? value) => _pendingAddProcedura = value;

  @override
  bool? get pendingAddNotificare => _pendingAddNotificare;
  @override
  set pendingAddNotificare(bool? value) => _pendingAddNotificare = value;

  @override
  int? get pendingAddDurata => _pendingAddDurata;
  @override
  set pendingAddDurata(int? value) => _pendingAddDurata = value;

  @override
  String? get pendingAddPatientId => _pendingAddPatientId;
  @override
  set pendingAddPatientId(String? value) => _pendingAddPatientId = value;

  // Patient handlers mixin
  @override
  bool get showDeletePatientConfirmation => _showDeletePatientConfirmation;
  @override
  set showDeletePatientConfirmation(bool value) =>
      _showDeletePatientConfirmation = value;

  @override
  bool get showHistoryModal => _showHistoryModal;
  @override
  set showHistoryModal(bool value) => _showHistoryModal = value;

  @override
  bool get showFilesModal => _showFilesModal;
  @override
  set showFilesModal(bool value) => _showFilesModal = value;

  // ============ State methods ============

  @override
  String? getEffectivePatientId() {
    return widget.patientId ?? _createdPatientId;
  }

  @override
  bool isEffectivelyAddMode() {
    return getEffectivePatientId() == null;
  }

  @override
  void initState() {
    super.initState();
    _numeController = TextEditingController(text: widget.patientName ?? '');
    _cnpController = TextEditingController(text: widget.initialCnp ?? '');
    _telefonController =
        TextEditingController(text: widget.initialTelefon ?? '');
    _emailController = TextEditingController();
    _descriereController = TextEditingController();

    _numeFocusNode = FocusNode();
    _cnpFocusNode = FocusNode();
    _telefonFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _setInitialFocus();
      if (widget.isAddMode) {
        final hasData = (widget.patientName?.isNotEmpty ?? false) ||
            (widget.initialCnp?.isNotEmpty ?? false) ||
            (widget.initialTelefon?.isNotEmpty ?? false);
        if (hasData) {
          final findResult = await PatientService.findPatientByCnpOrPhone(
            cnp: widget.initialCnp,
            telefon: widget.initialTelefon,
          );

          if (mounted) {
            if (findResult.success && findResult.data != null) {
              setState(() {
                _createdPatientId = findResult.data;
              });
            } else if (hasValidDataForSave()) {
              _hasUnsavedChanges = true;
              autoSavePatientDataAddMode();
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    if (_hasUnsavedChanges || (widget.isAddMode && hasValidDataForSave())) {
      autoSavePatientDataSilent();
    }
    _numeController.dispose();
    _cnpController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _descriereController.dispose();
    _numeFocusNode.dispose();
    _cnpFocusNode.dispose();
    _telefonFocusNode.dispose();
    super.dispose();
  }

  void _setInitialFocus() {
    if (!widget.isAddMode) return;

    final nume = _numeController.text.trim();
    final cnp = _cnpController.text.trim();
    final telefon = _telefonController.text.trim();

    final cnpValid =
        cnp.isNotEmpty && PatientValidation.validateCNP(cnp) == null;
    final telefonValid =
        telefon.isNotEmpty && PatientValidation.validatePhone(telefon) == null;

    if (cnp.isNotEmpty && !cnpValid) {
      _cnpFocusNode.requestFocus();
      Future.delayed(const Duration(milliseconds: 50), () {
        _cnpController.selection = TextSelection.fromPosition(
          TextPosition(offset: _cnpController.text.length),
        );
      });
      return;
    }

    if (telefon.isNotEmpty && !telefonValid) {
      _telefonFocusNode.requestFocus();
      Future.delayed(const Duration(milliseconds: 50), () {
        _telefonController.selection = TextSelection.fromPosition(
          TextPosition(offset: _telefonController.text.length),
        );
      });
      return;
    }

    if (cnpValid && nume.isEmpty) {
      _numeFocusNode.requestFocus();
      return;
    }

    if (telefonValid && nume.isEmpty) {
      _numeFocusNode.requestFocus();
      return;
    }

    if (nume.isEmpty) {
      _numeFocusNode.requestFocus();
    }
  }

  String _getDataHash(Map<String, dynamic>? patientData) {
    if (patientData == null) return '';
    return '${patientData['nume']}_${patientData['cnp']}_${patientData['telefon']}_${patientData['nr. telefon']}_${patientData['email']}_${patientData['descriere']}';
  }

  void _initializeControllers(Map<String, dynamic>? patientData) {
    final currentHash = _getDataHash(patientData);
    if (_lastInitializedDataHash == currentHash) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (patientData != null) {
        _numeController.text =
            patientData['nume']?.toString() ?? widget.patientName ?? '';
        _cnpController.text = patientData['cnp']?.toString() ?? '';
        _telefonController.text = patientData['telefon']?.toString() ??
            patientData['nr. telefon']?.toString() ??
            '';
        _emailController.text = patientData['email']?.toString() ?? '';
        _descriereController.text = patientData['descriere']?.toString() ?? '';
      } else {
        _numeController.text = widget.patientName ?? '';
        _cnpController.text = '';
        _telefonController.text = '';
        _emailController.text = '';
        _descriereController.text = '';
      }
    });

    _numeTouched = false;
    _cnpTouched = false;
    _telefonTouched = false;
    _emailTouched = false;
    _shouldValidateAll = false;
    _numeError = null;
    _cnpError = null;
    _telefonError = null;
    _emailError = null;

    _lastInitializedDataHash = currentHash;
  }

  @override
  Widget build(BuildContext context) {
    final patientId = getEffectivePatientId();

    if (patientId == null) {
      return _buildModalContent(null, const [], const []);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .snapshots(),
      builder: (context, snapshot) {
        List<Programare> currentProgramari = widget.programari;
        Map<String, dynamic>? patientData;

        if (snapshot.hasData && snapshot.data!.exists) {
          patientData = snapshot.data!.data() as Map<String, dynamic>;
          currentProgramari = PatientParser.parseProgramari(patientData);
          _initializeControllers(patientData);
        } else {
          _initializeControllers(null);
        }

        final now = DateTime.now();
        final fourHoursAgo = now.subtract(const Duration(hours: 4));
        final activeProgramari = currentProgramari.where((p) {
          final programareDate = p.programareTimestamp.toDate();
          return programareDate.isAfter(fourHoursAgo);
        }).toList();

        final expiredProgramariLocal = currentProgramari.where((p) {
          final programareDate = p.programareTimestamp.toDate();
          return programareDate.isBefore(fourHoursAgo) ||
              programareDate.isAtSameMomentAs(fourHoursAgo);
        }).toList();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _expiredProgramari = expiredProgramariLocal;
            });
          }
        });

        return _buildModalContent(
            patientData, activeProgramari, expiredProgramariLocal);
      },
    );
  }

  Widget _buildModalContent(Map<String, dynamic>? patientData,
      List<Programare> activeProgramari, List<Programare> expiredProgramariList) {
    return Stack(
      children: [
        ModalWrapper(
          onClose: widget.onClose,
          scale: widget.scale,
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              PatientModalHeader(
                scale: widget.scale,
                title: isEffectivelyAddMode()
                    ? 'Adaugă pacient'
                    : (widget.patientName ?? _numeController.text),
                onClose: widget.onClose,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(40 * widget.scale),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: PatientAppointmentsSection(
                          scale: widget.scale,
                          isAddMode: isEffectivelyAddMode(),
                          activeProgramari: activeProgramari,
                          onEdit: (Programare programare) {
                            setState(() {
                              _programareToEdit = programare;
                              _showEditProgramareModal = true;
                            });
                          },
                          onDelete: (Programare programare) {
                            showDeleteConfirmation(programare);
                          },
                          onAddProgramare: () {
                            setState(() {
                              _showAddProgramareModal = true;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 40 * widget.scale),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: PatientInfoForm(
                                scale: widget.scale,
                                numeController: _numeController,
                                cnpController: _cnpController,
                                telefonController: _telefonController,
                                emailController: _emailController,
                                descriereController: _descriereController,
                                numeFocusNode: _numeFocusNode,
                                cnpFocusNode: _cnpFocusNode,
                                telefonFocusNode: _telefonFocusNode,
                                numeError: _numeError,
                                cnpError: _cnpError,
                                telefonError: _telefonError,
                                emailError: _emailError,
                                numeTouched: _numeTouched,
                                cnpTouched: _cnpTouched,
                                telefonTouched: _telefonTouched,
                                emailTouched: _emailTouched,
                                shouldValidateAll: _shouldValidateAll,
                                onNumeChanged: (value) {
                                  setState(() {
                                    _numeTouched = true;
                                  });
                                  validateFieldIfTouched('nume', value);
                                  resetAutoSaveTimer();
                                },
                                onCnpChanged: (value) {
                                  setState(() {
                                    _cnpTouched = true;
                                  });
                                  validateFieldIfTouched('cnp', value);
                                  resetAutoSaveTimer();
                                },
                                onTelefonChanged: (value) {
                                  setState(() {
                                    _telefonTouched = true;
                                  });
                                  validateFieldIfTouched('telefon', value);
                                  resetAutoSaveTimer();
                                },
                                onEmailChanged: (value) {
                                  setState(() {
                                    _emailTouched = true;
                                  });
                                  validateFieldIfTouched('email', value);
                                  resetAutoSaveTimer();
                                },
                                onDescriereChanged: (value) {
                                  resetAutoSaveTimer();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PatientModalBottomButtons(
                scale: widget.scale,
                isAddMode: isEffectivelyAddMode(),
                hasHistory: _expiredProgramari.isNotEmpty,
                onSave: savePatientDataManually,
                onDelete: showDeletePatientConfirmationDialog,
                onHistory: () {
                  setState(() {
                    _showHistoryModal = true;
                  });
                },
                onFiles: () {
                  setState(() {
                    _showFilesModal = true;
                  });
                },
              ),
            ],
          ),
        ),
        PatientModalOverlays(
          scale: widget.scale,
          isAddMode: isEffectivelyAddMode(),
          patientId: getEffectivePatientId(),
          showAddProgramareModal: _showAddProgramareModal,
          showRetroactiveProgramareModal: _showRetroactiveProgramareModal,
          showEditProgramareModal: _showEditProgramareModal,
          showHistoryModal: _showHistoryModal,
          showFilesModal: _showFilesModal,
          showDeletePatientConfirmation: _showDeletePatientConfirmation,
          showOverlapConfirmation: _showOverlapConfirmation,
          programareToEdit: _programareToEdit,
          programareToDelete: _programareToDelete,
          expiredProgramari: _expiredProgramari,
          pendingAddDateTime: _pendingAddDateTime,
          pendingAddProcedura: _pendingAddProcedura,
          pendingAddNotificare: _pendingAddNotificare,
          pendingAddDurata: _pendingAddDurata,
          pendingAddPatientId: _pendingAddPatientId,
          notificationMessage: _notificationMessage,
          notificationIsSuccess: _notificationIsSuccess,
          onCloseAddProgramareModal: () {
            setState(() {
              _showAddProgramareModal = false;
            });
          },
          onCloseRetroactiveProgramareModal: () {
            setState(() {
              _showRetroactiveProgramareModal = false;
            });
          },
          onCloseEditProgramareModal: () {
            setState(() {
              _showEditProgramareModal = false;
              _programareToEdit = null;
            });
          },
          onCloseHistoryModal: () {
            setState(() {
              _showHistoryModal = false;
            });
          },
          onCloseFilesModal: () {
            setState(() {
              _showFilesModal = false;
            });
          },
          onValidationError: (String errorMessage) {
            setState(() {
              _notificationMessage = errorMessage;
              _notificationIsSuccess = false;
            });
          },
          onSaveAddProgramare: handleSaveAddProgramare,
          onSaveRetroactiveProgramare: handleSaveRetroactiveProgramare,
          onSaveEditProgramare: handleSaveEditProgramare,
          onEditProgramare: (Programare programare) {
            setState(() {
              _programareToEdit = programare;
              _showEditProgramareModal = true;
            });
          },
          onDeleteProgramare: deleteProgramare,
          onCancelDeleteProgramare: () {
            setState(() {
              _programareToDelete = null;
            });
          },
          onAddConsultation: () {
            setState(() {
              _showRetroactiveProgramareModal = true;
            });
          },
          onDeletePatient: deletePatient,
          onCancelDeletePatient: () {
            setState(() {
              _showDeletePatientConfirmation = false;
            });
          },
          onConfirmOverlap: handleOverlapConfirmation,
          onCancelOverlap: handleCancelOverlap,
          onDismissNotification: () {
            setState(() {
              _notificationMessage = null;
              _notificationIsSuccess = null;
            });
          },
          onAddProgramare: widget.onAddProgramare,
        ),
      ],
    );
  }
}
