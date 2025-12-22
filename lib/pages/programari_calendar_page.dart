import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:liu_stoma/pages/programare_details_page.dart';
import 'package:liu_stoma/widgets/teeth_background.dart';
import 'package:liu_stoma/utils/patient_parser.dart';
import 'package:liu_stoma/utils/navigation_utils.dart';
import 'package:liu_stoma/app.dart';
import 'package:liu_stoma/widgets/calendar/calendar_view_mode.dart';
import 'package:liu_stoma/widgets/calendar/view_mode_button.dart';
import 'package:liu_stoma/widgets/calendar/time_grid_view.dart';
import 'package:liu_stoma/widgets/calendar/month_view.dart';
import 'package:liu_stoma/widgets/calendar/animated_nav_button.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/widgets/add_programare_modal.dart';
import 'package:liu_stoma/services/patient_service.dart';
import 'package:liu_stoma/widgets/custom_notification.dart';
import 'package:liu_stoma/widgets/confirm_dialog.dart';
import 'package:liu_stoma/widgets/common/animated_back_button.dart';

class ProgramariCalendarPage extends StatefulWidget {
  const ProgramariCalendarPage({super.key});

  @override
  State<ProgramariCalendarPage> createState() => _ProgramariCalendarPageState();
}

class _ProgramariCalendarPageState extends State<ProgramariCalendarPage> {
  CalendarViewMode _viewMode = CalendarViewMode.week;
  DateTime _currentDate = DateTime.now();
  PageController? _pageController;
  int _currentPageIndex = 1000; // Middle of the page range
  bool _showEditProgramareModal = false;
  Programare? _programareToEdit;
  String? _patientIdForEdit;
  String? _patientNameForEdit;
  bool _showAddProgramareModal = false;
  DateTime? _selectedDateTime;
  String? _notificationMessage;
  bool? _notificationIsSuccess;
  bool _showOverlapConfirmation = false;
  DateTime? _pendingEditDateTime;
  List<Procedura>? _pendingEditProceduri;
  bool? _pendingEditNotificare;
  int? _pendingEditDurata;
  double? _pendingEditTotalOverride;
  double? _pendingEditAchitat;
  final GlobalKey<TimeGridViewState> _timeGridViewKey = GlobalKey<TimeGridViewState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _changeViewMode(CalendarViewMode mode) {
    setState(() {
      _viewMode = mode;
      _currentPageIndex = 1000; // Reset to middle
      _currentDate = DateTime.now();
      _pageController?.jumpToPage(_currentPageIndex);
    });
  }

  void _navigateToDayView(DateTime day) {
    // Calculate the page index for the target day in day view mode
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dayOnly = DateTime(day.year, day.month, day.day);
    final offset = dayOnly.difference(todayOnly).inDays;
    final targetPageIndex = 1000 + offset;
    
    setState(() {
      _viewMode = CalendarViewMode.day;
      _currentPageIndex = targetPageIndex;
      _currentDate = day;
      _pageController?.jumpToPage(targetPageIndex);
    });
  }

  DateTime _getDateForPage(int pageIndex, {bool isMobile = false}) {
    final offset = pageIndex - 1000;
    switch (_viewMode) {
      case CalendarViewMode.day:
        return DateTime.now().add(Duration(days: offset));
      case CalendarViewMode.week:
        if (isMobile) {
          // On mobile, move by 3 days at a time
          final today = DateTime.now();
          final startDate = DateTime(today.year, today.month, today.day);
          return startDate.add(Duration(days: offset * 3));
        }
        final startOfCurrentWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
        return startOfCurrentWeek.add(Duration(days: offset * 7));
      case CalendarViewMode.month:
        return DateTime(DateTime.now().year, DateTime.now().month + offset, DateTime.now().day);
    }
  }


