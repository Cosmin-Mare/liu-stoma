import 'package:flutter/material.dart';

/// Utility functions for consistent navigation transitions
class NavigationUtils {
  NavigationUtils._();

  /// Standard fade and scale transition used throughout the app
  static PageRouteBuilder<T> fadeScaleTransition<T>({
    required Widget page,
    Duration duration = const Duration(milliseconds: 650),
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: duration,
      pageBuilder: (_, animation, secondaryAnimation) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.97,
              end: 1.0,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

