import 'package:flutter/material.dart';
import 'package:liu_stoma/widgets/common/procedura_entry.dart';
import 'package:liu_stoma/widgets/common/payment_section.dart';

/// A reusable proceduri section widget used in both programare details page and add programare modal.
/// Contains the list of proceduri, add/remove buttons, and payment section.
/// 
/// Use [fontScale] to increase font sizes for mobile layouts (default 1.0, use ~1.7 for full mobile).
class ProceduriSection extends StatelessWidget {
  final double scale;
  final List<ProceduraEntry> proceduraEntries;
  final bool useTotalOverride;
  final TextEditingController totalOverrideController;
  final TextEditingController achitatController;
  final VoidCallback onAddProcedura;
  final VoidCallback? onAddConsult;
  final Function(int) onRemoveProcedura;
  final VoidCallback onTotalOverrideToggle;
  final VoidCallback onAchitaComplet;
  final VoidCallback? onFieldChanged;
  final bool isMobile;
  final bool isPaymentExpanded;
  final VoidCallback? onPaymentExpandToggle;
  final bool showEmptyState;
  /// Font scale multiplier for mobile layouts. Default 1.0, use ~1.7 for full mobile.
  final double fontScale;

  const ProceduriSection({
    super.key,
    required this.scale,
    required this.proceduraEntries,
    required this.useTotalOverride,
    required this.totalOverrideController,
    required this.achitatController,
    required this.onAddProcedura,
    this.onAddConsult,
    required this.onRemoveProcedura,
    required this.onTotalOverrideToggle,
    required this.onAchitaComplet,
    this.onFieldChanged,
    this.isMobile = false,
    this.isPaymentExpanded = true,
    this.onPaymentExpandToggle,
    this.showEmptyState = true,
    this.fontScale = 1.0,
  });

  double get _effectiveFontScale => scale * fontScale;

  double get totalCost => calculateTotalCost(proceduraEntries);

  double get effectiveTotal {
    if (useTotalOverride && totalOverrideController.text.trim().isNotEmpty) {
      return double.tryParse(totalOverrideController.text.trim()) ?? totalCost;
    }
    return totalCost;
  }

