import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/utils/patient_filters.dart';
import 'package:liu_stoma/utils/navigation_utils.dart';
import 'package:liu_stoma/widgets/patient_list.dart';
import 'package:liu_stoma/widgets/patient_modal.dart';
import 'package:liu_stoma/widgets/patient_search_bar.dart';
import 'package:liu_stoma/pages/patient_details_page.dart';
import 'package:liu_stoma/widgets/teeth_background.dart';
import 'package:liu_stoma/widgets/welcome_title.dart';
import 'package:liu_stoma/widgets/delete_patient_dialog.dart';
import 'package:liu_stoma/widgets/add_programare_modal.dart';
import 'package:liu_stoma/widgets/patient_long_press_menu.dart';
import 'package:liu_stoma/widgets/custom_notification.dart';
import 'package:liu_stoma/services/patient_service.dart';
import 'package:liu_stoma/pages/programare_details_page.dart';
import 'package:liu_stoma/app.dart';
import 'package:liu_stoma/widgets/confirm_dialog.dart';
import 'package:liu_stoma/widgets/common/animated_back_button.dart';

class PacientiPage extends StatefulWidget {
  final bool? isSelectionPage;
  const PacientiPage({super.key, this.isSelectionPage});

  @override
  State<PacientiPage> createState() => _PacientiPageState();
}
class _PacientiPageState extends State<PacientiPage> {
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');
  String? _selectedPatientName;
  String? _selectedPatientId;
  List<Programare> _selectedPatientProgramari = [];
  bool _showAddPatientModal = false;
  
  // Long-press popup menu state (mobile only)
  String? _longPressPatientId;
  bool _showDeletePatientConfirmation = false;
  bool _showAddProgramareModal = false;
  bool _showLongPressMenu = false;
  Offset? _longPressMenuPosition;
  Offset? _longPressCardPosition;
  Size? _longPressCardSize;
  String? _notificationMessage;
  bool? _notificationIsSuccess;
  bool _showOverlapConfirmation = false;
  DateTime? _pendingAddDateTime;
  List<Procedura>? _pendingAddProceduri;
  bool? _pendingAddNotificare;
  int? _pendingAddDurata;
  double? _pendingAddTotalOverride;
  double? _pendingAddAchitat;

