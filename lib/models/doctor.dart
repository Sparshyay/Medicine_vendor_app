import 'doctor_medicine_entry.dart';
import 'doctor_brochure_entry.dart';

class Doctor {
  final String id;
  final String name;
  final String specialization;
  final String hospital;
  final String contact;
  final List<DoctorMedicineEntry> medicinesGiven;
  final List<DoctorBrochureEntry> brochuresGiven;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.hospital,
    required this.contact,
    this.medicinesGiven = const [],
    this.brochuresGiven = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialization': specialization,
      'hospital': hospital,
      'contact': contact,
      'medicinesGiven': medicinesGiven.map((e) => e.toMap()).toList(),
      'brochuresGiven': brochuresGiven.map((e) => e.toMap()).toList(),
    };
  }

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'] as String,
      name: map['name'] as String,
      specialization: map['specialization'] as String,
      hospital: map['hospital'] as String,
      contact: map['contact'] as String,
      medicinesGiven: (map['medicinesGiven'] as List? ?? [])
          .map((e) {
            // Safely convert dynamic map to Map<String, dynamic>
            final mapData = Map<String, dynamic>.from(e as Map);
            return DoctorMedicineEntry.fromMap(mapData);
          })
          .toList(),
      brochuresGiven: (map['brochuresGiven'] as List? ?? [])
          .map((e) {
            // Safely convert dynamic map to Map<String, dynamic>
            final mapData = Map<String, dynamic>.from(e as Map);
            return DoctorBrochureEntry.fromMap(mapData);
          })
          .toList(),
    );
  }

  Doctor copyWith({
    String? id,
    String? name,
    String? specialization,
    String? hospital,
    String? contact,
    List<DoctorMedicineEntry>? medicinesGiven,
    List<DoctorBrochureEntry>? brochuresGiven,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      hospital: hospital ?? this.hospital,
      contact: contact ?? this.contact,
      medicinesGiven: medicinesGiven ?? this.medicinesGiven,
      brochuresGiven: brochuresGiven ?? this.brochuresGiven,
    );
  }
}
