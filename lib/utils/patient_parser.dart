import 'package:liu_stoma/models/programare.dart';

class PatientParser {
  static List<Programare> parseProgramari(Map<String, dynamic> patient) {
    final List<Programare> programari = [];
    
    if (patient['programari'] != null && patient['programari'] is List) {
      final programariList = patient['programari'] as List;
      for (var item in programariList) {
        if (item is Map<String, dynamic>) {
          try {
            programari.add(Programare.fromMap(item));
          } catch (e) {
            // Skip invalid entries
          }
        }
      }
    }
    
    return programari;
  }
}

