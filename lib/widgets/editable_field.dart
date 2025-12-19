import 'package:flutter/material.dart';
import 'package:liu_stoma/utils/design_constants.dart';

class EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final double scale;
  final TextInputType keyboardType;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  const EditableField({
    super.key,
    required this.label,
    required this.controller,
    required this.scale,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = !DesignConstants.isMobile(width);
    // Use smaller font size multiplier on desktop (0.75x)
    final fontSizeMultiplier = isDesktop ? 0.75 : 1.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 42 * scale * fontSizeMultiplier,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8 * scale),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28 * scale),
            border: Border.all(
              color: errorText != null
                  ? Colors.red[600]!
                  : Colors.black.withOpacity(0.2),
              width: errorText != null ? 3 * scale : 2 * scale,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            maxLines: maxLines,
            minLines: maxLines == 1 ? 1 : 3,
            textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
            textCapitalization: textCapitalization,
            style: TextStyle(
              fontSize: 36 * scale * fontSizeMultiplier,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Introduceți $label',
              hintStyle: TextStyle(
                fontSize: 36 * scale * fontSizeMultiplier,
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16 * scale),
              errorText: errorText,
              errorStyle: TextStyle(
                fontSize: 32 * scale * fontSizeMultiplier,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

