import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:liu_stoma/utils/design_constants.dart';

/// Reusable modal wrapper with backdrop blur and consistent styling
class ModalWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onClose;
  final double scale;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final bool preventCloseOnTap;

  const ModalWrapper({
    super.key,
    required this.child,
    required this.onClose,
    required this.scale,
    this.width,
    this.height,
    this.constraints,
    this.preventCloseOnTap = false,
  });

  @override
  State<ModalWrapper> createState() => _ModalWrapperState();
}

class _ModalWrapperState extends State<ModalWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.preventCloseOnTap ? null : widget.onClose,
          behavior: HitTestBehavior.opaque,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: DesignConstants.backdropBlurSigmaX * _blurAnimation.value,
              sigmaY: DesignConstants.backdropBlurSigmaY * _blurAnimation.value,
            ),
            child: Container(
              color: Colors.black.withOpacity(
                DesignConstants.backdropOpacity * _fadeAnimation.value,
              ),
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: GestureDetector(
                      onTap: () {
                        // Consume tap events to prevent them from bubbling to the outer GestureDetector
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: widget.width,
                        height: widget.height,
                        constraints: widget.constraints,
                        decoration: DesignConstants.modalDecoration(widget.scale),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

