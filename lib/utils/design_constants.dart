import 'package:flutter/material.dart';

/// Centralized design constants for consistent styling throughout the app
class DesignConstants {
  DesignConstants._();

  // Modal/Dialog styling
  static double modalBorderRadius(double scale) => 32 * scale;
  static double modalBorderWidth(double scale) => 7 * scale;
  static double modalShadowBlur(double scale) => 20 * scale;
  static Offset modalShadowOffset(double scale) => Offset(0, 10 * scale);
  static double modalPadding(double scale) => 40 * scale;

  // Button styling
  static double buttonBorderRadius(double scale) => 20 * scale;
  static double buttonBorderWidth(double scale) => 6 * scale;
  static double buttonPaddingHorizontal(double scale) => 40 * scale;
  static double buttonPaddingVertical(double scale) => 20 * scale;

  // Backdrop blur
  static const double backdropBlurSigmaX = 5.0;
  static const double backdropBlurSigmaY = 5.0;
  static const double backdropOpacity = 0.3;

  // Common colors
  static const Color borderColor = Colors.black;
  static const Color modalBackground = Colors.white;
  static Color get buttonSuccessColor => Colors.green[600]!;
  static Color get buttonDangerColor => Colors.red[600]!;
  static Color get buttonCancelColor => Colors.grey[400]!;

  // Breakpoints
  static const double mobileBreakpoint = 800;
  static const double tabletBreakpoint = 1200;

  // Design width for scaling
  static const double designWidth = 1200.0;

  /// Helper to check if the screen is mobile
  static bool isMobile(double width) => width < mobileBreakpoint;

  /// Helper to check if the screen is tablet
  static bool isTablet(double width) =>
      width >= mobileBreakpoint && width < tabletBreakpoint;

  /// Calculate scale based on width
  static double calculateScale(double width) =>
      (width / designWidth).clamp(0.4, 1.0);

  /// Get modal decoration
  static BoxDecoration modalDecoration(double scale) {
    return BoxDecoration(
      color: modalBackground,
      borderRadius: BorderRadius.circular(modalBorderRadius(scale)),
      border: Border.all(
        color: borderColor,
        width: modalBorderWidth(scale),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          blurRadius: modalShadowBlur(scale),
          offset: modalShadowOffset(scale),
        ),
      ],
    );
  }

  /// Get button decoration with state-based styling
  static BoxDecoration buttonDecoration({
    required double scale,
    required Color color,
    required bool isPressed,
    required bool isHovering,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(buttonBorderRadius(scale)),
      border: Border.all(
        color: borderColor,
        width: buttonBorderWidth(scale),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(
            isPressed ? 0.5 : (isHovering ? 0.6 : 0.4),
          ),
          blurRadius: isPressed
              ? 6 * scale
              : (isHovering ? 12 * scale : 8 * scale),
          offset: Offset(
            0,
            isPressed ? 4 * scale : (isHovering ? 8 * scale : 6 * scale),
          ),
        ),
      ],
    );
  }

  /// Get button scale based on state
  static double buttonScale({
    required bool isPressed,
    required bool isHovering,
  }) {
    return isPressed ? 0.97 : (isHovering ? 1.02 : 1.0);
  }
}

