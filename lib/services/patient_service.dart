import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:liu_stoma/models/programare.dart';
import 'package:liu_stoma/utils/patient_parser.dart';

class PatientServiceResult<T> {
  final bool success;
  final T? data;
  final String? errorMessage;

  PatientServiceResult.success(this.data)
      : success = true,
        errorMessage = null;

  PatientServiceResult.error(this.errorMessage)
      : success = false,
        data = null;
}

class PatientService {
  /// Capitalizes the first letter of each word in a string
  static String _capitalizeName(String name) {
    if (name.trim().isEmpty) return name;
    
    return name
        .trim()
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  static Future<PatientServiceResult<void>> savePatientData({
    required String patientId,
    required String nume,
    String? cnp,
    String? telefon,
    String? email,
    String? descriere,
  }) async {
    try {
      if (nume.trim().isEmpty) {
        return PatientServiceResult.error('Numele este obligatoriu');
      }
      
      final patientRef = FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId);
      
      final patientDoc = await patientRef.get();
      
      if (!patientDoc.exists) {
        return PatientServiceResult.error('Eroare: Pacientul nu a fost găsit');
      }
      
      final patientData = patientDoc.data() as Map<String, dynamic>;
      final currentProgramari = patientData['programari'] as List<dynamic>? ?? [];
      
      await patientRef.update({
        'nume': _capitalizeName(nume),
        'cnp': cnp?.trim().isEmpty ?? true ? null : cnp!.trim(),
        'telefon': telefon?.trim().isEmpty ?? true ? null : telefon!.trim(),
        'email': email?.trim().isEmpty ?? true ? null : email!.trim(),
        'descriere': descriere?.trim().isEmpty ?? true ? null : descriere!.trim(),
        'programari': currentProgramari,
      });
      
      return PatientServiceResult.success(null);
    } catch (e) {
      return PatientServiceResult.error('Eroare la salvare: $e');
    }
  }

