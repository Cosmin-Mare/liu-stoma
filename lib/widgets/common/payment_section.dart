import 'package:flutter/material.dart';

/// A reusable payment section widget used in both programare details page and add programare modal.
/// Contains total override toggle, achitat input, achita complet button, and rest de plata display.
/// 
/// Use [fontScale] to increase font sizes for mobile layouts (default 1.0, use ~1.7 for mobile).
class PaymentSection extends StatelessWidget {
  final double scale;
  final bool useTotalOverride;
  final TextEditingController totalOverrideController;
  final TextEditingController achitatController;
  final double totalCost;
  final double effectiveTotal;
  final double restDePlata;
  final VoidCallback onTotalOverrideToggle;
  final VoidCallback onAchitaComplet;
  final VoidCallback? onFieldChanged;
  final bool isMobile;
  final bool isExpanded;
  final VoidCallback? onExpandToggle;
  /// Font scale multiplier for mobile layouts. Default 1.0, use ~1.7 for full mobile.
  final double fontScale;

  const PaymentSection({
    super.key,
    required this.scale,
    required this.useTotalOverride,
    required this.totalOverrideController,
    required this.achitatController,
    required this.totalCost,
    required this.effectiveTotal,
    required this.restDePlata,
    required this.onTotalOverrideToggle,
    required this.onAchitaComplet,
    this.onFieldChanged,
    this.isMobile = false,
    this.isExpanded = true,
    this.onExpandToggle,
    this.fontScale = 1.0,
  });

  /// Effective scale that combines base scale with font scale
  double get _effectiveScale => scale * fontScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(
          color: Colors.black,
          width: 4 * scale,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8 * scale,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          _buildHeader(context),
          
          // Collapsible content
          if (onExpandToggle != null)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildContent(),
              crossFadeState: isExpanded 
                  ? CrossFadeState.showSecond 
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            )
          else
            _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final headerContent = Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        borderRadius: onExpandToggle != null && isExpanded
            ? BorderRadius.only(
                topLeft: Radius.circular(17 * scale),
                topRight: Radius.circular(17 * scale),
              )
            : BorderRadius.circular(17 * scale),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all((8 + 2 * (fontScale - 1)) * scale),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black,
                width: 2 * scale,
              ),
              borderRadius: BorderRadius.circular(10 * scale),
            ),
            child: Icon(
              Icons.payments_outlined,
              size: 24 * _effectiveScale,
              color: Colors.black,
            ),
          ),
          SizedBox(width: 12 * scale),
          Text(
            'Plată',
            style: TextStyle(
              fontSize: 24 * _effectiveScale,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          if (onExpandToggle != null) ...[
            const Spacer(),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 32 * scale,
                color: Colors.black,
              ),
            ),
          ],
        ],
      ),
    );

    if (onExpandToggle != null) {
      return GestureDetector(
        onTap: onExpandToggle,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: headerContent,
        ),
      );
    }
    return headerContent;
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        onExpandToggle != null ? 0 : 0,
        16 * scale,
        16 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total override toggle
          _TotalOverrideToggle(
            scale: scale,
            fontScale: fontScale,
            useTotalOverride: useTotalOverride,
            onToggle: onTotalOverrideToggle,
          ),
          
          // Total override input (only shown when enabled)
          if (useTotalOverride) ...[
            SizedBox(height: 14 * scale),
            _TotalOverrideInput(
              scale: scale,
              fontScale: fontScale,
              controller: totalOverrideController,
              totalCost: totalCost,
              onFieldChanged: onFieldChanged,
            ),
          ],
          
          SizedBox(height: 18 * scale),
          
          // Divider
          Container(
            height: 2 * scale,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1 * scale),
            ),
          ),
          
          SizedBox(height: 18 * scale),
          
          // Achitat section
          _buildAchitatSection(),
          
          // Rest de plată display for mobile
          if (isMobile) ...[
            SizedBox(height: 16 * scale),
            RestDePlataChip(
              scale: scale,
              fontScale: fontScale,
              restDePlata: restDePlata,
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAchitatSection() {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 22 * _effectiveScale,
                color: Colors.green[700],
              ),
              SizedBox(width: 8 * scale),
              Text(
                'Achitat:',
                style: TextStyle(
                  fontSize: 20 * _effectiveScale,
                  fontWeight: FontWeight.w700,
                  color: Colors.black  ,
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * scale),
          Row(
            children: [
              Expanded(
                child: _PaymentTextField(
                  scale: scale,
                  fontScale: fontScale,
                  controller: achitatController,
                  hint: '0',
                  onFieldChanged: onFieldChanged,
                ),
              ),
              SizedBox(width: 10 * scale),
              _RonLabel(scale: scale, fontScale: fontScale, color: Colors.green),
              SizedBox(width: 10 * scale),
              AchitaCompletButton(
                scale: scale,
                fontScale: fontScale,
                onTap: onAchitaComplet,
              ),
            ],
          ),
        ],
      );
    }
    
    return Row(
      children: [
        Icon(
          Icons.account_balance_wallet_outlined,
          size: 22 * _effectiveScale,
          color: Colors.black,
        ),
        SizedBox(width: 8 * scale),
        Text(
          'Achitat:',
          style: TextStyle(
            fontSize: 20 * _effectiveScale,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(width: 14 * scale),
        SizedBox(
          width: 150 * scale,
          child: _PaymentTextField(
            scale: scale,
            fontScale: fontScale,
            controller: achitatController,
            hint: '0',
            onFieldChanged: onFieldChanged,
          ),
        ),
        SizedBox(width: 10 * scale),
        _RonLabel(scale: scale, fontScale: fontScale, color: Colors.green),
        SizedBox(width: 10 * scale),
        AchitaCompletButton(
          scale: scale,
          fontScale: fontScale,
          onTap: onAchitaComplet,
        ),
        const Spacer(),
        RestDePlataChip(scale: scale, fontScale: fontScale, restDePlata: restDePlata),
      ],
    );
  }
}

