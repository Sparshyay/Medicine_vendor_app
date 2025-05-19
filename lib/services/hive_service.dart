import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

// Conditionally import dart:io and dart:html
// This avoids compilation errors on web platforms
import 'dart:io' if (dart.library.html) 'web_impl.dart';

import '../models/medicine.dart';
import '../models/doctor.dart';
import '../models/brochure.dart';
import '../models/doctor_medicine_entry.dart';
import '../models/doctor_medicine_entry_adapter.dart';
import '../models/app_settings.dart';
import 'package:file_picker/file_picker.dart';

class HiveService {
  static const String _medicinesBox = 'medicines';
  static const String _doctorsBox = 'doctors';
  static const String _brochuresBox = 'brochures';
  static const String _doctorMedicineEntriesBox = 'doctor_medicine_entries';
  static const String _settingsBox = 'settings';

  static Future<void> init() async {
    // Initialize Hive
    if (kIsWeb) {
      // Web initialization
    } else {
      // Get application documents directory for mobile/desktop
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        Hive.init('${appDocDir.path}/hive_data');
      } catch (e) {
        // Fallback initialization
        Hive.init('hive_data');
      }
    }

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MedicineAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DoctorAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(BrochureAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(DoctorMedicineEntryAdapter());
    }
    // AppSettings is now handled without Hive adapters

