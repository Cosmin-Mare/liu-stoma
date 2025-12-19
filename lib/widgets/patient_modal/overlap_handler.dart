import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/services/patient_service.dart';

class OverlapHandler {
  static Future<bool> checkAndHandleOverlap({
    required DateTime newDateTime,
    required int? newDurata,
    required String? patientId,
    required Programare? excludeProgramare,
    required Function(DateTime, String, bool, int?, String?) onOverlapDetected,
    required Function(String, Timestamp, bool, int?) onNoOverlap,
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
        '', // procedura will be set by caller
        false, // notificare will be set by caller
        newDurata,
        patientId,
      );
      return true;
    } else {
      return false;
    }
  }

  static Future<void> saveAfterOverlapConfirmation({
    required DateTime dateTime,
    required String procedura,
    required bool notificare,
    required int? durata,
    required String? patientId,
    required Programare? programareToEdit,
    required Function(Programare, String, Timestamp, bool, int?) onUpdate,
    required Function(String, String, Timestamp, bool, int?) onAdd,
    required Function(bool, String) onResult,
  }) async {
    final timestamp = Timestamp.fromDate(dateTime);
    
    if (programareToEdit != null) {
      // Editing existing appointment
      await onUpdate(programareToEdit, procedura, timestamp, notificare, durata);
    } else if (patientId != null) {
      // Adding new appointment
      final result = await PatientService.addProgramare(
        patientId: patientId,
        procedura: procedura,
        timestamp: timestamp,
        notificare: notificare,
        durata: durata,
      );
      onResult(result.success, result.errorMessage ?? 'Eroare la salvare');
    }
  }
}

