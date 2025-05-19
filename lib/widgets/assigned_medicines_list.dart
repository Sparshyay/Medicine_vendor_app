import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../models/doctor_medicine_entry.dart';
import '../services/hive_service.dart';

class AssignedMedicinesList extends StatelessWidget {
  final List<DoctorMedicineEntry> assignedMedicines;
  final List<Medicine> allMedicines;
  final Function(DoctorMedicineEntry)? onRemove;

  const AssignedMedicinesList({
    super.key,
    required this.assignedMedicines,
    required this.allMedicines,
    this.onRemove,
  });

  Medicine _findMedicine(String id) {
    return allMedicines.firstWhere(
      (m) => m.id == id,
      orElse: () => Medicine(
        id: '',
        name: 'Unknown Medicine',
        description: '',
        imageUrl: '',
        category: 'Unknown',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (assignedMedicines.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No medicines assigned'),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final entry in assignedMedicines)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(_findMedicine(entry.medicineId).imageUrl ?? ''),
                backgroundColor: Colors.grey[200],
              ),
              title: Text(_findMedicine(entry.medicineId).name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_findMedicine(entry.medicineId).description),
                  Text(
                    'Assigned: ${entry.dateGiven.toLocal().toString().split('.')[0]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              trailing: onRemove != null
                  ? IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => onRemove!(entry),
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}
