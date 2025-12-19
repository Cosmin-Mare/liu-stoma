import 'package:flutter/material.dart';
import 'package:liu_stoma/widgets/common/modal_wrapper.dart';
import 'package:liu_stoma/widgets/common/interactive_button.dart';
import 'package:liu_stoma/utils/design_constants.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final double scale;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.scale,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dialogWidth = isMobile ? screenWidth * 0.95 : screenWidth * 0.6;
    
    return ModalWrapper(
      onClose: onCancel,
      scale: scale,
      width: dialogWidth,
      constraints: BoxConstraints(
        maxWidth: 800 * scale,
        minHeight: 300 * scale,
      ),
      child: Padding(
        padding: EdgeInsets.all(DesignConstants.modalPadding(scale)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: (isMobile ? 96 : 48) * scale,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30 * scale),
            Text(
              message,
              style: TextStyle(
                fontSize: (isMobile ? 64 : 32) * scale,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40 * scale),
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InteractiveButton(
                        text: confirmText,
                        onTap: onConfirm,
                        scale: scale,
                        color: DesignConstants.buttonDangerColor,
                        fullWidth: true,
                      ),
                      SizedBox(height: 16 * scale),
                      InteractiveButton(
                        text: cancelText,
                        onTap: onCancel,
                        scale: scale,
                        color: DesignConstants.buttonCancelColor,
                        fullWidth: true,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InteractiveButton(
                        text: cancelText,
                        onTap: onCancel,
                        scale: scale,
                        color: DesignConstants.buttonCancelColor,
                      ),
                      SizedBox(width: 20 * scale),
                      InteractiveButton(
                        text: confirmText,
                        onTap: onConfirm,
                        scale: scale,
                        color: DesignConstants.buttonDangerColor,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