  static Future<PatientServiceResult<void>> deletePatient({
    required String patientId,
  }) async {
    try {
      final patientRef = FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId);
      
      await patientRef.delete();
      
      return PatientServiceResult.success(null);
    } catch (e) {
      return PatientServiceResult.error('Eroare la ștergerea pacientului: $e');
    }
  }

  static Future<PatientServiceResult<void>> deleteProgramare({
    required String patientId,
    required Programare programare,
  }) async {
    try {
      final patientRef = FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId);
      
      final patientDoc = await patientRef.get();
      
      if (!patientDoc.exists) {
        return PatientServiceResult.error('Eroare: Pacientul nu a fost găsit');
      }
      
      final patientData = patientDoc.data() as Map<String, dynamic>;
      final currentProgramari = patientData['programari'] as List<dynamic>? ?? [];
      
      currentProgramari.removeWhere((item) {
        if (item is Map<String, dynamic>) {
          final itemTimestamp = item['programare_timestamp'] as Timestamp?;
          final itemText = item['programare_text'] as String?;
          final itemDurata = item['durata'] as int?;
          return itemTimestamp != null &&
              itemTimestamp == programare.programareTimestamp &&
              itemText == programare.programareText &&
              itemDurata == programare.durata;
        }
        return false;
      });
      
      await patientRef.update({
        'programari': currentProgramari,
      });
      
      return PatientServiceResult.success(null);
    } catch (e) {
      return PatientServiceResult.error('Eroare la ștergere: $e');
    }
  }

  static Future<PatientServiceResult<void>> updateProgramare({
    required String patientId,
    required Programare oldProgramare,
    required String procedura,
    required Timestamp timestamp,
    required bool notificare,
    int? durata,
  }) async {
    try {
      print('[PatientService] updateProgramare called');
      print('[PatientService] patientId: $patientId');
      print('[PatientService] oldProgramare.programareText: ${oldProgramare.programareText}');
      print('[PatientService] oldProgramare.programareTimestamp: ${oldProgramare.programareTimestamp}');
      print('[PatientService] oldProgramare.durata: ${oldProgramare.durata} (type: ${oldProgramare.durata.runtimeType})');
      print('[PatientService] durata parameter: $durata (type: ${durata.runtimeType})');
      
      final patientRef = FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId);
      
      final patientDoc = await patientRef.get();
      
      if (!patientDoc.exists) {
        print('[PatientService] Patient document does not exist');
        return PatientServiceResult.error('Eroare: Pacientul nu a fost găsit');
      }
      
      final patientData = patientDoc.data() as Map<String, dynamic>;
      final currentProgramari = patientData['programari'] as List<dynamic>? ?? [];
      print('[PatientService] Found ${currentProgramari.length} existing programari');
      
      bool found = false;
      // Normalize old programare durata for comparison (null = 60)
      final oldDurataNormalized = oldProgramare.durata ?? 60;
      print('[PatientService] oldDurataNormalized: $oldDurataNormalized');
      
      for (int i = 0; i < currentProgramari.length; i++) {
        final item = currentProgramari[i];
        if (item is Map<String, dynamic>) {
          final itemTimestamp = item['programare_timestamp'] as Timestamp?;
          final itemText = item['programare_text'] as String?;
          final itemDurataRaw = item['durata'];
          print('[PatientService] Checking item $i: text=$itemText, timestamp=$itemTimestamp, durataRaw=$itemDurataRaw (type: ${itemDurataRaw.runtimeType})');
          final itemDurata = (itemDurataRaw as int?) ?? 60; // Normalize null to 60 for comparison
          print('[PatientService] itemDurata normalized: $itemDurata');
          
          final timestampMatch = itemTimestamp == oldProgramare.programareTimestamp;
          final textMatch = itemText == oldProgramare.programareText;
          final durataMatch = itemDurata == oldDurataNormalized;
          print('[PatientService] Matches: timestamp=$timestampMatch, text=$textMatch, durata=$durataMatch');
          
          if (itemTimestamp != null &&
              timestampMatch &&
              textMatch &&
              durataMatch) {
            print('[PatientService] Found matching programare at index $i');
            final newDurataValue = durata ?? 60;
            print('[PatientService] Updating with durata: $newDurataValue');
            currentProgramari[i] = {
              'programare_text': procedura,
              'programare_timestamp': timestamp,
              'programare_notification': notificare,
              'durata': newDurataValue, // Always store durata, default to 60 minutes
            };
            found = true;
            break;
          }
        }
      }
      
      if (!found) {
        print('[PatientService] ERROR: Programare not found in database');
        print('[PatientService] Searched for: text=${oldProgramare.programareText}, timestamp=${oldProgramare.programareTimestamp}, durata=$oldDurataNormalized');
        return PatientServiceResult.error('Eroare: Programarea nu a fost găsită');
      }
      
      print('[PatientService] Updating Firestore document...');
      await patientRef.update({
        'programari': currentProgramari,
      });
      print('[PatientService] Update successful');
      
      return PatientServiceResult.success(null);
    } catch (e, stackTrace) {
      print('[PatientService] EXCEPTION in updateProgramare: $e');
      print('[PatientService] Stack trace: $stackTrace');
      return PatientServiceResult.error('Eroare la actualizare: $e');
    }
  }

  static Future<PatientServiceResult<void>> addProgramare({
    required String patientId,
    required String procedura,
    required Timestamp timestamp,
    required bool notificare,
    int? durata,
  }) async {
    try {
      final patientRef = FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId);
      
      final patientDoc = await patientRef.get();
      
      if (!patientDoc.exists) {
        return PatientServiceResult.error('Eroare: Pacientul nu a fost găsit');
      }
      
      final patientData = patientDoc.data() as Map<String, dynamic>;
      final currentProgramari = patientData['programari'] as List<dynamic>? ?? [];
      
      final newProgramare = {
        'programare_text': procedura,
        'programare_timestamp': timestamp,
        'programare_notification': notificare,
        'durata': durata ?? 60, // Always store durata, default to 60 minutes
      };
      
      currentProgramari.add(newProgramare);
      
      await patientRef.update({
        'programari': currentProgramari,
      });
      
      return PatientServiceResult.success(null);
    } catch (e) {
      return PatientServiceResult.error('Eroare la salvare: $e');
    }
  }

  static Future<PatientServiceResult<String>> addPatient({
    required String nume,
    String? cnp,
    String? telefon,
    String? email,
    String? descriere,
  }) async {
    try {
      if (nume.trim().isEmpty) {
        return PatientServiceResult.error('Numele este obligatoriu');
      }
      
      final patientRef = FirebaseFirestore.instance
          .collection('patients')
          .doc();
      
      await patientRef.set({
        'nume': _capitalizeName(nume),
        'cnp': cnp?.trim().isEmpty ?? true ? null : cnp!.trim(),
        'telefon': telefon?.trim().isEmpty ?? true ? null : telefon!.trim(),
        'email': email?.trim().isEmpty ?? true ? null : email!.trim(),
        'descriere': descriere?.trim().isEmpty ?? true ? null : descriere!.trim(),
        'programari': <dynamic>[],
      });
      
      return PatientServiceResult.success(patientRef.id);
    } catch (e) {
      return PatientServiceResult.error('Eroare la adăugarea pacientului: $e');
    }
  }

  /// Find a patient by CNP or phone number
  static Future<PatientServiceResult<String?>> findPatientByCnpOrPhone({
    String? cnp,
    String? telefon,
  }) async {
    try {
      if ((cnp == null || cnp.trim().isEmpty) && 
          (telefon == null || telefon.trim().isEmpty)) {
        return PatientServiceResult.success(null);
      }

      final patientsRef = FirebaseFirestore.instance.collection('patients');
      
      // Try to find by CNP first
      if (cnp != null && cnp.trim().isNotEmpty) {
        final cnpQuery = await patientsRef
            .where('cnp', isEqualTo: cnp.trim())
            .limit(1)
            .get();
        
        if (cnpQuery.docs.isNotEmpty) {
          return PatientServiceResult.success(cnpQuery.docs.first.id);
        }
      }
      
      // Try to find by phone
      if (telefon != null && telefon.trim().isNotEmpty) {
        final telefonQuery = await patientsRef
            .where('telefon', isEqualTo: telefon.trim())
            .limit(1)
            .get();
        
        if (telefonQuery.docs.isNotEmpty) {
          return PatientServiceResult.success(telefonQuery.docs.first.id);
        }
      }
      
      return PatientServiceResult.success(null);
    } catch (e) {
      return PatientServiceResult.error('Eroare la căutare: $e');
    }
  }

  /// Check if a new appointment overlaps with any existing appointments from all patients
  static Future<bool> checkOverlapWithAllAppointments({
    required DateTime newDateTime,
    int? newDurata,
    String? excludePatientId,
    Programare? excludeProgramare,
  }) async {
    try {
      print('[PatientService] checkOverlapWithAllAppointments called');
      print('[PatientService] newDateTime: $newDateTime');
      print('[PatientService] newDurata: $newDurata');
      print('[PatientService] excludePatientId: $excludePatientId');
      print('[PatientService] excludeProgramare: $excludeProgramare');
      
      final newStartMinutes = newDateTime.hour * 60 + newDateTime.minute;
      final newEndMinutes = newStartMinutes + (newDurata ?? 60);
      final newDate = DateTime(newDateTime.year, newDateTime.month, newDateTime.day);
      
      print('[PatientService] New appointment: $newStartMinutes - $newEndMinutes minutes on ${newDate.year}-${newDate.month}-${newDate.day}');

      // Fetch all patients
      print('[PatientService] Fetching all patients from Firestore...');
      final patientsSnapshot = await FirebaseFirestore.instance
          .collection('patients')
          .get();
      
      print('[PatientService] Found ${patientsSnapshot.docs.length} patients');

      int totalAppointmentsChecked = 0;
      // Check all appointments from all patients
      for (var patientDoc in patientsSnapshot.docs) {
        final patientData = patientDoc.data();
        final programari = PatientParser.parseProgramari(patientData);
        final patientId = patientDoc.id;
        
        print('[PatientService] Checking patient $patientId with ${programari.length} appointments');

        for (var programare in programari) {
          totalAppointmentsChecked++;
          
          // Skip the appointment being edited (if provided)
          if (excludePatientId != null && excludeProgramare != null &&
              patientId == excludePatientId &&
              programare.programareTimestamp == excludeProgramare.programareTimestamp &&
              programare.programareText == excludeProgramare.programareText) {
            print('[PatientService] Skipping excluded appointment: ${programare.programareText}');
            continue;
          }

          final programareDate = programare.programareTimestamp.toDate();
          final programareDay = DateTime(
            programareDate.year,
            programareDate.month,
            programareDate.day,
          );

          // Check if same day
          if (programareDay.year == newDate.year &&
              programareDay.month == newDate.month &&
              programareDay.day == newDate.day) {
            final itemStartMinutes = programareDate.hour * 60 + programareDate.minute;
            final itemEndMinutes = itemStartMinutes + (programare.durata ?? 60);
            
            print('[PatientService] Checking appointment: ${programare.programareText} on same day');
            print('[PatientService] Existing: $itemStartMinutes - $itemEndMinutes minutes');
            print('[PatientService] New: $newStartMinutes - $newEndMinutes minutes');

            // Check for overlap
            if (newStartMinutes < itemEndMinutes && itemStartMinutes < newEndMinutes) {
              print('[PatientService] OVERLAP DETECTED!');
              print('[PatientService] Overlapping with: ${programare.programareText} from patient $patientId');
              return true;
            }
          }
        }
      }
      
      print('[PatientService] No overlap found. Checked $totalAppointmentsChecked appointments total.');
      return false;
    } catch (e) {
      // On error, return false to allow the save (fail open)
      print('[PatientService] ERROR in checkOverlapWithAllAppointments: $e');
      return false;
    }
  }
}

