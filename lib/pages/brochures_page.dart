import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../models/brochure.dart';
import '../services/hive_service.dart';
import '../widgets/brochure_gallery.dart';

class BrochuresPage extends StatefulWidget {
  const BrochuresPage({super.key});

  @override
  State<BrochuresPage> createState() => _BrochuresPageState();
}

class _BrochuresPageState extends State<BrochuresPage> {
  List<Brochure> _filteredBrochures = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _updateFilteredBrochures();
  }

  void _updateFilteredBrochures() {
    final brochures = HiveService.getBrochures();
    setState(() {
      _filteredBrochures = brochures
          .where((brochure) =>
              brochure.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              brochure.category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Search Images'),
                  content: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by title or category...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _updateFilteredBrochures();
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
        ],
      ),
      body: _filteredBrochures.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No images found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddBrochureDialog(context),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add Images'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: _filteredBrochures.length,
                itemBuilder: (context, index) {
                  final brochure = _filteredBrochures[index];
                  return GestureDetector(
                    onTap: () => _openGalleryView(context, index),
                    child: Hero(
                      tag: 'brochure-${brochure.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              brochure.imageUrl != null && brochure.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      brochure.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_not_supported, size: 40),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image, size: 40),
                                    ),
                              // Edit and Delete buttons overlay
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.white.withOpacity(0.7),
                                      child: IconButton(
                                        iconSize: 16,
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showEditBrochureDialog(context, brochure),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.white.withOpacity(0.7),
                                      child: IconButton(
                                        iconSize: 16,
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _showDeleteBrochureDialog(context, brochure),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBrochureDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showAddBrochureDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String title = '';
    String category = '';
    String content = '';
    String imageUrl = '';
    Uint8List? fileBytes;
    String? fileName;
    bool isFileUploaded = false;

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add New Brochure',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      onSaved: (value) => title = value ?? '',
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
                    ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
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
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  allowMultiple: false,
                                );
                                
                                if (result != null && result.files.isNotEmpty) {
                                  setState(() {
                                    fileBytes = result.files.first.bytes;
                                    fileName = result.files.first.name;
                                    isFileUploaded = true;
                                    // Convert bytes to base64 for storage or display
                                    if (fileBytes != null) {
                                      imageUrl = 'data:image/${fileName!.split('.').last};base64,${base64Encode(fileBytes!)}'; 
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          onSaved: (value) => imageUrl = isFileUploaded ? imageUrl : (value ?? ''),
                        ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
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
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Content',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 5,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      onSaved: (value) => content = value ?? '',
                    ).animate().fadeIn(delay: const Duration(milliseconds: 600)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        formKey.currentState?.save();
                        final now = DateTime.now();
                        final brochure = Brochure(
                          id: now.millisecondsSinceEpoch.toString(),
                          title: title,
                          category: category,
                          content: content,
                          imageUrl: imageUrl,
                          createdAt: now,
                          updatedAt: now,
                        );
                        HiveService.addBrochure(brochure);
                        _updateFilteredBrochures();
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditBrochureDialog(BuildContext context, Brochure brochure) async {
    final formKey = GlobalKey<FormState>();
    String title = brochure.title ?? '';
    String category = brochure.category ?? '';
    String content = brochure.content ?? '';
    String imageUrl = brochure.imageUrl ?? '';
    Uint8List? fileBytes;
    String? fileName;
    bool isFileUploaded = false;

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Brochure',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: title,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      onSaved: (value) => title = value ?? '',
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  allowMultiple: false,
                                );
                                
                                if (result != null && result.files.isNotEmpty) {
                                  setState(() {
                                    fileBytes = result.files.first.bytes;
                                    fileName = result.files.first.name;
                                    isFileUploaded = true;
                                    // Convert bytes to base64 for storage or display
                                    if (fileBytes != null) {
                                      imageUrl = 'data:image/${fileName!.split('.').last};base64,${base64Encode(fileBytes!)}'; 
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          onSaved: (value) => imageUrl = isFileUploaded ? imageUrl : (value ?? ''),
                        ),
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
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (imageUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Current image:', style: TextStyle(fontSize: 12)),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 100,
                                      width: 100,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.error_outline, size: 40),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: content,
                      decoration: InputDecoration(
                        labelText: 'Content',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 5,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      onSaved: (value) => content = value ?? '',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        formKey.currentState?.save();
                        final updatedBrochure = brochure.copyWith(
                          title: title,
                          category: category,
                          content: content,
                          imageUrl: imageUrl,
                          updatedAt: DateTime.now(),
                        );
                        HiveService.updateBrochure(updatedBrochure);
                        _updateFilteredBrochures();
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteBrochureDialog(BuildContext context, Brochure brochure) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Brochure'),
        content: Text('Are you sure you want to delete ${brochure.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await HiveService.deleteBrochure(brochure.id);
              _updateFilteredBrochures();
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

  void _openGalleryView(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenGallery(
          brochures: _filteredBrochures,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class FullScreenGallery extends StatefulWidget {
  final List<Brochure> brochures;
  final int initialIndex;

  const FullScreenGallery({
    super.key,
    required this.brochures,
    required this.initialIndex,
  });

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isInfoVisible = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isInfoVisible ? Icons.info_outline : Icons.info,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isInfoVisible = !_isInfoVisible;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              // Return to the gallery and edit the image
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Photo view gallery with swipe navigation
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              final brochure = widget.brochures[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: brochure.imageUrl != null && brochure.imageUrl!.isNotEmpty
                    ? NetworkImage(brochure.imageUrl!)
                    : const AssetImage('assets/placeholder.png') as ImageProvider,
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(tag: 'brochure-${brochure.id}'),
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(Icons.error_outline, color: Colors.white, size: 50),
                  ),
                ),
              );
            },
            itemCount: widget.brochures.length,
            loadingBuilder: (context, event) => Center(
              child: SizedBox(
                width: 30.0,
                height: 30.0,
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                ),
              ),
            ),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            pageController: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          
          // Navigation arrows
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: _currentIndex > 0
                ? GestureDetector(
                    onTap: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: _currentIndex < widget.brochures.length - 1
                ? GestureDetector(
                    onTap: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          
          // Image info overlay
          if (_isInfoVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.brochures[_currentIndex].title ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (widget.brochures[_currentIndex].category != null && widget.brochures[_currentIndex].category!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          widget.brochures[_currentIndex].category!,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Image ${_currentIndex + 1} of ${widget.brochures.length}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          // Counter indicator
          Positioned(
            top: MediaQuery.of(context).padding.top + 56, // Below app bar
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1}/${widget.brochures.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
