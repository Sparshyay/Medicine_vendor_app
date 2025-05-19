import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../models/medicine.dart';
import '../services/hive_service.dart';

class MedicinesPage extends StatefulWidget {
  const MedicinesPage({super.key});

  @override
  State<MedicinesPage> createState() => _MedicinesPageState();
}

class _MedicinesPageState extends State<MedicinesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Medicine> _filteredMedicines = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _updateFilteredMedicines();
  }

  void _updateFilteredMedicines() {
    setState(() {
      _filteredMedicines = HiveService.getMedicines()
          .where((medicine) =>
              medicine.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              medicine.category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    });
  }
  
  // Delete a medicine
  Future<void> _deleteMedicine(Medicine medicine, int index) async {
    // Delete from Hive
    await HiveService.deleteMedicine(medicine.id);
    
    // Update UI
    setState(() {
      _filteredMedicines.removeAt(index);
    });
    
    // Show snackbar with undo option
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${medicine.name} deleted"),
          action: SnackBarAction(
            label: "Undo",
            onPressed: () async {
              // Re-add the medicine to Hive
              await HiveService.addMedicine(medicine);
              // Update UI
              _updateFilteredMedicines();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicines'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _updateFilteredMedicines();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _updateFilteredMedicines();
                });
              },
            ),
          ),
          Expanded(
            child: _filteredMedicines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medical_services,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No medicines found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredMedicines.length,
                    itemBuilder: (context, index) {
                      final medicine = _filteredMedicines[index];
                      return Dismissible(
                        key: Key(medicine.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16.0),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirm Delete"),
                                content: Text("Are you sure you want to delete ${medicine.name}?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              );
                            },
                          ) ?? false;
                        },
                        onDismissed: (direction) {
                          _deleteMedicine(medicine, index);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                medicine.imageUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 48,
                                  height: 48,
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  child: const Icon(Icons.medical_services),
                                ),
                              ),
                            ),
                            title: Text(medicine.name),
                            subtitle: Text(
                              medicine.category,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Confirm Delete"),
                                          content: Text("Are you sure you want to delete ${medicine.name}?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        );
                                      },
                                    ) ?? false;
                                    
                                    if (shouldDelete) {
                                      _deleteMedicine(medicine, index);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    _showEditMedicineDialog(context, medicine);
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              _showMedicineDetails(context, medicine);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton.extended(
              onPressed: () {
                _showAddMedicineDialog(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Medicine'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMedicineDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String category = '';
    String description = '';
    String imageUrl = 'https://via.placeholder.com/150';
    Uint8List? fileBytes;
    String? fileName;
    bool isFileUploaded = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Add New Medicine',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          content: SingleChildScrollView(
            child: Form(
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
                  ).animate().fadeIn(),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => category = value ?? '',
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSaved: (value) => description = value ?? '',
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Image URL',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.upload_file),
                            onPressed: () async {
                              try {
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  allowMultiple: false,
                                );
                                
                                if (result != null && result.files.isNotEmpty) {
                                  final bytes = result.files.first.bytes;
                                  final name = result.files.first.name;
                                  
                                  if (bytes != null) {
                                    setDialogState(() {
                                      fileBytes = bytes;
                                      fileName = name;
                                      isFileUploaded = true;
                                      // Convert bytes to base64 for storage or display
                                      imageUrl = 'data:image/${name.split('.').last};base64,${base64Encode(bytes)}';
                                    });
                                  }
                                }
                              } catch (e) {
                                print('Error picking file: $e');
                              }
                            },
                          ),
                        ),
                        initialValue: isFileUploaded ? '' : imageUrl,
                        onSaved: (value) => imageUrl = isFileUploaded ? imageUrl : (value ?? ''),
                      ).animate().fadeIn(delay: 600.ms),
                      if (isFileUploaded && fileBytes != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('File selected: $fileName', style: const TextStyle(fontSize: 12, color: Colors.green)),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  fileBytes!,
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
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
                  final medicine = Medicine(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    category: category,
                    description: description,
                    imageUrl: imageUrl,
                    content: '',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await HiveService.addMedicine(medicine);
                  _updateFilteredMedicines();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMedicineDialog(BuildContext context, Medicine medicine) {
    final formKey = GlobalKey<FormState>();
    String name = medicine.name;
    String category = medicine.category;
    String description = medicine.description;
    String imageUrl = medicine.imageUrl;
    Uint8List? fileBytes;
    String? fileName;
    bool isFileUploaded = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Edit Medicine',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          content: SingleChildScrollView(
            child: Form(
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
                    initialValue: category,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => category = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: description,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSaved: (value) => description = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isFileUploaded)
                        TextFormField(
                          initialValue: imageUrl,
                          decoration: InputDecoration(
                            labelText: 'Image URL',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.upload_file),
                              onPressed: () async {
                                try {
                                  final result = await FilePicker.platform.pickFiles(
                                    type: FileType.image,
                                    allowMultiple: false,
                                  );
                                  
                                  if (result != null && result.files.isNotEmpty) {
                                    final bytes = result.files.first.bytes;
                                    final name = result.files.first.name;
                                    
                                    if (bytes != null) {
                                      setDialogState(() {
                                        fileBytes = bytes;
                                        fileName = name;
                                        isFileUploaded = true;
                                        // Convert bytes to base64 for storage or display
                                        imageUrl = 'data:image/${name.split('.').last};base64,${base64Encode(bytes)}';
                                      });
                                    }
                                  }
                                } catch (e) {
                                  print('Error picking file: $e');
                                }
                              },
                            ),
                          ),
                          onSaved: (value) => imageUrl = isFileUploaded ? imageUrl : (value ?? ''),
                        ),
                      if (isFileUploaded && fileBytes != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'File selected: $fileName',
                                      style: const TextStyle(fontSize: 12, color: Colors.green),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () {
                                      setDialogState(() {
                                        isFileUploaded = false;
                                        fileBytes = null;
                                        fileName = null;
                                        imageUrl = medicine.imageUrl;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  fileBytes!,
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Image:',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 100,
                                    width: double.infinity,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image, size: 40),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final result = await FilePicker.platform.pickFiles(
                                      type: FileType.image,
                                      allowMultiple: false,
                                    );
                                    
                                    if (result != null && result.files.isNotEmpty) {
                                      final bytes = result.files.first.bytes;
                                      final name = result.files.first.name;
                                      
                                      if (bytes != null) {
                                        setDialogState(() {
                                          fileBytes = bytes;
                                          fileName = name;
                                          isFileUploaded = true;
                                          // Convert bytes to base64 for storage or display
                                          imageUrl = 'data:image/${name.split('.').last};base64,${base64Encode(bytes)}';
                                        });
                                      }
                                    }
                                  } catch (e) {
                                    print('Error picking file: $e');
                                  }
                                },
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Upload New Image'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
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
                  final updatedMedicine = Medicine(
                    id: medicine.id,
                    name: name,
                    category: category,
                    description: description,
                    imageUrl: imageUrl,
                    content: medicine.content,
                    createdAt: medicine.createdAt,
                    updatedAt: DateTime.now(),
                  );
                  await HiveService.updateMedicine(updatedMedicine);
                  _updateFilteredMedicines();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMedicineDetails(BuildContext context, Medicine medicine) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Medicine image header
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.network(
                medicine.imageUrl,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  child: const Icon(Icons.medical_services, size: 64),
                ),
              ),
            ),
            
            // Medicine details
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      medicine.category,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    medicine.description.isNotEmpty
                        ? medicine.description
                        : 'No description available.',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  if (medicine.content.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Content',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      medicine.content,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditMedicineDialog(context, medicine);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
