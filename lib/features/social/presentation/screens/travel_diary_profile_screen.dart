import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/diary_entry.dart';
import '../../domain/models/user_profile.dart';
import '../../application/providers/diary_provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TravelDiaryProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? username; // Optional for display in app bar

  const TravelDiaryProfileScreen({
    super.key,
    required this.userId,
    this.username,
  });

  @override
  ConsumerState<TravelDiaryProfileScreen> createState() => _TravelDiaryProfileScreenState();
}

class _TravelDiaryProfileScreenState extends ConsumerState<TravelDiaryProfileScreen> {
  bool _isFollowing = false;

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider(widget.userId));
    final userDiariesAsync = ref.watch(userDiaryEntriesProvider(widget.userId));
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isCurrentUser = currentUser != null && widget.userId == currentUser.id;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: userProfileAsync.when(
        data: (userProfile) => userProfile == null 
            ? _buildNotFoundScreen()
            : _buildProfileContent(userProfile, userDiariesAsync, isCurrentUser),
        loading: () => _buildLoadingScreen(),
        error: (_, __) => _buildErrorScreen(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
      ),
    );
  }

  Widget _buildNotFoundScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Profile not found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This travel diary might have been removed',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'An error occurred',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(UserProfile profile, AsyncValue<List<DiaryEntry>> userDiariesAsync, bool isCurrentUser) {
    return CustomScrollView(
      slivers: [
        // Custom App Bar
        SliverAppBar(
          expandedHeight: 0,
          floating: true,
          pinned: true,
          backgroundColor: AppTheme.cream,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
            onPressed: () => context.pop(),
          ),
          title: Text(
            widget.username ?? profile.username,
            style: GoogleFonts.poppins(
              color: const Color(0xFF2D3748),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          actions: [
            if (isCurrentUser)
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF2D3748)),
                onPressed: () => _editProfile(),
              ),
            if (!isCurrentUser)
              IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF2D3748)),
                onPressed: () => _showMoreOptions(context),
              ),
          ],
        ),

        // Profile Header
        SliverToBoxAdapter(
          child: _buildProfileHeader(profile, isCurrentUser),
        ),

        // Stats Section
        SliverToBoxAdapter(
          child: _buildStatsSection(profile, userDiariesAsync),
        ),

        // Interaction Buttons
        if (!isCurrentUser)
          SliverToBoxAdapter(
            child: _buildInteractionButtons(),
          ),

        // Write Button for current user
        if (isCurrentUser)
          SliverToBoxAdapter(
            child: _buildWriteButton(),
          ),

        // Entries Section
        SliverToBoxAdapter(
          child: _buildSectionHeader(),
        ),

        // Entries Content
        _buildEntriesContent(userDiariesAsync),
      ],
    );
  }

  Widget _buildProfileHeader(UserProfile profile, bool isCurrentUser) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _getMoodGradient(profile.travelStyle),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFF12B347),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    profile.username.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.username,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3748),
                            ),
                          ),
                        ),
                        _buildTravelStyleBadge(profile.travelStyle),
                      ],
                    ),
                    if (profile.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Color(0xFF8B7355),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              profile.location!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF718096),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Joined ${DateFormat('MMMM yyyy').format(profile.joinedAt)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF8B7355),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Bio
          if (profile.bio != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                profile.bio!,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: const Color(0xFF2D3748),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTravelStyleBadge(String style) {
    final (icon, color) = _getTravelStyleInfo(style);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            style,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(UserProfile profile, AsyncValue<List<DiaryEntry>> userDiariesAsync) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: userDiariesAsync.when(
        data: (entries) {
          final totalEntries = entries.length;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(totalEntries, 'Entries', Icons.book_outlined),
              _buildStatColumn(profile.totalFollowers, 'Followers', Icons.people_outline),
              _buildStatColumn(profile.totalFollowing, 'Following', Icons.person_add_outlined),
            ],
          );
        },
        loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
        error: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn(0, 'Entries', Icons.book_outlined),
            _buildStatColumn(profile.totalFollowers, 'Followers', Icons.people_outline),
            _buildStatColumn(profile.totalFollowing, 'Following', Icons.person_add_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(int value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: const Color(0xFF12B347),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF718096),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionButtons() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _toggleFollow(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? const Color(0xFF718096) : const Color(0xFF12B347),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isFollowing ? Icons.check : Icons.person_add,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isFollowing ? 'Following' : 'Follow',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _sendThankYou(),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF12B347),
                side: const BorderSide(color: Color(0xFF12B347), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_outline, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Thanks',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildWriteButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: ElevatedButton(
        onPressed: () => _navigateToWriteEntry(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF12B347),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit, size: 18),
            const SizedBox(width: 8),
            Text(
              'Write New Entry',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          const Icon(
            Icons.grid_view,
            size: 20,
            color: Color(0xFF2D3748),
          ),
          const SizedBox(width: 8),
          Text(
            'Entries',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesContent(AsyncValue<List<DiaryEntry>> userDiariesAsync) {
    return SliverFillRemaining(
      child: userDiariesAsync.when(
        data: (entries) => _buildEntriesGrid(entries),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildEntriesGrid([]),
      ),
    );
  }

  Widget _buildEntriesGrid(List<DiaryEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No entries yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Start sharing your travel stories!',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          return _buildEntryCard(entries[index]);
        },
      ),
    );
  }

  Widget _buildEntryCard(DiaryEntry entry) {
    return GestureDetector(
      onTap: () => _openEntry(entry),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Entry Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _getMoodColor(entry.mood).withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getMoodEmoji(entry.mood),
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.mood,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getMoodColor(entry.mood),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Entry Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title ?? 'Untitled',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3748),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (entry.location != null && entry.location!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Color(0xFF8B7355),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              entry.location!,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF718096),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d').format(entry.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF8B7355),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  List<Color> _getMoodGradient(String mood) {
    switch (mood.toLowerCase()) {
      case 'excited':
        return [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)];
      case 'peaceful':
        return [const Color(0xFF4ECDC4), const Color(0xFF44A08D)];
      case 'adventurous':
        return [const Color(0xFFFC466B), const Color(0xFF3F5EFB)];
      case 'romantic':
        return [const Color(0xFFFF8A80), const Color(0xFFFFAB91)];
      case 'curious':
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      default:
        return [const Color(0xFF12B347), const Color(0xFF4ECDC4)];
    }
  }

  (String, Color) _getTravelStyleInfo(String style) {
    switch (style.toLowerCase()) {
      case 'adventurous':
        return ('🏔️', const Color(0xFFFC466B));
      case 'peaceful':
        return ('🧘', const Color(0xFF4ECDC4));
      case 'cultural':
        return ('🏛️', const Color(0xFF667eea));
      case 'foodie':
        return ('🍜', const Color(0xFFFF6B6B));
      case 'social':
        return ('👥', const Color(0xFFFFE66D));
      default:
        return ('✨', const Color(0xFF12B347));
    }
  }

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
      default:
        return const Color(0xFF12B347);
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
      default:
        return '😊';
    }
  }

  // Action methods
  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFollowing ? 'Now following this traveler!' : 'Unfollowed',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: _isFollowing ? const Color(0xFF12B347) : const Color(0xFF718096),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _sendThankYou() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Thank you sent! 💕',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFFFC466B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _navigateToWriteEntry() {
    context.push('/diaries/create-entry');
  }

  void _openEntry(DiaryEntry entry) {
    // TODO: Navigate to detailed entry view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening "${entry.title ?? 'Untitled'}"...',
          style: GoogleFonts.poppins(),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
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
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text('Report', style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: Text('Block', style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _editProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileModal(),
    );
  }
}

