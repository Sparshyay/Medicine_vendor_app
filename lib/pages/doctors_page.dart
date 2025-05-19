import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../models/medicine.dart';
import '../models/brochure.dart';
import '../models/doctor_medicine_entry.dart';
import '../models/doctor_brochure_entry.dart';
import '../services/hive_service.dart';
import '../widgets/doctor_list.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  List<Doctor> _filteredDoctors = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _updateFilteredDoctors();
  }

  void _updateFilteredDoctors() {
    final doctors = HiveService.getDoctors();
    setState(() {
      _filteredDoctors = doctors
          .where((doctor) =>
              doctor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              doctor.specialization.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              doctor.hospital.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    });
  }

  Future<void> _assignMedicine(Doctor doctor, String medicineId) async {
    final now = DateTime.now();
    final entry = DoctorMedicineEntry(
      medicineId: medicineId,
      dateGiven: now,
    );

    // Create a new list to avoid modifying the original list directly
    final updatedMedicines = List<DoctorMedicineEntry>.from(doctor.medicinesGiven);
    updatedMedicines.add(entry);
    
    final updatedDoctor = Doctor(
      id: doctor.id,
      name: doctor.name,
      specialization: doctor.specialization,
      hospital: doctor.hospital,
      contact: doctor.contact,
      medicinesGiven: updatedMedicines,
      brochuresGiven: doctor.brochuresGiven,
    );

    // Update in Hive
    await HiveService.updateDoctor(updatedDoctor);
    
    // Update the UI
    setState(() {
      // Refresh the doctors list to reflect the changes
      _updateFilteredDoctors();
    });
  }
  
  Future<void> _assignBrochure(Doctor doctor, String brochureId) async {
    final now = DateTime.now();
    final entry = DoctorBrochureEntry(
      brochureId: brochureId,
      dateGiven: now,
    );

    // Create a new list to avoid modifying the original list directly
    final updatedBrochures = List<DoctorBrochureEntry>.from(doctor.brochuresGiven);
    updatedBrochures.add(entry);
    
    final updatedDoctor = Doctor(
      id: doctor.id,
      name: doctor.name,
      specialization: doctor.specialization,
      hospital: doctor.hospital,
      contact: doctor.contact,
      medicinesGiven: doctor.medicinesGiven,
      brochuresGiven: updatedBrochures,
    );

    // Update in Hive
    await HiveService.updateDoctor(updatedDoctor);
    
    // Update the UI
    setState(() {
      // Refresh the doctors list to reflect the changes
      _updateFilteredDoctors();
    });
  }
  
  Future<void> _removeBrochure(Doctor doctor, DoctorBrochureEntry entry) async {
    // Create a new filtered list without the brochure to remove
    final updatedBrochures = doctor.brochuresGiven
        .where((e) => e.brochureId != entry.brochureId)
        .toList();
    
    final updatedDoctor = Doctor(
      id: doctor.id,
      name: doctor.name,
      specialization: doctor.specialization,
      hospital: doctor.hospital,
      contact: doctor.contact,
      medicinesGiven: doctor.medicinesGiven,
      brochuresGiven: updatedBrochures,
    );

    // Update in Hive
    await HiveService.updateDoctor(updatedDoctor);
    
    // Update the UI
    setState(() {
      // Refresh the doctors list to reflect the changes
      _updateFilteredDoctors();
    });
  }

  Future<void> _removeMedicine(Doctor doctor, DoctorMedicineEntry entry) async {
    // Create a new filtered list without the medicine to remove
    final updatedMedicines = doctor.medicinesGiven
        .where((e) => e.medicineId != entry.medicineId)
        .toList();
    
    final updatedDoctor = Doctor(
      id: doctor.id,
      name: doctor.name,
      specialization: doctor.specialization,
      hospital: doctor.hospital,
      contact: doctor.contact,
      medicinesGiven: updatedMedicines,
      brochuresGiven: doctor.brochuresGiven,
    );

    // Update in Hive
    await HiveService.updateDoctor(updatedDoctor);
    
    // Update the UI
    setState(() {
      // Refresh the doctors list to reflect the changes
      _updateFilteredDoctors();
    });
  }

  Widget _buildMedicinesTab(BuildContext context, Doctor doctor, StateSetter setDialogState) {
    final allMedicines = HiveService.getMedicines();
    final assignedMedicineIds = doctor.medicinesGiven.map((e) => e.medicineId).toSet();
    final availableMedicines = allMedicines.where((m) => !assignedMedicineIds.contains(m.id)).toList();
    String? selectedMedicineId = availableMedicines.isNotEmpty ? availableMedicines.first.id : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Assigned medicines list
        Expanded(
          child: doctor.medicinesGiven.isEmpty
              ? const Center(
                  child: Text('No medicines assigned yet'),
                )
              : ListView.builder(
                  itemCount: doctor.medicinesGiven.length,
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (context, index) {
                    final entry = doctor.medicinesGiven[index];
                    final medicine = allMedicines.firstWhere(
                      (m) => m.id == entry.medicineId,
                      orElse: () => Medicine(
                        id: entry.medicineId,
                        name: 'Unknown Medicine',
                        category: 'Unknown',
                        description: '',
                        imageUrl: '',
                        content: '',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Medicine image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: medicine.imageUrl.isNotEmpty
                                ? Image.network(
                                    medicine.imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.medical_services, size: 30),
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.medical_services, size: 30),
                                  ),
                            ),
                            const SizedBox(width: 16),
                            // Medicine info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    medicine.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      medicine.category,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Given on: ${_formatDate(entry.dateGiven)}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            // Remove button
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Remove medicine',
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Remove Medicine'),
                                    content: Text('Are you sure you want to remove "${medicine.name}" from this doctor?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ) ?? false;
                                
                                if (confirmed) {
                                  await _removeMedicine(doctor, entry);
                                  Navigator.of(context).pop();
                                  _showDoctorDetails(context, HiveService.getDoctors().firstWhere(
                                    (d) => d.id == doctor.id,
                                    orElse: () => doctor,
                                  ));
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        
        // Add medicine section
        if (availableMedicines.isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedMedicineId,
                    decoration: const InputDecoration(
                      labelText: 'Select Medicine',
                      border: OutlineInputBorder(),
                    ),
                    items: availableMedicines.map((medicine) {
                      return DropdownMenuItem<String>(
                        value: medicine.id,
                        child: Text(medicine.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedMedicineId = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: selectedMedicineId != null
                      ? () async {
                          await _assignMedicine(doctor, selectedMedicineId!);
                          Navigator.of(context).pop();
                          _showDoctorDetails(context, HiveService.getDoctors().firstWhere(
                            (d) => d.id == doctor.id,
                            orElse: () => doctor,
                          ));
                        }
                      : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Assign'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Show full-screen brochure preview
  void _showBrochureFullScreenPreview(BuildContext context, List<Map<String, dynamic>> brochures, int initialIndex) {
    final pageController = PageController(initialPage: initialIndex);
    final currentIndex = ValueNotifier<int>(initialIndex);
    
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // PageView for swiping through brochures
            PageView.builder(
              controller: pageController,
              itemCount: brochures.length,
              onPageChanged: (index) {
                currentIndex.value = index;
              },
              itemBuilder: (context, index) {
                final brochure = brochures[index]['brochure'] as Brochure;
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Center(
                    child: brochure.imageUrl != null && brochure.imageUrl!.isNotEmpty
                      ? Image.network(
                          brochure.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, size: 64),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 64),
                        ),
                  ),
                );
              },
            ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: Material(
                color: Colors.black.withOpacity(0.5),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
            // Navigation arrows
            if (brochures.length > 1) ...[              
              // Left arrow
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: ValueListenableBuilder<int>(
                  valueListenable: currentIndex,
                  builder: (context, index, _) {
                    return AnimatedOpacity(
                      opacity: index > 0 ? 1.0 : 0.3,
                      duration: const Duration(milliseconds: 200),
                      child: Material(
                        color: Colors.black.withOpacity(0.4),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: index > 0 ? () {
                            pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } : null,
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Right arrow
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: ValueListenableBuilder<int>(
                  valueListenable: currentIndex,
                  builder: (context, index, _) {
                    return AnimatedOpacity(
                      opacity: index < brochures.length - 1 ? 1.0 : 0.3,
                      duration: const Duration(milliseconds: 200),
                      child: Material(
                        color: Colors.black.withOpacity(0.4),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: index < brochures.length - 1 ? () {
                            pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } : null,
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Page indicator
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: ValueListenableBuilder<int>(
                    valueListenable: currentIndex,
                    builder: (context, index, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${index + 1} / ${brochures.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBrochuresTab(BuildContext context, Doctor doctor, StateSetter setDialogState) {
    final allBrochures = HiveService.getBrochures();
    final assignedBrochureIds = doctor.brochuresGiven.map((e) => e.brochureId).toSet();
    final availableBrochures = allBrochures.where((b) => !assignedBrochureIds.contains(b.id)).toList();
    
    // Get assigned brochures with their details
    final assignedBrochures = doctor.brochuresGiven.map((entry) {
      return {
        'entry': entry,
        'brochure': allBrochures.firstWhere(
          (b) => b.id == entry.brochureId,
          orElse: () => Brochure(
            id: entry.brochureId,
            title: 'Unknown Brochure',
            category: 'Unknown',
            content: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      };
    }).toList();
    
    // State variables
    var filteredBrochures = availableBrochures;
    String? selectedBrochureId = filteredBrochures.isNotEmpty ? filteredBrochures.first.id : null;
    final searchController = TextEditingController();
    
    void filterBrochures(String query) {
      setDialogState(() {
        filteredBrochures = availableBrochures
            .where((brochure) =>
                brochure.title.toLowerCase().contains(query.toLowerCase()) ||
                brochure.category.toLowerCase().contains(query.toLowerCase()))
            .toList();
        selectedBrochureId = filteredBrochures.isNotEmpty ? filteredBrochures.first.id : null;
      });
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Assigned brochures list
        Expanded(
          child: doctor.brochuresGiven.isEmpty
              ? const Center(
                  child: Text('No brochures assigned yet'),
                )
              : ListView.builder(
                  itemCount: assignedBrochures.length,
                  padding: const EdgeInsets.all(8.0),
                  itemBuilder: (context, index) {
                    final item = assignedBrochures[index];
                    final brochure = item['brochure'] as Brochure;
                    final entry = item['entry'] as DoctorBrochureEntry;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Open full-screen preview
                          _showBrochureFullScreenPreview(context, assignedBrochures, index);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: brochure.imageUrl != null && brochure.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      brochure.imageUrl!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.image, size: 32),
                                      ),
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image, size: 32),
                                    ),
                              ),
                              const SizedBox(width: 16),
                              // Brochure info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      brochure.title,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        brochure.category,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Given on: ${_formatDate(entry.dateGiven)}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // Remove button
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Remove brochure',
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Remove Brochure'),
                                      content: Text('Are you sure you want to remove "${brochure.title}" from this doctor?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  ) ?? false;
                                  
                                  if (confirmed) {
                                    await _removeBrochure(doctor, entry);
                                    Navigator.of(context).pop();
                                    _showDoctorDetails(context, HiveService.getDoctors().firstWhere(
                                      (d) => d.id == doctor.id,
                                      orElse: () => doctor,
                                    ));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        
        // Add brochure section
        if (availableBrochures.isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Brochures',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: filterBrochures,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedBrochureId,
                        decoration: const InputDecoration(
                          labelText: 'Select Brochure',
                          border: OutlineInputBorder(),
                        ),
                        items: filteredBrochures.map((brochure) {
                          return DropdownMenuItem<String>(
                            value: brochure.id,
                            child: Text(brochure.title),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedBrochureId = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: selectedBrochureId != null
                          ? () async {
                              await _assignBrochure(doctor, selectedBrochureId!);
                              Navigator.of(context).pop();
                              _showDoctorDetails(context, HiveService.getDoctors().firstWhere(
                                (d) => d.id == doctor.id,
                                orElse: () => doctor,
                              ));
                            }
                          : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Assign'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showDoctorDetails(BuildContext context, Doctor doctor) {
    // Get the latest doctor data to ensure we have the most up-to-date information
    final updatedDoctor = HiveService.getDoctors().firstWhere(
      (d) => d.id == doctor.id,
      orElse: () => doctor,
    );
    
    showDialog(
      context: context,
      builder: (context) => DefaultTabController(
        length: 2,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: BoxConstraints(
              maxWidth: 800,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Doctor info header with blue background
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Doctor avatar
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            updatedDoctor.name.isNotEmpty ? updatedDoctor.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Doctor details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              updatedDoctor.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              updatedDoctor.specialization,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.local_hospital, color: Colors.white70, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    updatedDoctor.hospital,
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone, color: Colors.white70, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  updatedDoctor.contact,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Action buttons
                      Row(
                        children: [
                          // Edit button
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            tooltip: 'Edit doctor',
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditDoctorDialog(context, updatedDoctor);
                            },
                          ),
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            tooltip: 'Delete doctor',
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteDoctorDialog(context, updatedDoctor);
                            },
                          ),
                          // Close button
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    tabs: const [
                      Tab(text: 'Medicines', icon: Icon(Icons.medication_outlined)),
                      Tab(text: 'Brochures', icon: Icon(Icons.menu_book_outlined)),
                    ],
                    labelColor: const Color(0xFF1A73E8),
                    unselectedLabelColor: Colors.grey.shade500,
                    indicatorColor: const Color(0xFF1A73E8),
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
                
                // Tab content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: TabBarView(
                      children: [
                        // Medicines tab
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: StatefulBuilder(
                            builder: (context, setTabState) => _buildMedicinesTab(context, updatedDoctor, setTabState),
                          ),
                        ),
                        
                        // Brochures tab
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: StatefulBuilder(
                            builder: (context, setTabState) => _buildBrochuresTab(context, updatedDoctor, setTabState),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        title: const Text(
          'Doctors',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            tooltip: 'Search doctors',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Search Doctors'),
                  content: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, specialization, or hospital...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _updateFilteredDoctors();
                      });
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 26),
            tooltip: 'Add new doctor',
            onPressed: () => _showAddDoctorDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: _filteredDoctors.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_information,
                      size: 64,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No doctors found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a new doctor to get started',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDoctorDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Doctor'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            )
          : DoctorList(
              doctors: _filteredDoctors,
              onDoctorSelected: (doctor) => _showDoctorDetails(context, doctor),
            ),
      ),
      floatingActionButton: _filteredDoctors.isNotEmpty ? FloatingActionButton.extended(
        onPressed: () => _showAddDoctorDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Doctor'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 4,
      ) : null,
    );
  }

  void _showAddDoctorDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String specialization = '';
    String hospital = '';
    String contact = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Doctor',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                onSaved: (value) => name = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Specialization',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                onSaved: (value) => specialization = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Hospital',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSaved: (value) => hospital = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Contact',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSaved: (value) => contact = value ?? '',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                final doctor = Doctor(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  specialization: specialization,
                  hospital: hospital,
                  contact: contact,
                );
                await HiveService.addDoctor(doctor);
                _updateFilteredDoctors();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDoctorDialog(BuildContext context, Doctor doctor) {
    final formKey = GlobalKey<FormState>();
    String name = doctor.name;
    String specialization = doctor.specialization;
    String hospital = doctor.hospital;
    String contact = doctor.contact;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Doctor',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                onSaved: (value) => name = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: specialization,
                decoration: InputDecoration(
                  labelText: 'Specialization',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                onSaved: (value) => specialization = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: hospital,
                decoration: InputDecoration(
                  labelText: 'Hospital',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSaved: (value) => hospital = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: contact,
                decoration: InputDecoration(
                  labelText: 'Contact',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSaved: (value) => contact = value ?? '',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                final updatedDoctor = Doctor(
                  id: doctor.id,
                  name: name,
                  specialization: specialization,
                  hospital: hospital,
                  contact: contact,
                  medicinesGiven: doctor.medicinesGiven,
                  brochuresGiven: doctor.brochuresGiven,
                );
                await HiveService.updateDoctor(updatedDoctor);
                _updateFilteredDoctors();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDoctorDialog(BuildContext context, Doctor doctor) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Doctor'),
        content: Text('Are you sure you want to delete ${doctor.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await HiveService.deleteDoctor(doctor.id);
              _updateFilteredDoctors();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
