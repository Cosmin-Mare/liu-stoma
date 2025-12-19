import 'package:flutter/material.dart';

class CustomNotification extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final double scale;
  final VoidCallback onDismiss;

  const CustomNotification({
    super.key,
    required this.message,
    required this.isSuccess,
    required this.scale,
    required this.onDismiss,
  });

  @override
  State<CustomNotification> createState() => _CustomNotificationState();
}

class _CustomNotificationState extends State<CustomNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: _slideAnimation.value,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? screenWidth * 0.9 : 500 * widget.scale,
                ),
                margin: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 * widget.scale : 20 * widget.scale,
                  vertical: 20 * widget.scale,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 48 * widget.scale : 32 * widget.scale,
                  vertical: isMobile ? 32 * widget.scale : 20 * widget.scale,
                ),
                decoration: BoxDecoration(
                  color: (widget.isSuccess ? Colors.green[600] : Colors.red[600])!.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(isMobile ? 50 * widget.scale : 40 * widget.scale),
                  border: Border.all(
                    color: Colors.black,
                    width: isMobile ? 8 * widget.scale : 6 * widget.scale,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20 * widget.scale,
                      offset: Offset(0, 8 * widget.scale),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isSuccess ? Icons.check_circle : Icons.error,
                      size: isMobile ? 48 * widget.scale : 32 * widget.scale,
                      color: Colors.white,
                      weight: 900,
                    ),
                    SizedBox(width: isMobile ? 24 * widget.scale : 16 * widget.scale),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          fontSize: isMobile ? 40 * widget.scale : 28 * widget.scale,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: isMobile ? 16 * widget.scale : 8 * widget.scale),
                    GestureDetector(
                      onTap: _dismiss,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Icon(
                          Icons.close,
                          size: isMobile ? 36 * widget.scale : 24 * widget.scale,
                          color: Colors.white,
                          weight: 900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

