import 'package:hive/hive.dart';
import '../models/doctor_medicine_entry.dart';

class DoctorMedicineEntryAdapter extends TypeAdapter<DoctorMedicineEntry> {
  @override
  final int typeId = 3;

  @override
  DoctorMedicineEntry read(BinaryReader reader) {
    final medicineId = reader.readString();
    final dateGiven = DateTime.parse(reader.readString());
    return DoctorMedicineEntry(
      medicineId: medicineId,
      dateGiven: dateGiven,
    );
  }

  @override
  void write(BinaryWriter writer, DoctorMedicineEntry obj) {
    writer.writeString(obj.medicineId);
    writer.writeString(obj.dateGiven.toIso8601String());
  }
}