class EditProfileModal extends StatefulWidget {
  @override
  _EditProfileModalState createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  String _selectedTravelStyle = 'Adventurous';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'wanderer_you');
    _bioController = TextEditingController(text: 'Exploring the Netherlands one mood at a time 🌍✨');
    _locationController = TextEditingController(text: 'Rotterdam, Netherlands');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Username cannot be empty',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFE55B4C),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF12B347),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _selectPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Photo selection coming soon!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF12B347),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: _isSaving ? const Color(0xFFE2E8F0) : const Color(0xFF718096),
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  'Edit Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                TextButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
                          ),
                        )
                      : Text(
                          'Save',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF12B347),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF12B347).withOpacity(0.1),
                            border: Border.all(
                              color: const Color(0xFF12B347),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'W',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF12B347),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _selectPhoto,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF12B347),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Username Field
                  _buildEditField('Username', _nameController, Icons.person_outline),
                  const SizedBox(height: 20),
                  
                  // Bio Field
                  _buildEditField('Bio', _bioController, Icons.edit_note, maxLines: 3),
                  const SizedBox(height: 20),
                  
                  // Location Field
                  _buildEditField('Location', _locationController, Icons.location_on_outlined),
                  const SizedBox(height: 20),
                  
                  // Travel Style Selection
                  Text(
                    'Travel Style',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Adventurous', 'Peaceful', 'Cultural', 'Foodie', 'Social'].map((style) {
                      final isSelected = style == _selectedTravelStyle;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTravelStyle = style;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF12B347) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF12B347) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            style,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF718096),
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
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          enabled: !_isSaving,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFF2D3748),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF12B347)),
            filled: true,
            fillColor: _isSaving ? const Color(0xFFF7FAFC).withOpacity(0.5) : const Color(0xFFF7FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF12B347)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
} 