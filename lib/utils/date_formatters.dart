import 'package:cloud_firestore/cloud_firestore.dart';

class DateFormatters {
  static String formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final months = [
      'ianuarie', 'februarie', 'martie', 'aprilie', 'mai', 'iunie',
      'iulie', 'august', 'septembrie', 'octombrie', 'noiembrie', 'decembrie'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final months = [
      'ianuarie', 'februarie', 'martie', 'aprilie', 'mai', 'iunie',
      'iulie', 'august', 'septembrie', 'octombrie', 'noiembrie', 'decembrie'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String formatDateShort(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  static String formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Extracts birthdate from CNP
  /// Returns null if CNP is invalid or cannot be parsed
  static DateTime? extractBirthdateFromCNP(String? cnp) {
    if (cnp == null || cnp.isEmpty) return null;
    
    // Must be exactly 13 digits
    if (!RegExp(r'^\d{13}$').hasMatch(cnp)) return null;
    
    final digits = cnp.split('').map((d) => int.parse(d)).toList();
    
    // First digit (S) must be 1-9
    if (digits[0] < 1 || digits[0] > 9) return null;
    
    // Extract date components
    final year = digits[1] * 10 + digits[2];
    final month = digits[3] * 10 + digits[4];
    final day = digits[5] * 10 + digits[6];
    
    // For codes 7, 8, 9 (foreigners), we can't determine century reliably
    final isForeigner = digits[0] >= 7 && digits[0] <= 9;
    if (isForeigner) return null;
    
    // Determine century from first digit
    int century;
    if (digits[0] == 1 || digits[0] == 2) {
      century = 1900;
    } else if (digits[0] == 3 || digits[0] == 4) {
      century = 1800;
    } else if (digits[0] == 5 || digits[0] == 6) {
      century = 2000;
    } else {
      return null;
    }
    
    // Validate month
    if (month < 1 || month > 12) return null;
    
    // Validate day
    if (day < 1 || day > 31) return null;
    
    // Try to create the date
    try {
      final fullYear = century + year;
      final date = DateTime(fullYear, month, day);
      // Verify the date is valid
      if (date.year != fullYear || date.month != month || date.day != day) {
        return null;
      }
      return date;
    } catch (e) {
      return null;
    }
  }

  /// Calculates age from CNP
  /// Returns null if age cannot be calculated
  static int? calculateAgeFromCNP(String? cnp) {
    final birthDate = extractBirthdateFromCNP(cnp);
    if (birthDate == null) return null;
    
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    // Don't return negative ages or 0
    return age > 0 ? age : null;
  }

  // Keep the old method for backwards compatibility, but it's deprecated
  @Deprecated('Use calculateAgeFromCNP instead')
  static int calculateAge(Timestamp? dataNasterii) {
    if (dataNasterii == null) return 0;
    final birthDate = dataNasterii.toDate();
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}

