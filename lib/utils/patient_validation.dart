class PatientValidation {
  /// Validates a CNP (Romanian personal numeric code)
  /// Returns null if valid or optional and empty, error message otherwise
  static String? validateCNP(String? value) {
    if (value == null || value.isEmpty) {
      return null; // CNP is optional
    }
    
    // Must be exactly 13 digits
    if (!RegExp(r'^\d{13}$').hasMatch(value)) {
      return 'CNP-ul trebuie să conțină exact 13 cifre';
    }
    
    final digits = value.split('').map((d) => int.parse(d)).toList();
    
    // First digit (S) must be 1-9
    if (digits[0] < 1 || digits[0] > 9) {
      return 'CNP invalid';
    }
    
    // Extract date components
    final year = digits[1] * 10 + digits[2];
    final month = digits[3] * 10 + digits[4];
    final day = digits[5] * 10 + digits[6];
    
    // For codes 7, 8, 9 (foreigners), skip date validation
    final isForeigner = digits[0] >= 7 && digits[0] <= 9;
    
    if (!isForeigner) {
      // Determine century from first digit
      int century;
      if (digits[0] == 1 || digits[0] == 2) {
        century = 1900;
      } else if (digits[0] == 3 || digits[0] == 4) {
        century = 1800;
      } else if (digits[0] == 5 || digits[0] == 6) {
        century = 2000;
      } else {
        return 'CNP invalid';
      }
      
      // Validate month
      if (month < 1 || month > 12) {
        return 'CNP invalid';
      }
      
      // Validate day
      if (day < 1 || day > 31) {
        return 'CNP invalid';
      }
      
      // Validate date exists (basic check)
      try {
        final fullYear = century + year;
        final date = DateTime(fullYear, month, day);
        if (date.year != fullYear || date.month != month || date.day != day) {
          return 'CNP invalid';
        }
      } catch (e) {
        return 'CNP invalid';
      }
    }
    
    // Validate county code (digits 8-9)
    final countyCode = digits[7] * 10 + digits[8];
    if (countyCode < 1 || (countyCode > 52 && countyCode != 99)) {
      return 'CNP invalid';
    }
    
    // Validate control digit (digit 13)
    // Weights: 2, 7, 9, 1, 4, 6, 3, 5, 8, 2, 7, 9
    final weights = [2, 7, 9, 1, 4, 6, 3, 5, 8, 2, 7, 9];
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += digits[i] * weights[i];
    }
    
    int remainder = sum % 11;
    int controlDigit = remainder == 10 ? 1 : remainder;
    
    if (controlDigit != digits[12]) {
      return 'CNP invalid';
    }
    
    return null;
  }
  
  /// Validates a Romanian phone number
  /// Returns null if valid or optional and empty, error message otherwise
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    // Romanian phone number formats:
    // - Mobile: 07XXXXXXXX (10 digits starting with 07)
    // - With country code: +407XXXXXXXX (13 characters)
    // - Landline: 021XXXXXXX or 031XXXXXXX (10 digits)
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check for mobile number (07XXXXXXXX - 10 digits)
    if (RegExp(r'^07[0-9]{8}$').hasMatch(cleaned)) {
      return null;
    }
    
    // Check for international format (+407XXXXXXXX - 13 characters)
    if (RegExp(r'^\+407[0-9]{8}$').hasMatch(cleaned)) {
      return null;
    }
    
    // Check for landline (02X or 03X followed by 7 digits - 10 digits total)
    if (RegExp(r'^0[23][0-9]{8}$').hasMatch(cleaned)) {
      return null;
    }
    
    return 'Număr de telefon invalid';
  }
  
  /// Validates an email address
  /// Returns null if valid or optional and empty, error message otherwise
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Adresă de email invalidă';
    }
    return null;
  }
  
  /// Validates a patient name
  /// Returns null if valid, error message otherwise
  /// Name is required and must not be empty after trimming, and cannot be "Pacient nou"
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Numele este obligatoriu';
    }
    if (value.trim() == 'Pacient nou') {
      return 'Numele este obligatoriu';
    }
    return null;
  }
}

