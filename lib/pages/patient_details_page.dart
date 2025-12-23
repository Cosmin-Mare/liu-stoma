import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/widgets/patient_details/programari_tab.dart';
import 'package:liu_stoma/widgets/patient_details/informatii_tab.dart';
import 'package:liu_stoma/widgets/patient_details/istoric_tab.dart';
import 'package:liu_stoma/widgets/patient_details/fisiere_tab.dart';
import 'package:liu_stoma/widgets/patient_details/patient_details_overlays.dart';
import 'package:liu_stoma/widgets/custom_notification.dart';
import 'package:liu_stoma/utils/patient_parser.dart';
import 'package:liu_stoma/services/patient_service.dart';
import 'package:liu_stoma/services/file_service.dart';

class PatientDetailsPage extends StatefulWidget {
  final String? patientName;
  final String? patientId;
  final String? initialCnp;
  final String? initialTelefon;
  final List<Programare> programari;
  final double scale;
  const PatientDetailsPage({
    super.key,
    this.patientName,
    this.patientId,
    this.initialCnp,
    this.initialTelefon,
    this.programari = const [],
    required this.scale,
  });

  bool get isAddMode => patientId == null;

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // State management
  bool _showAddProgramareModal = false;
  bool _showRetroactiveProgramareModal = false;
  bool _showEditProgramareModal = false;
  List<Programare> _expiredProgramari = [];
  Programare? _programareToEdit;
  Programare? _programareToDelete;
  bool _showDeletePatientConfirmation = false;
  String? _notificationMessage;
  bool? _notificationIsSuccess;

  // For add mode: store the actual patientId (created immediately)
  String? _actualPatientId;
  bool _isCreatingPatient = false;

  // Controllers
  late TextEditingController _numeController;
  late TextEditingController _cnpController;
  late TextEditingController _telefonController;
  late TextEditingController _emailController;
  late TextEditingController _descriereController;
  late FocusNode _numeFocusNode;
  late FocusNode _cnpFocusNode;
  late FocusNode _telefonFocusNode;

  // Validation
  String? _lastInitializedDataHash;

  // Files
  bool _isUploading = false;
  PatientFile? _fileToDelete;
  final GlobalKey<FisiereTabState> _fisiereTabKey = GlobalKey<FisiereTabState>();

  // Get the actual patientId to use (either from widget or from state in add mode)
  String? get _effectivePatientId => widget.patientId ?? _actualPatientId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _numeController = TextEditingController(text: widget.patientName ?? '');
    _cnpController = TextEditingController(text: widget.initialCnp ?? '');
    _telefonController = TextEditingController(text: widget.initialTelefon ?? '');
    _emailController = TextEditingController();
    _descriereController = TextEditingController();

    _numeFocusNode = FocusNode();
    _cnpFocusNode = FocusNode();
    _telefonFocusNode = FocusNode();

