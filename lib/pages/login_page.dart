import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:liu_stoma/utils/design_constants.dart';
import 'package:liu_stoma/widgets/add_programare_modal/modal_buttons.dart';
import 'package:liu_stoma/widgets/custom_notification.dart';
import 'package:liu_stoma/widgets/editable_field.dart';
import 'package:liu_stoma/widgets/teeth_background.dart';
import 'package:liu_stoma/widgets/titles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isHovering = false;
  bool isPressed = false;

  bool isLoading = false;
  String? errorMessage;

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Completează email și parola';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // SUCCESS:
      // AuthGate will automatically switch to MainPage
    } on FirebaseAuthException catch (e) {
      setState(() {
        print(e.code);
        errorMessage = _mapAuthError(e.code);
      });
    } catch (_) {
      setState(() {
        errorMessage = 'Eroare neașteptată';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _mapAuthError(String code) {
  switch (code) {
    case 'user-not-found':
      return 'Cont inexistent';
    case 'wrong-password':
      return 'Parolă incorectă';
    case 'invalid-email':
      return 'Email invalid';
    case 'user-disabled':
      return 'Cont dezactivat';
    default:
      return 'Autentificare eșuată';
  }
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
              child: Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 24.0 : 0.0,
                            ),
                            child: FittedBox(
                              child: LoginTitle(),
                            ),
                          ),
                        ),
                        SizedBox(height: 40 * scale),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 400 * scale),
                          padding: EdgeInsets.symmetric(vertical: 20 * scale),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20 * scale),
                            border: Border.all(
                              color: Colors.black,
                              width: 5 * scale,
                            ),
                          ),
                          child: 
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 20 * scale),
                            child:
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  EditableField(
                                    label: 'Email',
                                    controller: emailController,
                                    scale: scale,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  SizedBox(width: 20 * scale),
                                  EditableField(
                                    obscureText: true,
                                    label: 'Password',
                                    controller: passwordController,
                                    scale: scale,
                                    keyboardType: TextInputType.visiblePassword,
                                  ),
                                  SizedBox(height: 20 * scale),
                                  ModalSaveButton(
                                    scale: scale,
                                    onTap: isLoading ? () {} : _login,
                                    isHovering: isHovering,
                                    isPressed: isPressed,
                                    onHoverEnter: () {
                                      setState(() {
                                        isHovering = true;
                                      });
                                    },
                                    onHoverExit: () {
                                      setState(() {
                                        isHovering = false;
                                      });
                                    },
                                    onTapDown: () {
                                      setState(() {
                                        isPressed = true;
                                      });
                                    },
                                    onTapUp: () {
                                      setState(() {
                                        isPressed = false;
                                      });
                                    },
                                    onTapCancel: () {
                                      setState(() {
                                        isPressed = false;
                                      });
                                    },
                                    text: isLoading ? 'Se autentifică...' : 'Login',
                                  ),
                                ],
                              ),
                          ),
                        ),
                      ],
                    ),
                    if (errorMessage != null) 
                      CustomNotification(
                        message: errorMessage ?? '',
                        isSuccess: false,
                        scale: scale,
                        onDismiss: () {
                          setState(() {
                            errorMessage = null;
                          });
                        },
                      ),
                  ],
                )
              );
            },
          ),
          ),
        );
      },
    );
  }
}