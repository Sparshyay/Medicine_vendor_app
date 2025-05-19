class DoctorBrochureEntry {
  final String brochureId;
  final DateTime dateGiven;

  DoctorBrochureEntry({
    required this.brochureId,
    required this.dateGiven,
  });

  Map<String, dynamic> toMap() {
    return {
      'brochureId': brochureId,
      'dateGiven': dateGiven.toIso8601String(),
    };
  }

  factory DoctorBrochureEntry.fromMap(Map<String, dynamic> map) {
    return DoctorBrochureEntry(
      brochureId: map['brochureId'] as String,
      dateGiven: DateTime.parse(map['dateGiven'] as String),
    );
  }
}