  @override
  void dispose() {
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const designWidth = 1200.0;
        final width = constraints.maxWidth;

        // More conservative scaling for larger screens to prevent oversized elements
        // Scale calculation: smaller screens get smaller scale, but cap growth on large screens
        final isMobile = width < 800;
        double scale;
        if (isMobile) {
          scale = (width / designWidth).clamp(0.4, 0.7);
        } else if (width < 1400) {
          // For laptop screens, use a more moderate scale
          scale = 0.65 + ((width - 800) / 600) * 0.15; // Scale from 0.65 to 0.8
        } else {
          // For very large screens, cap at 0.75
          scale = 0.75;
        }
        
        final titleFontSize = 130.0 * scale;
        final strokeWidth = 9.0 * scale;
        final shadowOffset = 7.0 * scale;
        // Reduced top padding for better space usage
        final topPadding = constraints.maxHeight * 0.02;
        
        // Responsive search bar max width - smaller on small screens, reasonable on laptops
        final searchBarMaxWidth = width < 800 
            ? width * 0.9 
            : (width < 1400 ? 600.0 : 900.0);
        
        // Responsive horizontal padding - less padding on smaller screens
        final horizontalPadding = width < 800 
            ? 16.0 * scale 
            : 24.0 * scale;

        return Scaffold(
          body: Stack(
            children: [
              TeethBackground(
                vignetteRadius: 3.6, // slightly softer vignette than the main page
                child: Builder(
                  builder: (context) {
                    final safePadding = MediaQuery.of(context).padding;
                    return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('patients')
                  .orderBy('nume')
                  .snapshots(),
              builder: (context, snapshot) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: safePadding.top + topPadding),
                    // Back button
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 20 * scale),
                          child: AnimatedBackButton(
                            onTap: () {
                              if (widget.isSelectionPage != null) {
                                Navigator.of(context).pop(null);
                              } else {
                                Navigator.of(context).pushReplacement(
                                  NavigationUtils.fadeScaleTransition(
                                    page: const MainApp(),
                                  ),
                                );
                              }
                            },
                            scale: scale,
                            isMobile: isMobile,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: FittedBox(
                        child: PacientiTitle(
                          fontSize: titleFontSize,
                          strokeWidth: strokeWidth,
                          shadowOffset: shadowOffset,
                        ),
                      ),
                    ),
                    SizedBox(height: 20 * scale),
                    ValueListenableBuilder<String>(
                      valueListenable: _searchQueryNotifier,
                      builder: (context, searchQuery, child) {
                        int filteredCount = 0;
                        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                          final allPatients = snapshot.data!.docs;
                          final filteredPatients = PatientFilters.filterPatients(
                            allPatients,
                            searchQuery,
                          );
                          filteredCount = filteredPatients.length;
                        }
                        
                        return PatientSearchBar(
                          scale: scale,
                          maxWidth: searchBarMaxWidth,
                          horizontalPadding: horizontalPadding,
                          searchQueryNotifier: _searchQueryNotifier,
                          filteredCount: filteredCount,
                          onAddPatient: () {
                            if (isMobile) {
                              // Navigate to PatientDetailsPage on mobile
                              final rawQuery = _searchQueryNotifier.value;
                              final trimmedQuery = rawQuery.trim();
                              final searchType = PatientFilters.detectSearchType(trimmedQuery);
                              final digitsOnly = trimmedQuery.replaceAll(RegExp(r'[^0-9]'), '');

                              String? initialName;
                              String? initialCnp;
                              String? initialTelefon;

                              switch (searchType) {
                                case PatientSearchType.name:
                                  // Capitalize first letter of each word
                                  initialName = trimmedQuery
                                      .split(' ')
                                      .map((word) {
                                        if (word.isEmpty) return '';
                                        if (word.length == 1) return word.toUpperCase();
                                        return word[0].toUpperCase() + word.substring(1).toLowerCase();
                                      })
                                      .join(' ');
                                  break;
                                case PatientSearchType.cnp:
                                  initialCnp = digitsOnly;
                                  break;
                                case PatientSearchType.phone:
                                  initialTelefon = digitsOnly;
                                  break;
                              }

                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PatientDetailsPage(
                                    patientName: initialName,
                                    patientId: null,
                                    initialCnp: initialCnp,
                                    initialTelefon: initialTelefon,
                                    scale: scale,
                                  ),
                                ),
                              );
                            } else {
                              // Show modal on desktop
                              setState(() {
                                _showAddPatientModal = true;
                              });
                            }
                          },
                        );
                      },
                    ),
                    SizedBox(height: 20 * scale),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: _searchQueryNotifier,
                        builder: (context, searchQuery, child) {
                          return PatientList(
                            isMobile: isMobile,
                            snapshot: snapshot,
                            searchQuery: searchQuery,
                            scale: scale,
                            maxWidth: constraints.maxWidth,
                            horizontalPadding: horizontalPadding,
                            maxContentWidth: searchBarMaxWidth,
                            selectedPatientId: _longPressPatientId,
                            onPatientTap: (name, patientId, programari) {
                              print(
                                  '[PacientiPage] Patient tapped: $name (ID: $patientId)');
                              if (widget.isSelectionPage != null) {
                                Navigator.of(context).pop(patientId);
                              } else {  
                                if (isMobile) {
                                  // Navigate to separate page on mobile
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => PatientDetailsPage(
                                        patientName: name,
                                        patientId: patientId,
                                        programari: programari,
                                        scale: scale,
                                      ),
                                    ),
                                  );
                                } else {
                                  // Show modal on desktop
                                  setState(() {
                                    _selectedPatientName = name;
                                    _selectedPatientId = patientId;
                                    _selectedPatientProgramari = programari;
                                  });
                                }
                              }
                            },
                            onPatientLongPress: isMobile && widget.isSelectionPage == null
                                ? (name, patientId, programari, menuPosition, cardPosition, cardSize) {
                                    setState(() {
                                      _longPressPatientId = patientId;
                                      _longPressMenuPosition = menuPosition;
                                      _longPressCardPosition = cardPosition;
                                      _longPressCardSize = cardSize;
                                      _showLongPressMenu = true;
                                    });
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
              },
            ),
          ),
              // Modal overlay for editing existing patient (desktop only)
              if (!isMobile && _selectedPatientName != null && _selectedPatientId != null && widget.isSelectionPage == null)
                PatientModal(
                  patientName: _selectedPatientName!,
                  patientId: _selectedPatientId!,
                  programari: _selectedPatientProgramari,
                  scale: scale,
                  onClose: () {
                    print('[PacientiPage] Closing patient modal');
                    setState(() {
                      _selectedPatientName = null;
                      _selectedPatientId = null;
                      _selectedPatientProgramari = [];
                    });
                  },
                  onAddProgramare: () {
                    print('[PacientiPage] Programare added, modal will refresh from Firestore stream');
                    // The StreamBuilder will automatically refresh and show the new programare
                  },
                ),
              // Modal overlay for adding new patient (desktop only)
              if (_showAddPatientModal && !isMobile && widget.isSelectionPage == null)
                Builder(
                  builder: (context) {
                    final rawQuery = _searchQueryNotifier.value;
                    final trimmedQuery = rawQuery.trim();
                    final searchType = PatientFilters.detectSearchType(trimmedQuery);
                    final digitsOnly = trimmedQuery.replaceAll(RegExp(r'[^0-9]'), '');

                    String? initialName;
                    String? initialCnp;
                    String? initialTelefon;

                    switch (searchType) {
                      case PatientSearchType.name:
                        // Capitalize first letter of each word
                        initialName = trimmedQuery
                            .split(' ')
                            .map((word) {
                              if (word.isEmpty) return '';
                              if (word.length == 1) return word.toUpperCase();
                              return word[0].toUpperCase() + word.substring(1).toLowerCase();
                            })
                            .join(' ');
                        break;
                      case PatientSearchType.cnp:
                        initialCnp = digitsOnly;
                        break;
                      case PatientSearchType.phone:
                        initialTelefon = digitsOnly;
                        break;
                    }

                    return PatientModal(
                      patientName: initialName,
                      patientId: null,
                      initialCnp: initialCnp,
                      initialTelefon: initialTelefon,
                      programari: const [],
                      scale: scale,
                      onClose: () {
                        print('[PacientiPage] Closing add patient modal');
                        setState(() {
                          _showAddPatientModal = false;
                          _searchQueryNotifier.value = '';
                        });
                      },
                      onAddProgramare: () {
                        print('[PacientiPage] Patient added, list will refresh from Firestore stream');
                        // The StreamBuilder will automatically refresh and show the new patient
                      },
                    );
                  },
                ),
              // Long-press popup menu overlays (mobile only)
              if (isMobile && _showLongPressMenu && _longPressMenuPosition != null && widget.isSelectionPage == null)
                PatientLongPressMenu(
                  scale: scale,
                  cardScale: (scale * 1.9).clamp(0.4, 1.4), // Match card scale calculation
                  position: _longPressMenuPosition!,
                  onAddProgramare: () {
                    setState(() {
                      _showLongPressMenu = false;
                      _longPressMenuPosition = null;
                      _longPressCardPosition = null;
                      _longPressCardSize = null;
                    });
                    
                    // Navigate to ProgramareDetailsPage on mobile
                    if (_longPressPatientId != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProgramareDetailsPage(
                            programare: null,
                            patientId: _longPressPatientId!,
                            scale: scale,
                            isConsultatie: false,
                            onNotification: (String message, bool isSuccess) {
                              // Show notification after returning
                              setState(() {
                                _notificationMessage = message;
                                _notificationIsSuccess = isSuccess;
                              });
                            },
                          ),
                        ),
                      ).then((_) {
                        // Clear the selected patient ID after navigation
                        setState(() {
                          _longPressPatientId = null;
                        });
                      });
                    }
                  },
                  onDelete: () {
                    setState(() {
                      _showLongPressMenu = false;
                      _showDeletePatientConfirmation = true;
                    });
                  },
                  onClose: () {
                    setState(() {
                      _showLongPressMenu = false;
                      _longPressMenuPosition = null;
                      _longPressCardPosition = null;
                      _longPressCardSize = null;
                      if (!_showDeletePatientConfirmation && !_showAddProgramareModal) {
                        _longPressPatientId = null;
                      }
                    });
                  },
                  cardPosition: _longPressCardPosition,
                  cardSize: _longPressCardSize,
                ),
              if (isMobile && _showDeletePatientConfirmation)
                DeletePatientDialog(
                  scale: scale,
                  onCancel: () {
                    setState(() {
                      _showDeletePatientConfirmation = false;
                      _longPressPatientId = null;
                    });
                  },
                  onConfirm: () async {
                    if (_longPressPatientId == null) return;
                    
                    setState(() {
                      _showDeletePatientConfirmation = false;
                    });
                    
                    final result = await PatientService.deletePatient(
                      patientId: _longPressPatientId!,
                    );
                    
                    if (mounted) {
                      setState(() {
                        if (result.success) {
                          _notificationMessage = 'Pacient șters cu succes';
                          _notificationIsSuccess = true;
                        } else {
                          _notificationMessage = result.errorMessage ?? 'Eroare la ștergere';
                          _notificationIsSuccess = false;
                        }
                      });
                    }
                    
                    setState(() {
                      _longPressPatientId = null;
                    });
                  },
                ),
              if (isMobile && _showAddProgramareModal && _longPressPatientId != null)
                AddProgramareModal(
                  scale: scale,
                  shouldCloseAfterSave: false, // Don't auto-close, we'll close it after overlap confirmation
                  onClose: () {
                    setState(() {
                      _showAddProgramareModal = false;
                      _longPressPatientId = null;
                    });
                  },
                  onValidationError: (String errorMessage) {
                    setState(() {
                      _notificationMessage = errorMessage;
                      _notificationIsSuccess = false;
                    });
                  },
                  onSave: (List<Procedura> proceduri, Timestamp timestamp, bool notificare, int? durata, double? totalOverride, double achitat, String? patientId) async {
                    if (_longPressPatientId == null) return;
                    
                    // Check for overlaps before saving - check against ALL appointments from ALL patients
                    final newDateTime = timestamp.toDate();
                    
                    // Skip overlap check for consultations without dates (epoch date)
                    final isDateSkipped = newDateTime.year == 1970 && 
                                          newDateTime.month == 1 && 
                                          newDateTime.day == 1;
                    
                    final hasOverlap = !isDateSkipped && await PatientService.checkOverlapWithAllAppointments(
                      newDateTime: newDateTime,
                      newDurata: durata,
                    );
                    
                    if (hasOverlap) {
                      setState(() {
                        _pendingAddDateTime = newDateTime;
                        _pendingAddProceduri = proceduri;
                        _pendingAddNotificare = notificare;
                        _pendingAddDurata = durata;
                        _pendingAddTotalOverride = totalOverride;
                        _pendingAddAchitat = achitat;
                        _showOverlapConfirmation = true;
                      });
                      // Modal stays open - will close after user confirms overlap
                    } else {
                      // No overlap, save and close immediately
                      final result = await PatientService.addProgramare(
                        patientId: _longPressPatientId!,
                        proceduri: proceduri,
                        timestamp: timestamp,
                        notificare: notificare,
                        durata: durata,
                        totalOverride: totalOverride,
                        achitat: achitat,
                      );
                      
                      if (mounted) {
                        setState(() {
                          if (result.success) {
                            _showAddProgramareModal = false;
                            _notificationMessage = 'Programare adăugată cu succes!';
                            _notificationIsSuccess = true;
                          } else {
                            _notificationMessage = result.errorMessage ?? 'Eroare la salvare';
                            _notificationIsSuccess = false;
                          }
                          _longPressPatientId = null;
                        });
                      }
                    }
                  },
                ),
              // Overlap Confirmation Dialog for adding from pacienti page
              if (_showOverlapConfirmation)
                ConfirmDialog(
                  title: 'Confirmă suprapunerea',
                  message: 'Această programare se suprapune cu o altă programare. Ești sigură că vrei să continui?',
                  confirmText: 'Salvează',
                  cancelText: 'Anulează',
                  scale: scale,
                  onConfirm: () async {
                    if (_pendingAddDateTime != null && 
                        _pendingAddProceduri != null && 
                        _pendingAddNotificare != null &&
                        _longPressPatientId != null) {
                      final timestamp = Timestamp.fromDate(_pendingAddDateTime!);
                      final result = await PatientService.addProgramare(
                        patientId: _longPressPatientId!,
                        proceduri: _pendingAddProceduri!,
                        timestamp: timestamp,
                        notificare: _pendingAddNotificare!,
                        durata: _pendingAddDurata,
                        totalOverride: _pendingAddTotalOverride,
                        achitat: _pendingAddAchitat ?? 0.0,
                      );

                      setState(() {
                        _showOverlapConfirmation = false;
                        _pendingAddDateTime = null;
                        _pendingAddProceduri = null;
                        _pendingAddNotificare = null;
                        _pendingAddDurata = null;
                        _pendingAddTotalOverride = null;
                        _pendingAddAchitat = null;
                      });

                      if (mounted) {
                        setState(() {
                          if (result.success) {
                            _showAddProgramareModal = false;
                            _notificationMessage = 'Programare adăugată cu succes!';
                            _notificationIsSuccess = true;
                          } else {
                            _notificationMessage = result.errorMessage ?? 'Eroare la salvare';
                            _notificationIsSuccess = false;
                          }
                          _longPressPatientId = null;
                        });
                      }
                    }
                  },
                  onCancel: () {
                    // Just close the overlap confirmation, keep the add modal open
                    setState(() {
                      _showOverlapConfirmation = false;
                      _pendingAddDateTime = null;
                      _pendingAddProceduri = null;
                      _pendingAddNotificare = null;
                      _pendingAddDurata = null;
                      _pendingAddTotalOverride = null;
                      _pendingAddAchitat = null;
                    });
                  },
                ),
              // Custom notification overlay
              if (_notificationMessage != null && _notificationIsSuccess != null)
                CustomNotification(
                  message: _notificationMessage!,
                  isSuccess: _notificationIsSuccess!,
                  scale: scale,
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
      },
    );
  }

}
