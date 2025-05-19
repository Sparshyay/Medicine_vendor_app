class DoctorMedicineEntry {
  final String medicineId;
  final DateTime dateGiven;

  DoctorMedicineEntry({
    required this.medicineId,
    required this.dateGiven,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'dateGiven': dateGiven.toIso8601String(),
    };
  }

  factory DoctorMedicineEntry.fromMap(Map<String, dynamic> map) {
    return DoctorMedicineEntry(
      medicineId: map['medicineId'] as String,
      dateGiven: DateTime.parse(map['dateGiven'] as String),
    );
  }
}