  double get restDePlata {
    final achitat = double.tryParse(achitatController.text.trim()) ?? 0.0;
    return effectiveTotal - achitat;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2 * scale,
        ),
      ),
      padding: EdgeInsets.all(16 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and total
          _buildHeader(),
          SizedBox(height: 16 * scale),
          
          // Empty state
          if (proceduraEntries.isEmpty && showEmptyState)
            _buildEmptyState(),
          
          // Column headers (only on desktop and when there are entries)
          if (!isMobile && proceduraEntries.isNotEmpty)
            _buildColumnHeaders(),
          
          // Procedura entries
          ...List.generate(proceduraEntries.length, (index) {
            return _buildProceduraRow(index);
          }),
          
          SizedBox(height: 16 * scale),
          
          // Payment section
          PaymentSection(
            scale: scale,
            fontScale: fontScale,
            useTotalOverride: useTotalOverride,
            totalOverrideController: totalOverrideController,
            achitatController: achitatController,
            totalCost: totalCost,
            effectiveTotal: effectiveTotal,
            restDePlata: restDePlata,
            onTotalOverrideToggle: onTotalOverrideToggle,
            onAchitaComplet: onAchitaComplet,
            onFieldChanged: onFieldChanged,
            isMobile: isMobile,
            isExpanded: isPaymentExpanded,
            onExpandToggle: onPaymentExpandToggle,
          ),
          
          SizedBox(height: 12 * scale),
          
          // Add buttons
          _buildAddButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Proceduri',
          style: TextStyle(
            fontSize: 28 * _effectiveFontScale,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        // Total cost display
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16 * scale,
            vertical: 8 * scale,
          ),
          decoration: BoxDecoration(
            color: useTotalOverride ? Colors.orange[50] : Colors.green[50],
            borderRadius: BorderRadius.circular(12 * scale),
            border: Border.all(
              color: useTotalOverride ? Colors.orange[400]! : Colors.green[400]!,
              width: 2 * scale,
            ),
          ),
          child: Text(
            'Total: ${effectiveTotal.toStringAsFixed(0)} RON',
            style: TextStyle(
              fontSize: 24 * _effectiveFontScale,
              fontWeight: FontWeight.w700,
              color: useTotalOverride ? Colors.orange[800] : Colors.green[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(24 * scale),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2 * scale,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 48 * _effectiveFontScale,
            color: Colors.grey[400],
          ),
          SizedBox(height: 12 * scale),
          Text(
            'Nicio procedură adăugată',
            style: TextStyle(
              fontSize: 20 * _effectiveFontScale,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            'Apasă butonul de mai jos pentru a adăuga',
            style: TextStyle(
              fontSize: 16 * _effectiveFontScale,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders() {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              'Denumire procedură',
              style: TextStyle(
                fontSize: 20 * _effectiveFontScale,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          SizedBox(width: 12 * scale),
          SizedBox(
            width: 120 * scale,
            child: Text(
              'Preț (RON)',
              style: TextStyle(
                fontSize: 20 * _effectiveFontScale,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          SizedBox(width: 12 * scale),
          SizedBox(
            width: 80 * scale,
            child: Text(
              'Cant.',
              style: TextStyle(
                fontSize: 20 * _effectiveFontScale,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          SizedBox(width: 48 * scale), // Space for delete button
        ],
      ),
    );
  }

  Widget _buildProceduraRow(int index) {
    final entry = proceduraEntries[index];
    
    if (isMobile) {
      return ProceduraCardMobile(
        scale: scale,
        fontScale: fontScale,
        entry: entry,
        canDelete: proceduraEntries.length > 1,
        onDelete: () => onRemoveProcedura(index),
        onFieldChanged: onFieldChanged,
      );
    }
    
    return _ProceduraRowDesktop(
      scale: scale,
      fontScale: fontScale,
      entry: entry,
      canDelete: proceduraEntries.length > 1,
      onDelete: () => onRemoveProcedura(index),
      onFieldChanged: onFieldChanged,
    );
  }

  Widget _buildAddButtons() {
    return Wrap(
      spacing: 12 * scale,
      runSpacing: 12 * scale,
      children: [
        if (onAddConsult != null)
          AddProceduraButton(
            scale: scale,
            fontScale: fontScale,
            label: 'Consult',
            icon: Icons.medical_information_outlined,
            color: Colors.blue,
            onTap: onAddConsult!,
          ),
        AddProceduraButton(
          scale: scale,
          fontScale: fontScale,
          label: 'Adaugă procedură',
          icon: Icons.add_circle_outline,
          color: Colors.green,
          onTap: onAddProcedura,
        ),
      ],
    );
  }
}

/// Mobile-optimized procedura card widget.
/// Use [fontScale] to adjust font sizes (default 1.0, use ~1.7 for full mobile).
class ProceduraCardMobile extends StatelessWidget {
  final double scale;
  final double fontScale;
  final ProceduraEntry entry;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback? onFieldChanged;

  const ProceduraCardMobile({
    super.key,
    required this.scale,
    this.fontScale = 1.0,
    required this.entry,
    required this.canDelete,
    required this.onDelete,
    this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16 * scale),
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2 * scale,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Procedure name
          ProceduraTextField(
            scale: scale,
            fontScale: fontScale,
            controller: entry.numeController,
            hint: 'Denumire procedură',
            onFieldChanged: onFieldChanged,
          ),
          SizedBox(height: 10 * scale),
          
          // Cost and multiplier row
          Row(
            children: [
              Expanded(
                child: ProceduraTextField(
                  scale: scale,
                  fontScale: fontScale,
                  controller: entry.costController,
                  hint: 'Preț (RON)',
                  keyboardType: TextInputType.number,
                  onFieldChanged: onFieldChanged,
                ),
              ),
              SizedBox(width: 10 * scale),
              SizedBox(
                width: 80 * scale,
                child: ProceduraTextField(
                  scale: scale,
                  fontScale: fontScale,
                  controller: entry.multiplicatorController,
                  hint: 'x',
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onFieldChanged: onFieldChanged,
                ),
              ),
              SizedBox(width: 8 * scale),
              if (canDelete)
                _DeleteProceduraButton(
                  scale: scale,
                  fontScale: fontScale,
                  onDelete: onDelete,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProceduraRowDesktop extends StatelessWidget {
  final double scale;
  final double fontScale;
  final ProceduraEntry entry;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback? onFieldChanged;

  const _ProceduraRowDesktop({
    required this.scale,
    this.fontScale = 1.0,
    required this.entry,
    required this.canDelete,
    required this.onDelete,
    this.onFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10 * scale),
      child: Row(
        children: [
          // Procedure name
          Expanded(
            flex: 5,
            child: ProceduraTextField(
              scale: scale,
              fontScale: fontScale,
              controller: entry.numeController,
              hint: 'Denumire procedură',
              onFieldChanged: onFieldChanged,
            ),
          ),
          SizedBox(width: 12 * scale),
          
          // Cost
          SizedBox(
            width: 120 * scale,
            child: ProceduraTextField(
              scale: scale,
              fontScale: fontScale,
              controller: entry.costController,
              hint: 'Preț',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              onFieldChanged: onFieldChanged,
            ),
          ),
          SizedBox(width: 12 * scale),
          
          // Multiplier
          SizedBox(
            width: 80 * scale,
            child: ProceduraTextField(
              scale: scale,
              fontScale: fontScale,
              controller: entry.multiplicatorController,
              hint: 'x1',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onFieldChanged: onFieldChanged,
            ),
          ),
          SizedBox(width: 8 * scale),
          
          // Delete button
          if (canDelete)
            _DeleteProceduraButton(
              scale: scale,
              fontScale: fontScale,
              onDelete: onDelete,
            )
          else
            SizedBox(width: 40 * scale),
        ],
      ),
    );
  }
}

/// Reusable text field for procedura inputs.
/// Use [fontScale] to adjust font sizes (default 1.0, use ~1.7 for full mobile).
class ProceduraTextField extends StatelessWidget {
  final double scale;
  final double fontScale;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final TextAlign textAlign;
  final VoidCallback? onFieldChanged;

  const ProceduraTextField({
    super.key,
    required this.scale,
    this.fontScale = 1.0,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.textAlign = TextAlign.start,
    this.onFieldChanged,
  });

  double get _effectiveScale => scale * fontScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(
          color: Colors.black,
          width: 3 * scale,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: textAlign,
        onChanged: (_) => onFieldChanged?.call(),
        style: TextStyle(
          fontSize: 24 * _effectiveScale,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 24 * _effectiveScale,
            fontWeight: FontWeight.w500,
            color: Colors.black38,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16 * scale,
            vertical: 14 * scale,
          ),
        ),
      ),
    );
  }
}

class _DeleteProceduraButton extends StatelessWidget {
  final double scale;
  final double fontScale;
  final VoidCallback onDelete;

  const _DeleteProceduraButton({
    required this.scale,
    this.fontScale = 1.0,
    required this.onDelete,
  });

  double get _effectiveScale => scale * fontScale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDelete,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 40 * _effectiveScale,
          height: 40 * _effectiveScale,
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(10 * scale),
            border: Border.all(
              color: Colors.red[400]!,
              width: 2 * scale,
            ),
          ),
          child: Icon(
            Icons.close,
            size: 24 * _effectiveScale,
            color: Colors.red[700],
          ),
        ),
      ),
    );
  }
}

/// Reusable add button for proceduri.
/// Use [fontScale] to adjust font sizes (default 1.0, use ~1.7 for full mobile).
class AddProceduraButton extends StatefulWidget {
  final double scale;
  final double fontScale;
  final String label;
  final IconData icon;
  final MaterialColor color;
  final VoidCallback onTap;

  const AddProceduraButton({
    super.key,
    required this.scale,
    this.fontScale = 1.0,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<AddProceduraButton> createState() => _AddProceduraButtonState();
}

class _AddProceduraButtonState extends State<AddProceduraButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  double get _effectiveScale => widget.scale * widget.fontScale;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovering ? 1.02 : 1.0),
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: 24 * widget.scale,
              vertical: 14 * widget.scale,
            ),
            decoration: BoxDecoration(
              color: widget.color[600],
              borderRadius: BorderRadius.circular(20 * widget.scale),
              border: Border.all(
                color: Colors.black,
                width: 4 * widget.scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isPressed ? 0.5 : (_isHovering ? 0.6 : 0.4)),
                  blurRadius: _isPressed ? 4 * widget.scale : (_isHovering ? 10 * widget.scale : 6 * widget.scale),
                  offset: Offset(0, _isPressed ? 3 * widget.scale : (_isHovering ? 6 * widget.scale : 4 * widget.scale)),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 28 * _effectiveScale,
                  color: Colors.white,
                ),
                SizedBox(width: 10 * widget.scale),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 24 * _effectiveScale,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

