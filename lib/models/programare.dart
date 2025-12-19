import 'package:cloud_firestore/cloud_firestore.dart';

class Procedura {
  final String nume;
  final double cost;
  final int multiplicator;

  Procedura({
    required this.nume,
    required this.cost,
    this.multiplicator = 1,
  });

  factory Procedura.fromMap(Map<String, dynamic> map) {
    return Procedura(
      nume: map['nume'] ?? '',
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      multiplicator: map['multiplicator'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nume': nume,
      'cost': cost,
      'multiplicator': multiplicator,
    };
  }

  double get total => cost * multiplicator;

  Procedura copyWith({
    String? nume,
    double? cost,
    int? multiplicator,
  }) {
    return Procedura(
      nume: nume ?? this.nume,
      cost: cost ?? this.cost,
      multiplicator: multiplicator ?? this.multiplicator,
    );
  }
}

class Programare {
  final List<Procedura> proceduri;
  final Timestamp programareTimestamp;
  final bool programareNotification;
  final int? durata; // Duration in minutes
  final double? totalOverride; // Override calculated total
  final double achitat; // Amount already paid

  // Legacy field for backwards compatibility
  final String? programareText;

  Programare({
    required this.proceduri,
    required this.programareTimestamp,
    required this.programareNotification,
    this.durata,
    this.totalOverride,
    this.achitat = 0.0,
    this.programareText,
  });

  factory Programare.fromMap(Map<String, dynamic> map) {
    // Handle legacy data - if programare_text exists but no proceduri
    List<Procedura> proceduri = [];
    
    if (map['proceduri'] != null && map['proceduri'] is List) {
      proceduri = (map['proceduri'] as List)
          .map((p) => Procedura.fromMap(p as Map<String, dynamic>))
          .toList();
    } else if (map['programare_text'] != null && (map['programare_text'] as String).isNotEmpty) {
      // Legacy support: convert old programare_text to a single procedura
      proceduri = [
        Procedura(
          nume: map['programare_text'] as String,
          cost: 0.0,
          multiplicator: 1,
        ),
      ];
    }

    return Programare(
      proceduri: proceduri,
      programareTimestamp: map['programare_timestamp'] as Timestamp,
      programareNotification: map['programare_notification'] ?? false,
      durata: map['durata'] as int?,
      totalOverride: (map['total_override'] as num?)?.toDouble(),
      achitat: (map['achitat'] as num?)?.toDouble() ?? 0.0,
      programareText: map['programare_text'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'proceduri': proceduri.map((p) => p.toMap()).toList(),
      'programare_timestamp': programareTimestamp,
      'programare_notification': programareNotification,
      'durata': durata,
      'total_override': totalOverride,
      'achitat': achitat,
    };
  }

  /// Get the calculated total cost of all procedures
  double get calculatedTotal {
    return proceduri.fold(0.0, (total, p) => total + p.total);
  }

  /// Get the effective total (override if set, otherwise calculated)
  double get totalCost {
    return totalOverride ?? calculatedTotal;
  }

  /// Get the remaining amount to be paid
  double get restDePlata {
    return totalCost - achitat;
  }

  /// Check if fully paid
  bool get isPlatit {
    return achitat >= totalCost && totalCost > 0;
  }

  /// Get display text (concatenated procedure names)
  String get displayText {
    if (proceduri.isEmpty) return '';
    return proceduri.map((p) {
      if (p.multiplicator > 1) {
        return '${p.nume} x${p.multiplicator}';
      }
      return p.nume;
    }).join(', ');
  }

  Programare copyWith({
    List<Procedura>? proceduri,
    Timestamp? programareTimestamp,
    bool? programareNotification,
    int? durata,
    double? totalOverride,
    double? achitat,
  }) {
    return Programare(
      proceduri: proceduri ?? this.proceduri,
      programareTimestamp: programareTimestamp ?? this.programareTimestamp,
      programareNotification: programareNotification ?? this.programareNotification,
      durata: durata ?? this.durata,
      totalOverride: totalOverride ?? this.totalOverride,
      achitat: achitat ?? this.achitat,
    );
  }
}
