import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';

import '../../../../core/presentation/widgets/swirl_background.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../social/application/providers/diary_provider.dart';
import '../../../social/domain/models/diary_entry.dart';
import '../../../social/domain/models/user_profile.dart';
import '../../../social/domain/providers/profile_settings_providers.dart';
import '../../../social/presentation/screens/edit_profile_info_screen.dart';
import '../../../home/presentation/widgets/moody_character.dart';
import '../../../home/domain/enums/moody_feature.dart';
import 'travelers_discovery_screen.dart';
import 'notifications_screen.dart';
import 'diary_entry_detail_screen.dart';

class BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2A6049), Color(0xFF4ECDC4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class DiariesPlatformScreen extends ConsumerStatefulWidget {
  const DiariesPlatformScreen({super.key});

  @override
  ConsumerState<DiariesPlatformScreen> createState() => _DiariesPlatformScreenState();
}

class _DiariesPlatformScreenState extends ConsumerState<DiariesPlatformScreen> 
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;
  
  // Gesture handling variables
  Offset? _panStartPosition;
  bool _showGestureHint = true;
  int _headerTapCount = 0;
  DateTime? _lastHeaderTap;
  
  // Create tab state
  String? _selectedCreateMood;
  String? _selectedCreateLocation;
  
  final List<DiaryTab> _tabs = [
    DiaryTab(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Discover',
      color: const Color(0xFF2A6049),
    ),
    DiaryTab(
      icon: Icons.dynamic_feed_outlined,
      activeIcon: Icons.dynamic_feed,
      label: 'Activity',
      color: const Color(0xFFFF6B6B),
    ),
    DiaryTab(
      icon: Icons.add_a_photo_outlined,
      activeIcon: Icons.add_a_photo,
      label: 'Create',
      color: const Color(0xFF667eea),
    ),
    DiaryTab(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      color: const Color(0xFF4ECDC4),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    
    // Auto-hide gesture hint after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showGestureHint = false;
        });
      }
    });
    
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildCustomAppBar(),
            
            // Main Content
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildDiscoverTab(),
                  _buildActivityFeedTab(),
                  _buildCreateTab(),
                  _buildProfileTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Mood Check',
          style: GoogleFonts.museoModerno(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2A6049),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF4A5568),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70, // Reduced height
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isActive = index == _currentIndex;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onTabTapped(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, // Reduced padding
                      vertical: 6,   // Reduced padding
                    ),
                    decoration: BoxDecoration(
                      color: isActive 
                          ? tab.color.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16), // Smaller radius
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isActive ? tab.activeIcon : tab.icon,
                            key: ValueKey(isActive),
                            size: 20, // Smaller icon
                            color: isActive ? tab.color : const Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 2), // Reduced spacing
                        Text(
                          tab.label,
                          style: GoogleFonts.poppins(
                            fontSize: 10, // Smaller font
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? tab.color : const Color(0xFF9CA3AF),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Tab Content Builders
  Widget _buildDiscoverTab() {
    return const DiaryHomeFeed();
  }

  Widget _buildActivityFeedTab() {
    return const ActivityFeedTabContent();
  }

  Widget _buildCreateTab() {
    return _buildEnhancedCreateTab();
  }

  Widget _buildEnhancedCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Mood Selector
          _buildQuickMoodSelector(),
          
          const SizedBox(height: 32),
          
          // Recent Locations Carousel
          _buildRecentLocations(),
          
          const SizedBox(height: 40),
          
          // Main Camera Section
          _buildMainCameraSection(),
          
          const SizedBox(height: 32),
          
          // Photo Options
          _buildPhotoOptions(),
        ],
      ),
    );
  }

  Widget _buildQuickMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎭 How are you feeling?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose your mood to frame your story',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF718096),
          ),
        ),
        const SizedBox(height: 16),
        
        // Mood chips in two rows
        Column(
          children: [
            // First row
            Row(
              children: [
                _buildMoodChip('😊', 'Happy', const Color(0xFFFFC107)),
                const SizedBox(width: 8),
                _buildMoodChip('🏞️', 'Adventure', const Color(0xFFFF6B35)),
                const SizedBox(width: 8),
                _buildMoodChip('💕', 'Romantic', const Color(0xFFE91E63)),
                const SizedBox(width: 8),
                _buildMoodChip('🧘', 'Peaceful', const Color(0xFF2A6049)),
              ],
            ),
            const SizedBox(height: 8),
            // Second row
            Row(
              children: [
                _buildMoodChip('🎉', 'Excited', const Color(0xFFFF9800)),
                const SizedBox(width: 8),
                _buildMoodChip('🙏', 'Grateful', const Color(0xFF2196F3)),
                const SizedBox(width: 8),
                _buildMoodChip('😌', 'Relaxed', const Color(0xFF00BCD4)),
                const SizedBox(width: 8),
                _buildMoodChip('🤩', 'Wonder', const Color(0xFF9C27B0)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMoodChip(String emoji, String mood, Color color) {
    final isSelected = _selectedCreateMood == mood;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCreateMood = isSelected ? null : mood;
          });
          HapticFeedback.lightImpact();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 4),
              Text(
                mood,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentLocations() {
    final recentLocations = [
      {'name': 'Rotterdam', 'country': 'Netherlands', 'visits': '5 visits'},
      {'name': 'Amsterdam', 'country': 'Netherlands', 'visits': '3 visits'},
      {'name': 'Utrecht', 'country': 'Netherlands', 'visits': '2 visits'},
      {'name': 'The Hague', 'country': 'Netherlands', 'visits': '1 visit'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📍 Recent Locations',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Quick tag your location',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF718096),
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentLocations.length,
            itemBuilder: (context, index) {
              final location = recentLocations[index];
              final isSelected = _selectedCreateLocation == location['name'];
              
              return Container(
                width: 140,
                margin: EdgeInsets.only(right: 12, left: index == 0 ? 0 : 0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCreateLocation = isSelected ? null : location['name'];
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2A6049) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2A6049) : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          location['name']!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF2D3748),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          location['country']!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isSelected ? Colors.white70 : const Color(0xFF718096),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          location['visits']!,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: isSelected ? Colors.white60 : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainCameraSection() {
    return Center(
      child: Column(
        children: [
          // Large camera circle
          GestureDetector(
            onTap: _createNewPost,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_a_photo,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'Share Your Moment',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Capture and share your travel experiences\nwith the WanderFeed community',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF718096),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoOptions() {
    return Column(
      children: [
        // Take Photo button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.camera,
                maxWidth: 1920,
                maxHeight: 1920,
                imageQuality: 85,
              );
              if (image != null) {
                _showEnhancedCreatePostDialog(image);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A6049),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.camera_alt, size: 24),
            label: Text(
              'Take Photo',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Choose from Gallery button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1920,
                maxHeight: 1920,
                imageQuality: 85,
              );
              if (image != null) {
                _showEnhancedCreatePostDialog(image);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2196F3),
              side: const BorderSide(color: Color(0xFF2196F3), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.photo_library, size: 24),
            label: Text(
              'Choose from Gallery',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEnhancedCreatePostDialog(XFile image) {
    final TextEditingController captionController = TextEditingController();
    final TextEditingController locationController = TextEditingController(
      text: _selectedCreateLocation ?? '',
    );
    String selectedMood = _selectedCreateMood ?? 'Happy';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600])),
                    ),
                    const Spacer(),
                    Text(
                      'Create Post',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _submitEnhancedPost(image, captionController.text, locationController.text, selectedMood),
                      child: Text('Share', style: GoogleFonts.poppins(color: const Color(0xFF2A6049), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo preview
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(image.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Pre-selected mood indicator
                      if (_selectedCreateMood != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getMoodTagColor(_selectedCreateMood!).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getMoodTagColor(_selectedCreateMood!).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _getMoodEmoji(_selectedCreateMood!),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Feeling ${_selectedCreateMood!.toLowerCase()}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _getMoodTagColor(_selectedCreateMood!),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCreateMood = null;
                                  });
                                  setModalState(() {
                                    selectedMood = 'Happy';
                                  });
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: _getMoodTagColor(_selectedCreateMood!),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Caption input
                      TextField(
                        controller: captionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: _selectedCreateMood != null 
                              ? 'Share what made you feel ${_selectedCreateMood!.toLowerCase()}...'
                              : 'Write a caption...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2A6049)),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Location input (pre-filled if selected)
                      TextField(
                        controller: locationController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_on, color: Color(0xFF2A6049)),
                          hintText: 'Add location...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2A6049)),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Mood selection (if not pre-selected)
                      if (_selectedCreateMood == null) ...[
                        Text(
                          'How are you feeling?',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['Happy', 'Excited', 'Peaceful', 'Adventurous', 'Grateful', 'Inspired', 'Relaxed', 'Energetic']
                              .map((mood) => GestureDetector(
                                onTap: () => setModalState(() => selectedMood = mood),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selectedMood == mood ? _getMoodTagColor(mood) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: selectedMood == mood ? _getMoodTagColor(mood) : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _getMoodEmoji(mood),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        mood,
                                        style: GoogleFonts.poppins(
                                          color: selectedMood == mood ? Colors.white : Colors.grey[700],
                                          fontWeight: selectedMood == mood ? FontWeight.w600 : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitEnhancedPost(XFile image, String caption, String location, String mood) async {
    Navigator.pop(context); // Close the modal
    
    // Show loading indicator
    showWanderMoodToast(
      context,
      message: 'Sharing your ${mood.toLowerCase()} moment...',
      leading: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
      backgroundColor: _getMoodTagColor(mood),
      duration: const Duration(seconds: 2),
    );
    
    try {
      // Create new diary entry request from the post
      final request = CreateDiaryEntryRequest(
        title: caption.isNotEmpty ? caption : 'New ${mood} moment',
        story: caption.isNotEmpty ? caption : 'Feeling ${mood.toLowerCase()} at this beautiful place!',
        mood: mood,
        location: location.isNotEmpty ? location : null,
        tags: [mood.toLowerCase(), if (location.isNotEmpty) location.toLowerCase()],
        photos: [image.path], // In real app, this would be uploaded URL
        isPublic: true,
      );
      
      // Add to diary service (this would normally save to database)
      final diaryService = ref.read(diaryServiceProvider);
      await diaryService.createDiaryEntry(request);
      
      // Invalidate providers to refresh feeds
      ref.invalidate(diaryFeedProvider);
      ref.invalidate(userDiaryEntriesProvider('current_user'));
      ref.invalidate(friendsDiaryFeedProvider);
      
      // Reset selections after successful post
      setState(() {
        _selectedCreateMood = null;
        _selectedCreateLocation = null;
      });
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Show success and navigate to see the post
      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Your ${mood.toLowerCase()} moment has been shared! ✨',
          duration: const Duration(seconds: 4),
          actionLabel: 'View',
          onAction: () {
            // Switch to Activity tab to see the new post
            setState(() {
              _currentIndex = 1;
            });
          },
        );
      }
      
    } catch (e) {
      // Handle error
      if (mounted) {
        showWanderMoodToast(
          context,
          message: 'Failed to share post: $e',
          isError: true,
        );
      }
    }
  }

  Widget _buildProfileTab() {
    return const DiaryProfileTab();
  }



  // Helper Methods
  String _getSubtitleForTab(int index) {
    switch (index) {
      case 0:
        return 'Stories from your community';
      case 1:
        return 'See what your travel community is up to';
      case 2:
        return 'Share your moment';
      case 3:
        return '';
      default:
        return '';
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Add haptic feedback
    if (index == 2) { // Profile tab
      // Could trigger a special animation or modal for profile
    }
  }

  void _showNotifications() {
    // TODO: Show notifications panel
    showWanderMoodToast(
      context,
      message: 'Notifications feature coming soon! 🔔',
    );
  }

  void _openNotificationsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  // Mood Helper Methods
  Color _getMoodTagColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return const Color(0xFFFFC107); // Amber
      case 'adventure':
      case 'adventurous':
        return const Color(0xFFFF6B35); // Orange-red
      case 'romantic':
        return const Color(0xFFE91E63); // Pink
      case 'peaceful':
        return const Color(0xFF2A6049); // Green
      case 'excited':
        return const Color(0xFFFF9800); // Orange
      case 'grateful':
        return const Color(0xFF2196F3); // Blue
      case 'relaxed':
        return const Color(0xFF00BCD4); // Cyan
      case 'wonder':
        return const Color(0xFF9C27B0); // Purple
      case 'inspired':
        return const Color(0xFF673AB7); // Deep Purple
      case 'energetic':
        return const Color(0xFFFF5722); // Deep Orange
      default:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }
  
  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'adventure':
      case 'adventurous':
        return '🏞️';
      case 'romantic':
        return '💕';
      case 'peaceful':
        return '🧘';
      case 'excited':
        return '🎉';
      case 'grateful':
        return '🙏';
      case 'relaxed':
        return '😌';
      case 'wonder':
        return '🤩';
      case 'inspired':
        return '💡';
      case 'energetic':
        return '⚡';
      default:
        return '✨';
    }
  }

  Color _getMoodColor(String mood) {
    return _getMoodTagColor(mood);
  }

  void _showSearch() {
    // TODO: Show search interface
    showWanderMoodToast(
      context,
      message: 'Search feature coming soon! 🔍',
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMoreOptionsSheet(),
    );
  }

  // Gesture Handlers
  void _handlePullDownGesture() {
    if (mounted) {
      HapticFeedback.mediumImpact();
      _exitDiaryPlatform('Pull down detected! 👆');
    }
  }

  void _handleEdgeSwipeGesture() {
    if (mounted) {
      HapticFeedback.mediumImpact();
      _exitDiaryPlatform('Edge swipe detected! 👈');
    }
  }

  void _handleHeaderTap() {
    final now = DateTime.now();
    
    // Reset if too much time passed
    if (_lastHeaderTap != null && now.difference(_lastHeaderTap!).inSeconds > 2) {
      _headerTapCount = 0;
    }
    
    _headerTapCount++;
    _lastHeaderTap = now;
    
    // Light haptic feedback on each tap
    HapticFeedback.lightImpact();
    
    if (_headerTapCount >= 2) {
      // Double tap detected!
      HapticFeedback.heavyImpact(); // Stronger feedback for successful double tap
      _exitDiaryPlatform('Double tap detected! ✨');
      _headerTapCount = 0;
    }
  }

  void _exitDiaryPlatform(String message) {
    // Hide gesture hint
    setState(() {
      _showGestureHint = false;
    });
    
    // Show feedback message
    showWanderMoodToast(
      context,
      message: message,
      duration: const Duration(milliseconds: 1000),
    );
    
    // Navigate back with slight delay for feedback
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  // Photo Upload & Post Creation
  void _createNewPost() async {
    try {
      // Show photo source selection
      final ImageSource? source = await _showPhotoSourceDialog();
      if (source == null) return;

      // Pick image with better error handling
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        // User cancelled or no image selected
        return;
      }

      // Show post creation dialog with photo
      _showCreatePostDialog(image);

    } catch (e) {
      // Handle different types of errors
      String errorMessage = 'Failed to access camera or gallery';
      
      if (e.toString().contains('camera_access_denied')) {
        errorMessage = 'Camera access denied. Please enable camera permissions in Settings.';
      } else if (e.toString().contains('photo_access_denied')) {
        errorMessage = 'Photo library access denied. Please enable photo permissions in Settings.';
      } else if (e.toString().contains('camera_not_available')) {
        errorMessage = 'Camera is not available on this device.';
      }
      
      showWanderMoodToast(
        context,
        message: errorMessage,
        isError: true,
        duration: const Duration(seconds: 4),
        actionLabel: 'Settings',
        onAction: () {
          // TODO: Open app settings
        },
      );
    }
  }

  Future<ImageSource?> _showPhotoSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              'Add Photo to Your Feed',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A6049).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF2A6049)),
              ),
              title: Text('Take Photo', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              subtitle: Text('Capture the moment', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: Color(0xFF2196F3)),
              ),
              title: Text('Choose from Gallery', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              subtitle: Text('Select existing photo', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCreatePostDialog(XFile image) {
    final TextEditingController captionController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    String selectedMood = 'Happy';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600])),
                    ),
                    const Spacer(),
                    Text(
                      'Create Post',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _submitPost(image, captionController.text, locationController.text, selectedMood),
                      child: Text('Share', style: GoogleFonts.poppins(color: const Color(0xFF2A6049), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo preview
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(image.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Caption input
                      TextField(
                        controller: captionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Write a caption...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2A6049)),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Location input
                      TextField(
                        controller: locationController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_on, color: Color(0xFF2A6049)),
                          hintText: 'Add location...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2A6049)),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Mood selection
                      Text(
                        'How are you feeling?',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['Happy', 'Excited', 'Peaceful', 'Adventurous', 'Grateful', 'Inspired', 'Relaxed', 'Energetic']
                            .map((mood) => GestureDetector(
                              onTap: () => setModalState(() => selectedMood = mood),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selectedMood == mood ? _getMoodColor(mood) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selectedMood == mood ? _getMoodColor(mood) : Colors.grey[300]!,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getMoodEmoji(mood),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      mood,
                                      style: GoogleFonts.poppins(
                                        color: selectedMood == mood ? Colors.white : Colors.grey[700],
                                        fontWeight: selectedMood == mood ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitPost(XFile image, String caption, String location, String mood) async {
    Navigator.pop(context); // Close the modal
    
    // Show loading indicator
    showWanderMoodToast(
      context,
      message: 'Sharing your moment...',
      leading: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
      duration: const Duration(seconds: 3),
    );

    try {
      // TODO: Implement actual post creation with photo upload
      // For now, just show success message
      await Future.delayed(const Duration(seconds: 2)); // Simulate upload
      
      showWanderMoodToast(
        context,
        message: '✨ Your moment has been shared!',
      );

      // Refresh the feed
      ref.invalidate(diaryFeedProvider);
      ref.invalidate(friendsDiaryFeedProvider);

    } catch (e) {
      showWanderMoodToast(
        context,
        message: 'Failed to share post: $e',
        isError: true,
      );
    }
  }

  Widget _buildGestureHint() {
    return AnimatedOpacity(
      opacity: _showGestureHint ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.touch_app,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Swipe from edge, pull down, or double-tap WanderFeed to go back',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _showGestureHint = false),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreOptionsSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text('Settings', style: GoogleFonts.poppins()),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text('Help & Support', style: GoogleFonts.poppins()),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('About WanderFeed', style: GoogleFonts.poppins()),
            onTap: () => Navigator.pop(context),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }


}

// Data Model
class DiaryTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  DiaryTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}

// Enhanced Tab Widgets
class DiaryHomeFeed extends ConsumerStatefulWidget {
  const DiaryHomeFeed({super.key});

  @override
  ConsumerState<DiaryHomeFeed> createState() => _DiaryHomeFeedState();
}

class _DiaryHomeFeedState extends ConsumerState<DiaryHomeFeed> {
  String _selectedMoodFilter = 'All';
  String _selectedSortFilter = 'Latest';
  bool _showFilters = false;
  final TextEditingController _searchController = TextEditingController();
  
  // Moody dropdown state
  bool _showMoodyBubble = false;
  bool _moodyExpanded = false;
  String _currentMoodyMessage = '';
  List<String> _moodyDetails = [];
  
  // Moody notification system (now handled by floating bubble)
  
  final List<Map<String, dynamic>> _socialNotifications = [
    {
      'type': 'new_post',
      'message': 'alex_travels just shared "Perfect Morning in Rotterdam" 📸',
      'emoji': '👋',
      'mood': 'happy'
    },
    {
      'type': 'like',
      'message': 'Your "Epic Bike Ride to Kinderdijk" got 5 new likes! ❤️',
      'emoji': '💕',
      'mood': 'excited'
    },
    {
      'type': 'comment',
      'message': 'foodie_sara commented on your latest post 💬',
      'emoji': '💬',
      'mood': 'happy'
    },
    {
      'type': 'follower',
      'message': '2 new wanderers started following you! 🎉',
      'emoji': '👥',
      'mood': 'excited'
    },
    {
      'type': 'trending',
      'message': 'Your "Hidden Gem Alert! 🍜" is trending in Utrecht!',
      'emoji': '🔥',
      'mood': 'excited'
    },
    {
      'type': 'friend_activity',
      'message': 'Your friend circle shared 8 new travel moments today',
      'emoji': '✨',
      'mood': 'happy'
    },
    {
      'type': 'milestone',
      'message': 'Congrats! You reached 50 likes on your travel stories 🏆',
      'emoji': '🎊',
      'mood': 'excited'
    },
    {
      'type': 'location',
      'message': '3 travelers near you posted from Rotterdam today 📍',
      'emoji': '🌍',
      'mood': 'happy'
    },
  ];
  
  final List<String> _moodFilters = [
    'All', '🌅 Adventurous', '😌 Chill', '💕 Romantic', '🎉 Social', 
    '🧘 Solo', '🏛️ Cultural', '🏖️ Beach', '🏔️ Nature'
  ];
  
  final List<String> _sortFilters = [
    'Latest', 'Friends Only', 'Trending', 'Mood Match', 'Nearby'
  ];

  @override
  void initState() {
    super.initState();
    _generateMoodyGreeting();
    // Start with bubble hidden
    _showMoodyBubble = false;
  }
  




  void _generateMoodyGreeting() {
    final hour = DateTime.now().hour;
    String timeGreeting;
    
    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }
    
    final currentUserProfile = ref.read(currentUserProfileProvider);
    currentUserProfile.when(
      data: (profile) {
        final userName = profile?.username ?? profile?.fullName ?? 'Wanderer';
        
        _currentMoodyMessage = '$timeGreeting $userName! 🎉 Check out what\'s happening in your community';
        _moodyDetails = [
          '👋 alex_travels shared "Perfect Morning in Rotterdam" 2h ago',
          '💬 foodie_sara commented on your "Epic Bike Ride to Kinderdijk"',
          '❤️ Your latest post got 5 new likes from local travelers',
          '👥 2 new wanderers (marco_explorer, luna_beachlover) followed you',
          '🔥 Your "Hidden Gem Alert! 🍜" is trending in Utrecht (12 likes)',
          '📍 3 friends posted from Rotterdam today',
        ];
      },
      loading: () {
        _currentMoodyMessage = '$timeGreeting! 🎉 See what your travel community is up to';
        _moodyDetails = [
          '👋 alex_travels shared "Perfect Morning in Rotterdam"',
          '💬 New comments on community posts',
          '❤️ Your posts are getting lots of love',
          '👥 New travelers joined your circle',
          '🔥 Trending posts from your area',
          '📍 Fresh stories from fellow wanderers',
        ];
      },
      error: (_, __) {
        _currentMoodyMessage = '$timeGreeting! 🎉 See what your travel community is up to';
        _moodyDetails = [
          '👋 alex_travels shared "Perfect Morning in Rotterdam"',
          '💬 New comments on community posts',
          '❤️ Your posts are getting lots of love',
          '👥 New travelers joined your circle',
          '🔥 Trending posts from your area',
          '📍 Fresh stories from fellow wanderers',
        ];
      },
    );
  }





  void _onFilterChanged(String newFilter) {
    setState(() {
      _selectedMoodFilter = newFilter;
    });
    
    // React to filter changes
    if (newFilter != 'All') {
      final emoji = newFilter.split(' ').first;
      _reactToUserAction('Loving the ${newFilter.substring(2)} vibes? $emoji Here\'s what\'s trending.');
    }
  }

  void _onSortChanged(String newSort) {
    setState(() {
      _selectedSortFilter = newSort;
    });
    
    // React to sort changes
    switch (newSort) {
      case 'Trending':
        _reactToUserAction('🔥 Showing you the hottest posts right now!');
        break;
      case 'Mood Match':
        _reactToUserAction('🎯 Finding posts that match your vibe perfectly!');
        break;
      case 'Nearby':
        _reactToUserAction('📍 Discovering amazing places near you!');
        break;
    }
  }

  void _reactToUserAction(String message) {
    // This method can be removed or simplified since we're not using floating bubbles
    // Just update the message for when user opens the dropdown
    _currentMoodyMessage = message;
    _moodyDetails = [
      '✨ Curating perfect matches for you',
      '🎨 Based on your travel style',
      '💫 Fresh discoveries incoming',
    ];
  }

  void _onViewActivityTapped() {
    setState(() {
      _showMoodyBubble = false;
    });
    
    // Show activity feed modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildActivityFeedModal(),
    );
  }

  void _onFriendsTapped() {
    setState(() {
      _showMoodyBubble = false;
      _selectedSortFilter = 'Friends Only';
    });
    
    // Show friends filter applied message
    showWanderMoodToast(
      context,
      message: 'Now showing posts from friends only',
      leading: const Icon(Icons.people, color: Colors.white, size: 20),
      backgroundColor: const Color(0xFF667eea),
      duration: const Duration(seconds: 4),
      actionLabel: 'Show All',
      onAction: () {
        setState(() {
          _selectedSortFilter = 'Latest';
        });
      },
    );
    
    // Invalidate providers to refresh feed with friends filter
    ref.invalidate(friendsDiaryFeedProvider);
  }

  void _onActivityAction(String action, String context) {
    Navigator.pop(this.context); // Close the modal first
    
    switch (action) {
      case 'view_post':
        // Navigate to specific post
        showWanderMoodToast(
          this.context,
          message: 'Opening $context\'s post...',
          leading: const Icon(Icons.article, color: Colors.white, size: 20),
          backgroundColor: const Color(0xFF667eea),
        );
        break;
        
      case 'reply':
        // Open reply interface
        _showReplyDialog(context);
        break;
        
      case 'view_likes':
        // Show likes modal
        _showLikesModal();
        break;
        
      case 'view_profiles':
        // Show followers modal
        _showFollowersModal();
        break;
        
      case 'view_stats':
        // Show post statistics
        _showStatsModal();
        break;
        
      case 'explore':
        // Filter to location-based posts
        setState(() {
          _selectedSortFilter = 'Nearby';
        });
        showWanderMoodToast(
          this.context,
          message: 'Showing posts from Rotterdam area',
          leading: const Icon(Icons.explore, color: Colors.white, size: 20),
        );
        break;
    }
  }

  void _showReplyDialog(String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reply to $username',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Write your reply...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showWanderMoodToast(
                this.context,
                message: 'Reply sent to $username!',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
            ),
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showLikesModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '❤️ 5 People Liked Your Post',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...['marco_explorer', 'luna_beachlover', 'alex_travels', 'foodie_sara', 'wanderer123']
                .map((name) => ListTile(
                      leading: CircleAvatar(
                        child: Text(name[0].toUpperCase()),
                      ),
                      title: Text(name),
                      subtitle: Text('Liked your post'),
                      trailing: TextButton(
                        onPressed: () {},
                        child: Text('Follow'),
                      ),
                    )),
          ],
        ),
      ),
    );
  }

  void _showFollowersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: Color(0xFF667eea),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Followers',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          '2 travelers started following you',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Followers List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildFollowerCard(
                    userId: 'marco_explorer',
                    name: 'Marco Rodriguez',
                    username: 'marco_explorer',
                    bio: 'Adventure seeker from Barcelona 🏔️',
                    avatar: 'M',
                    avatarColor: const Color(0xFF667eea),
                    followers: 1247,
                    posts: 89,
                  ),
                  const SizedBox(height: 16),
                  _buildFollowerCard(
                    userId: 'luna_beachlover',
                    name: 'Luna Martinez',
                    username: 'luna_beachlover',
                    bio: 'Beach enthusiast from Maldives 🏖️',
                    avatar: 'L',
                    avatarColor: const Color(0xFF4ECDC4),
                    followers: 892,
                    posts: 156,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatsModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🔥 Post Statistics',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('👀', '124', 'Views'),
                _buildStatItem('❤️', '12', 'Likes'),
                _buildStatItem('💬', '8', 'Comments'),
                _buildStatItem('📤', '3', 'Shares'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your post is trending in Utrecht! 🎉',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF2A6049),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String count, String label) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowerCard({
    required String userId,
    required String name,
    required String username,
    required String bio,
    required String avatar,
    required Color avatarColor,
    required int followers,
    required int posts,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: () => _onProfileTap(userId, name),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: avatarColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      avatar,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _onProfileTap(userId, name),
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                    ),
                    Text(
                      '@$username',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF667eea),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bio,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF718096),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Stats Row
          Row(
            children: [
              _buildUserStat(posts.toString(), 'Posts'),
              const SizedBox(width: 20),
              _buildUserStat(followers.toString(), 'Followers'),
              const Spacer(),
              
              // Action Buttons
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => _onProfileTap(userId, name),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF667eea)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      'View Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF667eea),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _onFollowBack(userId, name),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      'Follow Back',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStat(String count, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  void _onProfileTap(String userId, String name) {
    Navigator.pop(context); // Close the modal
    
    // Navigate to user profile
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildUserProfileModal(userId, name),
    );
  }

  void _onFollowBack(String userId, String name) {
    // Simulate follow back action
    showWanderMoodToast(
      context,
      message: 'You are now following $name!',
      leading: const Icon(Icons.person_add, color: Colors.white, size: 20),
      duration: const Duration(seconds: 4),
      actionLabel: 'View Profile',
      onAction: () => _onProfileTap(userId, name),
    );
    
    // Could also update following status in database here
    // ref.read(userServiceProvider).followUser(userId);
  }

  Widget _buildUserProfileModal(String userId, String name) {
    // Mock user data - in real app, this would come from a provider
    final userData = _getUserData(userId);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Profile Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar and basic info
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: userData['avatarColor'],
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: userData['avatarColor'].withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          userData['avatar'],
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                          Text(
                            '@${userData['username']}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFF667eea),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userData['bio'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF718096),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildProfileStat(userData['posts'].toString(), 'Posts'),
                    _buildProfileStat(userData['followers'].toString(), 'Followers'),
                    _buildProfileStat(userData['following'].toString(), 'Following'),
                    _buildProfileStat(userData['countries'].toString(), 'Countries'),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _onFollowBack(userId, name),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Follow',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showMessageDialog(userData['name']);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF667eea)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Message',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF667eea),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Recent Posts Section
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Adventures',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: ListView(
                      children: userData['recentPosts'].map<Widget>((post) {
                        return _buildProfilePostCard(post);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePostCard(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.image,
              color: Colors.grey[400],
              size: 24,
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  post['location'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.favorite, size: 14, color: Colors.red[400]),
                    const SizedBox(width: 4),
                    Text(
                      post['likes'].toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF718096),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.comment, size: 14, color: Colors.blue[400]),
                    const SizedBox(width: 4),
                    Text(
                      post['comments'].toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getUserData(String userId) {
    // Mock user data - in real app, this would come from a provider/API
    final users = {
      'marco_explorer': {
        'name': 'Marco Rodriguez',
        'username': 'marco_explorer',
        'bio': 'Adventure seeker from Barcelona 🏔️\nLove hiking, climbing, and discovering hidden gems!',
        'avatar': 'M',
        'avatarColor': const Color(0xFF667eea),
        'posts': 89,
        'followers': 1247,
        'following': 456,
        'countries': 23,
        'recentPosts': [
          {
            'title': 'Sunrise at Montjuïc Castle',
            'location': 'Barcelona, Spain',
            'likes': 45,
            'comments': 12,
          },
          {
            'title': 'Hidden Beach in Costa Brava',
            'location': 'Girona, Spain',
            'likes': 67,
            'comments': 8,
          },
          {
            'title': 'Mountain Trail Discovery',
            'location': 'Pyrenees, Spain',
            'likes': 34,
            'comments': 15,
          },
        ],
      },
      'luna_beachlover': {
        'name': 'Luna Martinez',
        'username': 'luna_beachlover',
        'bio': 'Beach enthusiast from Maldives 🏖️\nOcean lover, sunset chaser, and island hopper!',
        'avatar': 'L',
        'avatarColor': const Color(0xFF4ECDC4),
        'posts': 156,
        'followers': 892,
        'following': 234,
        'countries': 18,
        'recentPosts': [
          {
            'title': 'Perfect Sunset at Malé',
            'location': 'Maldives',
            'likes': 89,
            'comments': 23,
          },
          {
            'title': 'Underwater Paradise',
            'location': 'Ari Atoll, Maldives',
            'likes': 156,
            'comments': 31,
          },
          {
            'title': 'Island Life Vibes',
            'location': 'Baa Atoll, Maldives',
            'likes': 78,
            'comments': 19,
          },
        ],
      },
    };
    
    return users[userId] ?? users['marco_explorer']!;
  }

  void _showMessageDialog(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Message $name',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Write your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showWanderMoodToast(
                this.context,
                message: 'Message sent to $name!',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
            ),
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getWanderSpots() {
    // Mock data - in real app, this would come from a provider based on location and mood
    return [
      {
        'id': 'taproom_rotterdam',
        'name': 'Taproom Rotterdam',
        'type': 'Bar',
        'vibe': ['Local Gem', 'Chill'],
        'description': 'Craft beer haven with industrial vibes',
        'rating': 4.8,
        'priceLevel': 2,
        'distance': '0.3 km',
        'isSponsored': true,
        'image': 'https://images.unsplash.com/photo-1572116469696-31de0f17cc34?w=400',
        'address': 'Witte de Withstraat 33',
        'openNow': true,
        'tags': ['Craft Beer', 'Industrial', 'Local'],
        'mood': 'Chill',
        'friendsVisited': 8,
        'totalVisits': 127,
      },
      {
        'id': 'boho_cafe',
        'name': 'Boho Café',
        'type': 'Café',
        'vibe': ['Warm Vibes', 'Romantic'],
        'description': 'Cozy corner café with artisanal coffee',
        'rating': 4.6,
        'priceLevel': 2,
        'distance': '0.7 km',
        'isSponsored': false,
        'image': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400',
        'address': 'Oude Binnenweg 56',
        'openNow': true,
        'tags': ['Coffee', 'Cozy', 'WiFi'],
        'mood': 'Romantic',
        'friendsVisited': 12,
        'totalVisits': 89,
      },
      {
        'id': 'urban_kitchen',
        'name': 'Urban Kitchen',
        'type': 'Restaurant',
        'vibe': ['Trendy', 'Cultural'],
        'description': 'Modern fusion cuisine in trendy setting',
        'rating': 4.7,
        'priceLevel': 3,
        'distance': '1.2 km',
        'isSponsored': true,
        'image': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
        'address': 'Katendrecht 42',
        'openNow': false,
        'tags': ['Fusion', 'Modern', 'Date Night'],
        'mood': 'Trendy',
        'friendsVisited': 5,
        'totalVisits': 203,
      },
    ];
  }

  Widget _buildWanderSpotCard(Map<String, dynamic> spot, int index) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: 16, left: index == 0 ? 0 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with sponsored badge
          Stack(
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: spot['image'] != null
                      ? Image.network(
                          spot['image'],
                          width: double.infinity,
                                                     height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: double.infinity,
                            color: _getSpotGradient(spot['mood'])[0].withOpacity(0.3),
                            child: Center(
                              child: Icon(
                                _getSpotIcon(spot['type']),
                                size: 40,
                                color: _getSpotGradient(spot['mood'])[1],
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          color: _getSpotGradient(spot['mood'])[0].withOpacity(0.3),
                          child: Center(
                            child: Icon(
                              _getSpotIcon(spot['type']),
                              size: 40,
                              color: _getSpotGradient(spot['mood'])[1],
                            ),
                          ),
                        ),
                ),
              ),
              
              // Sponsored badge
              if (spot['isSponsored'])
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Sponsored',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2A6049),
                      ),
                    ),
                  ),
                ),
                
              // Open/Closed status
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: spot['openNow'] 
                        ? Colors.green.withOpacity(0.9)
                        : Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    spot['openNow'] ? 'Open' : 'Closed',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          spot['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            spot['rating'].toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 3),
                  
                  // Vibe tags
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _buildVibeTag(spot['type'], const Color(0xFF667eea)),
                      _buildVibeTag(spot['vibe'][0], const Color(0xFF2A6049)),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Description
                  Text(
                    spot['description'],
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF718096),
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Social proof
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 12,
                        color: const Color(0xFF2A6049),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${spot['friendsVisited']} friends visited',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF2A6049),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${spot['totalVisits']} total visits',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Distance and action
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: const Color(0xFF718096),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        spot['distance'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF718096),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _onWanderSpotTap(spot),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _getSpotGradient(spot['mood']),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Check Out',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibeTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  List<Color> _getSpotGradient(String mood) {
    switch (mood.toLowerCase()) {
      case 'chill':
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      case 'romantic':
        return [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)];
      case 'trendy':
        return [const Color(0xFF2A6049), const Color(0xFF4ECDC4)];
      case 'cultural':
        return [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)];
      default:
        return [const Color(0xFF2A6049), const Color(0xFF4ECDC4)];
    }
  }

  IconData _getSpotIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bar':
        return Icons.local_bar;
      case 'café':
      case 'cafe':
        return Icons.local_cafe;
      case 'restaurant':
        return Icons.restaurant;
      case 'shop':
        return Icons.shopping_bag;
      default:
        return Icons.place;
    }
  }

  void _onWanderSpotTap(Map<String, dynamic> spot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildWanderSpotDetail(spot),
    );
  }

  Widget _buildWanderSpotDetail(Map<String, dynamic> spot) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header with image
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: _getSpotGradient(spot['mood'])[0].withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Stack(
              children: [
                // Background pattern
                Center(
                  child: Icon(
                    _getSpotIcon(spot['type']),
                    size: 80,
                    color: _getSpotGradient(spot['mood'])[1].withOpacity(0.3),
                  ),
                ),
                
                // Close button
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ),
                
                // Sponsored badge
                if (spot['isSponsored'])
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: const Color(0xFF2A6049),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Featured',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2A6049),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          spot['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              spot['rating'].toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Address and status
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: const Color(0xFF718096),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          spot['address'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF718096),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: spot['openNow'] ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          spot['openNow'] ? 'Open Now' : 'Closed',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: spot['openNow'] ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Vibe tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDetailVibeTag(spot['type'], const Color(0xFF667eea)),
                      ...spot['vibe'].map<Widget>((vibe) => 
                        _buildDetailVibeTag(vibe, const Color(0xFF2A6049))),
                      ...spot['tags'].map<Widget>((tag) => 
                        _buildDetailVibeTag(tag, const Color(0xFF718096))),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    'About this place',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    spot['description'] + '\n\nPerfect for travelers looking for ${spot['mood'].toLowerCase()} vibes. Located just ${spot['distance']} away from your current location.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF718096),
                      height: 1.5,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            showWanderMoodToast(
                              context,
                              message: 'Directions to ${spot['name']}',
                              backgroundColor: const Color(0xFF667eea),
                            );
                          },
                          icon: const Icon(Icons.directions),
                          label: Text('Directions'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF667eea),
                            side: const BorderSide(color: Color(0xFF667eea)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            showWanderMoodToast(
                              context,
                              message: 'Saved ${spot['name']} to your list!',
                            );
                          },
                          icon: const Icon(Icons.bookmark_add),
                          label: Text('Save Spot'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A6049),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailVibeTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showBusinessSignupInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Join WanderSpots',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get your business featured to travelers based on their mood and location.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              '• Monthly featured placement\n• Mood-based targeting\n• Analytics dashboard\n• Starting from €49/month',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF718096),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showWanderMoodToast(
                context,
                message: 'Business signup coming soon!',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A6049),
            ),
            child: Text('Learn More'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWelcomeWithMoody() {
    return Column(
      children: [
        // Main row with welcome text and Moody
        Row(
          children: [
            // Welcome Text (Left side) - hide when notifications are open
            if (!_showMoodyBubble)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back! 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap Moody to see what\'s been happening while you were enjoying life ✨',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF718096),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Spacer(),
            
            const SizedBox(width: 12),
            
            // Interactive Moody Character (Right side)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showMoodyBubble = !_showMoodyBubble;
                  _moodyExpanded = false; // Reset expansion state
                });
              },
              child: MoodyCharacter(
                size: 50,
                mood: 'happy',
                currentFeature: MoodyFeature.none,
              ),
            ),
          ],
        ),
        
        // Social notifications dropdown (appears below when Moody is tapped)
        if (_showMoodyBubble) ...[
          const SizedBox(height: 12),
          _buildSocialNotificationsDropdown(),
        ],
      ],
    );
  }

  Widget _buildSocialNotificationsDropdown() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '🎭',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currentMoodyMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _moodyExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _moodyExpanded = !_moodyExpanded;
                  });
                },
              ),
            ],
          ),
          
          // Expanded details
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _moodyExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      ..._moodyDetails.map((detail) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Text(
                              '• ',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                detail,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMoodyActionButton(
                              'View Activity',
                              Icons.notifications_outlined,
                              () => _onViewActivityTapped(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMoodyActionButton(
                              'Friends',
                              Icons.people_outline,
                              () => _onFriendsTapped(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeedModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF667eea),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity Feed',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        'Latest updates from your travel community',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Activity List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildActivityItem(
                  icon: '👋',
                  title: 'alex_travels shared a new post',
                  subtitle: '"Perfect Morning in Rotterdam"',
                  time: '2 hours ago',
                  actionText: 'View Post',
                  onTap: () => _onActivityAction('view_post', 'alex_travels'),
                ),
                _buildActivityItem(
                  icon: '💬',
                  title: 'foodie_sara commented on your post',
                  subtitle: '"Epic Bike Ride to Kinderdijk"',
                  time: '4 hours ago',
                  actionText: 'Reply',
                  onTap: () => _onActivityAction('reply', 'foodie_sara'),
                ),
                _buildActivityItem(
                  icon: '❤️',
                  title: 'Your post got 5 new likes',
                  subtitle: 'From local travelers in Rotterdam',
                  time: '6 hours ago',
                  actionText: 'View Likes',
                  onTap: () => _onActivityAction('view_likes', 'likes'),
                ),
                _buildActivityItem(
                  icon: '👥',
                  title: '2 new followers',
                  subtitle: 'marco_explorer and luna_beachlover started following you',
                  time: '8 hours ago',
                  actionText: 'View Profiles',
                  onTap: () => _onActivityAction('view_profiles', 'followers'),
                ),
                _buildActivityItem(
                  icon: '🔥',
                  title: 'Your post is trending!',
                  subtitle: '"Hidden Gem Alert! 🍜" is popular in Utrecht',
                  time: '12 hours ago',
                  actionText: 'View Stats',
                  onTap: () => _onActivityAction('view_stats', 'trending'),
                ),
                _buildActivityItem(
                  icon: '📍',
                  title: 'Friends posted from your area',
                  subtitle: '3 new posts from Rotterdam today',
                  time: '1 day ago',
                  actionText: 'Explore',
                  onTap: () => _onActivityAction('explore', 'location'),
                ),
                
                // Load more button
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Load more activities
                    },
                    child: Text(
                      'Load More Activities',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF667eea),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String icon,
    required String title,
    required String subtitle,
    required String time,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          
          // Action button
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: const Color(0xFF667eea).withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              actionText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF667eea),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsFeedAsync = ref.watch(friendsDiaryFeedProvider);
    final publicFeedAsync = ref.watch(diaryFeedProvider);
    final currentUserProfile = ref.watch(currentUserProfileProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(friendsDiaryFeedProvider);
        ref.invalidate(diaryFeedProvider);
        // Show Moody reaction to refresh
        _reactToUserAction('🔄 Fetching the latest adventures for you!');
      },
      child: CustomScrollView(
        slivers: [
          // Enhanced Header with Search & Personalization
          _buildEnhancedHeader(currentUserProfile),
          
          // Mood Filter Pills
          _buildMoodFilterPills(),
          
          // Featured Stories Carousel
          _buildFeaturedCarousel(publicFeedAsync),
          
          // WanderSpots - Local Business Recommendations
          _buildWanderSpots(),
          
          // People You Might Like Section
          _buildPeopleSuggestions(),
          
          // Main Feed with Smart Sorting
          _buildMainFeed(friendsFeedAsync, publicFeedAsync),
        ],
      ),
    );
  }



  Widget _buildMoodyActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader(AsyncValue<UserProfile?> profileAsync) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line 1: Title Section
            profileAsync.when(
              data: (profile) => _buildPersonalizedWelcome(profile),
              loading: () => _buildDefaultWelcome(),
              error: (_, __) => _buildDefaultWelcome(),
            ),
            
            const SizedBox(height: 12),
            
            // Line 2: Welcome Text + Interactive Moody Character
            _buildWelcomeWithMoody(),
            
            const SizedBox(height: 12),
            
            // Line 3: Search Bar
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedWelcome(UserProfile? profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WanderFeed',
          style: GoogleFonts.museoModerno(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2A6049),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WanderFeed',
          style: GoogleFonts.museoModerno(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2A6049),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
  


  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search places, moods, or travelers...',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF9CA3AF),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _showFilters ? Icons.tune : Icons.tune_outlined,
              color: _showFilters ? const Color(0xFF2A6049) : const Color(0xFF9CA3AF),
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: GoogleFonts.poppins(fontSize: 14),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildQuickActionChip(
          icon: Icons.explore,
          label: 'Explore',
          color: const Color(0xFF2A6049),
          onTap: () {},
        ),
        const SizedBox(width: 8),
        _buildQuickActionChip(
          icon: Icons.trending_up,
          label: 'Trending',
          color: const Color(0xFFFF6B6B),
          onTap: () {
            setState(() {
              _selectedSortFilter = 'Trending';
            });
          },
        ),
        const SizedBox(width: 8),
        _buildQuickActionChip(
          icon: Icons.psychology,
          label: 'Mood Match',
          color: const Color(0xFF667eea),
          onTap: () {
            setState(() {
              _selectedSortFilter = 'Mood Match';
            });
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePostButton() {
    return GestureDetector(
      onTap: () => context.push('/create-diary-entry'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A6049), Color(0xFF4ECDC4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A6049).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_a_photo, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              'Share',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodFilterPills() {
    if (!_showFilters) return const SliverToBoxAdapter(child: SizedBox.shrink());
    
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _moodFilters.length,
          itemBuilder: (context, index) {
            final mood = _moodFilters[index];
            final isSelected = mood == _selectedMoodFilter;
            
            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                                 onTap: () {
                   _onFilterChanged(mood);
                 },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF2A6049) 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF2A6049) 
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: const Color(0xFF2A6049).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Text(
                    mood,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF4A5568),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedCarousel(AsyncValue<List<DiaryEntry>> publicFeedAsync) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Text(
                  '✨ Featured Stories',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
                Text(
                  'Popular journeys',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF718096),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 400, // Even taller for more vertical length
            child: publicFeedAsync.when(
              data: (entries) {
                final featuredEntries = _getCuratedFeaturedStories(entries);
                return PageView.builder(
                  controller: PageController(viewportFraction: 0.45), // Much narrower horizontally
                  padEnds: false,
                  itemCount: featuredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = featuredEntries[index];
                    return _buildFeaturedCard(entry, index);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2A6049),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(DiaryEntry entry, int index) {
    return Container(
      width: 180, // Fixed narrower width
      margin: EdgeInsets.only(
        left: index == 0 ? 20 : 8,
        right: 8,
        top: 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Image
            Container(
              width: 180,
              height: 384, // Much taller for more vertical length
              child: entry.photos.isNotEmpty
                  ? Image.network(
                      entry.photos.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => _buildFallbackImage(entry),
                    )
                  : _buildFallbackImage(entry),
            ),
            
            // Gradient overlay for better text readability
            Container(
              width: 180,
              height: 384,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            
            // Content Overlay (Bottom Left)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mood Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getMoodTagColor(entry.mood),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getMoodEmoji(entry.mood),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.mood,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Title
                  Text(
                    entry.title ?? _generateFeaturedTitle(entry),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Location
                  if (entry.location?.isNotEmpty == true)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            entry.location!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            // Tap to view
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openFullDiaryPost(entry),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for Featured Stories
  List<DiaryEntry> _getCuratedFeaturedStories(List<DiaryEntry> entries) {
    // Simulate curated content based on different criteria
    final now = DateTime.now();
    final thisWeek = now.subtract(const Duration(days: 7));
    
    // Filter recent entries with good engagement potential
    final recentEntries = entries.where((entry) => 
      entry.createdAt.isAfter(thisWeek) && 
      entry.photos.isNotEmpty &&
      entry.location?.isNotEmpty == true
    ).toList();
    
    // Sort by engagement potential (photos, location, mood variety)
    recentEntries.sort((a, b) {
      int scoreA = _calculateEngagementScore(a);
      int scoreB = _calculateEngagementScore(b);
      return scoreB.compareTo(scoreA);
    });
    
    // Take top 6 for variety
    return recentEntries.take(6).toList();
  }
  
  int _calculateEngagementScore(DiaryEntry entry) {
    int score = 0;
    score += entry.photos.length * 2; // Photos are important
    score += entry.location?.isNotEmpty == true ? 3 : 0; // Location adds value
    score += entry.title?.isNotEmpty == true ? 2 : 0; // Good titles
    score += _isInterestingMood(entry.mood) ? 2 : 0; // Interesting moods
    return score;
  }
  
  bool _isInterestingMood(String mood) {
    final interestingMoods = ['adventurous', 'romantic', 'wonder', 'peaceful', 'excited', 'grateful'];
    return interestingMoods.contains(mood.toLowerCase());
  }
  
  String _generateFeaturedTitle(DiaryEntry entry) {
    // Generate engaging titles based on mood and location
    final mood = entry.mood.toLowerCase();
    final location = entry.location ?? 'somewhere amazing';
    
    switch (mood) {
      case 'adventurous':
        return 'Finding adventure in $location';
      case 'romantic':
        return 'Romantic escape in $location';
      case 'wonder':
        return 'Discovering magic in $location';
      case 'peaceful':
        return 'Finding peace in $location';
      case 'excited':
        return 'Incredible moments in $location';
      case 'grateful':
        return 'Grateful moments from $location';
      default:
        return 'Beautiful journey in $location';
    }
  }
  
  Widget _buildFallbackImage(DiaryEntry entry) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getMoodTagColor(entry.mood).withOpacity(0.7),
            _getMoodTagColor(entry.mood),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getMoodEmoji(entry.mood),
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              entry.mood,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _openFullDiaryPost(DiaryEntry entry) {
    // Navigate to full diary post view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEntryDetailScreen(entry: entry),
      ),
    );
  }

  Widget _buildWanderSpots() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Text(
                  '📍 WanderSpots for You',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
                Text(
                  'Based on your vibe',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF718096),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Subtitle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'WanderSpots – Local places matching your mood and location',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF718096),
                height: 1.3,
              ),
            ),
          ),
          
          Container(
            height: 310,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _getWanderSpots().length,
              itemBuilder: (context, index) {
                final spot = _getWanderSpots()[index];
                return _buildWanderSpotCard(spot, index);
              },
            ),
          ),
          
          // Small promotional message
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 14,
                  color: const Color(0xFF718096),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'New cozy cafés & spots are joining WanderMood daily',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF718096),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showBusinessSignupInfo(),
                  child: Text(
                    'Join as business',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF2A6049),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleSuggestions() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Text(
                  '👥 Travelers You Might Like',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TravelersDiscoveryScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'See All',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF2A6049),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 5,
              itemBuilder: (context, index) {
                return _buildPersonSuggestionCard(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainScreenHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '🌍 Community Feed',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const Spacer(),
          _buildSortDropdown(),
        ],
      ),
    );
  }

  Widget _buildForYouSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Text(
                '🎯 For You',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A6049).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Based on your vibes',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2A6049),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Recommendation Cards
        Container(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _getPersonalizedRecommendations().length,
            itemBuilder: (context, index) {
              return _buildRecommendationCard(index);
            },
          ),
        ),
        
        const SizedBox(height: 8),
      ],
    );
  }

  List<Map<String, dynamic>> _getPersonalizedRecommendations() {
    // Simulate user's mood preferences (in real app, this would come from user data)
    final userMoodPreferences = ['🧘 peaceful', '🏞️ adventurous', '💕 romantic'];
    
    return [
      {
        'title': 'Hidden Zen Garden in Kyoto',
        'location': 'Kyoto, Japan',
        'mood': '🧘 peaceful',
        'author': 'zen_traveler',
        'likes': 84,
        'image': 'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?w=400&h=300&fit=crop',
        'reason': 'Based on your love for peaceful moments',
        'timeAgo': '3h ago',
      },
      {
        'title': 'Epic Sunrise Hike in Patagonia',
        'location': 'Torres del Paine, Chile',
        'mood': '🏞️ adventurous',
        'author': 'mountain_soul',
        'likes': 127,
        'image': 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=400&h=300&fit=crop',
        'reason': 'Perfect for adventure seekers like you',
        'timeAgo': '5h ago',
      },
      {
        'title': 'Romantic Sunset in Santorini',
        'location': 'Oia, Greece',
        'mood': '💕 romantic',
        'author': 'couple_wanderers',
        'likes': 203,
        'image': 'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=400&h=300&fit=crop',
        'reason': 'Matches your romantic travel style',
        'timeAgo': '1d ago',
      },
      {
        'title': 'Cozy Coffee Shop Vibes',
        'location': 'Amsterdam, Netherlands',
        'mood': '😌 relaxed',
        'author': 'coffee_nomad',
        'likes': 92,
        'image': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400&h=300&fit=crop',
        'reason': 'Great for chill moments',
        'timeAgo': '6h ago',
      },
    ];
  }

  Widget _buildRecommendationCard(int index) {
    final recommendation = _getPersonalizedRecommendations()[index];
    
    return GestureDetector(
      onTap: () {
        // Show detailed view or navigate to post
        showWanderMoodToast(
          context,
          message: 'Opening "${recommendation['title']}"',
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with mood tag
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      recommendation['image'],
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[300]!, Colors.grey[400]!],
                            ),
                          ),
                          child: const Icon(Icons.image_not_supported, size: 40),
                        );
                      },
                    ),
                  ),
                  // Mood tag
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getMoodColor(recommendation['mood']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recommendation['mood'],
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 11, color: Colors.grey[600]),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            recommendation['location'],
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recommendation['reason'],
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: const Color(0xFF2A6049),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.favorite_border, size: 11, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Text(
                          '${recommendation['likes']}',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case '🧘 peaceful':
        return const Color(0xFF10B981); // Green
      case '🏞️ adventurous':
        return const Color(0xFFEF4444); // Red-orange
      case '💕 romantic':
        return const Color(0xFFEC4899); // Pink
      case '😌 relaxed':
        return const Color(0xFF06B6D4); // Cyan
      case '🎉 excited':
        return const Color(0xFFF59E0B); // Orange
      case '🏛️ cultural':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  Widget _buildLocalCommunitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with stats
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Text(
                '📍 Near You',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '12 active travelers',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // Show all local posts
                  setState(() {
                    _selectedSortFilter = 'Nearby';
                  });
                  showWanderMoodToast(
                    context,
                    message: 'Showing all nearby posts',
                    backgroundColor: const Color(0xFF3B82F6),
                  );
                },
                child: Text(
                  'See All',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Local activity highlights
        _buildLocalActivityHighlights(),
        
        // Recent local posts
        Container(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _getLocalCommunityPosts().length,
            itemBuilder: (context, index) {
              return _buildLocalPostCard(index);
            },
          ),
        ),
        
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLocalActivityHighlights() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.05),
            const Color(0xFF06B6D4).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.trending_up,
                  color: const Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What\'s happening in Rotterdam',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '5 travelers shared new discoveries today',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActivityStat('🏛️', 'Museums', '3 new'),
              const SizedBox(width: 16),
              _buildActivityStat('🍜', 'Food', '7 spots'),
              const SizedBox(width: 16),
              _buildActivityStat('🚲', 'Cycling', '2 routes'),
              const SizedBox(width: 16),
              _buildActivityStat('🎨', 'Art', '4 galleries'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStat(String emoji, String category, String count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              category,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            Text(
              count,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: const Color(0xFF3B82F6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getLocalCommunityPosts() {
    return [
      {
        'title': 'Hidden Street Art in Katendrecht',
        'location': 'Rotterdam, Netherlands',
        'distance': '2.3 km away',
        'author': 'local_explorer',
        'authorImage': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
        'likes': 23,
        'image': 'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=400&h=250&fit=crop',
        'timeAgo': '2h ago',
        'mood': '🎨 cultural',
      },
      {
        'title': 'Best Stroopwafel in the City',
        'location': 'Markthal, Rotterdam',
        'distance': '1.8 km away',
        'author': 'foodie_rotterdam',
        'authorImage': 'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=100',
        'likes': 45,
        'image': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=250&fit=crop',
        'timeAgo': '4h ago',
        'mood': '😋 foodie',
      },
      {
        'title': 'Sunrise Bike Ride to Kinderdijk',
        'location': 'Kinderdijk, Netherlands',
        'distance': '15 km away',
        'author': 'cycling_dutchie',
        'authorImage': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100',
        'likes': 67,
        'image': 'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=400&h=250&fit=crop',
        'timeAgo': '6h ago',
        'mood': '🚲 active',
      },
      {
        'title': 'Cozy Canal-side Café',
        'location': 'Delfshaven, Rotterdam',
        'distance': '3.1 km away',
        'author': 'coffee_wanderer',
        'authorImage': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
        'likes': 31,
        'image': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=400&h=250&fit=crop',
        'timeAgo': '8h ago',
        'mood': '☕ relaxed',
      },
    ];
  }

  Widget _buildLocalPostCard(int index) {
    final post = _getLocalCommunityPosts()[index];
    
    return GestureDetector(
      onTap: () {
        showWanderMoodToast(
          context,
          message: 'Opening "${post['title']}"',
          backgroundColor: const Color(0xFF3B82F6),
        );
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  post['image'],
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[200]!, Colors.blue[300]!],
                        ),
                      ),
                      child: const Icon(Icons.image_not_supported, size: 30),
                    );
                  },
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 11, color: Colors.grey[600]),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            post['distance'],
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFF3B82F6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          post['timeAgo'],
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ClipOval(
                          child: Image.network(
                            post['authorImage'],
                            width: 16,
                            height: 16,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3B82F6),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  post['author'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            post['author'],
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.favorite_border, size: 11, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Text(
                          '${post['likes']}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyHighlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Text(
                '🌟 This Week\'s Wanderlust',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Weekly recap',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Weekly Stats Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFF59E0B).withOpacity(0.05),
                const Color(0xFFEF4444).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
          ),
          child: Column(
            children: [
              // Community Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeeklyStat('🌍', '234', 'New Posts'),
                  _buildWeeklyStat('👥', '47', 'Countries'),
                  _buildWeeklyStat('❤️', '1.2k', 'Likes Given'),
                  _buildWeeklyStat('💬', '89', 'New Friends'),
                ],
              ),
              
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 16),
              
              // Trending Moods
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: const Color(0xFFF59E0B),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Trending Moods This Week',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Mood Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getTrendingMoods().map((mood) {
                  return _buildTrendingMoodTag(mood);
                }).toList(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildWeeklyStat(String emoji, String number, String label) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          number,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getTrendingMoods() {
    return [
      {'mood': '🏖️ Beach vibes', 'count': '23 posts', 'trend': 'up'},
      {'mood': '🏛️ Cultural', 'count': '18 posts', 'trend': 'up'},
      {'mood': '🍜 Foodie', 'count': '31 posts', 'trend': 'hot'},
      {'mood': '🧘 Peaceful', 'count': '15 posts', 'trend': 'up'},
      {'mood': '🏞️ Adventure', 'count': '27 posts', 'trend': 'hot'},
      {'mood': '💕 Romantic', 'count': '12 posts', 'trend': 'new'},
    ];
  }

  Widget _buildTrendingMoodTag(Map<String, dynamic> mood) {
    Color tagColor;
    Color textColor;
    
    switch (mood['trend']) {
      case 'hot':
        tagColor = const Color(0xFFEF4444);
        textColor = Colors.white;
        break;
      case 'up':
        tagColor = const Color(0xFF10B981);
        textColor = Colors.white;
        break;
      case 'new':
        tagColor = const Color(0xFF8B5CF6);
        textColor = Colors.white;
        break;
      default:
        tagColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
    }
    
    return GestureDetector(
      onTap: () {
        showWanderMoodToast(
          context,
          message: 'Filtering by ${mood['mood']}',
          backgroundColor: tagColor,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: tagColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mood['mood'],
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                mood['count'],
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonSuggestionCard(int index) {
    final mockUsers = [
      {'name': 'Sarah', 'vibe': 'Adventure Seeker', 'location': 'Bali', 'image': 'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=200'},
      {'name': 'Marco', 'vibe': 'Culture Explorer', 'location': 'Tokyo', 'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200'},
      {'name': 'Luna', 'vibe': 'Beach Lover', 'location': 'Maldives', 'image': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200'},
      {'name': 'Alex', 'vibe': 'Solo Wanderer', 'location': 'Iceland', 'image': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200'},
      {'name': 'Maya', 'vibe': 'Foodie Traveler', 'location': 'Paris', 'image': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200'},
    ];
    
    final user = mockUsers[index % mockUsers.length];
    
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2A6049), width: 2),
            ),
            child: ClipOval(
              child: Image.network(
                user['image']!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to gradient avatar if image fails
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2A6049),
                          const Color(0xFF4ECDC4),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        user['name']![0],
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user['name']!,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          Text(
            user['vibe']!,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMainFeed(
    AsyncValue<List<DiaryEntry>> friendsFeedAsync,
    AsyncValue<List<DiaryEntry>> publicFeedAsync,
  ) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Screen Header
          _buildMainScreenHeader(),
          
          // Smart Recommendations Section
          _buildForYouSection(),
          
          // Local Community Section
          _buildLocalCommunitySection(),
          
          // Weekly Community Highlights
          _buildWeeklyHighlights(),
          
          // Feed Content
          _selectedSortFilter == 'Friends Only'
            ? friendsFeedAsync.when(
                data: (friendsEntries) {
                  final filteredEntries = _filterAndSortEntries(friendsEntries);
                  
                  if (filteredEntries.isEmpty) {
                    return _buildEmptyFriendsState();
                  }
                  
                  return Column(
                    children: filteredEntries.map((entry) {
                      return DiaryFeedCard(
                        entry: entry,
                        onTap: () => _onEntryTap(context, entry),
                        onLike: () => _onLike(ref, entry.id),
                        onSave: () => _onSave(ref, entry.id),
                        onComment: () => _onComment(context, entry),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => _buildErrorState(),
              )
            : friendsFeedAsync.when(
                data: (friendsEntries) {
                  return publicFeedAsync.when(
                    data: (publicEntries) {
                      final allEntries = [...friendsEntries, ...publicEntries];
                      final filteredEntries = _filterAndSortEntries(allEntries);
                      
                      return Column(
                        children: filteredEntries.map((entry) {
                          return DiaryFeedCard(
                            entry: entry,
                            onTap: () => _onEntryTap(context, entry),
                            onLike: () => _onLike(ref, entry.id),
                            onSave: () => _onSave(ref, entry.id),
                            onComment: () => _onComment(context, entry),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => _buildErrorState(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => _buildErrorState(),
              ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSortFilter,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF4A5568),
            fontWeight: FontWeight.w500,
          ),
          items: _sortFilters.map((filter) {
            return DropdownMenuItem(
              value: filter,
              child: Text(filter),
            );
          }).toList(),
                     onChanged: (value) {
             if (value != null) {
               _onSortChanged(value);
             }
           },
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.explore_off,
            size: 64,
            color: const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load posts',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(diaryFeedProvider);
              ref.invalidate(friendsDiaryFeedProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A6049),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Try Again',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFriendsState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: Icon(
                Icons.people_outline,
                size: 40,
                color: Color(0xFF667eea),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No friends\' posts yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with other travelers to see their amazing stories here!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedSortFilter = 'Latest';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Explore All Posts',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DiaryEntry> _filterAndSortEntries(List<DiaryEntry> entries) {
    var filtered = entries;
    
    // Apply mood filter
    if (_selectedMoodFilter != 'All') {
      final moodEmoji = _selectedMoodFilter.split(' ').first;
      filtered = filtered.where((entry) => 
        entry.mood.contains(moodEmoji) || 
        entry.mood.toLowerCase().contains(_selectedMoodFilter.toLowerCase())
      ).toList();
    }
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((entry) =>
        entry.title?.toLowerCase().contains(searchTerm) == true ||
        entry.location?.toLowerCase().contains(searchTerm) == true ||
        entry.story?.toLowerCase().contains(searchTerm) == true
      ).toList();
    }
    
    // Apply sorting
    switch (_selectedSortFilter) {
      case 'Latest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Friends Only':
        // Show only friends' posts, sorted by latest
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Trending':
        // Sort by engagement (likes + comments)
        filtered.sort((a, b) => (b.likesCount + b.commentsCount).compareTo(a.likesCount + a.commentsCount));
        break;
      case 'Mood Match':
        // Could implement mood similarity algorithm here
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Nearby':
        // Could implement location-based sorting here
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    
    return filtered;
  }

  void _onEntryTap(BuildContext context, DiaryEntry entry) {
    // Navigate to diary detail
    showWanderMoodToast(
      context,
      message: 'Opening "${entry.title ?? 'Story'}"...',
    );
  }

  void _onLike(WidgetRef ref, String entryId) {
    // Toggle like
    ref.read(diaryServiceProvider).toggleLike(entryId).then((_) {
      ref.invalidate(diaryFeedProvider);
      ref.invalidate(friendsDiaryFeedProvider);
    }).catchError((error) {
      // Handle error
    });
  }

  void _onSave(WidgetRef ref, String entryId) {
    // Toggle save
    ref.read(diaryServiceProvider).toggleSave(entryId).then((_) {
      ref.invalidate(diaryFeedProvider);
      ref.invalidate(friendsDiaryFeedProvider);
    }).catchError((error) {
      // Handle error
    });
  }

  void _onComment(BuildContext context, DiaryEntry entry) {
    showWanderMoodToast(
      context,
      message: 'Comments feature coming soon! 💬',
    );
  }

  // Mood Helper Methods for DiaryHomeFeedState
  Color _getMoodTagColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return const Color(0xFFFFC107); // Amber
      case 'adventure':
      case 'adventurous':
        return const Color(0xFFFF6B35); // Orange-red
      case 'romantic':
        return const Color(0xFFE91E63); // Pink
      case 'peaceful':
        return const Color(0xFF2A6049); // Green
      case 'excited':
        return const Color(0xFFFF9800); // Orange
      case 'grateful':
        return const Color(0xFF2196F3); // Blue
      case 'relaxed':
        return const Color(0xFF00BCD4); // Cyan
      case 'wonder':
        return const Color(0xFF9C27B0); // Purple
      case 'inspired':
        return const Color(0xFF673AB7); // Deep Purple
      case 'energetic':
        return const Color(0xFFFF5722); // Deep Orange
      default:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }
  
  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'adventure':
      case 'adventurous':
        return '🏞️';
      case 'romantic':
        return '💕';
      case 'peaceful':
        return '🧘';
      case 'excited':
        return '🎉';
      case 'grateful':
        return '🙏';
      case 'relaxed':
        return '😌';
      case 'wonder':
        return '🤩';
      case 'inspired':
        return '💡';
      case 'energetic':
        return '⚡';
      default:
        return '✨';
    }
  }
}

// Beautiful Feed Card Component
class DiaryFeedCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComment;

  const DiaryFeedCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onLike,
    required this.onSave,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getMoodGradient(entry.mood),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Text(
                      _getMoodEmoji(entry.mood),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            entry.userName ?? 'Anonymous',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getMoodColor(entry.mood).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              entry.mood,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getMoodColor(entry.mood),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (entry.location != null && entry.location!.isNotEmpty) ...[
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: const Color(0xFF718096),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              entry.location!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF718096),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _formatTimeAgo(entry.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // More Options
                IconButton(
                  icon: const Icon(
                    Icons.more_horiz,
                    color: Color(0xFF718096),
                  ),
                  onPressed: () => _showOptions(context),
                ),
              ],
            ),
          ),
          
          // Story Content
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.title != null && entry.title!.isNotEmpty) ...[
                    Text(
                      entry.title!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    entry.story,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                      color: const Color(0xFF4A5568),
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: entry.tags.take(3).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF718096),
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildActionButton(
                  icon: entry.isLiked ? Icons.favorite : Icons.favorite_outline,
                  label: entry.likesCount > 0 ? '${entry.likesCount}' : 'Like',
                  color: entry.isLiked ? const Color(0xFFE53E3E) : const Color(0xFF718096),
                  onTap: onLike,
                ),
                const SizedBox(width: 20),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: entry.commentsCount > 0 ? '${entry.commentsCount}' : 'Comment',
                  color: const Color(0xFF718096),
                  onTap: onComment,
                ),
                const Spacer(),
                _buildActionButton(
                  icon: entry.isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  label: 'Save',
                  color: entry.isSaved ? const Color(0xFFFFE66D) : const Color(0xFF718096),
                  onTap: onSave,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }





  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Helper methods for DiaryFeedCard
  List<Color> _getMoodGradient(String mood) {
    Color moodColor = _getMoodTagColor(mood);
    return [
      moodColor.withOpacity(0.8),
      moodColor,
    ];
  }
  
  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'adventure':
      case 'adventurous':
        return '🏞️';
      case 'romantic':
        return '💕';
      case 'peaceful':
        return '🧘';
      case 'excited':
        return '🎉';
      case 'grateful':
        return '🙏';
      case 'relaxed':
        return '😌';
      case 'wonder':
        return '🤩';
      case 'inspired':
        return '💡';
      case 'energetic':
        return '⚡';
      default:
        return '✨';
    }
  }

  Color _getMoodTagColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return const Color(0xFFFFC107); // Amber
      case 'adventure':
      case 'adventurous':
        return const Color(0xFFFF6B35); // Orange-red
      case 'romantic':
        return const Color(0xFFE91E63); // Pink
      case 'peaceful':
        return const Color(0xFF2A6049); // Green
      case 'excited':
        return const Color(0xFFFF9800); // Orange
      case 'grateful':
        return const Color(0xFF2196F3); // Blue
      case 'relaxed':
        return const Color(0xFF00BCD4); // Cyan
      case 'wonder':
        return const Color(0xFF9C27B0); // Purple
      case 'inspired':
        return const Color(0xFF673AB7); // Deep Purple
      case 'energetic':
        return const Color(0xFFFF5722); // Deep Orange
      default:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  Color _getMoodColor(String mood) {
    return _getMoodTagColor(mood);
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              'Post Options',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: const Icon(Icons.bookmark_outline, color: Color(0xFF2A6049)),
              title: Text('Save Post', style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context),
            ),
            
            ListTile(
              leading: const Icon(Icons.person_add_outlined, color: Color(0xFF2196F3)),
              title: Text('Follow User', style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context),
            ),
            
            ListTile(
              leading: const Icon(Icons.report_outlined, color: Color(0xFFFF5722)),
              title: Text('Report Post', style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class DiaryDiscoverTab extends StatelessWidget {
  const DiaryDiscoverTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore, size: 64, color: Color(0xFF667eea)),
          const SizedBox(height: 16),
          Text(
            'Discover Feature Coming Soon!',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore stories by mood & location',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }
}

class DiaryWriteTab extends StatelessWidget {
  const DiaryWriteTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit, size: 64, color: Color(0xFFFC466B)),
          const SizedBox(height: 16),
          Text(
            'Create Your Story!',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Writing interface coming soon',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }
}

class DiaryProfileTab extends ConsumerStatefulWidget {
  const DiaryProfileTab({super.key});

  @override
  ConsumerState<DiaryProfileTab> createState() => _DiaryProfileTabState();
}

class _DiaryProfileTabState extends ConsumerState<DiaryProfileTab> with SingleTickerProviderStateMixin {
  late TabController _contentTabController;
  int _selectedContentTab = 0;
  
  // Stats cards variables
  PageController _statsPageController = PageController(viewportFraction: 0.85);
  int _currentStatsPage = 0;
  
  @override
  void initState() {
    super.initState();
    _contentTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _contentTabController.dispose();
    _statsPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserProfile = ref.watch(currentUserProfileProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;
    final AsyncValue<List<DiaryEntry>> userDiaries = currentUser != null 
        ? ref.watch(userDiaryEntriesProvider(currentUser.id))
        : const AsyncValue<List<DiaryEntry>>.loading();
    
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Profile Header Section
        SliverToBoxAdapter(
          child: _buildProfileHeader(currentUserProfile, userDiaries),
        ),
        
        // Travel Snapshot Section
        SliverToBoxAdapter(
          child: _buildTravelSnapshot(currentUserProfile, userDiaries),
        ),
        
        // Content Tabs
        SliverToBoxAdapter(
          child: _buildContentTabs(),
        ),
        
        // Content based on selected tab
        _buildSelectedContent(userDiaries),
      ],
    );
  }



  Widget _buildProfileHeader(AsyncValue<UserProfile?> profileAsync, AsyncValue<List<DiaryEntry>> diariesAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: [
          // Edit button at top right
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _showEditProfile(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Color(0xFF2A6049),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Left-aligned Profile Section (like reference image)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              profileAsync.when(
                data: (profile) => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: profile?.imageUrl != null ? null : const LinearGradient(
                      colors: [Color(0xFF2A6049), Color(0xFF0D8B2F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2A6049).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: profile?.imageUrl != null 
                        ? DecorationImage(
                            image: NetworkImage(profile!.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profile?.imageUrl == null ? Center(
                    child: Text(
                      profile?.fullName?.substring(0, 1).toUpperCase() ?? 
                      profile?.email?.substring(0, 1).toUpperCase() ?? 'E',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ) : null,
                ),
                loading: () => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2A6049), Color(0xFF0D8B2F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2A6049).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
                error: (_, __) => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2A6049), Color(0xFF0D8B2F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2A6049).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'E',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Profile Information (right side)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username and Country Flag
                    Row(
                      children: [
                        Flexible(
                          child: profileAsync.when(
                            data: (profile) => Text(
                              profile?.fullName ?? profile?.username ?? 'Edvienne Merencia',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3748),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            loading: () => Text(
                              'Loading...',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                            error: (_, __) => Text(
                              'Edvienne Merencia',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF2A6049).withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Text(
                            '🇳🇱',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Bio
                    profileAsync.when(
                      data: (profile) => Text(
                        profile?.displayTravelBio ?? 'Exploring cities through coffee & culture ☕ 🏛️',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF718096),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      loading: () => Text(
                        'Loading...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF718096),
                        ),
                      ),
                      error: (_, __) => Text(
                        'Exploring cities through coffee & culture ☕ 🏛️',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF718096),
                          height: 1.3,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Currently exploring
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Color(0xFF8B7355),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: profileAsync.when(
                            data: (profile) => Text(
                              'Currently exploring ${profile?.displayCurrentlyExploring ?? 'Rotterdam'}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF8B7355),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            loading: () => Text(
                              'Loading...',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF8B7355),
                              ),
                            ),
                            error: (_, __) => Text(
                              'Currently exploring Rotterdam',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF8B7355),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Mood of the Month
          _buildMoodOfTheMonth(),
        ],
      ),
    );
  }

  Widget _buildMoodCloud() {
    return ref.watch(currentUserProfileProvider).when(
      data: (profile) {
        final moods = profile?.displayTravelVibes ?? ['Spontaneous', 'Social', 'Relaxed', 'Adventurous', 'Cultural', 'Peaceful'];
        return _buildMoodCloudContent(moods);
      },
      loading: () => _buildMoodCloudContent(['Loading...']),
      error: (_, __) => _buildMoodCloudContent(['Adventurous', 'Cultural', 'Peaceful']),
    );
  }

  Widget _buildMoodCloudContent(List<String> moods) {
    final colors = [
      const Color(0xFF2A6049), // Main brand green
      const Color(0xFF4ECDC4), // Teal  
      const Color(0xFF667eea), // Blue
      const Color(0xFFE91E63), // Pink
      const Color(0xFFFF9800), // Orange
      const Color(0xFF8E24AA), // Purple
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Travel Vibes',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: moods.asMap().entries.map((entry) {
            final index = entry.key;
            final mood = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors[index % colors.length].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors[index % colors.length].withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                mood,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors[index % colors.length],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTravelSnapshot(AsyncValue<UserProfile?> profileAsync, AsyncValue<List<DiaryEntry>> diariesAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horizontal Scrollable Stats Cards
          _buildHorizontalStatsCards(),
          
          const SizedBox(height: 20),
          
          // Travel Vibes
          _buildMoodCloud(),
        ],
      ),
    );
  }

  Widget _buildHorizontalStatsCards() {
    final statsData = [
      {
        'value': '12',
        'label': 'Posts Shared',
        'icon': Icons.photo_camera_outlined,
        'onTap': () => _showMyFeed(),
      },
      {
        'value': '8',
        'label': 'Places Explored',
        'icon': Icons.map_outlined,
        'onTap': () => _showMyPlaces(),
      },
      {
        'value': '24',
        'label': 'Followers',
        'icon': Icons.people_outline,
        'onTap': () => _showFollowers(),
      },
      {
        'value': '18',
        'label': 'Following',
        'icon': Icons.person_add_outlined,
        'onTap': () => _showFollowing(),
      },
    ];

    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: statsData.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 6,
                right: index == statsData.length - 1 ? 0 : 6,
              ),
              child: GestureDetector(
                onTap: stat['onTap'] as VoidCallback?,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2A6049).withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        stat['icon'] as IconData,
                        color: const Color(0xFF2A6049),
                        size: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stat['value'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D3748),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stat['label'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF718096),
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF718096),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildMoodOfTheMonth() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2A6049).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF2A6049).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Text('🌿', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mood of the Month',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF718096),
                  ),
                ),
                Text(
                  'Mostly Peaceful this December',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildContentTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.view_module_outlined,
                size: 18,
                color: Color(0xFF718096),
              ),
              const SizedBox(width: 6),
              Text(
                'Content',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTabButton('📸 My Feed', 0),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTabButton('📍 Map View', 1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTabButton('🔖 Saved', 2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isActive = _selectedContentTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedContentTab = index;
        });
        _contentTabController.animateTo(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2A6049) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF718096),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCameraButton() {
    return GestureDetector(
      onTap: () => _openPhotoCreation(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A6049), Color(0xFF45A049)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2A6049).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              'Add Photo',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPhotoCreation() {
    // Switch to the Discover tab (index 1) which is now the photo creation tab
    // This assumes we're in the main platform screen context
    showWanderMoodToast(
      context,
      message: 'Tap the camera tab to add photos!',
    );
  }

  Widget _buildSelectedContent(AsyncValue<List<DiaryEntry>> diariesAsync) {
    switch (_selectedContentTab) {
      case 0:
        return _buildMyWanderFeed(diariesAsync);
      case 1:
        return _buildMapContent();
      case 2:
        return _buildSavedContent();
      default:
        return _buildMyWanderFeed(diariesAsync);
    }
  }

  List<DiaryEntry> _getMockUserPosts() {
    return [
      DiaryEntry(
        id: 'mock_1',
        userId: 'current_user',
        title: 'Beautiful Amsterdam',
        story: 'Exploring the canals and feeling adventurous!',
        mood: 'Adventurous',
        location: 'Amsterdam, Netherlands',
        photos: ['https://picsum.photos/400/400?random=1'],
        tags: ['travel', 'adventure', 'amsterdam'],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isPublic: true,
        likesCount: 12,
        commentsCount: 3,
        isLiked: false,
        isSaved: false,
      ),
      DiaryEntry(
        id: 'mock_2',
        userId: 'current_user',
        title: 'Peaceful Morning',
        story: 'Starting the day with gratitude and peace.',
        mood: 'Peaceful',
        location: 'Rotterdam, Netherlands',
        photos: ['https://picsum.photos/400/400?random=2'],
        tags: ['morning', 'peaceful', 'gratitude'],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        isPublic: true,
        likesCount: 8,
        commentsCount: 1,
        isLiked: false,
        isSaved: false,
      ),
    ];
  }

  Widget _buildMyWanderFeed(AsyncValue<List<DiaryEntry>> diariesAsync) {
    return diariesAsync.when(
      data: (entries) {
        // Create mock posts if no entries exist
        final mockPosts = _getMockUserPosts();
        final postsToShow = entries.isNotEmpty ? entries : mockPosts;
        
        if (postsToShow.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(),
          );
        }
        
        return SliverToBoxAdapter(
          child: Container(
            height: 600,
            padding: const EdgeInsets.all(20),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Instagram-style 3-column grid
                childAspectRatio: 1.0, // Square photos
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: postsToShow.length,
              itemBuilder: (context, index) {
                final entry = postsToShow[index];
                return _buildPhotoFeedCard(entry);
              },
            ),
          ),
        );
      },
      loading: () => SliverToBoxAdapter(
        child: Container(
          height: 200,
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF4ECDC4),
            ),
          ),
        ),
      ),
      error: (_, __) => SliverToBoxAdapter(
        child: Container(
          height: 600,
          padding: const EdgeInsets.all(20),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _getMockUserPosts().length,
            itemBuilder: (context, index) {
              final entry = _getMockUserPosts()[index];
              return _buildPhotoFeedCard(entry);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoFeedCard(DiaryEntry entry) {
    return GestureDetector(
      onTap: () => _openEntry(entry),
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
          child: entry.photos.isNotEmpty
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    // Display the actual image
                    Image.network(
                      entry.photos.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to mood color if image fails to load
                        return Container(
                          color: _getMoodColor(entry.mood).withOpacity(0.3),
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: _getMoodColor(entry.mood),
                              size: 24,
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: const Color(0xFF2A6049),
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    ),
                    // Optional: Add a subtle mood indicator overlay in the top-right corner
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getMoodEmoji(entry.mood),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getMoodColor(entry.mood),
                        _getMoodColor(entry.mood).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getMoodEmoji(entry.mood),
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.mood,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildFeedCard(DiaryEntry entry) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _getMoodColor(entry.mood).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getMoodEmoji(entry.mood),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getMoodColor(entry.mood).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.mood,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getMoodColor(entry.mood),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Entry info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title ?? 'Untitled Memory',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.location != null && entry.location!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 10,
                        color: Color(0xFF718096),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          entry.location!,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: const Color(0xFF718096),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedContent() {
          final folders = [
        {'name': 'Barcelona Dreams', 'count': 8, 'color': const Color(0xFFE91E63)},
        {'name': 'Summer Solo', 'count': 12, 'color': const Color(0xFF3F51B5)},
        {'name': 'Date Night Ideas', 'count': 6, 'color': const Color(0xFFFF9800)},
        {'name': 'Coffee Culture', 'count': 15, 'color': const Color(0xFF795548)},
      ];
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final folder = folders[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                                         decoration: BoxDecoration(
                       color: folder['color'] as Color,
                       borderRadius: BorderRadius.circular(10),
                     ),
                                         child: Icon(
                       Icons.folder_outlined,
                       color: Colors.white,
                       size: 20,
                     ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder['name'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          '${folder['count']} saved stories',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            );
          },
          childCount: folders.length,
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 48,
              color: Color(0xFF2A6049),
            ),
            const SizedBox(height: 12),
            Text(
              'Interactive Map Coming Soon!',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Explore your travel journey visually',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF718096),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            size: 48,
            color: Color(0xFF2A6049),
          ),
          const SizedBox(height: 16),
          Text(
            'Start Your WanderFeed Journey!',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your first travel story and connect with fellow wanderers',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              // Switch to Write tab
              // This would need to be coordinated with the parent widget
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A6049),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Create First Story',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildEditProfileSheet(),
    );
  }

  void _navigateToEditProfileInfo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EditProfileInfoScreen(),
      ),
    );
  }

  Future<void> _changeProfilePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      try {
        final actions = ref.read(profileSettingsActionsProvider);
        final imageUrl = await actions.uploadProfilePhoto(image.path);
        
        if (imageUrl != null && mounted) {
          showWanderMoodToast(
            context,
            message: 'Profile photo updated!',
          );
        }
      } catch (e) {
        if (mounted) {
          showWanderMoodToast(
            context,
            message: 'Error uploading photo: $e',
            isError: true,
          );
        }
      }
    }
  }

  void _navigateToMoodPreferences() {
    showWanderMoodToast(
      context,
      message: 'Travel Mood Preferences coming soon!',
    );
  }

  void _navigateToPrivacySettings() {
    showWanderMoodToast(
      context,
      message: 'Privacy Settings coming soon!',
    );
  }

  void _navigateToGeneralSettings() {
    showWanderMoodToast(
      context,
      message: 'General Settings coming soon!',
    );
  }

  void _showMyFeed() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _MyFeedScreen(scrollController: scrollController),
        ),
      ),
    );
  }

  void _showMyPlaces() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _MyPlacesScreen(
            scrollController: scrollController,
            onPlaceTap: _showPlaceDetails,
          ),
        ),
      ),
    );
  }

  void _showFollowers() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _FollowersScreen(scrollController: scrollController),
        ),
      ),
    );
  }

  void _showFollowing() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _FollowingScreen(scrollController: scrollController),
        ),
      ),
    );
  }

  void _showPlaceDetails(BuildContext context, Map<String, dynamic> place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _PlaceDetailsScreen(
            place: place,
            scrollController: scrollController,
            onVisitTap: _navigateToPost,
          ),
        ),
      ),
    );
  }

  void _navigateToPost(BuildContext context, Map<String, dynamic> visit) {
    // Close the current modal first
    Navigator.pop(context);
    
    // Check if visit has a post
    if (visit['hasPost'] == true && visit['postId'] != null) {
      // Navigate to the specific diary post using the proper route
      context.push('/social/post/${visit['postId']}');
    } else {
      // Show message if no post exists for this visit
      showWanderMoodToast(
        context,
        message: 'No diary post found for this visit',
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Widget _buildEditProfileSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Profile Settings',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Color(0xFF2A6049)),
            title: Text('Edit Profile Info', style: GoogleFonts.poppins()),
            subtitle: Text('Update bio, location, travel vibes', style: GoogleFonts.poppins(fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              _navigateToEditProfileInfo();
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFF2A6049)),
            title: Text('Change Profile Photo', style: GoogleFonts.poppins()),
            onTap: () {
              Navigator.pop(context);
              _changeProfilePhoto();
            },
          ),
          ListTile(
            leading: const Icon(Icons.mood_outlined, color: Color(0xFF2A6049)),
            title: Text('Travel Mood Preferences', style: GoogleFonts.poppins()),
            onTap: () {
              Navigator.pop(context);
              _navigateToMoodPreferences();
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility_outlined, color: Color(0xFF2A6049)),
            title: Text('Privacy Settings', style: GoogleFonts.poppins()),
            subtitle: Text('Control who can see your stories', style: GoogleFonts.poppins(fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              _navigateToPrivacySettings();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Color(0xFF2A6049)),
            title: Text('General Settings', style: GoogleFonts.poppins()),
            onTap: () {
              Navigator.pop(context);
              _navigateToGeneralSettings();
            },
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Helper methods for mood colors and emojis
  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'excited':
        return const Color(0xFFFF6B6B);
      case 'peaceful':
        return const Color(0xFF4ECDC4);
      case 'adventurous':
        return const Color(0xFFFC466B);
      case 'romantic':
        return const Color(0xFFFF8A80);
      case 'curious':
        return const Color(0xFF667eea);
      case 'grateful':
        return const Color(0xFFFFE66D);
      case 'inspired':
        return const Color(0xFF9C88FF);
      case 'relaxed':
        return const Color(0xFF81C784);
      case 'wonder':
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFF2A6049);
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'excited':
        return '🤩';
      case 'peaceful':
        return '😌';
      case 'adventurous':
        return '🚀';
      case 'romantic':
        return '💕';
      case 'curious':
        return '🤔';
      case 'grateful':
        return '🙏';
      case 'inspired':
        return '✨';
      case 'relaxed':
        return '😎';
      case 'wonder':
        return '🤩';
      default:
        return '😊';
    }
  }

  void _openEntry(DiaryEntry entry) {
    showWanderMoodToast(
      context,
      message: 'Opening: ${entry.title ?? "Untitled Entry"}',
      backgroundColor: const Color(0xFF4ECDC4),
    );
  }
}