class _TotalOverrideToggle extends StatefulWidget {
  final double scale;
  final double fontScale;
  final bool useTotalOverride;
  final VoidCallback onToggle;

  const _TotalOverrideToggle({
    required this.scale,
    this.fontScale = 1.0,
    required this.useTotalOverride,
    required this.onToggle,
  });

  @override
  State<_TotalOverrideToggle> createState() => _TotalOverrideToggleState();
}

class _TotalOverrideToggleState extends State<_TotalOverrideToggle> {
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
          widget.onToggle();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : (_isHovering ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14 * widget.scale,
              vertical: 10 * widget.scale,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14 * widget.scale),
              border: Border.all(
                color: widget.useTotalOverride 
                    ? Colors.orange[400]! 
                    : (_isHovering ? Colors.black : Colors.black),
                width: 2.5 * widget.scale,
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5 * widget.scale, offset: Offset(0, 5 * widget.scale))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 28 * _effectiveScale,
                  height: 28 * _effectiveScale,
                  decoration: BoxDecoration(
                    gradient: widget.useTotalOverride 
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.orange[500]!, Colors.deepOrange[400]!],
                          )
                        : null,
                    color: widget.useTotalOverride ? null : Colors.white,
                    borderRadius: BorderRadius.circular(8 * widget.scale),
                    border: Border.all(
                      color: widget.useTotalOverride ? Colors.orange[700]! : Colors.black,
                      width: 3 * widget.scale,
                    ),
                  ),
                  child: widget.useTotalOverride
                      ? Icon(
                          Icons.check_rounded,
                          size: 20 * _effectiveScale,
                          color: Colors.white,
                        )
                      : null,
                ),
                SizedBox(width: 12 * widget.scale),
                Flexible(
                  child: Text(
                    'Modifică totalul manual',
                    style: TextStyle(
                      fontSize: 20 * _effectiveScale,
                      fontWeight: FontWeight.w700,
                      color: widget.useTotalOverride ? Colors.orange[800] : Colors.black87,
                    ),
                  ),
                ),
                if (widget.useTotalOverride) ...[
                  SizedBox(width: 8 * widget.scale),
                  Icon(
                    Icons.edit_outlined,
                    size: 20 * _effectiveScale,
                    color: Colors.orange[600],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalOverrideInput extends StatelessWidget {
  final double scale;
  final double fontScale;
  final TextEditingController controller;
  final double totalCost;
  final VoidCallback? onFieldChanged;

  const _TotalOverrideInput({
    required this.scale,
    this.fontScale = 1.0,
    required this.controller,
    required this.totalCost,
    this.onFieldChanged,
  });

  double get _effectiveScale => scale * fontScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(
          color: Colors.orange[200]!,
          width: 2 * scale,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.price_change_outlined,
                size: 22 * _effectiveScale,
                color: Colors.orange[700],
              ),
              SizedBox(width: 8 * scale),
              Text(
                'Total nou:',
                style: TextStyle(
                  fontSize: 18 * _effectiveScale,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange[800],
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: _PaymentTextField(
                  scale: scale,
                  fontScale: fontScale,
                  controller: controller,
                  hint: totalCost.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  onFieldChanged: onFieldChanged,
                ),
              ),
              SizedBox(width: 10 * scale),
              _RonLabel(scale: scale, fontScale: fontScale, color: Colors.orange),
            ],
          ),
          SizedBox(height: 10 * scale),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16 * _effectiveScale,
                color: Colors.orange[400],
              ),
              SizedBox(width: 6 * scale),
              Flexible(
                child: Text(
                  'Total calculat: ${totalCost.toStringAsFixed(0)} RON',
                  style: TextStyle(
                    fontSize: 16 * _effectiveScale,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentTextField extends StatelessWidget {
  final double scale;
  final double fontScale;
  final TextEditingController controller;
  final String hint;
  final TextAlign textAlign;
  final VoidCallback? onFieldChanged;

  const _PaymentTextField({
    required this.scale,
    this.fontScale = 1.0,
    required this.controller,
    required this.hint,
    this.textAlign = TextAlign.right,
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
        keyboardType: TextInputType.number,
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

class _RonLabel extends StatelessWidget {
  final double scale;
  final double fontScale;
  final MaterialColor color;

  const _RonLabel({
    required this.scale,
    this.fontScale = 1.0,
    required this.color,
  });

  double get _effectiveScale => scale * fontScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6 * scale,
        vertical: 8 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Text(
        'RON',
        style: TextStyle(
          fontSize: 20 * _effectiveScale,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    );
  }
}

/// Achita complet button widget
class AchitaCompletButton extends StatefulWidget {
  final double scale;
  final double fontScale;
  final VoidCallback onTap;

  const AchitaCompletButton({
    super.key,
    required this.scale,
    this.fontScale = 1.0,
    required this.onTap,
  });

  @override
  State<AchitaCompletButton> createState() => _AchitaCompletButtonState();
}

class _AchitaCompletButtonState extends State<AchitaCompletButton> {
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
          scale: _isPressed ? 0.95 : (_isHovering ? 1.03 : 1.0),
          alignment: Alignment.center,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: 14 * widget.scale,
              vertical: 10 * widget.scale,
            ),
            decoration: BoxDecoration(
              color: _isHovering ? Colors.green[700] : Colors.green[600],
              borderRadius: BorderRadius.circular(20 * widget.scale),
              border: Border.all(
                color: Colors.black,
                width: 3 * widget.scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isPressed ? 0.4 : (_isHovering ? 0.5 : 0.3)),
                  blurRadius: _isPressed ? 4 * widget.scale : (_isHovering ? 8 * widget.scale : 6 * widget.scale),
                  offset: Offset(0, _isPressed ? 2 * widget.scale : (_isHovering ? 5 * widget.scale : 3 * widget.scale)),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 25 * _effectiveScale,
                  color: Colors.white,
                ),
                SizedBox(width: 6 * widget.scale),
                Text(
                  'Achită',
                  style: TextStyle(
                    fontSize: 20 * _effectiveScale,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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

/// Rest de plată chip widget
class RestDePlataChip extends StatelessWidget {
  final double scale;
  final double fontScale;
  final double restDePlata;
  final bool fullWidth;

  const RestDePlataChip({
    super.key,
    required this.scale,
    this.fontScale = 1.0,
    required this.restDePlata,
    this.fullWidth = false,
  });

  double get _effectiveScale => scale * fontScale;

  @override
  Widget build(BuildContext context) {
    final isPaid = restDePlata <= 0;
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(50 * scale),
        border: Border.all(
          color: Colors.black,
          width: 3 * scale,
        )
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.warning,
            size: 24 * _effectiveScale,
            color: Colors.white,
          ),
          SizedBox(width: 10 * scale),
          Flexible(
            child: Text(
              isPaid 
                  ? 'Plătit complet' 
                  : 'Datorie: ${restDePlata.toStringAsFixed(0)} RON',
              style: TextStyle(
                fontSize: 20 * _effectiveScale,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