    // Auto-open Informații tab (index 1) when in add mode
    if (widget.isAddMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController.index != 1) {
          _tabController.animateTo(1);
        }
      });
      // Create patient document immediately so we can use all tabs
      _createDraftPatient();
    }
  }

  Future<void> _createDraftPatient() async {
    if (_isCreatingPatient || _actualPatientId != null) return;
    
    setState(() {
      _isCreatingPatient = true;
    });

    try {
      // Create a draft patient with minimal data
      final patientRef = FirebaseFirestore.instance
          .collection('patients')
          .doc();
      
      final numeEmpty = _numeController.text.trim().isEmpty;
      final cnpProvided = _cnpController.text.trim().isNotEmpty;
      final telefonProvided = _telefonController.text.trim().isNotEmpty;
      await patientRef.set({
        'nume': numeEmpty && !cnpProvided && !telefonProvided
            ? 'Pacient nou' 
            : _numeController.text.trim(),
        'cnp': _cnpController.text.trim().isEmpty ? null : _cnpController.text.trim(),
        'telefon': _telefonController.text.trim().isEmpty ? null : _telefonController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'descriere': _descriereController.text.trim().isEmpty ? null : _descriereController.text.trim(),
        'programari': <dynamic>[],
        'clinicId': PatientService.clinicId,
      });
      
      setState(() {
        _actualPatientId = patientRef.id;
        _isCreatingPatient = false;
      });
    } catch (e) {
      setState(() {
        _isCreatingPatient = false;
        _notificationMessage = 'Eroare la crearea pacientului: $e';
        _notificationIsSuccess = false;
      });
    }
  }

  Future<void> _cleanupDraftPatientIfNeeded() async {
    // Only cleanup if we're in add mode and have a draft patient
    if (!widget.isAddMode || _actualPatientId == null) return;
    
    try {
      // Check the actual patient document in Firestore
      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(_actualPatientId)
          .get();
      
      if (!patientDoc.exists) return;
      
      final patientData = patientDoc.data();
      final nume = patientData?['nume']?.toString().trim() ?? '';
      
      // Delete the draft patient if it doesn't have a valid name
      if (nume.isEmpty || nume == 'Pacient nou') {
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(_actualPatientId)
            .delete();
      }
    } catch (e) {
      // Ignore errors when cleaning up
      print('Error cleaning up draft patient: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  String _getDataHash(Map<String, dynamic>? patientData) {
    if (patientData == null) return '';
    return '${patientData['nume']}_${patientData['cnp']}_${patientData['telefon']}_${patientData['nr. telefon']}_${patientData['email']}_${patientData['descriere']}';
  }

  void _initializeControllers(Map<String, dynamic>? patientData) {
    final currentHash = _getDataHash(patientData);
    if (_lastInitializedDataHash == currentHash) {
      return;
    }

    if (patientData != null) {
      _numeController.text = patientData['nume']?.toString() ?? widget.patientName ?? '';
      _cnpController.text = patientData['cnp']?.toString() ?? '';
      _telefonController.text = patientData['telefon']?.toString() ?? patientData['nr. telefon']?.toString() ?? '';
      _emailController.text = patientData['email']?.toString() ?? '';
      _descriereController.text = patientData['descriere']?.toString() ?? '';
    } else {
      _numeController.text = widget.patientName ?? '';
      _cnpController.text = '';
      _telefonController.text = '';
      _emailController.text = '';
      _descriereController.text = '';
    }

    _lastInitializedDataHash = currentHash;
  }

  Future<void> _deletePatient() async {
    setState(() {
      _showDeletePatientConfirmation = false;
    });

    final result = await PatientService.deletePatient(
      patientId: widget.patientId!,
    );

    setState(() {
      if (result.success) {
        _notificationMessage = 'Pacient șters cu succes!';
        _notificationIsSuccess = true;
      } else {
        _notificationMessage = result.errorMessage ?? 'Eroare la ștergerea pacientului';
        _notificationIsSuccess = false;
      }
    });

    if (result.success) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  Future<void> _deleteFile(PatientFile file) async {
    _fisiereTabKey.currentState?.deleteFile(file);
  }

  void _handleNotification(String? message, bool? isSuccess) {
    setState(() {
      _notificationMessage = message;
      _notificationIsSuccess = isSuccess;
    });
  }

  void _handleFileToDeleteChanged(PatientFile? file) {
    setState(() {
      _fileToDelete = file;
    });
  }

  void _handleUploadingChanged(bool isUploading) {
    setState(() {
      _isUploading = isUploading;
    });
  }

  Future<void> _handlePatientCreated(String? newPatientId) async {
    // In add mode, we already have the patientId, just update the document
    // No need to navigate, just show success message
    if (widget.isAddMode && _effectivePatientId != null) {
      setState(() {
        _notificationMessage = 'Pacient salvat cu succes!';
        _notificationIsSuccess = true;
      });
    } else if (newPatientId != null) {
      // Navigate to the same page but with the new patient ID
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PatientDetailsPage(
              patientName: _numeController.text,
              patientId: newPatientId,
              scale: widget.scale,
            ),
          ),
        );
      }
    }
  }

  Widget _buildMainContent(AsyncSnapshot<DocumentSnapshot> snapshot) {
    List<Programare> currentProgramari = widget.programari;
    Map<String, dynamic>? patientData;

    if (snapshot.hasData && snapshot.data!.exists) {
      patientData = snapshot.data!.data() as Map<String, dynamic>;
      currentProgramari = PatientParser.parseProgramari(patientData);
      _initializeControllers(patientData);
    } else {
      _initializeControllers(null);
    }

    // Filter programari: only show those from 4 hours ago onwards
    final now = DateTime.now();
    final fourHoursAgo = now.subtract(const Duration(hours: 4));
    final activeProgramari = currentProgramari.where((p) {
      final programareDate = p.programareTimestamp.toDate();
      return programareDate.isAfter(fourHoursAgo);
    }).toList();

    final expiredProgramari = currentProgramari.where((p) {
      final programareDate = p.programareTimestamp.toDate();
      return programareDate.isBefore(fourHoursAgo) || programareDate.isAtSameMomentAs(fourHoursAgo);
    }).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _expiredProgramari = expiredProgramari;
        });
      }
    });

    return Stack(
      children: [
        Column(
          children: [
            // Tab bar at the top
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 3 * widget.scale),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: Icon(Icons.calendar_today, size: 60 * widget.scale),
                    child: Text('Programări', style: TextStyle(fontSize: 30 * widget.scale)),
                  ),
                  Tab(
                    icon: Icon(Icons.person, size: 60 * widget.scale),
                    child: Text('Informații', style: TextStyle(fontSize: 32 * widget.scale)),
                  ),
                  Tab(
                    icon: Icon(Icons.history, size: 60 * widget.scale),
                    child: Text('Istoric', style: TextStyle(fontSize: 32 * widget.scale)),
                  ),
                  Tab(
                    icon: Icon(Icons.folder, size: 60 * widget.scale),
                    child: Text('Fișiere', style: TextStyle(fontSize: 32 * widget.scale)),
                  ),
                ],
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue[600],
                labelStyle: TextStyle(
                  fontSize: 32 * widget.scale,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 32 * widget.scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Tab content
            Expanded(
              child: Container(
                color: Colors.white,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Programari tab
                    _effectivePatientId != null
                        ? ProgramariTab(
                            activeProgramari: activeProgramari,
                            patientId: _effectivePatientId!,
                            scale: widget.scale,
                            onRefresh: () => setState(() {}),
                            onNotification: _handleNotification,
                          )
                        : Center(
                            child: CircularProgressIndicator(),
                          ),
                    // Informatii tab
                    _effectivePatientId != null
                        ? InformatiiTab(
                            numeController: _numeController,
                            cnpController: _cnpController,
                            telefonController: _telefonController,
                            emailController: _emailController,
                            descriereController: _descriereController,
                            numeFocusNode: _numeFocusNode,
                            cnpFocusNode: _cnpFocusNode,
                            telefonFocusNode: _telefonFocusNode,
                            patientId: _effectivePatientId,
                            scale: widget.scale,
                            onNotification: _handleNotification,
                            onDeletePatient: widget.isAddMode
                                ? null
                                : () {
                                    setState(() {
                                      _showDeletePatientConfirmation = true;
                                    });
                                  },
                            onPatientCreated: widget.isAddMode ? _handlePatientCreated : null,
                          )
                        : Center(
                            child: CircularProgressIndicator(),
                          ),
                    // Istoric tab
                    _effectivePatientId != null
                        ? IstoricTab(
                            expiredProgramari: expiredProgramari,
                            patientId: _effectivePatientId!,
                            scale: widget.scale,
                            onRefresh: () => setState(() {}),
                            onNotification: _handleNotification,
                          )
                        : Center(
                            child: CircularProgressIndicator(),
                          ),
                    // Fisiere tab
                    _effectivePatientId != null
                        ? FisiereTab(
                            key: _fisiereTabKey,
                            patientId: _effectivePatientId!,
                            scale: widget.scale,
                            onNotification: _handleNotification,
                            onFileToDeleteChanged: _handleFileToDeleteChanged,
                            onUploadingChanged: _handleUploadingChanged,
                          )
                        : Center(
                            child: CircularProgressIndicator(),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_effectivePatientId != null)
          PatientDetailsOverlays(
            showAddProgramareModal: _showAddProgramareModal,
            showRetroactiveProgramareModal: _showRetroactiveProgramareModal,
            showEditProgramareModal: _showEditProgramareModal,
            showDeletePatientConfirmation: _showDeletePatientConfirmation,
            expiredProgramari: _expiredProgramari,
            programareToEdit: _programareToEdit,
            programareToDelete: _programareToDelete,
            fileToDelete: _fileToDelete,
            notificationMessage: _notificationMessage,
            notificationIsSuccess: _notificationIsSuccess,
            patientId: _effectivePatientId!,
            scale: widget.scale,
            onRefresh: () => setState(() {}),
            onSetShowAddProgramareModal: (bool value) {
              setState(() {
                _showAddProgramareModal = value;
              });
            },
            onSetShowRetroactiveProgramareModal: (bool value) {
              setState(() {
                _showRetroactiveProgramareModal = value;
              });
            },
            onSetShowEditProgramareModal: (bool value) {
              setState(() {
                _showEditProgramareModal = value;
              });
            },
            onSetShowDeletePatientConfirmation: (bool value) {
              setState(() {
                _showDeletePatientConfirmation = value;
              });
            },
            onSetProgramareToEdit: (Programare? value) {
              setState(() {
                _programareToEdit = value;
              });
            },
            onSetProgramareToDelete: (Programare? value) {
              setState(() {
                _programareToDelete = value;
              });
            },
            onSetFileToDelete: (PatientFile? value) {
              setState(() {
                _fileToDelete = value;
              });
            },
            onNotification: _handleNotification,
            onDeletePatient: _deletePatient,
            onDeleteFile: _deleteFile,
          ),
        // Notification overlay
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

  Widget _buildAddModeContent() {
    return Stack(
      children: [
        Column(
          children: [
            // Tab bar at the top
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 3 * widget.scale),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: Icon(Icons.calendar_today, size: 60 * widget.scale),
                    text: 'Programări',
                  ),
                  Tab(
                    icon: Icon(Icons.person, size: 60 * widget.scale),
                    text: 'Informații',
                  ),
                  Tab(
                    icon: Icon(Icons.history, size: 60 * widget.scale),
                    text: 'Istoric',
                  ),
                  Tab(
                    icon: Icon(Icons.folder, size: 60 * widget.scale),
                    text: 'Fișiere',
                  ),
                ],
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue[600],
                labelStyle: TextStyle(
                  fontSize: 32 * widget.scale,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 32 * widget.scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Programari tab - empty for add mode
                  Center(
                    child: Text(
                      'Nu există programări pentru un pacient nou',
                      style: TextStyle(
                        fontSize: 32 * widget.scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Informatii tab
                  InformatiiTab(
                    numeController: _numeController,
                    cnpController: _cnpController,
                    telefonController: _telefonController,
                    emailController: _emailController,
                    descriereController: _descriereController,
                    numeFocusNode: _numeFocusNode,
                    cnpFocusNode: _cnpFocusNode,
                    telefonFocusNode: _telefonFocusNode,
                    patientId: null,
                    scale: widget.scale,
                    onNotification: _handleNotification,
                    onPatientCreated: _handlePatientCreated,
                  ),
                  // Istoric tab - empty for add mode
                  Center(
                    child: Text(
                      'Nu există istoric pentru un pacient nou',
                      style: TextStyle(
                        fontSize: 32 * widget.scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Fisiere tab - empty for add mode
                  Center(
                    child: Text(
                      'Nu există fișiere pentru un pacient nou',
                      style: TextStyle(
                        fontSize: 32 * widget.scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Notification overlay
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isUploading,
      onPopInvoked: (didPop) async {
        if (didPop) {
          // Cleanup draft patient if user navigated away without a valid name
          await _cleanupDraftPatientIfNeeded();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            widget.isAddMode ? 'Adaugă pacient' : (widget.patientName ?? ''),
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
            onPressed: _isUploading ? null : () async {
              await _cleanupDraftPatientIfNeeded();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: _effectivePatientId != null
              ? FirebaseFirestore.instance
                  .collection('patients')
                  .doc(_effectivePatientId)
                  .snapshots()
              : null,
          builder: (context, snapshot) {
            // In add mode, show loading while creating patient
            if (widget.isAddMode && _isCreatingPatient) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            
            // In add mode but patient not created yet, show loading
            if (widget.isAddMode && _effectivePatientId == null) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            
            // If no patientId available, show add mode content
            if (_effectivePatientId == null) {
              return _buildAddModeContent();
            }
            
            return _buildMainContent(snapshot);
          },
        ),
      ),
    );
  }
}
