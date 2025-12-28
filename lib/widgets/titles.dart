import 'package:flutter/material.dart';

class LoginTitle extends StatelessWidget {
  const LoginTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const _GradientOutlinedText(text: "Login");
  }
}

class WelcomeTitle extends StatelessWidget {
  final double fontSize;
  final double strokeWidth;
  final double shadowOffset;

  const WelcomeTitle({
    super.key,
    required this.fontSize,
    required this.strokeWidth,
    required this.shadowOffset,
  });

  @override
  Widget build(BuildContext context) {
    return const _GradientOutlinedText(
      text: 'Welcome!',
    );
  }
}

/// Smaller title used on the Pacienți page.
class PacientiTitle extends StatelessWidget {
  final double fontSize;
  final double strokeWidth;
  final double shadowOffset;

  const PacientiTitle({
    super.key,
    required this.fontSize,
    required this.strokeWidth,
    required this.shadowOffset,
  });

  @override
  Widget build(BuildContext context) {
    return _GradientOutlinedText(
      text: 'Pacienți',
      fontSize: fontSize,
      strokeWidth: strokeWidth,
      shadowOffset: shadowOffset,
    );
  }
}

/// Reusable gradient + outline text used by both titles.
class _GradientOutlinedText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final double? strokeWidth;
  final double? shadowOffset;

  const _GradientOutlinedText({
    required this.text,
    this.fontSize,
    this.strokeWidth,
    this.shadowOffset,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedFontSize = fontSize ?? 140.0;
    final resolvedStrokeWidth = strokeWidth ?? 10.0;
    final resolvedShadowOffset = shadowOffset ?? 8.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Stroke text for black outline
        Text(
          text,
          style: TextStyle(
            fontSize: resolvedFontSize,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto Slab',
            shadows: [
              Shadow(
                color: const Color(0xaa000000), // ~35% black
                offset: Offset(resolvedShadowOffset, resolvedShadowOffset),
                blurRadius: 4 * (resolvedFontSize / 140.0),
              ),
            ],
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = resolvedStrokeWidth
              ..strokeJoin =
                  StrokeJoin.round, // soften sharp corners on outlines
          ),
        ),
        // Gradient fill text on top
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xffB2CEFF),
              Color(0xffF97FFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          blendMode: BlendMode.srcIn,
          child: Text(
            text,
            style: TextStyle(
              fontSize: resolvedFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Roboto Slab',
            ),
          ),
        ),
      ],
    );
  }
}