  List<DateTime> _getDaysForPage(DateTime date, {bool isMobile = false}) {
    switch (_viewMode) {
      case CalendarViewMode.day:
        return [date];
      case CalendarViewMode.week:
        if (isMobile) {
          // On mobile, show only 3 consecutive days
          return List.generate(3, (i) => date.add(Duration(days: i)));
        }
        final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
        return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
      case CalendarViewMode.month:
        final firstDay = DateTime(date.year, date.month, 1);
        final lastDay = DateTime(date.year, date.month + 1, 0);
        final days = <DateTime>[];
        // Add days from previous month to fill first week
        final startWeekday = firstDay.weekday;
        for (int i = startWeekday - 1; i > 0; i--) {
          days.add(firstDay.subtract(Duration(days: i)));
        }
        // Add days of current month
        for (int i = 1; i <= lastDay.day; i++) {
          days.add(DateTime(date.year, date.month, i));
        }
        // Add days from next month to fill last week
        final endWeekday = lastDay.weekday;
        for (int i = 1; i <= 7 - endWeekday; i++) {
          days.add(lastDay.add(Duration(days: i)));
        }
        return days;
    }
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const designWidth = 1200.0;
        final scale = (width / designWidth).clamp(0.4, 1.0);
        final isMobile = width < 800;

        return Scaffold(
          body: TeethBackground(
            child: Builder(
              builder: (context) {
                final safePadding = MediaQuery.of(context).padding;
                return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('patients')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 5 * scale,
                    ),
                  );
                }

                // Collect all programari from all patients
                final List<Map<String, dynamic>> allProgramari = [];
                for (var doc in snapshot.data!.docs) {
                  final patientData = doc.data() as Map<String, dynamic>;
                  final patientName = patientData['nume'] as String? ?? '';
                  final programari = PatientParser.parseProgramari(patientData);
                  
                  for (var programare in programari) {
                    // final programareDate = programare.programareTimestamp.toDate();
                    // // Only show future programari or those from today
                    // final now = DateTime.now();
                    // final today = DateTime(now.year, now.month, now.day);
                    // final programareDay = DateTime(
                    //   programareDate.year,
                    //   programareDate.month,
                    //   programareDate.day,
                    // );
                    allProgramari.add({
                      'programare': programare,
                      'patientName': patientName,
                      'patientId': doc.id,
                    });
                  }
                }

                final months = [
                  'ianuarie', 'februarie', 'martie', 'aprilie', 'mai', 'iunie',
                  'iulie', 'august', 'septembrie', 'octombrie', 'noiembrie', 'decembrie'
                ];
                final weekdays = [
                  'Luni', 'Marți', 'Miercuri', 'Joi', 'Vineri', 'Sâmbătă', 'Duminică'
                ];

                return Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: 40 * scale,
                        right: 40 * scale,
                        top: safePadding.top + 40 * scale,
                        bottom: safePadding.bottom + 40 * scale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // Back button and controls
                      if (isMobile) ...[
                        // Mobile layout: Stack vertically
                        Row(
                          children: [
                            AnimatedBackButton(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  NavigationUtils.fadeScaleTransition(
                                    page: const MainApp(),
                                  ),
                                );
                              },
                              scale: scale,
                              isMobile: true,
                            ),
                          ],
                        ),
                        SizedBox(height: 20 * scale),
                        // View mode and navigation buttons in second row
                        Row(
                          children: [
                            ViewModeButton(
                              label: 'Zi',
                              mode: CalendarViewMode.day,
                              currentMode: _viewMode,
                              scale: scale,
                              onTap: () => _changeViewMode(CalendarViewMode.day),
                              isMobile: true,
                            ),
                            SizedBox(width: 12 * scale),
                            ViewModeButton(
                              label: 'Săpt',
                              mode: CalendarViewMode.week,
                              currentMode: _viewMode,
                              scale: scale,
                              onTap: () => _changeViewMode(CalendarViewMode.week),
                              isMobile: true,
                            ),
                            SizedBox(width: 12 * scale),
                            ViewModeButton(
                              label: 'Lună',
                              mode: CalendarViewMode.month,
                              currentMode: _viewMode,
                              scale: scale,
                              onTap: () => _changeViewMode(CalendarViewMode.month),
                              isMobile: true,
                            ),
                            const Spacer(),
                            AnimatedNavButton(
                              onTap: () {
                                _pageController?.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              scale: scale,
                              isMobile: true,
                              child: Icon(
                                Icons.chevron_left,
                                size: 50 * scale,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(width: 12 * scale),
                            AnimatedNavButton(
                              onTap: () {
                                _pageController?.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              scale: scale,
                              isMobile: true,
                              child: Icon(
                                Icons.chevron_right,
                                size: 50 * scale,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ] else
                        // Desktop layout: Single row
                        Row(
                          children: [
                            AnimatedBackButton(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  NavigationUtils.fadeScaleTransition(
                                    page: const MainApp(),
                                  ),
                                );
                              },
                              scale: scale,
                              isMobile: false,
                            ),
                            SizedBox(width: 20 * scale),
                            // View mode buttons
                            ViewModeButton(
                              label: 'Zi',
                              mode: CalendarViewMode.day,
                              currentMode: _viewMode,
                              scale: scale,
                              onTap: () => _changeViewMode(CalendarViewMode.day),
                            ),
                            SizedBox(width: 12 * scale),
                            ViewModeButton(
                              label: 'Săptămână',
                              mode: CalendarViewMode.week,
                              currentMode: _viewMode,
                              scale: scale,
                              onTap: () => _changeViewMode(CalendarViewMode.week),
                            ),
                            SizedBox(width: 12 * scale),
                            ViewModeButton(
                              label: 'Lună',
                              mode: CalendarViewMode.month,
                              currentMode: _viewMode,
                              scale: scale,
                              onTap: () => _changeViewMode(CalendarViewMode.month),
                            ),
                            const Spacer(),
                            // Navigation buttons
                            AnimatedNavButton(
                              onTap: () {
                                _pageController?.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              scale: scale,
                              child: Icon(
                                Icons.chevron_left,
                                size: 32 * scale,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(width: 12 * scale),
                            AnimatedNavButton(
                              onTap: () {
                                setState(() {
                                  _currentPageIndex = 1000;
                                  _currentDate = DateTime.now();
                                });
                                _pageController?.jumpToPage(1000);
                              },
                              scale: scale,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20 * scale,
                                vertical: 12 * scale,
                              ),
                              child: Text(
                                _getTopRightText(),
                                style: TextStyle(
                                  fontSize: 28 * scale,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            SizedBox(width: 12 * scale),
                            AnimatedNavButton(
                              onTap: () {
                                _pageController?.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              scale: scale,
                              child: Icon(
                                Icons.chevron_right,
                                size: 32 * scale,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: isMobile ? 28 * scale : 20 * scale),
                      // Calendar grid with horizontal scrolling
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPageIndex = index;
                              _currentDate = _getDateForPage(index, isMobile: isMobile);
                            });
                          },
                          itemBuilder: (context, index) {
                            final pageDate = _getDateForPage(index, isMobile: isMobile);
                            final pageDays = _getDaysForPage(pageDate, isMobile: isMobile);
                            final isCurrentPage = index == _currentPageIndex;
                            
                            return _viewMode == CalendarViewMode.month
                                ? MonthView(
                                    days: pageDays,
                                    allProgramari: allProgramari,
                                    scale: scale,
                                    months: months,
                                    weekdays: weekdays,
                                    currentDate: pageDate,
                                    onDayTap: _navigateToDayView,
                                    isMobile: isMobile,
                                  )
                                : TimeGridView(
                                    key: isCurrentPage ? _timeGridViewKey : null,
                                    days: pageDays,
                                    allProgramari: allProgramari,
                                    scale: scale,
                                    months: months,
                                    weekdays: weekdays,
                                    currentDate: pageDate,
                                    onProgramareTap: _handleProgramareTap,
                                    onAddProgramareTap: _handleAddProgramareTap,
                                    isMobile: isMobile,
                                    onNotification: _handleNotification,
                                  );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                    // Edit Programare Modal
                    if (_showEditProgramareModal && _programareToEdit != null && _patientIdForEdit != null)
                      AddProgramareModal(
                        scale: scale,
                        initialProgramare: _programareToEdit,
                        patientId: _patientIdForEdit, // Enable autosave
                        patientName: _patientNameForEdit,
                        shouldCloseAfterSave: false, // Don't auto-close, we'll close it after overlap confirmation
                        isRetroactive: () {
                          final programareDate = _programareToEdit!.programareTimestamp.toDate();
                          return programareDate.year == 1970 && 
                                 programareDate.month == 1 && 
                                 programareDate.day == 1;
                        }(),
                        onClose: () {
                          final editedDateTime = _programareToEdit?.programareTimestamp.toDate();
                          setState(() {
                            _showEditProgramareModal = false;
                            _programareToEdit = null;
                            _patientIdForEdit = null;
                            _patientNameForEdit = null;
                          });
                          // Scroll to the appointment after cancel
                          if (editedDateTime != null) {
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted && _timeGridViewKey.currentState != null) {
                                _timeGridViewKey.currentState!.scrollToTime(editedDateTime);
                              }
                            });
                          }
                        },
                        onValidationError: (String errorMessage) {
                          setState(() {
                            _notificationMessage = errorMessage;
                            _notificationIsSuccess = false;
                          });
                        },
                        onSave: (proceduri, timestamp, notificare, durata, totalOverride, achitat, patientId) async {
                          await _handleSaveProgramare(proceduri, timestamp, notificare, durata, totalOverride, achitat, allProgramari);
                        },
                        onDelete: () async {
                          if (_patientIdForEdit != null && _programareToEdit != null) {
                            await _deleteProgramare(_programareToEdit!);
                          }
                        },
                      ),
                      if (_showAddProgramareModal)
                        if (!isMobile)
                          AddProgramareModal(
                            scale: scale,
                            initialDateTime: _selectedDateTime!,
                            onClose: () {
                              setState(() {
                                _showAddProgramareModal = false;
                                _selectedDateTime = null;
                              });
                            },
                            onSave: (proceduri, timestamp, notificare, durata, totalOverride, achitat, patientId) async {
                              await _handleAddProgramare(patientId, proceduri, timestamp, notificare, durata, totalOverride, achitat, allProgramari);
                            },
                            onValidationError: (errorMessage) => _handleNotification(errorMessage, false),
                          ),

                    // Overlap Confirmation Dialog
                    if (_showOverlapConfirmation)
                      ConfirmDialog(
                        title: 'Confirmă suprapunerea',
                        message: 'Această programare se suprapune cu o altă programare. Ești sigură că vrei să continui?',
                        confirmText: 'Salvează',
                        cancelText: 'Anulează',
                        scale: scale,
                        onConfirm: () async {
                          if (_pendingEditDateTime != null && 
                              _pendingEditProceduri != null && 
                              _pendingEditNotificare != null &&
                              _programareToEdit != null) {
                            final timestamp = Timestamp.fromDate(_pendingEditDateTime!);
                            // Ensure durata defaults to 60 minutes if null
                            final durataValue = _pendingEditDurata ?? 60;
                            await _updateProgramare(
                              _programareToEdit!,
                              _pendingEditProceduri!,
                              timestamp,
                              _pendingEditNotificare!,
                              durataValue,
                              _pendingEditTotalOverride,
                              _pendingEditAchitat ?? 0.0,
                              _patientIdForEdit!,
                            );
                          }
                          setState(() {
                            _showOverlapConfirmation = false;
                            _pendingEditDateTime = null;
                            _pendingEditProceduri = null;
                            _pendingEditNotificare = null;
                            _pendingEditDurata = null;
                            _pendingEditTotalOverride = null;
                            _pendingEditAchitat = null;
                          });
                        },
                        onCancel: () {
                          // Just close the overlap confirmation, keep the edit modal open
                          setState(() {
                            _showOverlapConfirmation = false;
                            _pendingEditDateTime = null;
                            _pendingEditProceduri = null;
                            _pendingEditNotificare = null;
                            _pendingEditDurata = null;
                            _pendingEditTotalOverride = null;
                            _pendingEditAchitat = null;
                          });
                        },
                      ),
                    // Notification
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
                );
              },
            );
              },
            ),
          ),
        );
      },
    );
  }

