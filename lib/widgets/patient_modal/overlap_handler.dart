import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/services/patient_service.dart';

class OverlapHandler {
  static Future<bool> checkAndHandleOverlap({
    required DateTime newDateTime,
    required int? newDurata,
    required String? patientId,
    required Programare? excludeProgramare,
    required Function(DateTime, List<Procedura>, bool, int?, double?, double, String?) onOverlapDetected,
    required Function(List<Procedura>, Timestamp, bool, int?, double?, double) onNoOverlap,
  }) async {
    // Skip overlap check for consultations without dates (epoch date)
    final isDateSkipped = newDateTime.year == 1970 && 
                          newDateTime.month == 1 && 
                          newDateTime.day == 1;
    
    if (isDateSkipped) {
      // No overlap check needed for consultations without dates
      return false;
    }
    
    final hasOverlap = await PatientService.checkOverlapWithAllAppointments(
      newDateTime: newDateTime,
      newDurata: newDurata,
      excludePatientId: patientId,
      excludeProgramare: excludeProgramare,
    );

    if (hasOverlap) {
      onOverlapDetected(
        newDateTime,
        [], // proceduri will be set by caller
        false, // notificare will be set by caller
        newDurata,
        null, // totalOverride will be set by caller
        0.0, // achitat will be set by caller
        patientId,
      );
      return true;
    } else {
      return false;
    }
  }

  static Future<void> saveAfterOverlapConfirmation({
    required DateTime dateTime,
    required List<Procedura> proceduri,
    required bool notificare,
    required int? durata,
    required double? totalOverride,
    required double achitat,
    required String? patientId,
    required Programare? programareToEdit,
    required Function(Programare, List<Procedura>, Timestamp, bool, int?, double?, double) onUpdate,
    required Function(String, List<Procedura>, Timestamp, bool, int?, double?, double) onAdd,
    required Function(bool, String) onResult,
  }) async {
    final timestamp = Timestamp.fromDate(dateTime);
    
    if (programareToEdit != null) {
      // Editing existing appointment
      await onUpdate(programareToEdit, proceduri, timestamp, notificare, durata, totalOverride, achitat);
    } else if (patientId != null) {
      // Adding new appointment
      final result = await PatientService.addProgramare(
        patientId: patientId,
        proceduri: proceduri,
        timestamp: timestamp,
        notificare: notificare,
        durata: durata,
        totalOverride: totalOverride,
        achitat: achitat,
      );
      onResult(result.success, result.errorMessage ?? 'Eroare la salvare');
    }
  }
}
