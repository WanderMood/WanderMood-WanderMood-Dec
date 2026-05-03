import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/features/profile/domain/providers/profile_provider.dart';
import 'package:wandermood/features/profile/domain/providers/current_user_profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/l10n/app_localizations.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import '../widgets/edit_favorite_vibes.dart'
    show allVibes, localizedVibeDescription, localizedVibeLabelForStored, localizedVibeName;
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/core/constants/inclusion_preference_options.dart';
import 'package:wandermood/core/providers/preferences_provider.dart';
import 'package:wandermood/core/utils/profile_username.dart';

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

  DateTime? _dateOfBirth;
  String? _selectedGender; // 'woman' | 'man' | 'non_binary' | 'prefer_not_to_say'
  String? _profileImageUrl;
  String? _selectedImagePath;
  bool _isSaving = false;
  bool _isLoading = true;
  bool _hasChanges = false;
  
  EditScreenMode _currentMode = EditScreenMode.edit;
  List<String> _favoriteVibes = [];
  
  // Original data for comparison
  Map<String, dynamic> _originalData = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
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
          .select('travel_vibes, date_of_birth, gender')
          .eq('id', userId)
          .maybeSingle();

      final travelVibesRaw = profileResponse?['travel_vibes'] as List<dynamic>?;
      var vibes = _loadTravelVibes(travelVibesRaw);
      if (vibes.isEmpty &&
          currentProfile != null &&
          currentProfile.selectedMoods.isNotEmpty) {
        vibes = List<String>.from(currentProfile.selectedMoods);
      }
      
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
          _selectedGender = (profileResponse?['gender'] as String?) ??
              currentProfile?.gender;
          _profileImageUrl = avatarUrl;
          _favoriteVibes = vibes;
          
          _originalData = {
            'name': currentProfile?.fullName ?? '',
            'username': currentProfile?.username ?? '',
            'email': email,
            'bio': currentProfile?.bio ?? '',
            'dateOfBirth': dateOfBirth,
            'gender': _selectedGender,
            'imageUrl': avatarUrl,
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
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final hasChanges = 
        _nameController.text != (_originalData['name'] ?? '') ||
        _usernameController.text != (_originalData['username'] ?? '') ||
        _emailController.text != (_originalData['email'] ?? '') ||
        _bioController.text != (_originalData['bio'] ?? '') ||
        _dateOfBirth != _originalData['dateOfBirth'] ||
        _selectedGender != _originalData['gender'] ||
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

  List<String> _loadTravelVibes(List<dynamic>? rawVibes) {
    if (rawVibes == null || rawVibes.isEmpty) return [];
    final vibes = rawVibes
        .map((v) => v.toString())
        .where((v) => v.trim().isNotEmpty)
        .toList();

    const defaultVibes = ['Spontaneous', 'Social', 'Relaxed'];
    final isDefault =
        vibes.length == defaultVibes.length &&
            vibes.every(defaultVibes.contains);

    if (isDefault) return [];
    return vibes;
  }

  int? _calculateAge(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    var age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  String? _deriveAgeGroup(DateTime? dateOfBirth) {
    final age = _calculateAge(dateOfBirth);
    if (age == null) return null;
    if (age < 25) return 'young_adult';
    if (age <= 34) return 'twenties_thirties';
    if (age <= 44) return 'thirties_forties';
    return 'forties_plus';
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
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final maxDate = DateTime.now();
    var picked = _dateOfBirth ?? DateTime(maxDate.year - 18, maxDate.month, maxDate.day);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: Text(
                          MaterialLocalizations.of(sheetCtx).cancelButtonLabel,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: _wmStone,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          if (!mounted) return;
                          setState(() {
                            _dateOfBirth = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            );
                            _checkForChanges();
                          });
                        },
                        child: Text(
                          l10n.profileEditVibesDone,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: _wmForest,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 216,
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: GoogleFonts.poppins(
                            fontSize: 20,
                            color: const Color(0xFF1E1C18),
                          ),
                        ),
                      ),
                      child: Localizations.override(
                        context: context,
                        locale: locale,
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.date,
                          initialDateTime: picked.isAfter(maxDate)
                              ? maxDate
                              : (picked.isBefore(DateTime(1900))
                                  ? DateTime(1900)
                                  : picked),
                          minimumDate: DateTime(1900),
                          maximumDate: maxDate,
                          onDateTimeChanged: (d) {
                            picked = d;
                            setModal(() {});
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmDiscardUnsaved() async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.profileEditUnsavedTitle,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          l10n.profileEditUnsavedMessage,
          style: GoogleFonts.poppins(fontSize: 14, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileEditKeepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: Text(l10n.profileEditDiscard),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEditBack() async {
    final navigator = Navigator.of(context);
    if (!_hasChanges) {
      if (mounted) navigator.pop();
      return;
    }
    final discard = await _confirmDiscardUnsaved();
    if (discard == true && mounted) {
      navigator.pop();
    }
  }

  Future<void> _saveProfile() async {
    if (!_hasChanges) return;
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final normalizedUsername = normalizeProfileUsername(_usernameController.text);
      if (normalizedUsername == null || normalizedUsername.isEmpty) {
        if (mounted) {
          showWanderMoodToast(
            context,
            message: l10n.profileEditUsernameRequiredError,
            isError: true,
          );
        }
        return;
      }

      final takenRows = await supabase
          .from('profiles')
          .select('id')
          .ilike('username', normalizedUsername)
          .neq('id', userId)
          .limit(1);
      if ((takenRows as List<dynamic>).isNotEmpty) {
        if (mounted) {
          showWanderMoodToast(
            context,
            message: l10n.profileEditUsernameTakenError,
            isError: true,
          );
        }
        return;
      }

      String? imageUrl = _profileImageUrl;
      
      // Upload new image if selected
      if (_selectedImagePath != null) {
        imageUrl = await ref.read(profileProvider.notifier).uploadProfileImage(_selectedImagePath!);
      }

      // Update profile
      await ref.read(profileProvider.notifier).updateProfile(
        fullName: _nameController.text,
        username: normalizedUsername,
        imageUrl: imageUrl,
        dateOfBirth: _dateOfBirth,
        bio: _bioController.text,
      );

      // Update travel_vibes and gender in profiles table
      await supabase
          .from('profiles')
          .update({
            'travel_vibes': _favoriteVibes,
            'gender': _selectedGender,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Keep user_preferences in sync so the main profile (CurrentUserProfile)
      // immediately reflects updated vibes.
      Map<String, dynamic>? existingPrefsRow;
      try {
        existingPrefsRow = await supabase
            .from('user_preferences')
            .select('dietary_restrictions')
            .eq('user_id', userId)
            .maybeSingle();
      } catch (_) {}

      final rawDr = existingPrefsRow?['dietary_restrictions'];
      final dietaryList = rawDr is List
          ? normalizeInclusionPreferenceKeys(
              rawDr.map((e) => e.toString()).toList(),
            )
          : <String>[];

      await supabase
          .from('user_preferences')
          .upsert({
            'user_id': userId,
            'selected_moods': _favoriteVibes,
            'moods': _favoriteVibes,
            'age_group': _deriveAgeGroup(_dateOfBirth),
            'dietary_restrictions': dietaryList,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id');

      ref.invalidate(preferencesProvider);

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
        showWanderMoodToast(context, message: l10n.profileEditUpdated);
        Navigator.pop(context);
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        final msg = e.code == '23505'
            ? l10n.profileEditUsernameTakenError
            : l10n.profileEditUpdateFailed(e.message);
        showWanderMoodToast(context, message: msg, isError: true);
      }
    } catch (e) {
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _wmCream,
        body: const Center(child: CircularProgressIndicator(color: _wmForest)),
      );
    }

    if (_currentMode == EditScreenMode.photo) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          setState(() => _currentMode = EditScreenMode.edit);
        },
        child: _buildPhotoScreen(),
      );
    }

    if (_currentMode == EditScreenMode.vibes) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          setState(() => _currentMode = EditScreenMode.edit);
        },
        child: _buildVibesScreen(),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final discard = await _confirmDiscardUnsaved();
        if (!mounted) return;
        if (discard == true) {
          navigator.pop();
        }
      },
      child: _buildEditScreen(),
    );
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
                      onPressed: _handleEditBack,
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
                        onPressed:
                            (_hasChanges && !_isSaving) ? _saveProfile : null,
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
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  AppLocalizations.of(context)!.profileEditSave,
                                  style: GoogleFonts.poppins(
                                    color:
                                        _hasChanges ? Colors.white : _wmStone,
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
                                autocorrect: false,
                                textCapitalization: TextCapitalization.none,
                                validator: (value) {
                                  final n = normalizeProfileUsername(value ?? '');
                                  if (n == null || n.isEmpty) {
                                    return l10n.profileEditUsernameRequiredError;
                                  }
                                  if (!isValidProfileUsernameFormat(n)) {
                                    return l10n.profileEditUsernameFormatError;
                                  }
                                  return null;
                                },
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
                                      ? DateFormat.yMd(
                                          Localizations.localeOf(context).toString(),
                                        ).format(_dateOfBirth!)
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

                      // Gender
                      _buildGenderCard(),
                      const SizedBox(height: 12),

                      _buildInputCard(
                        label: l10n.prefSectionDietaryInclusion,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.profileEditDietaryInPreferencesHint,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _wmStone,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () =>
                                    context.push('/settings/preferences'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _wmForest,
                                  side: const BorderSide(
                                    color: _wmForest,
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  l10n.profileEditDietaryInPreferencesButton,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
    final ImageProvider? displayImage = _selectedImagePath != null
        ? FileImage(File(_selectedImagePath!))
        : (_profileImageUrl != null
            ? wmCachedNetworkImageProvider(_profileImageUrl!) as ImageProvider
            : null);
    
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
          GestureDetector(
            onTap: () => setState(() => _currentMode = EditScreenMode.photo),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: displayImage == null ? _wmForestTint : null,
                    border: Border.all(color: _wmForest, width: 2),
                    image: displayImage != null
                        ? DecorationImage(image: displayImage, fit: BoxFit.cover)
                        : null,
                  ),
                  child: displayImage == null
                      ? Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: _wmForest,
                            ),
                          ),
                        )
                      : null,
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.35),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.profileEditPhotoOverlayLabel,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  Widget _buildGenderCard() {
    final l10n = AppLocalizations.of(context)!;
    const options = [
      'man',
      'woman',
      'non_binary',
      'prefer_not_to_say',
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wmParchment, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileEditGenderLabel,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _wmStone,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Builder(builder: (context) {
                    final key = options[i];
                    final label = _genderLabel(l10n, key);
                    final isSelected = _selectedGender == key;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedGender = isSelected ? null : key;
                        });
                        _checkForChanges();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? _wmForest : _wmForestTint,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected ? _wmForest : _wmParchment,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected ? Colors.white : const Color(0xFF1E1C18),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _genderLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'woman': return l10n.profileGenderWoman;
      case 'man': return l10n.profileGenderMan;
      case 'non_binary': return l10n.profileGenderNonBinary;
      case 'prefer_not_to_say': return l10n.profileGenderPreferNotToSay;
      default: return key;
    }
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
                  localizedVibeLabelForStored(AppLocalizations.of(context)!, vibe),
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
                                  image: wmCachedNetworkImageProvider(_profileImageUrl!),
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
                      childAspectRatio: 0.72,
                    ),
                    itemCount: allVibes.length,
                    itemBuilder: (context, index) {
                      final vibe = allVibes[index];
                      final l10nV = AppLocalizations.of(context)!;
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
                                localizedVibeName(l10nV, vibe.id),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  localizedVibeDescription(l10nV, vibe.id),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    height: 1.25,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
