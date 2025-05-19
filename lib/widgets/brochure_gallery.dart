import 'package:flutter/material.dart';
import '../models/brochure.dart';
import '../services/hive_service.dart';
import 'dart:html' as html;
import 'dart:convert';

class BrochureGallery extends StatefulWidget {
  const BrochureGallery({super.key});

  @override
  State<BrochureGallery> createState() => _BrochureGalleryState();
}

class _BrochureGalleryState extends State<BrochureGallery> {
  List<Brochure> _brochures = [];
  bool _isLoading = true;
  final html.InputElement _uploadInput = html.InputElement(type: 'file')
    ..accept = 'image/*'
    ..multiple = false;

  @override
  void initState() {
    super.initState();
    _loadBrochures();
  }

  Future<void> _loadBrochures() async {
    setState(() {
      _isLoading = true;
    });
    final brochures = HiveService.getBrochures();
    setState(() {
      _brochures = brochures;
      _isLoading = false;
    });
  }

  void _uploadBrochure() {
    _uploadInput.click();
    _uploadInput.onChange.listen((event) async {
      final files = _uploadInput.files;
      if (files?.length == 1) {
        final file = files![0];
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        
        reader.onLoad.listen((event) async {
          final bytes = reader.result as List<int>;
          final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          final newBrochure = Brochure(
            id: DateTime.now().toString(),
            title: file.name,
            imageUrl: dataUrl,
            category: 'Brochure',
            content: 'Uploaded brochure',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await HiveService.addBrochure(newBrochure);
          await _loadBrochures();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_brochures.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No brochures available'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Brochures',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _uploadBrochure,
                icon: const Icon(Icons.upload),
                label: const Text('Upload Brochure'),
              ),
            ],
          ),
        ),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final brochure in _brochures)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(brochure.imageUrl ?? ''),
                  ),
                  title: Text(brochure.title),
                  subtitle: Text(brochure.category),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
