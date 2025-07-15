import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wandermood/features/social/domain/models/diary_entry.dart';
import 'package:wandermood/features/social/application/providers/diary_provider.dart';
import 'dart:io';

class CreateDiaryEntryScreen extends ConsumerStatefulWidget {
  const CreateDiaryEntryScreen({super.key});

  @override
  ConsumerState<CreateDiaryEntryScreen> createState() => _CreateDiaryEntryScreenState();
}

class _CreateDiaryEntryScreenState extends ConsumerState<CreateDiaryEntryScreen> {
  final _storyController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedMood;
  List<String> _selectedTags = [];
  bool _isSharing = false;
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _showLocationSuggestions = false;
  List<String> _locationSuggestions = [];

  final List<String> _availableMoods = [
    'Excited',
    'Peaceful',
    'Adventurous',
    'Romantic',
    'Curious',
    'Grateful',
    'Inspired',
    'Relaxed'
  ];

  final List<String> _availableTags = [
    'hiddenGem',
    'coffee',
    'food',
    'nature',
    'culture',
    'adventure',
    'peaceful',
    'romantic',
    'photography',
    'local',
    'museum',
    'outdoor',
    'indoor',
    'budget',
    'luxury',
    'family',
    'solo',
    'friends'
  ];

  final List<String> _popularPlaces = [
    'Markthal, Rotterdam',
    'Vondelpark, Amsterdam',
    'Kinderdijk Windmills',
    'Giethoorn Village',
    'Keukenhof Gardens',
    'Anne Frank House, Amsterdam',
    'Zaanse Schans',
    'Rijksmuseum, Amsterdam',
    'Cube Houses, Rotterdam',
    'Central Station, Rotterdam',
    'Dam Square, Amsterdam',
    'Edam Cheese Market',
    'Hoge Veluwe National Park',
    'Madurodam, The Hague',
    'Peace Palace, The Hague',
    'Bloemenmarkt, Amsterdam',
    'Erasmus Bridge, Rotterdam',
    'Jordaan District, Amsterdam',
    'Binnenhof, The Hague',
    'Leiden Historic Center'
  ];

  @override
  void initState() {
    super.initState();
    _locationController.addListener(_onLocationChanged);
  }

