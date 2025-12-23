import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/utils/date_formatters.dart';
import 'package:liu_stoma/utils/patient_filters.dart';
import 'package:liu_stoma/utils/patient_parser.dart';
import 'package:liu_stoma/widgets/patient_card.dart';

class PatientList extends StatelessWidget {
  final bool isMobile;
  final AsyncSnapshot<QuerySnapshot> snapshot;
  final String searchQuery;
  final double scale;
  final double maxWidth;
  final double horizontalPadding;
  final double maxContentWidth;
  final Function(String name, String patientId, List<Programare> programari)
      onPatientTap;
  final Function(String name, String patientId, List<Programare> programari, Offset menuPosition, Offset cardPosition, Size cardSize)?
      onPatientLongPress;
  final String? selectedPatientId;

  const PatientList({
    super.key,
    required this.isMobile,
    required this.snapshot,
    required this.searchQuery,
    required this.scale,
    required this.maxWidth,
    required this.horizontalPadding,
    required this.maxContentWidth,
    required this.onPatientTap,
    this.onPatientLongPress,
    this.selectedPatientId,
  });

  @override
  Widget build(BuildContext context) {
    // Only show loading on initial load, not on subsequent rebuilds
    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (snapshot.hasError) {
      print(snapshot.error);
      return Center(
        child: Text('Error: ${snapshot.error}'),
      );
    }
    
    // If we have no data, show empty state
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      // Only show empty message if we're not waiting (to avoid flicker)
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Center(
        child: Text('Nu există pacienți'),
      );
    }

    final allPatients = snapshot.data!.docs;
    final filteredPatients = PatientFilters.filterPatients(
      allPatients,
      searchQuery,
    );

    if (filteredPatients.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Text(
          'Nu s-au găsit pacienți',
          style: TextStyle(
            fontSize: 42 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      );
    }

    // Mobile layout: single column, much larger cards for readability
    if (isMobile) {
      final cardSpacing = 20.0 * scale;
      // Make cards and text roughly ~2x larger vs base page scale
      final cardScale = (scale * 1.9).clamp(0.4, 1.4);

      return Padding(
        // Match horizontal margin with the search bar on mobile
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final doc in filteredPatients)
                    Padding(
                      padding: EdgeInsets.only(bottom: cardSpacing),
                      child: PatientCard(
                        key: ValueKey(doc.id),
                        patientId: doc.id,
                        nume:
                            (doc.data() as Map<String, dynamic>)['nume'] ?? '',
                        varsta: DateFormatters.calculateAgeFromCNP(
                          (doc.data() as Map<String, dynamic>)['cnp']
                              ?.toString(),
                        ),
                        programari: PatientParser.parseProgramari(
                          doc.data() as Map<String, dynamic>,
                        ),
                        formatTimestamp: DateFormatters.formatTimestamp,
                        scale: cardScale,
                        isSelected: selectedPatientId == doc.id,
                        onTap: () {
                          final patientData =
                              doc.data() as Map<String, dynamic>;
                          final nume = patientData['nume'] ?? '';
                          final programari =
                              PatientParser.parseProgramari(patientData);
                          onPatientTap(nume, doc.id, programari);
                        },
                        onLongPress: onPatientLongPress != null
                            ? (menuPosition, cardPosition, cardSize) {
                                final patientData =
                                    doc.data() as Map<String, dynamic>;
                                final nume = patientData['nume'] ?? '';
                                final programari =
                                    PatientParser.parseProgramari(patientData);
                                onPatientLongPress!(nume, doc.id, programari, menuPosition, cardPosition, cardSize);
                              }
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Desktop/tablet layout: rows of 2 cards each
    final rows = <Widget>[];
    final cardSpacing = 20.0 * scale;
    final desktopHorizontalPadding = 24 * scale;
    // Calculate card width: (maxWidth - 2*horizontalPadding - cardSpacing) / 2
    final cardWidth =
        (maxWidth - 2 * desktopHorizontalPadding - cardSpacing) / 2;

    for (int i = 0; i < filteredPatients.length; i += 2) {
      final rowChildren = <Widget>[];
      final isLastRow = i + 2 >= filteredPatients.length;
      final cardsInRow = filteredPatients.length - i;

      for (int j = 0; j < 2 && i + j < filteredPatients.length; j++) {
        final patient = filteredPatients[i + j].data() as Map<String, dynamic>;
        final nume = patient['nume'] ?? '';
        final cnp = patient['cnp']?.toString();
        final varsta = DateFormatters.calculateAgeFromCNP(cnp);
        final programari = PatientParser.parseProgramari(patient);

        final patientId = filteredPatients[i + j].id;

        // If last row has only one card, use fixed width instead of Expanded
        final cardWidget = Padding(
          padding: EdgeInsets.only(
            right: j == 0 ? cardSpacing / 2 : 0,
            left: j == 1 ? cardSpacing / 2 : 0,
          ),
          child: PatientCard(
            key: ValueKey(patientId),
            patientId: patientId,
            nume: nume,
            varsta: varsta,
            programari: programari,
            formatTimestamp: DateFormatters.formatTimestamp,
            scale: scale,
            isSelected: selectedPatientId == patientId,
            onTap: () => onPatientTap(nume, patientId, programari),
            onLongPress: onPatientLongPress != null
                ? (menuPosition, cardPosition, cardSize) {
                    // Need to get card position and size for desktop too
                    // For now, approximate from menu position
                    onPatientLongPress!(nume, patientId, programari, menuPosition, cardPosition, cardSize);
                  }
                : null,
          ),
        );

        if (isLastRow && cardsInRow == 1) {
          // Single card in last row: use fixed width
          rowChildren.add(
            SizedBox(
              width: cardWidth,
              child: cardWidget,
            ),
          );
        } else {
          // Normal case: use Expanded
          rowChildren.add(
            Expanded(
              child: cardWidget,
            ),
          );
        }
      }
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: cardSpacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: desktopHorizontalPadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
  }
}