    await Hive.openBox<Medicine>(_medicinesBox);
    await Hive.openBox<Doctor>(_doctorsBox);
    await Hive.openBox<Brochure>(_brochuresBox);
    await Hive.openBox<DoctorMedicineEntry>(_doctorMedicineEntriesBox);
    await Hive.openBox(_settingsBox);
  }

  // Medicine operations
  static Future<void> addMedicine(Medicine medicine) async {
    final box = Hive.box<Medicine>(_medicinesBox);
    await box.put(medicine.id, medicine);
  }

  static Future<void> updateMedicine(Medicine medicine) async {
    final box = Hive.box<Medicine>(_medicinesBox);
    await box.put(medicine.id, medicine);
  }

  static Future<void> deleteMedicine(String id) async {
    final box = Hive.box<Medicine>(_medicinesBox);
    await box.delete(id);
  }

  static List<Medicine> getMedicines() {
    final box = Hive.box<Medicine>(_medicinesBox);
    return box.values.toList();
  }

  // Doctor operations
  static Future<void> addDoctor(Doctor doctor) async {
    final box = Hive.box<Doctor>(_doctorsBox);
    await box.put(doctor.id, doctor);
  }

  static Future<void> updateDoctor(Doctor doctor) async {
    final box = Hive.box<Doctor>(_doctorsBox);
    await box.put(doctor.id, doctor);
  }

  static Future<void> deleteDoctor(String id) async {
    final box = Hive.box<Doctor>(_doctorsBox);
    await box.delete(id);
  }

  static List<Doctor> getDoctors() {
    final box = Hive.box<Doctor>(_doctorsBox);
    return box.values.toList();
  }

  // Brochure operations
  static Future<void> addBrochure(Brochure brochure) async {
    final box = Hive.box<Brochure>(_brochuresBox);
    await box.put(brochure.id, brochure);
  }

  static Future<void> updateBrochure(Brochure brochure) async {
    final box = Hive.box<Brochure>(_brochuresBox);
    await box.put(brochure.id, brochure);
  }

  static Future<void> deleteBrochure(String id) async {
    final box = Hive.box<Brochure>(_brochuresBox);
    await box.delete(id);
  }

  static List<Brochure> getBrochures() {
    final box = Hive.box<Brochure>(_brochuresBox);
    return box.values.toList();
  }

  // Doctor Medicine Entry operations
  static Future<void> addDoctorMedicineEntry(DoctorMedicineEntry entry) async {
    final box = Hive.box<DoctorMedicineEntry>(_doctorMedicineEntriesBox);
    await box.put(entry.medicineId, entry);
  }

  static Future<void> updateDoctorMedicineEntry(DoctorMedicineEntry entry) async {
    final box = Hive.box<DoctorMedicineEntry>(_doctorMedicineEntriesBox);
    await box.put(entry.medicineId, entry);
  }

  static Future<void> deleteDoctorMedicineEntry(String medicineId) async {
    final box = Hive.box<DoctorMedicineEntry>(_doctorMedicineEntriesBox);
    await box.delete(medicineId);
  }

  static List<DoctorMedicineEntry> getDoctorMedicineEntries() {
    final box = Hive.box<DoctorMedicineEntry>(_doctorMedicineEntriesBox);
    return box.values.toList();
  }
  
  // App Settings operations
  static Future<void> saveSettings(AppSettings settings) async {
    final box = Hive.box(_settingsBox);
    await box.put('app_settings', settings.toMap());
  }
  
  static AppSettings? getSettings() {
    final box = Hive.box(_settingsBox);
    final map = box.get('app_settings');
    if (map == null) return null;
    return AppSettings.fromMap(Map<String, dynamic>.from(map));
  }
  
  // Backup and Restore operations
  
  /// Exports all data to a JSON file
  static Future<Map<String, dynamic>> exportDataAsJson() async {
    final medicines = getMedicines();
    final doctors = getDoctors();
    final brochures = getBrochures();
    
    final data = {
      'medicines': medicines.map((m) => m.toMap()).toList(),
      'doctors': doctors.map((d) => d.toMap()).toList(),
      'brochures': brochures.map((b) => b.toMap()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
    
    return data;
  }
  
  /// Exports data to a JSON file and shares it
  static Future<void> shareJsonBackup() async {
    final data = await exportDataAsJson();
    final jsonString = jsonEncode(data);
    
    try {
      if (kIsWeb) {
        // Web implementation handled by downloadString function
        downloadString(jsonString, 'mrship_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      } else {
        // Mobile/desktop implementation
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/mrship_backup_${DateTime.now().millisecondsSinceEpoch}.json');
        await file.writeAsString(jsonString);
        await Share.shareXFiles([XFile(file.path)], text: 'MRship App Backup');
      }
    } catch (e) {
      print('Error sharing JSON backup: $e');
    }
  }
  
  /// Exports data to an Excel file and shares it
  static Future<void> shareExcelBackup() async {
    final excel = Excel.createExcel();
    
    // Create Medicines sheet
    final medicinesSheet = excel['Medicines'];
    final medicines = getMedicines();
    
    // Add headers
    medicinesSheet.appendRow(['ID', 'Name', 'Description', 'Category', 'Created At', 'Updated At']);
    
    // Add data rows
    for (final medicine in medicines) {
      medicinesSheet.appendRow([
        medicine.id,
        medicine.name,
        medicine.description,
        medicine.category,
        medicine.createdAt.toIso8601String(),
        medicine.updatedAt.toIso8601String(),
      ]);
    }
    
    // Create Doctors sheet
    final doctorsSheet = excel['Doctors'];
    final doctors = getDoctors();
    
    // Add headers
    doctorsSheet.appendRow(['ID', 'Name', 'Specialization', 'Hospital', 'Contact']);
    
    // Add data rows
    for (final doctor in doctors) {
      doctorsSheet.appendRow([
        doctor.id,
        doctor.name,
        doctor.specialization,
        doctor.hospital,
        doctor.contact,
      ]);
    }
    
    // Create Assigned Medicines sheet
    final assignedSheet = excel['Assigned Medicines'];
    assignedSheet.appendRow(['Doctor ID', 'Doctor Name', 'Medicine ID', 'Medicine Name', 'Date Assigned']);
    
    for (final doctor in doctors) {
      for (final entry in doctor.medicinesGiven) {
        final medicine = medicines.firstWhere(
          (m) => m.id == entry.medicineId,
          orElse: () => Medicine(
            id: 'unknown',
            name: 'Unknown Medicine',
            description: '',
            category: '',
            imageUrl: '',
            content: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        
        assignedSheet.appendRow([
          doctor.id,
          doctor.name,
          entry.medicineId,
          medicine.name,
          entry.dateGiven.toIso8601String(),
        ]);
      }
    }
    
    try {
      final bytes = excel.encode();
      if (bytes != null) {
        if (kIsWeb) {
          // Web implementation handled by downloadBytes function
          downloadBytes(bytes, 'mrship_backup_${DateTime.now().millisecondsSinceEpoch}.xlsx');
        } else {
          // Mobile/desktop implementation
          final directory = await getTemporaryDirectory();
          final file = File('${directory.path}/mrship_backup_${DateTime.now().millisecondsSinceEpoch}.xlsx');
          await file.writeAsBytes(bytes);
          await Share.shareXFiles([XFile(file.path)], text: 'MRship App Backup');
        }
      }
    } catch (e) {
      print('Error sharing Excel backup: $e');
    }
  }
  
  /// Imports data from a JSON string
  static Future<bool> importDataFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Clear existing data
      await Hive.box<Medicine>(_medicinesBox).clear();
      await Hive.box<Doctor>(_doctorsBox).clear();
      await Hive.box<Brochure>(_brochuresBox).clear();
      
      // Import medicines
      final medicinesData = data['medicines'] as List<dynamic>;
      for (final medicineMap in medicinesData) {
        final medicine = Medicine.fromMap(medicineMap as Map<String, dynamic>);
        await addMedicine(medicine);
      }
      
      // Import doctors
      final doctorsData = data['doctors'] as List<dynamic>;
      for (final doctorMap in doctorsData) {
        final doctor = Doctor.fromMap(doctorMap as Map<String, dynamic>);
        await addDoctor(doctor);
      }
      
      // Import brochures
      final brochuresData = data['brochures'] as List<dynamic>;
      for (final brochureMap in brochuresData) {
        final brochure = Brochure.fromMap(brochureMap as Map<String, dynamic>);
        await addBrochure(brochure);
      }
      
      return true;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }
  
  /// Clears all data from the database
  static Future<void> clearAllData() async {
    await Hive.box<Medicine>(_medicinesBox).clear();
    await Hive.box<Doctor>(_doctorsBox).clear();
    await Hive.box<Brochure>(_brochuresBox).clear();
    await Hive.box<DoctorMedicineEntry>(_doctorMedicineEntriesBox).clear();
  }
  
  // Helper function to download a string as a file in web
  static void downloadString(String content, String fileName) {
    if (kIsWeb) {
      try {
        final bytes = Uint8List.fromList(utf8.encode(content));
        downloadBytes(bytes, fileName);
      } catch (e) {
        print('Error downloading string: $e');
      }
    }
  }
  
  // Helper function to download bytes as a file in web
  static void downloadBytes(List<int> bytes, String fileName) {
    if (kIsWeb) {
      try {
        // Use a simple approach for web downloads
        final blob = WebBlob(bytes);
        WebHelper.downloadBlob(blob, fileName);
      } catch (e) {
        print('Error downloading bytes: $e');
      }
    }
  }
}

// Mock classes for web downloads
class WebBlob {
  final List<int> bytes;
  WebBlob(this.bytes);
}

class WebHelper {
  static void downloadBlob(WebBlob blob, String fileName) {
    // This is a placeholder - in a real app, you'd implement web-specific download logic
    print('Downloading $fileName');
  }
}

class MedicineAdapter extends TypeAdapter<Medicine> {
  @override
  final int typeId = 0;

  @override
  Medicine read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.read());
    return Medicine.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, Medicine obj) {
    writer.write(obj.toMap());
  }
}

class DoctorAdapter extends TypeAdapter<Doctor> {
  @override
  final int typeId = 1;

  @override
  Doctor read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.read());
    return Doctor.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, Doctor obj) {
    writer.write(obj.toMap());
  }
}

class BrochureAdapter extends TypeAdapter<Brochure> {
  @override
  final int typeId = 2;

  @override
  Brochure read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.read());
    return Brochure.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, Brochure obj) {
    writer.write(obj.toMap());
  }
}

