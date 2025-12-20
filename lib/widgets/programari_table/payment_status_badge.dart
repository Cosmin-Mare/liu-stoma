import 'package:flutter/material.dart';
import 'package:liu_stoma/models/programare.dart';

/// A badge showing the payment status of a programare.
/// Shows "Plătit", "Datorie: X", or "Neplătit" based on payment status.
class PaymentStatusBadge extends StatelessWidget {
  final Programare programare;
  final double scale;
  final bool isMobile;

  const PaymentStatusBadge({
    super.key,
    required this.programare,
    required this.scale,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    if (programare.totalCost <= 0) {
      return const SizedBox.shrink();
    }

    final isPaid = programare.isPlatit;
    final hasPartialPayment = programare.achitat > 0 && !isPaid;
    
    if (isPaid) {
      return _buildPaidBadge();
    } else if (hasPartialPayment) {
      return _buildPartialPaymentBadge();
    } else {
      return _buildUnpaidBadge();
    }
  }

  Widget _buildPaidBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (isMobile ? 10 : 8) * scale,
        vertical: (isMobile ? 6 : 4) * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.green,
        border: Border.all(
          color: Colors.black,
          width: 2 * scale,
        ),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: (isMobile ? 18 : 16) * scale,
            color: Colors.white,
          ),
          SizedBox(width: 4 * scale),
          Text(
            'Plătit',
            style: TextStyle(
              fontSize: (isMobile ? 18 : 16) * scale,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartialPaymentBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (isMobile ? 10 : 8) * scale,
        vertical: (isMobile ? 6 : 4) * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.orange[400],
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(
          color: Colors.black,
          width: 2 * scale,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning,
            size: (isMobile ? 18 : 16) * scale,
            color: Colors.white,
          ),
          SizedBox(width: 4 * scale),
          Text(
            'Datorie: ${programare.restDePlata.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: (isMobile ? 18 : 16) * scale,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnpaidBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (isMobile ? 10 : 8) * scale,
        vertical: (isMobile ? 6 : 4) * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.red,
        border: Border.all(
          color: Colors.black,
          width: 2 * scale,
        ),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cancel,
            size: (isMobile ? 18 : 16) * scale,
            color: Colors.white,
          ),
          SizedBox(width: 4 * scale),
          Text(
            'Neplătit',
            style: TextStyle(
              fontSize: (isMobile ? 18 : 16) * scale,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

