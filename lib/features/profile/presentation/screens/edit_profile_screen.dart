import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';
import 'package:wandermood/features/profile/domain/providers/current_user_profile_provider.dart';
import 'package:wandermood/features/places/application/places_service.dart';
import 'package:wandermood/features/places/domain/models/place.dart';
import 'package:wandermood/core/providers/user_location_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import '../widgets/edit_favorite_vibes.dart' show allVibes;
import 'dart:io';
import 'dart:async';

// WanderMood v2 — Edit Profile (Screen 12)
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmForestTint = Color(0xFFEBF3EE);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmStone = Color(0xFF8C8780);

enum EditScreenMode { edit, photo, vibes }

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  
  DateTime? _dateOfBirth;
  String? _profileImageUrl;
  String? _selectedImagePath;
  bool _isSaving = false;
  bool _isLoading = true;
  bool _hasChanges = false;
  
  EditScreenMode _currentMode = EditScreenMode.edit;
  List<String> _favoriteVibes = [];
  
  // Location autocomplete
  List<PlaceAutocomplete> _locationSuggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  
  // Original data for comparison
  Map<String, dynamic> _originalData = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
    _locationController.addListener(_onLocationChanged);
  }

  Future<void> _loadCurrentProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final userId = user?.id;
      
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Use currentUserProfileProvider - same source as profile screen (guarantees data consistency)
      final currentProfile = await ref.read(currentUserProfileProvider.future);
      
      // Fetch extra fields from profiles (date_of_birth, currently_exploring, travel_vibes)
      final profileResponse = await supabase
          .from('profiles')
          .select('travel_vibes, currently_exploring, date_of_birth')
          .eq('id', userId)
          .maybeSingle();

      final travelVibesRaw = profileResponse?['travel_vibes'];
      final List<String> travelVibes = travelVibesRaw is List
          ? travelVibesRaw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
          : (travelVibesRaw is String ? [travelVibesRaw] : <String>[]);
      
      // Prefer travel_vibes from profiles; fall back to selectedMoods from user_preferences
      final vibes = travelVibes.isNotEmpty ? travelVibes : (currentProfile?.selectedMoods ?? []);
      
      final dateOfBirthRaw = profileResponse?['date_of_birth'];
      final DateTime? dateOfBirth = dateOfBirthRaw != null
          ? (dateOfBirthRaw is String ? DateTime.tryParse(dateOfBirthRaw) : null)
          : null;
      
      // Email from auth (profiles may not have it); avatar from currentProfile (image_url or avatar_url)
      final email = user?.email ?? '';
      final avatarUrl = currentProfile?.avatarUrl;
      
      if (mounted) {
        setState(() {
          _nameController.text = currentProfile?.fullName ?? '';
          _usernameController.text = currentProfile?.username ?? '';
          _emailController.text = email;
          _bioController.text = currentProfile?.bio ?? '';
          _dateOfBirth = dateOfBirth;
          _profileImageUrl = avatarUrl;
          _locationController.text = profileResponse?['currently_exploring'] as String? ?? '';
          _favoriteVibes = vibes;
          
          _originalData = {
            'name': currentProfile?.fullName ?? '',
            'username': currentProfile?.username ?? '',
            'email': email,
            'bio': currentProfile?.bio ?? '',
            'dateOfBirth': dateOfBirth,
            'imageUrl': avatarUrl,
            'location': profileResponse?['currently_exploring'] as String? ?? '',
            'vibes': List<String>.from(_favoriteVibes),
          };
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _removeOverlay();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onLocationChanged() {
    _checkForChanges();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchLocationSuggestions();
    });
  }

  Future<void> _fetchLocationSuggestions() async {
    final query = _locationController.text.trim();
    
    if (query.isEmpty || query.length < 2) {
      setState(() {
        _locationSuggestions = [];
        _isLoadingSuggestions = false;
      });
      _removeOverlay();
      return;
    }

    setState(() => _isLoadingSuggestions = true);

    try {
      final placesService = ref.read(placesServiceProvider.notifier);

      // Use text-based autocomplete so cities like "Rotterdam" always appear,
      // regardless of current GPS radius.
      final suggestions = await placesService.getAutocomplete(query);

      if (mounted) {
        setState(() {
          _locationSuggestions = suggestions;
          _isLoadingSuggestions = false;
        });
        _showSuggestionsOverlay();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationSuggestions = [];
          _isLoadingSuggestions = false;
        });
        _removeOverlay();
      }
    }
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();
    
    if (_locationSuggestions.isEmpty) {
      return;
    }

    final overlay = Overlay.of(context);
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: renderBox.size.width - 48, // Match card padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, renderBox.size.height + 8),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isLoadingSuggestions
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _locationSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _locationSuggestions[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: _wmForest,
                            size: 20,
                          ),
                          title: Text(
                            suggestion.description,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                          ),
                          onTap: () {
                            _selectLocation(suggestion);
                          },
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _selectLocation(PlaceAutocomplete suggestion) {
    setState(() {
      _locationController.text = suggestion.description;
      _locationSuggestions = [];
    });
    _removeOverlay();
    _checkForChanges();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _checkForChanges() {
    final hasChanges = 
        _nameController.text != (_originalData['name'] ?? '') ||
        _usernameController.text != (_originalData['username'] ?? '') ||
        _emailController.text != (_originalData['email'] ?? '') ||
        _bioController.text != (_originalData['bio'] ?? '') ||
        _dateOfBirth != _originalData['dateOfBirth'] ||
        _locationController.text != (_originalData['location'] ?? '') ||
        _selectedImagePath != null ||
        !_listEquals(_favoriteVibes, _originalData['vibes'] ?? []);
    
    setState(() => _hasChanges = hasChanges);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!b.contains(a[i])) return false;
    }
    return true;
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
        _checkForChanges();
      });
    }
  }

  Future<void> _removePhoto() async {
    setState(() {
      _selectedImagePath = null;
      _profileImageUrl = null;
      _checkForChanges();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _wmForest,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
        _checkForChanges();
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_hasChanges) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      String? imageUrl = _profileImageUrl;
      
      // Upload new image if selected
      if (_selectedImagePath != null) {
        imageUrl = await ref.read(profileProvider.notifier).uploadProfileImage(_selectedImagePath!);
      }

      // Update profile
      await ref.read(profileProvider.notifier).updateProfile(
        fullName: _nameController.text,
        username: _usernameController.text,
        imageUrl: imageUrl,
        dateOfBirth: _dateOfBirth,
        bio: _bioController.text,
      );

      // Update location and travel_vibes in profiles table
      await supabase
          .from('profiles')
          .update({
            'currently_exploring': _locationController.text.isEmpty ? null : _locationController.text,
            'travel_vibes': _favoriteVibes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Keep user_preferences in sync so the main profile (CurrentUserProfile)
      // immediately reflects updated vibes.
      await supabase
          .from('user_preferences')
          .upsert({
            'user_id': userId,
            'selected_moods': _favoriteVibes,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');

      // Update email in auth if changed
      if (_emailController.text != _originalData['email']) {
        await supabase.auth.updateUser(
          UserAttributes(email: _emailController.text),
        );
      }

      // Refresh both legacy profile provider and the new current user profile
      // so all profile UIs stay in sync after editing.
      ref.invalidate(profileProvider);
      await ref.read(currentUserProfileProvider.notifier).refresh();

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showWanderMoodToast(context, message: l10n.profileEditUpdated);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        showWanderMoodToast(
          context,
          message: l10n.profileEditUpdateFailed(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _nameController.text = _originalData['name'] ?? '';
      _usernameController.text = _originalData['username'] ?? '';
      _emailController.text = _originalData['email'] ?? '';
      _bioController.text = _originalData['bio'] ?? '';
      _dateOfBirth = _originalData['dateOfBirth'];
      _locationController.text = _originalData['location'] ?? '';
      _favoriteVibes = List<String>.from(_originalData['vibes'] ?? []);
      _selectedImagePath = null;
      _hasChanges = false;
      _currentMode = EditScreenMode.edit;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _wmCream,
        body: const Center(child: CircularProgressIndicator(color: _wmForest)),
      );
    }

    // Photo Screen
    if (_currentMode == EditScreenMode.photo) {
      return _buildPhotoScreen();
    }

    // Vibes Screen
    if (_currentMode == EditScreenMode.vibes) {
      return _buildVibesScreen();
    }

    // Main Edit Screen
    return _buildEditScreen();
  }

  Widget _buildEditScreen() {
    final l10n = AppLocalizations.of(context)!;
    final profileState = ref.watch(profileProvider);
    
    return Scaffold(
      backgroundColor: _wmCream,
      body: profileState.when(
        data: (profile) => Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 12,
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Color(0xFF4B5563),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.profileEditTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        onPressed: _hasChanges ? _saveProfile : null,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _hasChanges ? _wmForest : _wmParchment,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.profileEditSave,
                            style: GoogleFonts.poppins(
                              color: _hasChanges ? Colors.white : _wmStone,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: _wmParchment),
            
            // Content
            Expanded(
              child: GestureDetector(
                onTap: () => _removeOverlay(),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      _removeOverlay();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Photo Section
                          _buildProfilePhotoCard(),
                          const SizedBox(height: 10),
                      
                      // Full Name
                      _buildInputCard(
                        label: l10n.profileEditNameLabel,
                        child: TextFormField(
                          controller: _nameController,
                          onChanged: (_) => _checkForChanges(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.profileEditNameHint,
                            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _wmParchment, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _wmParchment, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _wmForest, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Username
                      _buildInputCard(
                        label: l10n.profileEditUsernameLabel,
                        child: Row(
                          children: [
                            Text(
                              '@',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[400],
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _usernameController,
                                onChanged: (_) => _checkForChanges(),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                                decoration: InputDecoration(
                                  hintText: l10n.profileEditUsernameHint,
                                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: _wmParchment, width: 1.5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: _wmParchment, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: _wmForest, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Email
                      _buildInputCard(
                        label: l10n.profileEditEmailLabel,
                        child: Row(
                          children: [
                            const Icon(Icons.email_outlined, color: Color(0xFF9CA3AF), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                onChanged: (_) => _checkForChanges(),
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                                decoration: InputDecoration(
                                  hintText: l10n.profileEditEmailHint,
                                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: _wmParchment, width: 1.5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: _wmParchment, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: _wmForest, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Bio
                      _buildInputCard(
                        label: l10n.profileEditBioLabel,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _bioController,
                              onChanged: (_) => _checkForChanges(),
                              maxLines: 3,
                              maxLength: 150,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                              decoration: InputDecoration(
                                hintText: l10n.profileEditBioHint,
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _wmParchment, width: 1.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _wmParchment, width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _wmForest, width: 2),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                                counterStyle: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _wmStone,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Location with autocomplete
                      _buildLocationInputCard(),
                      const SizedBox(height: 12),
                      
                      // Birthday
                      _buildInputCard(
                        label: l10n.profileEditBirthdayLabel,
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, color: Color(0xFF9CA3AF), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _dateOfBirth != null
                                      ? DateFormat('yyyy-MM-dd').format(_dateOfBirth!)
                                      : l10n.profileEditSelectDate,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: _dateOfBirth != null ? Colors.grey[800] : Colors.grey[400],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Favorite Vibes
                      _buildFavoriteVibesCard(),
                      const SizedBox(height: 20), // Bottom padding
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: _wmForest),
        ),
        error: (error, stack) => Center(
          child: Text(
            AppLocalizations.of(context)!.profileEditErrorLoading(error.toString()),
            style: GoogleFonts.poppins(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoCard() {
    final displayImage = _selectedImagePath != null
        ? FileImage(File(_selectedImagePath!))
        : (_profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null) as ImageProvider?;
    
    final initial = _nameController.text.isNotEmpty
        ? _nameController.text[0].toUpperCase()
        : '?';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: displayImage == null ? _wmForestTint : null,
              shape: BoxShape.circle,
              border: displayImage == null
                  ? Border.all(color: _wmParchment, width: 1.5)
                  : null,
              image: displayImage != null
                  ? DecorationImage(image: displayImage, fit: BoxFit.cover)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: displayImage == null
                ? Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _wmForest,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.profileEditProfilePhoto,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.profileEditProfilePhotoTap,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _currentMode = EditScreenMode.photo),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _wmForestTint,
                shape: BoxShape.circle,
                border: Border.all(color: _wmParchment, width: 0.5),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: _wmForest,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildLocationInputCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.profileEditLocationLabel,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          CompositedTransformTarget(
            link: _layerLink,
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFF9CA3AF), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _locationController,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.profileEditLocationHint,
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _wmParchment, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _wmParchment, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _wmForest, width: 2),
                      ),
                      suffixIcon: _isLoadingSuggestions
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _wmForest,
                                ),
                              ),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onTap: () {
                      if (_locationController.text.isNotEmpty && _locationSuggestions.isNotEmpty) {
                        _showSuggestionsOverlay();
                      }
                    },
                    onChanged: (_) {
                      // _onLocationChanged will handle this via listener
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteVibesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: _wmForest, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.profileEditFavoriteVibesTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _currentMode = EditScreenMode.vibes),
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.profileEditFavoriteVibesEdit,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _wmForest,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: _wmForest,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _favoriteVibes.map((vibe) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _wmForestTint,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _wmParchment, width: 0.5),
                ),
                child: Text(
                  vibe,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _wmForest,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoScreen() {
    final l10n = AppLocalizations.of(context)!;
    final initial = _nameController.text.isNotEmpty
        ? _nameController.text[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: _wmCream,
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 16,
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF374151)),
                    onPressed: () => setState(() => _currentMode = EditScreenMode.edit),
                  ),
                  Expanded(
                    child: Text(
                      l10n.profileEditProfilePhoto,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
            ),
          ),
          Container(height: 1, color: _wmParchment),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Container(
                    width: 192,
                    height: 192,
                    decoration: BoxDecoration(
                      color: _selectedImagePath == null && _profileImageUrl == null
                          ? _wmForestTint
                          : null,
                      shape: BoxShape.circle,
                      border: _selectedImagePath == null && _profileImageUrl == null
                          ? Border.all(color: _wmParchment, width: 2)
                          : null,
                      image: _selectedImagePath != null
                          ? DecorationImage(
                              image: FileImage(File(_selectedImagePath!)),
                              fit: BoxFit.cover,
                            )
                          : (_profileImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_profileImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _selectedImagePath == null && _profileImageUrl == null
                        ? Center(
                            child: Text(
                              initial,
                              style: GoogleFonts.poppins(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: _wmForest,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 48),
                  
                  // Take Photo Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(fromCamera: true),
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      label: Text(
                        l10n.profileEditPhotoTake,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _wmForest,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Choose from Gallery Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(fromCamera: false),
                      icon: const Icon(Icons.photo_library_outlined, color: _wmForest, size: 20),
                      label: Text(
                        l10n.profileEditPhotoChoose,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _wmForest,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _wmForest, width: 1.5),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  
                  // Remove Photo Button (if photo exists)
                  if (_selectedImagePath != null || _profileImageUrl != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _removePhoto,
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        label: Text(
                          l10n.profileEditPhotoRemove,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibesScreen() {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _wmCream,
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 16,
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF374151)),
                    onPressed: () => setState(() => _currentMode = EditScreenMode.edit),
                  ),
                  Expanded(
                    child: Text(
                      l10n.profileEditVibesTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _currentMode = EditScreenMode.edit;
                          _checkForChanges();
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _wmForest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.profileEditVibesDone,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: _wmParchment),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileEditFavoriteVibesSubtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Vibes Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: allVibes.length,
                    itemBuilder: (context, index) {
                      final vibe = allVibes[index];
                      final isSelected = _favoriteVibes.any(
                        (v) => v.toLowerCase() == vibe.name.toLowerCase(),
                      );
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _favoriteVibes.removeWhere(
                                (v) => v.toLowerCase() == vibe.name.toLowerCase(),
                              );
                            } else {
                              if (_favoriteVibes.length < 5) {
                                _favoriteVibes.add(vibe.name);
                              }
                            }
                            _checkForChanges();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? _wmForestTint : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? _wmForest : _wmParchment,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _wmForest.withOpacity(0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: _wmForestTint,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? _wmForest : _wmParchment,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    vibe.emoji,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                vibe.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (isSelected) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: _wmForest,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
