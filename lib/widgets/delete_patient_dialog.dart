import 'dart:ui';
import 'package:flutter/material.dart';

class DeletePatientDialog extends StatefulWidget {
  final double scale;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const DeletePatientDialog({
    super.key,
    required this.scale,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<DeletePatientDialog> createState() => _DeletePatientDialogState();
}

class _DeletePatientDialogState extends State<DeletePatientDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _deleteConfirmController = TextEditingController();
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
    _deleteConfirmController.dispose();
    super.dispose();
  }

  bool get _canDelete => _deleteConfirmController.text.toLowerCase().trim() == 'confirm';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dialogWidth = isMobile ? screenWidth * 0.95 : screenWidth * 0.6;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onCancel,
          behavior: HitTestBehavior.opaque,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 5 * _blurAnimation.value,
              sigmaY: 5 * _blurAnimation.value,
            ),
            child: Container(
              color: Colors.black.withOpacity(0.3 * _fadeAnimation.value),
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: GestureDetector(
                      onTap: () {}, // Prevent closing when clicking on the dialog itself
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: dialogWidth,
                        constraints: BoxConstraints(
                          maxWidth: 800 * widget.scale,
                          minHeight: 400 * widget.scale,
                          maxHeight: MediaQuery.of(context).size.height * 0.9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32 * widget.scale),
                          border: Border.all(
                            color: Colors.black,
                            width: 7 * widget.scale,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20 * widget.scale,
                              offset: Offset(0, 10 * widget.scale),
                            ),
                          ],
                        ),
                        child: Padding(
                  padding: EdgeInsets.only(
                    left: 40 * widget.scale,
                    right: 40 * widget.scale,
                    top: 40 * widget.scale,
                    bottom: 40 * widget.scale + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Confirmă ștergerea',
                          style: TextStyle(
                            fontSize: (isMobile ? 96 : 48) * widget.scale,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 30 * widget.scale),
                        Text(
                          'Ești sigură că vrei să ștergi acest pacient? Această acțiune nu poate fi anulată.',
                          style: TextStyle(
                            fontSize: (isMobile ? 64 : 32) * widget.scale,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20 * widget.scale),
                        Text(
                          'Tastați "confirm" pentru a confirma:',
                          style: TextStyle(
                            fontSize: (isMobile ? 56 : 28) * widget.scale,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12 * widget.scale),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12 * widget.scale),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.2),
                              width: 2 * widget.scale,
                            ),
                          ),
                          child: TextField(
                            controller: _deleteConfirmController,
                            autofocus: true,
                            style: TextStyle(
                              fontSize: (isMobile ? 48 : 24) * widget.scale,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'confirm',
                              hintStyle: TextStyle(
                                fontSize: (isMobile ? 48 : 24) * widget.scale,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[500],
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all((isMobile ? 32 : 16) * widget.scale),
                            ),
                            onChanged: (value) {
                              setState(() {}); // Rebuild to update button state
                            },
                          ),
                        ),
                        SizedBox(height: 40 * widget.scale),
                        isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildDeleteDialogButton(
                                    text: 'Șterge',
                                    color: _canDelete ? Colors.red[600]! : Colors.grey[400]!,
                                    onTap: _canDelete ? widget.onConfirm : () {},
                                    isMobile: isMobile,
                                  ),
                                  SizedBox(height: 16 * widget.scale),
                                  _buildDeleteDialogButton(
                                    text: 'Anulează',
                                    color: Colors.grey[400]!,
                                    onTap: widget.onCancel,
                                    isMobile: isMobile,
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _buildDeleteDialogButton(
                                    text: 'Anulează',
                                    color: Colors.grey[400]!,
                                    onTap: widget.onCancel,
                                    isMobile: isMobile,
                                  ),
                                  SizedBox(width: 20 * widget.scale),
                                  _buildDeleteDialogButton(
                                    text: 'Șterge',
                                    color: _canDelete ? Colors.red[600]! : Colors.grey[400]!,
                                    onTap: _canDelete ? widget.onConfirm : () {},
                                    isMobile: isMobile,
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                      ),
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

  Widget _buildDeleteDialogButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 40 * widget.scale,
            vertical: 20 * widget.scale,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20 * widget.scale),
            border: Border.all(
              color: Colors.black,
              width: 6 * widget.scale,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 8 * widget.scale,
                offset: Offset(0, 6 * widget.scale),
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: (isMobile ? 64 : 32) * widget.scale,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

