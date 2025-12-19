import 'package:cloud_firestore/cloud_firestore.dart';

enum PatientSearchType {
  name,
  cnp,
  phone,
}

class PatientFilters {
  /// Detects whether the query looks like a name, CNP, or phone.
  /// Rules:
  /// - If it starts with "0" or "+", it's a phone number.
  /// - If it's numeric but does NOT start with "0" or "+", it's a CNP.
  /// - Otherwise, it's treated as a name.
  static PatientSearchType detectSearchType(String rawQuery) {
    final query = rawQuery.trim();
    if (query.isEmpty) return PatientSearchType.name;

    // Quick check if the query is only digits/space/+/- (numeric-like)
    final numericLike = RegExp(r'^[0-9+\s-]+$').hasMatch(query);

    if (numericLike) {
      final startsWithPlus = query.startsWith('+');
      final startsWithZero = query.startsWith('0');

      if (startsWithPlus || startsWithZero) {
        return PatientSearchType.phone;
      } else {
        // Numeric-like but not starting with 0 or + => treat as CNP
        return PatientSearchType.cnp;
      }
    }

    return PatientSearchType.name;
  }

  static List<QueryDocumentSnapshot> filterPatients(
    List<QueryDocumentSnapshot> patients,
    String searchQuery,
  ) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return patients;
    }

    final searchType = detectSearchType(query);
    final digitsOnly = query.replaceAll(RegExp(r'[^0-9]'), '');

    return patients.where((doc) {
      final patient = doc.data() as Map<String, dynamic>;

      switch (searchType) {
        case PatientSearchType.name:
          final nume = (patient['nume'] ?? '').toString().toLowerCase();
          return nume.contains(query);

        case PatientSearchType.cnp:
          final rawCnp = (patient['cnp'] ?? '').toString();
          final cnpDigits =
              rawCnp.replaceAll(RegExp(r'[^0-9]'), '');
          return cnpDigits.contains(digitsOnly);

        case PatientSearchType.phone:
          final rawTelefon = (patient['telefon'] ?? patient['nr. telefon'] ?? '')
              .toString();
          final phoneDigits =
              rawTelefon.replaceAll(RegExp(r'[^0-9]'), '');
          return phoneDigits.contains(digitsOnly);
      }
    }).toList();
  }
}


