import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/social/domain/models/social_post.dart';
import 'package:wandermood/features/social/domain/providers/social_providers.dart';
import 'package:wandermood/features/social/presentation/screens/user_profile_screen.dart';

class EditSocialProfileScreen extends ConsumerStatefulWidget {
  const EditSocialProfileScreen({super.key});

  @override
  ConsumerState<EditSocialProfileScreen> createState() => _EditSocialProfileScreenState();
}

class _EditSocialProfileScreenState extends ConsumerState<EditSocialProfileScreen> {
  File? _profileImage;
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  bool _isLoading = false;
  List<String> _selectedInterests = [];
  
  // Popular travel interests for selection
  final List<String> _availableInterests = [
    'Hiking', 'Beach', 'Urban', 'Mountain', 'Cultural',
    'Food', 'Photography', 'Adventure', 'Relaxation', 'Backpacking',
    'Luxury', 'Budget', 'Wildlife', 'Sports', 'History',
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Get the current profile data
    final userId = ref.read(currentUserIdProvider);
    final profile = ref.read(profileByIdProvider(userId));
    
    // Initialize controllers with current data
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    _usernameController = TextEditingController(text: profile?.username ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    
    // Initialize selected interests
    if (profile != null) {
      _selectedInterests = List<String>.from(profile.interests);
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }
  
  void _saveProfile() {
    // Validate form
    if (_nameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and username are required'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // In a real app, this would send the updated profile to a backend
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          duration: Duration(seconds: 2),
        ),
      );
      
      Navigator.of(context).pop();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Get current profile image
    final userId = ref.watch(currentUserIdProvider);
    final profile = ref.watch(profileByIdProvider(userId));
    final userAvatar = profile?.avatar ?? '';
    
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Edit Profile',
            style: GoogleFonts.museoModerno(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF12B347),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF12B347)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF12B347),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile image selection
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              image: _profileImage != null
                                  ? DecorationImage(
                                      image: FileImage(_profileImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : DecorationImage(
                                      image: NetworkImage(userAvatar),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF12B347),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Form fields
                    Text(
                      'Full Name',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Your full name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF12B347),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    Text(
                      'Username',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'Your username',
                        prefixText: '@',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF12B347),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    Text(
                      'Bio',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tell us about yourself...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF12B347),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    Text(
                      'Interests',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableInterests.map((interest) {
                        final isSelected = _selectedInterests.contains(interest);
                        return GestureDetector(
                          onTap: () => _toggleInterest(interest),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF12B347) 
                                  : const Color(0xFF12B347).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              interest,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: isSelected ? Colors.white : const Color(0xFF12B347),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF12B347),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
} 