class PhotoCreationTab extends ConsumerStatefulWidget {
  const PhotoCreationTab({super.key});

  @override
  ConsumerState<PhotoCreationTab> createState() => _PhotoCreationTabState();
}

class _PhotoCreationTabState extends ConsumerState<PhotoCreationTab> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Camera Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_a_photo,
              size: 50,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Title
          Text(
            'Share Your Moment',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Subtitle
          Text(
            'Capture and share your travel experiences\nwith the WanderFeed community',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF718096),
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Action Buttons
          Column(
            children: [
              // Take Photo Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _takePhoto(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A6049),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Take Photo',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Choose from Gallery Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _chooseFromGallery(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF667eea),
                    side: const BorderSide(color: Color(0xFF667eea), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Choose from Gallery',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        _showCreatePostDialog(image);
      }
    } catch (e) {
      showWanderMoodToast(
        context,
        message: 'Failed to take photo: $e',
        isError: true,
      );
    }
  }

  void _chooseFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        _showCreatePostDialog(image);
      }
    } catch (e) {
      showWanderMoodToast(
        context,
        message: 'Failed to pick image: $e',
        isError: true,
      );
    }
  }

  void _showCreatePostDialog(XFile image) {
    final TextEditingController captionController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    String selectedMood = 'Happy';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600])),
                    ),
                    const Spacer(),
                    Text(
                      'Create Post',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _submitPost(image, captionController.text, locationController.text, selectedMood),
                      child: Text('Share', style: GoogleFonts.poppins(color: const Color(0xFF2A6049), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo preview
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(image.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Caption input
                      TextField(
                        controller: captionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Write a caption...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2A6049)),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Location input
                      TextField(
                        controller: locationController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_on, color: Color(0xFF2A6049)),
                          hintText: 'Add location...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2A6049)),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Mood selection
                      Text(
                        'How are you feeling?',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['Happy', 'Excited', 'Peaceful', 'Adventurous', 'Grateful', 'Inspired', 'Relaxed', 'Energetic']
                            .map((mood) => GestureDetector(
                              onTap: () => setModalState(() => selectedMood = mood),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selectedMood == mood ? _getMoodColor(mood) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selectedMood == mood ? _getMoodColor(mood) : Colors.grey[300]!,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getMoodEmoji(mood),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      mood,
                                      style: GoogleFonts.poppins(
                                        color: selectedMood == mood ? Colors.white : Colors.grey[700],
                                        fontWeight: selectedMood == mood ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitPost(XFile image, String caption, String location, String mood) async {
    Navigator.pop(context); // Close the modal
    
    // Show loading indicator
    showWanderMoodToast(
      context,
      message: 'Sharing your moment...',
      leading: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
      duration: const Duration(seconds: 3),
    );

    try {
      // TODO: Implement actual post creation with photo upload
      await Future.delayed(const Duration(seconds: 2)); // Simulate upload
      
      showWanderMoodToast(
        context,
        message: '✨ Your moment has been shared!',
      );

      // Refresh the feed
      ref.invalidate(diaryFeedProvider);
      ref.invalidate(friendsDiaryFeedProvider);

    } catch (e) {
      showWanderMoodToast(
        context,
        message: 'Failed to share post: $e',
        isError: true,
      );
    }
  }

  // Helper methods
  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'excited':
        return const Color(0xFFFF6B6B);
      case 'peaceful':
        return const Color(0xFF4ECDC4);
      case 'adventurous':
        return const Color(0xFFFC466B);
      case 'grateful':
        return const Color(0xFFFFE66D);
      case 'inspired':
        return const Color(0xFF9C88FF);
      case 'relaxed':
        return const Color(0xFF81C784);
      case 'energetic':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF2A6049);
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'excited':
        return '🤩';
      case 'peaceful':
        return '😌';
      case 'adventurous':
        return '🚀';
      case 'grateful':
        return '🙏';
      case 'inspired':
        return '✨';
      case 'relaxed':
        return '😎';
      case 'energetic':
        return '⚡';
      default:
        return '😊';
    }
  }
}

class DiarySavedTab extends StatelessWidget {
  const DiarySavedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bookmark, size: 64, color: Color(0xFFFFE66D)),
          const SizedBox(height: 16),
          Text(
            'Saved Stories!',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your bookmarked content',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }
}

// My Feed Screen
class _MyFeedScreen extends ConsumerWidget {
  final ScrollController scrollController;
  
  const _MyFeedScreen({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserProfile = ref.watch(currentUserProfileProvider);
    final currentUser = Supabase.instance.client.auth.currentUser;
    final AsyncValue<List<DiaryEntry>> userDiaries = currentUser != null 
        ? ref.watch(userDiaryEntriesProvider(currentUser.id))
        : const AsyncValue<List<DiaryEntry>>.loading();
    
    return Column(
      children: [
        // Handle bar
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.photo_camera, color: Color(0xFF2A6049), size: 24),
              const SizedBox(width: 12),
              Text(
                'My Feed',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              Text(
                '12 posts',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF718096),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Feed posts grid
        Expanded(
          child: userDiaries.when(
            data: (posts) => GridView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Close the modal
                    context.push('/social/post/${post.id}'); // Navigate to full post
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo section - Always shows image or placeholder
                        Expanded(
                          flex: 4,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              image: post.photos.isNotEmpty 
                                ? DecorationImage(
                                    image: NetworkImage(post.photos.first),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                              gradient: post.photos.isEmpty ? LinearGradient(
                                colors: [
                                  _getMoodColor(post.mood).withOpacity(0.3),
                                  _getMoodColor(post.mood).withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ) : null,
                            ),
                            child: Stack(
                              children: [
                                // If no photo, show placeholder content
                                if (post.photos.isEmpty)
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.photo_camera_outlined,
                                          size: 40,
                                          color: _getMoodColor(post.mood).withOpacity(0.6),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _getMoodEmoji(post.mood),
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                // Mood tag overlay (always visible)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getMoodColor(post.mood),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _getMoodEmoji(post.mood),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          post.mood,
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
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
                        
                        // Post caption and info
                        Container(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Caption (first line of story)
                              if (post.story.isNotEmpty)
                                Text(
                                  post.story.split('\n').first,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF2D3748),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              
                              const SizedBox(height: 6),
                              
                              // Location and date
                              Row(
                                children: [
                                  if (post.location?.isNotEmpty == true) ...[
                                    Icon(
                                      Icons.location_on,
                                      size: 11,
                                      color: _getMoodColor(post.mood),
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        post.location ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: _getMoodColor(post.mood),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  Text(
                                    DateFormat('MMM d').format(post.createdAt),
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      color: const Color(0xFF718096),
                                    ),
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
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text(
                'Unable to load feed',
                style: GoogleFonts.poppins(color: const Color(0xFF718096)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods for mood styling
  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'excited':
      case 'adventurous':
        return const Color(0xFFE91E63);
      case 'peaceful':
      case 'relaxed':
        return const Color(0xFF009688);
      case 'cultural':
      case 'inspired':
        return const Color(0xFF3F51B5);
      case 'happy':
      case 'joyful':
        return const Color(0xFFFF9800);
      case 'grateful':
      case 'content':
        return const Color(0xFF2A6049);
      default:
        return const Color(0xFF8E24AA);
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'excited':
        return '🤩';
      case 'adventurous':
        return '🚀';
      case 'peaceful':
        return '😌';
      case 'relaxed':
        return '😊';
      case 'cultural':
        return '🎭';
      case 'inspired':
        return '✨';
      case 'happy':
        return '😄';
      case 'joyful':
        return '🎉';
      case 'grateful':
        return '🙏';
      case 'content':
        return '😇';
      default:
        return '😊';
    }
  }
}

// My Places Screen
class _MyPlacesScreen extends ConsumerWidget {
  final ScrollController scrollController;
  final Function(BuildContext, Map<String, dynamic>) onPlaceTap;
  
  const _MyPlacesScreen({
    required this.scrollController,
    required this.onPlaceTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = [
      {'name': 'Rotterdam Central', 'visits': 8, 'lastVisit': 'Yesterday'},
      {'name': 'Erasmus Bridge', 'visits': 3, 'lastVisit': '2 days ago'},
      {'name': 'Markthal', 'visits': 5, 'lastVisit': '1 week ago'},
      {'name': 'Cube Houses', 'visits': 2, 'lastVisit': '2 weeks ago'},
      {'name': 'Euromast', 'visits': 1, 'lastVisit': '1 month ago'},
      {'name': 'Witte de Withstraat', 'visits': 4, 'lastVisit': '3 days ago'},
      {'name': 'Kinderdijk', 'visits': 1, 'lastVisit': '2 months ago'},
      {'name': 'Boijmans Museum', 'visits': 2, 'lastVisit': '1 month ago'},
    ];
    
    return Column(
      children: [
        // Handle bar
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.map, color: Color(0xFF3F51B5), size: 24),
              const SizedBox(width: 12),
              Text(
                'Places Explored',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              Text(
                '${places.length} places',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF718096),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Places list
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              return GestureDetector(
                onTap: () => onPlaceTap(context, place),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
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
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3F51B5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.place,
                          color: Color(0xFF3F51B5),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place['name'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${place['visits']} visits • Last: ${place['lastVisit']}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF718096),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF718096),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Followers Screen
class _FollowersScreen extends StatefulWidget {
  final ScrollController scrollController;
  
  const _FollowersScreen({required this.scrollController});

  @override
  State<_FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<_FollowersScreen> {
  late List<Map<String, dynamic>> followers;

  @override
  void initState() {
    super.initState();
    followers = [
      {'name': 'Alex Chen', 'username': 'alex_travels', 'mutual': true},
      {'name': 'Sarah Johnson', 'username': 'foodie_sara', 'mutual': false},
      {'name': 'Mike Rodriguez', 'username': 'wanderlust_mike', 'mutual': true},
      {'name': 'Emma Wilson', 'username': 'culture_lover', 'mutual': true},
      {'name': 'David Kim', 'username': 'nature_escape', 'mutual': false},
    ];
  }

  void _removeFollower(int index) {
    final follower = followers[index];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Remove Follower',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to remove ${follower['name']} from your followers?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  followers.removeAt(index);
                });
                Navigator.of(context).pop();
                showWanderMoodToast(
                  context,
                  message: '${follower['name']} has been removed',
                  backgroundColor: const Color(0xFFE91E63),
                  duration: const Duration(seconds: 2),
                );
              },
              child: Text(
                'Remove',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFE91E63),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Column(
      children: [
        // Handle bar
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.people, color: Color(0xFFE91E63), size: 24),
              const SizedBox(width: 12),
              Text(
                'Followers',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              Text(
                '${followers.length} followers',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF718096),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Followers list
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: followers.length,
            itemBuilder: (context, index) {
              final follower = followers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          (follower['name'] as String).substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                follower['name'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2D3748),
                                ),
                              ),
                              if (follower['mutual'] as bool) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE91E63).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Mutual',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: const Color(0xFFE91E63),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${follower['username']}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _removeFollower(index),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63).withOpacity(0.1),
                        foregroundColor: const Color(0xFFE91E63),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Remove',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Following Screen
class _FollowingScreen extends StatefulWidget {
  final ScrollController scrollController;
  
  const _FollowingScreen({required this.scrollController});

  @override
  State<_FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<_FollowingScreen> {
  late List<Map<String, dynamic>> following;

  @override
  void initState() {
    super.initState();
    following = [
      {'name': 'Alex Chen', 'username': 'alex_travels', 'mutual': true},
      {'name': 'Mike Rodriguez', 'username': 'wanderlust_mike', 'mutual': true},
      {'name': 'Emma Wilson', 'username': 'culture_lover', 'mutual': true},
    ];
  }

  void _unfollowUser(int index) {
    final person = following[index];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Unfollow User',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to unfollow ${person['name']}?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  following.removeAt(index);
                });
                Navigator.of(context).pop();
                showWanderMoodToast(
                  context,
                  message: 'You unfollowed ${person['name']}',
                  backgroundColor: const Color(0xFFFF9800),
                  duration: const Duration(seconds: 2),
                );
              },
              child: Text(
                'Unfollow',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFF9800),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Column(
      children: [
        // Handle bar
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.person_add, color: Color(0xFFFF9800), size: 24),
              const SizedBox(width: 12),
              Text(
                'Following',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const Spacer(),
              Text(
                '${following.length} following',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF718096),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Following list
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: following.length,
            itemBuilder: (context, index) {
              final person = following[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          (person['name'] as String).substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                person['name'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2D3748),
                                ),
                              ),
                              if (person['mutual'] as bool) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9800).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Mutual',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: const Color(0xFFFF9800),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${person['username']}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _unfollowUser(index),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800).withOpacity(0.1),
                        foregroundColor: const Color(0xFFFF9800),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Unfollow',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 

// Place Details Screen
class _PlaceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> place;
  final ScrollController scrollController;
  final Function(BuildContext, Map<String, dynamic>) onVisitTap;
  
  const _PlaceDetailsScreen({
    required this.place,
    required this.scrollController,
    required this.onVisitTap,
  });

  @override
  Widget build(BuildContext context) {
    // Sample visit history for the place with post IDs
    final visits = [
      {
        'date': 'December 15, 2024',
        'mood': 'Relaxed',
        'photos': 3,
        'notes': 'Amazing coffee and great atmosphere. Perfect for working remotely.',
        'rating': 5,
        'postId': 'post_rotterdam_central_dec15',
        'hasPost': true,
      },
      {
        'date': 'November 28, 2024',
        'mood': 'Social',
        'photos': 1,
        'notes': 'Met up with friends here. Love the vibe!',
        'rating': 4,
        'postId': 'post_rotterdam_central_nov28',
        'hasPost': true,
      },
      {
        'date': 'November 10, 2024',
        'mood': 'Adventurous',
        'photos': 2,
        'notes': 'First time visiting. Really impressed by the architecture.',
        'rating': 5,
        'postId': 'post_rotterdam_central_nov10',
        'hasPost': true,
      },
    ];
    
    return Column(
      children: [
        // Handle bar
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF3F51B5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.place,
                  color: Color(0xFF3F51B5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place['name'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      '${place['visits']} visits total',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xFF718096)),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Visit History
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: visits.length,
            itemBuilder: (context, index) {
              final visit = visits[index];
              return GestureDetector(
                onTap: () => onVisitTap(context, visit),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Visit header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A6049).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            visit['mood'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF2A6049),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          visit['date'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Notes
                    Text(
                      visit['notes'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF2D3748),
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Visit stats
                    Row(
                      children: [
                        // Rating
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < (visit['rating'] as int) 
                                  ? Icons.star 
                                  : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            );
                          }),
                        ),
                        const SizedBox(width: 16),
                        // Photos
                        Row(
                          children: [
                            const Icon(
                              Icons.photo_camera_outlined,
                              size: 16,
                              color: Color(0xFF718096),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${visit['photos']} photos',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF718096),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Tap indicator
                    Row(
                      children: [
                        const Icon(
                          Icons.launch,
                          size: 14,
                          color: Color(0xFF2A6049),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'View full post',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF2A6049),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Activity Feed Tab Content
class ActivityFeedTabContent extends StatefulWidget {
  const ActivityFeedTabContent({Key? key}) : super(key: key);

  @override
  State<ActivityFeedTabContent> createState() => _ActivityFeedTabContentState();
}

class _ActivityFeedTabContentState extends State<ActivityFeedTabContent> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                                         Text(
                       'Activity Feed',
                       style: GoogleFonts.museoModerno(
                         fontSize: 32,
                         fontWeight: FontWeight.bold,
                         color: const Color(0xFF2A6049),
                         letterSpacing: 0.5,
                       ),
                     ),
                    const Spacer(),
                                         IconButton(
                       icon: const Icon(
                         Icons.notifications_outlined,
                         color: Color(0xFF2D3748),
                         size: 24,
                       ),
                       onPressed: () => _openNotificationsScreen(),
                     ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'See what your travel community is up to',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Stories Section
        SliverToBoxAdapter(
          child: _buildStoriesSection(),
        ),

        // Activity Filter Tabs
        SliverToBoxAdapter(
          child: _buildFilterTabs(),
        ),

        // Activity Feed
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final activities = _getActivityFeed();
              if (index >= activities.length) return null;
              
              return _buildActivityCard(activities[index], index);
            },
            childCount: _getActivityFeed().length,
          ),
        ),

        // Loading indicator
        if (_isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2A6049),
                ),
              ),
            ),
          ),

        // Bottom spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildStoriesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_stories,
                    color: const Color(0xFF2A6049),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Travel Stories',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _viewAllStories(),
                    child: Text(
                      'View All',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF2A6049),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _getStories().length,
                  itemBuilder: (context, index) {
                    final story = _getStories()[index];
                    return _buildStoryItem(story);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryItem(Map<String, dynamic> story) {
    return GestureDetector(
      onTap: () => _viewStory(story),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: story['hasStory'] ? const LinearGradient(
                  colors: [
                    Color(0xFF2A6049),
                    Color(0xFF81C784),
                  ],
                ) : null,
                border: Border.all(
                  color: story['hasStory'] ? const Color(0xFF2A6049) : Colors.grey[300]!, 
                  width: 2
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    story['avatar'],
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2A6049),
                              Color(0xFF81C784),
                            ],
                          ),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2A6049),
                              Color(0xFF81C784),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            story['firstName'][0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              story['firstName'],
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('All', true),
          const SizedBox(width: 8),
          _buildFilterChip('Following', false),
          const SizedBox(width: 8),
          _buildFilterChip('Nearby', false),
          const SizedBox(width: 8),
          _buildFilterChip('Trending', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _onFilterChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF2A6049) 
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF2A6049) 
                : Colors.grey[300]!,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF2A6049).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => _navigateToUserProfile(activity),
        child: Card(
          elevation: 4,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getUserColor(activity['user']),
                    child: Text(
                      activity['user'][0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              activity['user'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D3748),
                              ),
                            ),
                            if (activity['isVerified'] == true) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: const Color(0xFF2A6049),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              activity['location'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${activity['time']}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => _showPostOptions(activity),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                activity['content'],
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF2D3748),
                  height: 1.5,
                ),
              ),
            ),

            // Image if available
            if (activity['hasImage'] == true && activity['imageUrl'] != null)
              Container(
                margin: const EdgeInsets.all(16),
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    activity['imageUrl'],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFF2A6049),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Image not available',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildActionButton(
                    Icons.favorite_border,
                    '${activity['likes']}',
                    () => _likePost(activity),
                  ),
                  const SizedBox(width: 20),
                  _buildActionButton(
                    Icons.comment_outlined,
                    '${activity['comments']}',
                    () => _commentOnPost(activity),
                  ),
                  const SizedBox(width: 20),
                  _buildActionButton(
                    Icons.share_outlined,
                    'Share',
                    () => _sharePost(activity),
                  ),
                  const Spacer(),
                  _buildActionButton(
                    Icons.bookmark_border,
                    '',
                    () => _savePost(activity),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        // Stop propagation to parent GestureDetector
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Add more tappable area
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey[600],
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getUserColor(String name) {
    final colors = [
      const Color(0xFF2A6049),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
      const Color(0xFF00BCD4),
    ];
    return colors[name.hashCode % colors.length];
  }

  List<Map<String, dynamic>> _getStories() {
    return [
      {
        'author': 'Sarah Miller',
        'firstName': 'Sarah',
        'avatar': 'https://images.unsplash.com/photo-1494790108755-2616b612b47c?w=100&h=100&fit=crop&crop=face',
        'preview': 'Amsterdam Adventure',
        'timestamp': '2h ago',
        'hasStory': true,
      },
      {
        'author': 'Marco Silva',
        'firstName': 'Marco',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face',
        'preview': 'Barcelona Vibes',
        'timestamp': '4h ago',
        'hasStory': true,
      },
      {
        'author': 'Luna Chen',
        'firstName': 'Luna',
        'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop&crop=face',
        'preview': 'Beach Day',
        'timestamp': '6h ago',
        'hasStory': true,
      },
      {
        'author': 'Alex Turner',
        'firstName': 'Alex',
        'avatar': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face',
        'preview': 'Mountain Hike',
        'timestamp': '8h ago',
        'hasStory': true,
      },
      {
        'author': 'Emma Wilson',
        'firstName': 'Emma',
        'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&h=100&fit=crop&crop=face',
        'preview': 'Food Tour',
        'timestamp': '12h ago',
        'hasStory': true,
      },
      {
        'author': 'David Kim',
        'firstName': 'David',
        'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop&crop=face',
        'preview': 'Tokyo Cherry Blossoms',
        'timestamp': '1d ago',
        'hasStory': true,
      },
    ];
  }

  List<Map<String, dynamic>> _getActivityFeed() {
    return [
      {
        'user': 'Sarah Miller',
        'userId': 'user1',
        'location': 'Amsterdam, Netherlands',
        'time': '2h ago',
        'content': 'Just discovered the most amazing hidden café in the Jordaan district! The coffee here is absolutely incredible and the atmosphere is so cozy. Perfect spot for digital nomads ☕✨',
        'likes': 24,
        'comments': 8,
        'hasImage': true,
        'imageUrl': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&h=400&fit=crop',
        'isVerified': true,
      },
      {
        'user': 'Marco Silva',
        'userId': 'user2',
        'location': 'Barcelona, Spain',
        'time': '4h ago',
        'content': 'Sunset from Park Güell never gets old 🌅 Gaudí really knew how to pick the perfect spots. The city looks magical from up here!',
        'likes': 45,
        'comments': 12,
        'hasImage': true,
        'imageUrl': 'https://images.unsplash.com/photo-1539037116277-4db20889f2d4?w=800&h=400&fit=crop',
        'isVerified': false,
      },
      {
        'user': 'Luna Chen',
        'userId': 'user3',
        'location': 'Scheveningen, Netherlands',
        'time': '6h ago',
        'content': 'Beach volleyball session complete! 🏐 Nothing beats the feeling of sand between your toes and the North Sea breeze. Who\'s joining me tomorrow?',
        'likes': 18,
        'comments': 5,
        'hasImage': false,
        'isVerified': true,
      },
      {
        'user': 'Alex Turner',
        'userId': 'user4',
        'location': 'Swiss Alps',
        'time': '8h ago',
        'content': 'Reached the summit after 6 hours of hiking! The view from 3,000m is absolutely breathtaking. Every step was worth it 🏔️',
        'likes': 67,
        'comments': 23,
        'hasImage': true,
        'imageUrl': 'https://images.unsplash.com/photo-1464822759844-d150baec3a5e?w=800&h=400&fit=crop',
        'isVerified': false,
      },
      {
        'user': 'Emma Wilson',
        'userId': 'user5',
        'location': 'Rome, Italy',
        'time': '12h ago',
        'content': 'Food tour day 3: tried the most authentic carbonara at this tiny family restaurant. The owner taught me the secret recipe! 🍝',
        'likes': 31,
        'comments': 9,
        'hasImage': true,
        'imageUrl': 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?w=800&h=400&fit=crop',
        'isVerified': true,
      },
      {
        'user': 'David Kim',
        'userId': 'user6',
        'location': 'Tokyo, Japan',
        'time': '1d ago',
        'content': 'Cherry blossom season is here! Spent the entire day in Ueno Park capturing the perfect shots. Nature\'s artistry at its finest 🌸📸',
        'likes': 89,
        'comments': 34,
        'hasImage': true,
        'isVerified': false,
      },
    ];
  }

  void _navigateToUserProfile(Map<String, dynamic> activity) {
    final userId = activity['userId'];
    if (userId != null) {
      context.push('/social/profile/$userId');
    } else {
      // Fallback: show a snackbar if userId is not available
      showWanderMoodToast(
        context,
        message: 'Opening ${activity['user']}\'s profile...',
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You have 3 new notifications'),
            const SizedBox(height: 12),
            Text('• Sarah liked your post'),
            Text('• Marco started following you'),
            Text('• New travel story from Luna'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewAllStories() {
    showWanderMoodToast(
      context,
      message: 'Opening all travel stories...',
    );
  }

  void _viewStory(Map<String, dynamic> story) {
    showWanderMoodToast(
      context,
      message: 'Opening ${story['author']}\'s story...',
    );
  }

  void _onFilterChanged(String filter) {
    showWanderMoodToast(
      context,
      message: 'Filtering by: $filter',
    );
  }

  void _showPostOptions(Map<String, dynamic> activity) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Save Post'),
              onTap: () {
                Navigator.pop(context);
                _savePost(activity);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: Text('Follow ${activity['user']}'),
              onTap: () {
                Navigator.pop(context);
                _followUser(activity['user']);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report Post'),
              onTap: () {
                Navigator.pop(context);
                _reportPost(activity);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _likePost(Map<String, dynamic> activity) {
    showWanderMoodToast(
      context,
      message: 'Liked ${activity['user']}\'s post!',
    );
  }

  void _commentOnPost(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comment on ${activity['user']}\'s post'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Write a comment...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showWanderMoodToast(
                context,
                message: 'Comment posted!',
              );
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _sharePost(Map<String, dynamic> activity) {
    showWanderMoodToast(
      context,
      message: 'Shared ${activity['user']}\'s post!',
    );
  }

  void _savePost(Map<String, dynamic> activity) {
    showWanderMoodToast(
      context,
      message: 'Saved ${activity['user']}\'s post!',
    );
  }

  void _followUser(String username) {
    showWanderMoodToast(
      context,
      message: 'Following $username!',
    );
  }

  void _reportPost(Map<String, dynamic> activity) {
    showWanderMoodToast(
      context,
      message: 'Reported ${activity['user']}\'s post',
      backgroundColor: const Color(0xFFFF6B6B),
    );
  }

  void _openNotificationsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }


}