  String _getTitleText(double scale) {
    final months = [
      'ianuarie', 'februarie', 'martie', 'aprilie', 'mai', 'iunie',
      'iulie', 'august', 'septembrie', 'octombrie', 'noiembrie', 'decembrie'
    ];
    
    switch (_viewMode) {
      case CalendarViewMode.day:
        return '${_currentDate.day} ${months[_currentDate.month - 1]} ${_currentDate.year}';
      case CalendarViewMode.week:
        final startOfWeek = _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        if (startOfWeek.month == endOfWeek.month) {
          return '${startOfWeek.day} - ${endOfWeek.day} ${months[startOfWeek.month - 1]} ${startOfWeek.year}';
        } else {
          return '${startOfWeek.day} ${months[startOfWeek.month - 1]} - ${endOfWeek.day} ${months[endOfWeek.month - 1]} ${startOfWeek.year}';
        }
      case CalendarViewMode.month:
        return '${months[_currentDate.month - 1]} ${_currentDate.year}';
    }
  }

  String _getTopRightText() {
    return _getTitleText(1.0);
  }

  void _handleProgramareTap(Programare programare, String patientId) {
    // Find patient name from the stream
    final patientDoc = FirebaseFirestore.instance.collection('patients').doc(patientId);
    patientDoc.get().then((doc) {
      if (doc.exists && mounted) {
        final patientData = doc.data() as Map<String, dynamic>;
        final patientName = patientData['nume'] as String? ?? '';
        setState(() {
          _programareToEdit = programare;
          _patientIdForEdit = patientId;
          _patientNameForEdit = patientName;
          _showEditProgramareModal = true;
        });
      }
    });
  }

