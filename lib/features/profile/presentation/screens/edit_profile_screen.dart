import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  File? _selectedImage;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize form with existing user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserData();
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  void _initializeUserData() {
    final profileData = ref.read(profileProvider);
    
    profileData.whenData((profile) {
      if (profile != null) {
        setState(() {
          _nameController.text = profile.fullName ?? '';
          _emailController.text = profile.email ?? '';
          _bioController.text = profile.bio ?? '';
        });
      }
    });
  }
  
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Here you would implement the actual API call to update the profile
      // For now, we'll just simulate a delay and show success
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF12B347),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileData = ref.watch(profileProvider);
    
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
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: profileData.when(
          data: (profile) => Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (profile?.imageUrl != null
                                ? NetworkImage(profile!.imageUrl!) as ImageProvider
                                : null),
                        child: (_selectedImage == null && profile?.imageUrl == null)
                            ? Text(
                                profile?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                                style: GoogleFonts.poppins(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF12B347),
                                ),
                              )
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12B347),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          onPressed: _pickImage,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Full Name
                  _buildTextFieldWithLabel(
                    label: 'Full Name',
                    controller: _nameController,
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Email
                  _buildTextFieldWithLabel(
                    label: 'Email',
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Bio
                  _buildTextFieldWithLabel(
                    label: 'Bio',
                    controller: _bioController,
                    icon: Icons.description_outlined,
                    maxLines: 3,
                    maxLength: 150,
                  ),
                  const SizedBox(height: 24),
                  
                  // Interests Section
                  _buildSectionHeader('Travel Interests'),
                  
                  // Interest Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInterestChip('Nature', true),
                      _buildInterestChip('Food', false),
                      _buildInterestChip('History', true),
                      _buildInterestChip('Culture', true),
                      _buildInterestChip('Adventure', false),
                      _buildInterestChip('Relaxation', true),
                      _buildInterestChip('Photography', false),
                      _buildInterestChip('Shopping', false),
                      _buildInterestChip('Nightlife', false),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF12B347),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: const Color(0xFF12B347).withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading profile',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.refresh(profileProvider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12B347),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF12B347),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
  
  Widget _buildTextFieldWithLabel({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          style: GoogleFonts.poppins(
            fontSize: 16,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF12B347)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF12B347)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInterestChip(String label, bool selected) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: selected ? Colors.white : Colors.black87,
        ),
      ),
      selected: selected,
      onSelected: (newValue) {
        // In a real app, you would update the selected state
        setState(() {
          // Update interests
        });
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: const Color(0xFF12B347),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    );
  }
} 