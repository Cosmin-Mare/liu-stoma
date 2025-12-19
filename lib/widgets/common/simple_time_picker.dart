import 'package:flutter/material.dart';
import 'package:liu_stoma/utils/design_constants.dart';
import 'package:liu_stoma/widgets/common/interactive_button.dart';

/// Consolidated time picker widget with consistent styling
class SimpleTimePicker extends StatefulWidget {
  final double scale;
  final TimeOfDay initialTime;
  final bool isMobileLayout;

  const SimpleTimePicker({
    super.key,
    required this.scale,
    required this.initialTime,
    this.isMobileLayout = false,
  });

  @override
  State<SimpleTimePicker> createState() => _SimpleTimePickerState();
}

class _SimpleTimePickerState extends State<SimpleTimePicker> {
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    // Round minute to nearest 10-minute interval
    _selectedMinute = ((widget.initialTime.minute / 10).round() * 10) % 60;
  }

  @override
  Widget build(BuildContext context) {
    final double dialogWidth = widget.isMobileLayout
        ? MediaQuery.of(context).size.width * 0.75
        : MediaQuery.of(context).size.width * 0.5;

    final double maxWidth =
        widget.isMobileLayout ? 1000 * widget.scale : 600 * widget.scale;
    final double minHeight =
        widget.isMobileLayout ? 600 * widget.scale : 400 * widget.scale;
    final double titleFontSize =
        widget.isMobileLayout ? 56 * widget.scale : 48 * widget.scale;
    final double padding =
        widget.isMobileLayout ? 60 * widget.scale : 40 * widget.scale;
    final double dropdownWidth =
        widget.isMobileLayout ? 150 * widget.scale : 120 * widget.scale;
    final double iconSize =
        widget.isMobileLayout ? 48 * widget.scale : 32 * widget.scale;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          minHeight: minHeight,
        ),
        decoration: DesignConstants.modalDecoration(widget.scale),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Selectează ora',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40 * widget.scale),
              // Time selection with labels for non-mobile
              if (!widget.isMobileLayout) ...[
                // Labels row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: dropdownWidth,
                      child: Text(
                        'Ora',
                        style: TextStyle(
                          fontSize: 28 * widget.scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 40 * widget.scale),
                    SizedBox(width: 60 * widget.scale), // Space for colon
                    SizedBox(width: 40 * widget.scale),
                    SizedBox(
                      width: dropdownWidth,
                      child: Text(
                        'Minute',
                        style: TextStyle(
                          fontSize: 28 * widget.scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16 * widget.scale),
              ],
              // Dropdowns row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildDropdown(
                    width: dropdownWidth,
                    value: _selectedHour,
                    items: List.generate(24, (index) => index),
                    iconSize: iconSize,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedHour = value);
                      }
                    },
                  ),
                  SizedBox(width: 40 * widget.scale),
                  Text(
                    ':',
                    style: TextStyle(
                      fontSize: 60 * widget.scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 40 * widget.scale),
                  _buildDropdown(
                    width: dropdownWidth,
                    value: _selectedMinute,
                    items: List.generate(6, (index) => index * 10),
                    iconSize: iconSize,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedMinute = value);
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 50 * widget.scale),
              // Buttons
              widget.isMobileLayout
                  ? Column(
                      children: [
                        InteractiveButton(
                          text: 'Anulează',
                          onTap: () => Navigator.of(context).pop(),
                          scale: widget.scale,
                          color: DesignConstants.buttonCancelColor,
                          fullWidth: true,
                        ),
                        SizedBox(height: 20 * widget.scale),
                        InteractiveButton(
                          text: 'Confirmă',
                          onTap: () => Navigator.of(context).pop(
                            TimeOfDay(
                              hour: _selectedHour,
                              minute: _selectedMinute,
                            ),
                          ),
                          scale: widget.scale,
                          color: DesignConstants.buttonSuccessColor,
                          fullWidth: true,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InteractiveButton(
                          text: 'Anulează',
                          onTap: () => Navigator.of(context).pop(),
                          scale: widget.scale,
                          color: DesignConstants.buttonCancelColor,
                        ),
                        SizedBox(width: 20 * widget.scale),
                        InteractiveButton(
                          text: 'Confirmă',
                          onTap: () => Navigator.of(context).pop(
                            TimeOfDay(
                              hour: _selectedHour,
                              minute: _selectedMinute,
                            ),
                          ),
                          scale: widget.scale,
                          color: DesignConstants.buttonSuccessColor,
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required double width,
    required int value,
    required List<int> items,
    required double iconSize,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28 * widget.scale),
        border: Border.all(
          color: Colors.black,
          width: 5 * widget.scale,
        ),
      ),
      child: DropdownButton<int>(
        value: value,
        isExpanded: true,
        underline: Container(),
        dropdownColor: Colors.white,
        icon: Icon(
          Icons.arrow_drop_down,
          size: iconSize,
          color: Colors.black,
          weight: 900,
        ),
        style: TextStyle(
          fontSize: 40 * widget.scale,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        items: items.map((item) {
          return DropdownMenuItem<int>(
            value: item,
            child: Center(
              child: Text(
                item.toString().padLeft(2, '0'),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

