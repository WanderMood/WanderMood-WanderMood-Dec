import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final List<File> _selectedImages = [];
  final List<String> _selectedTags = [];
  String _location = '';
  String _activity = '';
  bool _isLoading = false;
  
  // Predefined tag options
  final List<String> _tagOptions = [
    'travel', 'nature', 'adventure', 'food', 'culture', 
    'city', 'beach', 'mountains', 'hiking', 'roadtrip',
    'photography', 'sightseeing', 'local', 'history', 'architecture'
  ];
  
  // Predefined activity options
  final List<String> _activityOptions = [
    'Hiking', 'Sightseeing', 'Food Tasting', 'Shopping', 'Museum Visit',
    'Beach Day', 'Cultural Experience', 'City Tour', 'Photography', 'Relaxing',
    'Road Trip', 'Camping', 'Historical Tour', 'Local Festival', 'Nature Walk'
  ];
  
  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            _selectedImages.add(File(image.path));
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }
  
  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImages.add(File(photo.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }
  
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }
  
  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        if (_selectedTags.length < 5) { // Limit to 5 tags
          _selectedTags.add(tag);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can select up to 5 tags')),
          );
        }
      }
    });
  }
  
  void _showLocationPicker() {
    // This would typically integrate with Maps API
    // For now, just show a simple dialog with some options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Location',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              'Eindhoven', 'Amsterdam', 'Rotterdam', 'Utrecht', 'The Hague',
              'Maastricht', 'Delft', 'Groningen', 'Leiden', 'Haarlem'
            ].map((city) => ListTile(
              title: Text(city),
              onTap: () {
                setState(() {
                  _location = city;
                });
                Navigator.pop(context);
              },
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showActivityPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Activity',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _activityOptions.map((activity) => ListTile(
              title: Text(activity),
              onTap: () {
                setState(() {
                  _activity = activity;
                });
                Navigator.pop(context);
              },
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF12B347)),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Color(0xFF12B347)),
              title: Text(
                'Take a Photo',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _createPost() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulate creating post
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      Navigator.pop(context, true); // Return true for success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
    }
  }
  
  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Create Post',
            style: GoogleFonts.museoModerno(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF12B347),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF12B347)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _createPost,
              child: Text(
                'Post',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _isLoading ? Colors.grey : const Color(0xFF12B347),
                ),
              ),
            ),
          ],
        ),
        body: _isLoading 
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Preview Area
                    if (_selectedImages.isEmpty)
                      GestureDetector(
                        onTap: _showImageOptions,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF12B347).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 50,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Add Photos',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length + 1, // +1 for add button
                              itemBuilder: (context, index) {
                                if (index == _selectedImages.length) {
                                  return GestureDetector(
                                    onTap: _showImageOptions,
                                    child: Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF12B347).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_circle_outline,
                                            size: 36,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Add More',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                
                                return Stack(
                                  children: [
                                    Container(
                                      width: 150,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _selectedImages[index],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Caption input
                    Text(
                      'Caption',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _captionController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Write a caption...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Location
                    InkWell(
                      onTap: _showLocationPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF12B347),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _location.isEmpty ? 'Add Location' : _location,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: _location.isEmpty ? FontWeight.w400 : FontWeight.w500,
                                  color: _location.isEmpty ? Colors.grey[600] : Colors.black87,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Activity
                    InkWell(
                      onTap: _showActivityPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_activity_outlined,
                              color: Color(0xFF12B347),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _activity.isEmpty ? 'Add Activity' : _activity,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: _activity.isEmpty ? FontWeight.w400 : FontWeight.w500,
                                  color: _activity.isEmpty ? Colors.grey[600] : Colors.black87,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Tags section
                    Text(
                      'Tags',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tagOptions.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return GestureDetector(
                          onTap: () => _toggleTag(tag),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF12B347) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF12B347) 
                                    : Colors.grey.shade300,
                                width: 1,
                              ),
                              boxShadow: isSelected 
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF12B347).withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ] 
                                  : null,
                            ),
                            child: Text(
                              '#$tag',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.grey[600],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
      ),
    );
  }
} 