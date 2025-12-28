import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:liu_stoma/pacienti_page.dart';
import 'package:liu_stoma/pages/programari_calendar_page.dart';
import 'package:liu_stoma/services/patient_service.dart';
import 'package:liu_stoma/utils/design_constants.dart';
import 'package:liu_stoma/utils/navigation_utils.dart';
import 'package:liu_stoma/widgets/common/animated_back_button.dart';
import 'package:liu_stoma/widgets/pacienti_button.dart';
import 'package:liu_stoma/widgets/teeth_background.dart';
import 'package:liu_stoma/widgets/titles.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool isLoggedIn = false;
  final uid = FirebaseAuth.instance.currentUser!.uid;
  String clinicId = '';

  @override
  void initState() {
    super.initState();
    _getUserDoc();
  }

  Future<void> _getUserDoc() async {
    if(!mounted) return;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    setState(() {
      print(uid);
      clinicId = userDoc.data()?['clinicId'] as String? ?? '';
    });
    
    await PatientService.setClinicId(clinicId);
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Overall UI scale based on window width (don't grow past 1.0)
        final scale = DesignConstants.calculateScale(width);
        final isMobile = DesignConstants.isMobile(width);

        // Vertical padding as a fraction of height so it doesn't explode
        final verticalPadding = constraints.maxHeight * 0.1;
        final titleFontSize = 140.0 * scale;
        // Bigger buttons on mobile for better touch targets
        final mobileButtonScale = isMobile ? 1.1 : 0.7;
        final buttonFontSize = 80.0 * scale * mobileButtonScale;
        final buttonHorizontal = 64.0 * scale * mobileButtonScale;
        final buttonVertical = 24.0 * scale * mobileButtonScale;
        final strokeWidth = 10.0 * scale;
        final shadowOffset = 8.0 * scale;

        return Scaffold(
          body: TeethBackground(
            child: Builder(
              builder: (context) {
                final safePadding = MediaQuery.of(context).padding;
                return Padding(
              padding: EdgeInsets.only(
                top: safePadding.top + verticalPadding,
                bottom: safePadding.bottom + verticalPadding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // AnimatedBackButton(
                  //   scale: scale,
                  //   onTap: () {
                  //     _logout();
                  //   },
                  // ),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24.0 : 0.0,
                      ),
                      child: FittedBox(
                        child: WelcomeTitle(
                          fontSize: titleFontSize,
                          strokeWidth: strokeWidth,
                          shadowOffset: shadowOffset,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40 * scale),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PacientiButton(
                        label: 'Vezi Pacienții',
                        fontSize: buttonFontSize,
                        horizontalPadding: buttonHorizontal,
                        verticalPadding: buttonVertical,
                        onPressed: () {
                          Navigator.of(context).push(
                            NavigationUtils.fadeScaleTransition(
                              page: PacientiPage(),
                            ),
                          );
                        },
                      ),
                      if (!isMobile) SizedBox(width: 30 * scale),
                      if (!isMobile)
                        PacientiButton(
                          label: 'Vezi Programări',
                          fontSize: buttonFontSize,
                          horizontalPadding: buttonHorizontal,
                          verticalPadding: buttonVertical,
                          baseColor: const Color(0xffF97FFF),
                          hoverColor: const Color(0xffFFA3FF),
                          pressedColor: const Color(0xffE066E6),
                          onPressed: () {
                            Navigator.of(context).push(
                              NavigationUtils.fadeScaleTransition(
                                page: ProgramariCalendarPage(),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  if (isMobile) SizedBox(height: 40 * scale),
                  if (isMobile)
                    PacientiButton(
                      label: 'Vezi Programări',
                      fontSize: buttonFontSize,
                      horizontalPadding: buttonHorizontal,
                      verticalPadding: buttonVertical,
                      baseColor: const Color(0xffF97FFF),
                      hoverColor: const Color(0xffFFA3FF),
                      pressedColor: const Color(0xffE066E6),
                      onPressed: () {
                        Navigator.of(context).push(
                          NavigationUtils.fadeScaleTransition(
                            page: ProgramariCalendarPage(),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
            },
          ),
          ),
        );
      },
    );
  }
}