  void _handleAddProgramareTap(DateTime dateTime, bool isMobile, scale) {
    if (isMobile) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProgramareDetailsPage(
            programare: null,
            patientId: _patientIdForEdit,
            scale: scale,
            isConsultatie: false,
            initialDateTime: dateTime,
            onNotification: _handleNotification,
          ),
        ),
      );
    } else {
      setState(() {
        _showAddProgramareModal = true;
        _selectedDateTime = dateTime;
      });
    }
  }

  Future<void> _handleSaveProgramare(List<Procedura> proceduri, Timestamp timestamp, bool notificare, int? durata, double? totalOverride, double achitat, List<Map<String, dynamic>> allProgramari) async {
    // Check for overlaps before saving - check against ALL appointments from ALL patients
    final editedDateTime = timestamp.toDate();
    // Ensure durata defaults to 60 minutes if null
    final durataValue = durata ?? 60;
    
    // Skip overlap check for consultations without dates (epoch date)
    final isDateSkipped = editedDateTime.year == 1970 && 
                          editedDateTime.month == 1 && 
                          editedDateTime.day == 1;
    
    final hasOverlap = !isDateSkipped && _checkOverlap(
      editedDateTime,
      durataValue,
      allProgramari,
      excludePatientId: _patientIdForEdit,
      excludeProgramare: _programareToEdit,
    );
    
    if (hasOverlap) {
      setState(() {
        _pendingEditDateTime = editedDateTime;
        _pendingEditProceduri = proceduri;
        _pendingEditNotificare = notificare;
        _pendingEditDurata = durataValue;
        _pendingEditTotalOverride = totalOverride;
        _pendingEditAchitat = achitat;
        _showOverlapConfirmation = true;
      });
      // Modal stays open - will close after user confirms overlap
    } else {
      // No overlap, save and close immediately
      await _updateProgramare(_programareToEdit!, proceduri, timestamp, notificare, durataValue, totalOverride, achitat, _patientIdForEdit!);
    }
  }

  Future<void> _handleAddProgramare(String? patientId, List<Procedura> proceduri, Timestamp timestamp, bool notificare, int? durata, double? totalOverride, double achitat, List<Map<String, dynamic>> allProgramari) async {
    if (patientId == null) {
      setState(() {
        _notificationMessage = 'Nu a fost selectat niciun pacient';
        _notificationIsSuccess = false;
      });
      return;
    }
    // Check for overlaps before saving - check against ALL appointments from ALL patients
    final editedDateTime = timestamp.toDate();
    // Ensure durata defaults to 60 minutes if null
    final durataValue = durata ?? 60;
    
    // Skip overlap check for consultations without dates (epoch date)
    final isDateSkipped = editedDateTime.year == 1970 && 
                          editedDateTime.month == 1 && 
                          editedDateTime.day == 1;

    final programare = Programare(
      proceduri: proceduri,
      programareTimestamp: timestamp,
      programareNotification: notificare,
      durata: durataValue,
      totalOverride: totalOverride,
      achitat: achitat,
    );

    final hasOverlap = !isDateSkipped && _checkOverlap(
      editedDateTime,
      durataValue,
      allProgramari,
      excludePatientId: patientId,
      excludeProgramare: programare,
    );
    
    if (hasOverlap) {
      setState(() {
        _pendingEditDateTime = editedDateTime;
        _pendingEditProceduri = proceduri;
        _pendingEditNotificare = notificare;
        _pendingEditDurata = durataValue;
        _pendingEditTotalOverride = totalOverride;
        _pendingEditAchitat = achitat;
        _showOverlapConfirmation = true;
      });
      // Modal stays open - will close after user confirms overlap
    } else {
      // No overlap, save and close immediately
      // await _updateProgramare(programare, proceduri, timestamp, notificare, durataValue, totalOverride, achitat, patientId);
      final result = await PatientService.addProgramare(
        patientId: patientId,
        proceduri: proceduri,
        timestamp: timestamp,
        notificare: notificare,
        durata: durataValue,
        totalOverride: totalOverride,
        achitat: achitat,
      );
      if (mounted) {
        setState(() {
          if (result.success) {
            _notificationMessage = 'Programare adăugată cu succes!';
            _notificationIsSuccess = true;
          } else {
            _notificationMessage = result.errorMessage ?? 'Eroare la adăugare';
            _notificationIsSuccess = false;
          }
        });
      }
    }
  }

  // Check overlap against all appointments from all patients (using the provided allProgramari list)
  bool _checkOverlap(DateTime newDateTime, int? newDurata, List<Map<String, dynamic>> allProgramari, {String? excludePatientId, Programare? excludeProgramare}) {
    final newStartMinutes = newDateTime.hour * 60 + newDateTime.minute;
    final newEndMinutes = newStartMinutes + (newDurata ?? 60);
    final newDate = DateTime(newDateTime.year, newDateTime.month, newDateTime.day);

    // Check against ALL appointments from ALL patients
    for (var item in allProgramari) {
      final programare = item['programare'] as Programare;
      final itemPatientId = item['patientId'] as String;
      
      // Skip the appointment being edited (only if excludePatientId and excludeProgramare are provided)
      // For adding new appointments, these will be null so all appointments are checked
      if (excludePatientId != null && excludeProgramare != null &&
          itemPatientId == excludePatientId && 
          programare.programareTimestamp == excludeProgramare.programareTimestamp &&
          programare.displayText == excludeProgramare.displayText) {
        continue;
      }

      final programareDate = programare.programareTimestamp.toDate();
      final programareDay = DateTime(programareDate.year, programareDate.month, programareDate.day);
      
      // Check if same day
      if (programareDay.year == newDate.year &&
          programareDay.month == newDate.month &&
          programareDay.day == newDate.day) {
        final itemStartMinutes = programareDate.hour * 60 + programareDate.minute;
        final itemEndMinutes = itemStartMinutes + (programare.durata ?? 60);
        
        // Check for overlap
        if (newStartMinutes < itemEndMinutes && itemStartMinutes < newEndMinutes) {
          return true;
        }
      }
    }
    return false;
  }

  void _handleNotification(String message, bool isSuccess) {
    setState(() {
      _notificationMessage = message;
      _notificationIsSuccess = isSuccess;
    });
  }

  Future<void> _updateProgramare(Programare oldProgramare, List<Procedura> proceduri, Timestamp timestamp, bool notificare, int? durata, double? totalOverride, double achitat, String? patientId) async {
    if (patientId == null) return;

    final result = await PatientService.updateProgramare(
      patientId: patientId,
      oldProgramare: oldProgramare,
      proceduri: proceduri,
      timestamp: timestamp,
      notificare: notificare,
      durata: durata,
      totalOverride: totalOverride,
      achitat: achitat,
    );
    
    final editedDateTime = timestamp.toDate();
    
    setState(() {
      _showEditProgramareModal = false;
      _programareToEdit = null;
      _patientIdForEdit = null;
      _patientNameForEdit = null;
    });
    
    // Scroll to the edited appointment
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _timeGridViewKey.currentState != null) {
        _timeGridViewKey.currentState!.scrollToTime(editedDateTime);
      }
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _handleNotification(result.success ? 'Programare actualizată cu succes!' : result.errorMessage ?? 'Eroare la actualizare', result.success);
      }
    });
  }

  Future<void> _deleteProgramare(Programare programare) async {
    if (_patientIdForEdit == null) return;
    
    final result = await PatientService.deleteProgramare(
      patientId: _patientIdForEdit!,
      programare: programare,
    );
    
    setState(() {
      _showEditProgramareModal = false;
      _programareToEdit = null;
      _patientIdForEdit = null;
      _patientNameForEdit = null;
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          if (result.success) {
            _notificationMessage = 'Programare ștearsă cu succes!';
            _notificationIsSuccess = true;
          } else {
            _notificationMessage = result.errorMessage ?? 'Eroare la ștergere';
            _notificationIsSuccess = false;
          }
        });
      }
    });
  }


}