  void _onLocationChanged() {
    final query = _locationController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _showLocationSuggestions = false;
        _locationSuggestions = [];
      });
      return;
    }

    setState(() {
      _locationSuggestions = _popularPlaces
          .where((place) => place.toLowerCase().contains(query))
          .take(5)
          .toList();
      _showLocationSuggestions = _locationSuggestions.isNotEmpty;
    });
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)).toList());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to pick images: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFE55B4C),
        ),
      );
    }
  }

  Future<void> _pickSingleImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Photos',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPhotoOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickImages();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPhotoOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 80,
                      );
                      if (image != null) {
                        setState(() {
                          _selectedImages.add(File(image.path));
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF12B347),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF2D3748)),
            onPressed: () => context.pop(),
          ),
          title: Text(
            '✍️ New Diary Entry',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSharing ? null : _shareEntry,
              child: _isSharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Share',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF12B347),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mood Selection
              _buildSectionHeader('How was this experience?', '😊'),
              const SizedBox(height: 12),
              _buildMoodSelector(),
              
              const SizedBox(height: 32),
              
              // Location
              _buildSectionHeader('Where were you?', '📍'),
              const SizedBox(height: 12),
              _buildLocationField(),
              
              const SizedBox(height: 32),
              
              // Photos
              _buildSectionHeader('Photos', '📸'),
              const SizedBox(height: 12),
              _buildPhotoSection(),
              
              const SizedBox(height: 32),
              
              // Story
              _buildSectionHeader('Tell your story', '✨'),
              const SizedBox(height: 12),
              _buildStoryField(),
              
              const SizedBox(height: 32),
              
              // Tags
              _buildSectionHeader('Add tags', '🏷️'),
              const SizedBox(height: 12),
              _buildTagSelector(),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String emoji) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _availableMoods.map((mood) {
        final isSelected = _selectedMood == mood;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedMood = mood;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _getMoodColor(mood) : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? _getMoodColor(mood) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: _getMoodColor(mood).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Text(
              mood,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF718096),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationField() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: 'e.g. Markthal, Rotterdam',
              hintStyle: GoogleFonts.poppins(
                color: const Color(0xFFA0AEC0),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: _locationController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFFA0AEC0)),
                      onPressed: () {
                        _locationController.clear();
                        setState(() {
                          _showLocationSuggestions = false;
                        });
                      },
                    )
                  : null,
            ),
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: const Color(0xFF2D3748),
            ),
            onChanged: (value) {
              // Trigger rebuild to show/hide clear button
              setState(() {});
            },
          ),
        ),
        
        // Location suggestions dropdown
        if (_showLocationSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _locationSuggestions.map((place) {
                return InkWell(
                  onTap: () {
                    _locationController.text = place;
                    setState(() {
                      _showLocationSuggestions = false;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _locationSuggestions.last == place
                              ? Colors.transparent
                              : const Color(0xFFF7FAFC),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF12B347),
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            place,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.north_west,
                          color: Color(0xFFA0AEC0),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    if (_selectedImages.isEmpty) {
      return GestureDetector(
        onTap: _pickSingleImage,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF12B347),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.add_a_photo_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add photos',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF718096),
                  ),
                ),
                Text(
                  'Tap to select from gallery',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFA0AEC0),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                // Add more photos button
                return GestureDetector(
                  onTap: _pickSingleImage,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: Color(0xFF12B347),
                          size: 24,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Add more',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImages[index],
                        width: 100,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
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
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_selectedImages.length} photo${_selectedImages.length == 1 ? '' : 's'} selected',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _storyController,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: 'Share your story... What made this experience special? Any tips for fellow travelers?',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFFA0AEC0),
            fontSize: 14,
            height: 1.5,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: const Color(0xFF2D3748),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose tags that describe your experience:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF718096),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF12B347).withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF12B347)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Text(
                  '#$tag',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected 
                        ? const Color(0xFF12B347)
                        : const Color(0xFF718096),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'excited':
        return const Color(0xFFE55B4C);
      case 'peaceful':
        return const Color(0xFF4A90E2);
      case 'adventurous':
        return const Color(0xFFE17B47);
      case 'romantic':
        return const Color(0xFFE91E63);
      case 'curious':
        return const Color(0xFF9C27B0);
      case 'grateful':
        return const Color(0xFFFF9800);
      case 'inspired':
        return const Color(0xFF8BC34A);
      case 'relaxed':
        return const Color(0xFF52C41A);
      default:
        return const Color(0xFF12B347);
    }
  }

  void _shareEntry() async {
    if (_selectedMood == null || _storyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a mood and write your story',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFE55B4C),
        ),
      );
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      // Create the diary entry request
      final request = CreateDiaryEntryRequest(
        story: _storyController.text.trim(),
        mood: _selectedMood!,
        location: _locationController.text.trim().isNotEmpty 
            ? _locationController.text.trim() 
            : null,
        tags: _selectedTags,
        photos: _selectedImages.map((file) => file.path).toList(),
        isPublic: true, // Default to public
      );

      // Use the diary service to create the entry
      final diaryService = ref.read(diaryServiceProvider);
      await diaryService.createDiaryEntry(request);

      if (mounted) {
        setState(() {
          _isSharing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✨ Your diary entry has been shared!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFF12B347),
          ),
        );
        
        // Invalidate the diary feed to refresh the data
        ref.invalidate(diaryFeedProvider);
        ref.invalidate(friendsDiaryFeedProvider);
        ref.invalidate(userDiaryEntriesProvider);
        
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to share diary entry: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFFE55B4C),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _locationController.removeListener(_onLocationChanged);
    _storyController.dispose();
    _locationController.dispose();
    super.dispose();
  }
} 