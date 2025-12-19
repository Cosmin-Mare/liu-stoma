import 'package:cloud_firestore/cloud_firestore.dart';

class Programare {
  final String programareText;
  final Timestamp programareTimestamp;
  final bool programareNotification;
  final int? durata; // Duration in minutes

  Programare({
    required this.programareText,
    required this.programareTimestamp,
    required this.programareNotification,
    this.durata,
  });

  factory Programare.fromMap(Map<String, dynamic> map) {
    return Programare(
      programareText: map['programare_text'] ?? '',
      programareTimestamp: map['programare_timestamp'] as Timestamp,
      programareNotification: map['programare_notification'] ?? false,
      durata: map['durata'] as int?,
    );
  }
}

