import 'package:flutter/material.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/utils/date_formatters.dart';
import 'package:liu_stoma/widgets/programari_table/animated_row.dart';
import 'package:liu_stoma/widgets/programari_table/animated_card.dart';
import 'package:liu_stoma/widgets/programari_table/payment_status_badge.dart';

/// A table/list widget for displaying programari.
/// Automatically switches between mobile (cards) and desktop (table rows) layouts.
class ProgramariTable extends StatelessWidget {
  final List<Programare> programari;
  final double scale;
  final Function(Programare programare) onEdit;
  final Function(Programare programare) onDelete;
  final bool showDeleteButton;
  final bool showVerticalBar;

  const ProgramariTable({
    super.key,
    required this.programari,
    required this.scale,
    required this.onEdit,
    required this.onDelete,
    this.showDeleteButton = true,
    this.showVerticalBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    
    // Sort programari in reverse chronological order (newest first)
    final sortedProgramari = List<Programare>.from(programari)
      ..sort((a, b) => b.programareTimestamp.compareTo(a.programareTimestamp));

    if (sortedProgramari.isEmpty) {
      return Center(
        child: Text(
          'Nu există programări',
          style: TextStyle(
            fontSize: 32 * scale,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      );
    }

    if (isMobile) {
      return _buildMobileLayout(sortedProgramari);
    }

    return _buildDesktopLayout(sortedProgramari);
  }

  Widget _buildMobileLayout(List<Programare> sortedProgramari) {
    return ListView.separated(
      padding: EdgeInsets.all(12 * scale),
      itemCount: sortedProgramari.length,
      separatorBuilder: (context, index) => SizedBox(height: 12 * scale),
      itemBuilder: (context, index) {
        final programare = sortedProgramari[index];
        final programareDate = programare.programareTimestamp.toDate();
        final isEpochDate = programareDate.year == 1970 && 
                            programareDate.month == 1 && 
                            programareDate.day == 1;
        
        final bool hasNotification = programare.programareNotification == true;
        
        return AnimatedCard(
          onTap: () => onEdit(programare),
          scale: scale,
          hasNotification: hasNotification,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date/time and notification indicator
              _buildMobileCardHeader(programare, isEpochDate, hasNotification),
              // Procedures list
              _buildMobileCardContent(programare),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileCardHeader(Programare programare, bool isEpochDate, bool hasNotification) {
    return Container(
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: hasNotification ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(13 * scale),
          topRight: Radius.circular(13 * scale),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasNotification ? Icons.notifications_active : Icons.notifications_off,
            size: 24 * scale,
            color: hasNotification ? Colors.green[700] : Colors.red[700],
          ),
          SizedBox(width: 10 * scale),
          if (!isEpochDate) ...[
            Text(
              DateFormatters.formatDateShort(programare.programareTimestamp),
              style: TextStyle(
                fontSize: 22 * scale,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: 12 * scale),
            Text(
              DateFormatters.formatTime(programare.programareTimestamp),
              style: TextStyle(
                fontSize: 22 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ] else
            Text(
              'Fără dată',
              style: TextStyle(
                fontSize: 22 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          const Spacer(),
          if (programare.durata != null)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * scale,
                vertical: 4 * scale,
              ),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: Text(
                '${programare.durata} min',
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ),
          if (showDeleteButton) ...[
            SizedBox(width: 8 * scale),
            GestureDetector(
              onTap: () => onDelete(programare),
              child: Container(
                padding: EdgeInsets.all(6 * scale),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Icon(
                  Icons.delete,
                  size: 22 * scale,
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileCardContent(Programare programare) {
    return Padding(
      padding: EdgeInsets.all(12 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...programare.proceduri.map((p) => _buildMobileProceduraRow(p)),
          if (programare.proceduri.length > 1 || programare.totalCost > 0) ...[
            Divider(height: 16 * scale, thickness: 2 * scale),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Payment status
                PaymentStatusBadge(
                  programare: programare,
                  scale: scale,
                  isMobile: true,
                ),
                // Total cost
                Row(
                  children: [
                    Text(
                      'Total: ',
                      style: TextStyle(
                        fontSize: 22 * scale,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      '${programare.totalCost.toStringAsFixed(0)} RON',
                      style: TextStyle(
                        fontSize: 22 * scale,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileProceduraRow(Procedura p) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Text(
        p.multiplicator > 1 ? '${p.nume} x${p.multiplicator}' : p.nume,
        style: TextStyle(
          fontSize: 22 * scale,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(List<Programare> sortedProgramari) {
    return Column(
      children: [
        // Header row
        _buildDesktopHeader(),
        // Data rows
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: sortedProgramari.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Colors.black26,
            ),
            itemBuilder: (context, index) {
              final programare = sortedProgramari[index];
              return _buildDesktopRow(programare);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12 * scale),
          topRight: Radius.circular(12 * scale),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 24 * scale,
        vertical: 18 * scale,
      ),
      child: Row(
        children: [
          if (showDeleteButton) ...[
            SizedBox(
              width: 60 * scale,
              child: Text(
                '',
                style: TextStyle(
                  fontSize: 32 * scale,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(width: 20 * scale),
          ],
          SizedBox(
            width: 200 * scale,
            child: Row(
              children: [
                Text(
                  'Data',
                  style: TextStyle(
                    fontSize: 28 * scale,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 24 * scale),
                Text(
                  'Ora',
                  style: TextStyle(
                    fontSize: 28 * scale,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16 * scale),
          Expanded(
            child: Text(
              'Proceduri',
              style: TextStyle(
                fontSize: 28 * scale,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(
            width: 140 * scale,
            child: Text(
              'Cost',
              style: TextStyle(
                fontSize: 28 * scale,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 96 * scale,
            child: Center(
              child: Text(
                'Durată',
                style: TextStyle(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRow(Programare programare) {
    final programareDate = programare.programareTimestamp.toDate();
    final isEpochDate = programareDate.year == 1970 && 
                        programareDate.month == 1 && 
                        programareDate.day == 1;
    
    final bool hasNotification = programare.programareNotification == true;
    
    return AnimatedRow(
      onTap: () => onEdit(programare),
      scale: scale,
      showVerticalBar: showVerticalBar,
      hasNotification: hasNotification,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delete button
          if (showDeleteButton) ...[
            SizedBox(
              width: 60 * scale,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onDelete(programare),
                  child: Container(
                    width: 40 * scale,
                    height: 40 * scale,
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(8 * scale),
                      border: Border.all(
                        color: Colors.black,
                        width: 3 * scale,
                      ),
                    ),
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 24 * scale,
                      weight: 900,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 20 * scale),
          ],
          // Date + Time
          SizedBox(
            width: 200 * scale,
            child: isEpochDate
                ? Text(
                    'Fără dată',
                    style: TextStyle(
                      fontSize: 24 * scale,
                      fontWeight: FontWeight.w500,
                      color: Colors.black45,
                    ),
                  )
                : Row(
                    children: [
                      Text(
                        DateFormatters.formatDateShort(programare.programareTimestamp),
                        style: TextStyle(
                          fontSize: 24 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 16 * scale),
                      Text(
                        DateFormatters.formatTime(programare.programareTimestamp),
                        style: TextStyle(
                          fontSize: 24 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
          ),
          SizedBox(width: 16 * scale),
          // Procedures list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: programare.proceduri.map((p) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 4 * scale),
                  child: Text(
                    p.multiplicator > 1 
                        ? '${p.nume} x${p.multiplicator}'
                        : p.nume,
                    style: TextStyle(
                      fontSize: 24 * scale,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Total cost with payment status
          SizedBox(
            width: 140 * scale,
            child: programare.totalCost > 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${programare.totalCost.toStringAsFixed(0)} RON',
                        style: TextStyle(
                          fontSize: 22 * scale,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4 * scale),
                      PaymentStatusBadge(
                        programare: programare,
                        scale: scale,
                      ),
                    ],
                  )
                : Text(
                    '-',
                    style: TextStyle(
                      fontSize: 22 * scale,
                      fontWeight: FontWeight.w500,
                      color: Colors.black45,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          // Duration
          SizedBox(
            width: 96 * scale,
            child: Center(
              child: Text(
                programare.durata != null ? '${programare.durata} min' : '-',
                style: TextStyle(
                  fontSize: 24 * scale,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
