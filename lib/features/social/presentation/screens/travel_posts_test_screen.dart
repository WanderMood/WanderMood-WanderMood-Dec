import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/presentation/widgets/swirl_background.dart';
import '../../application/travel_post_provider.dart';
import '../../domain/models/travel_post.dart';

class TravelPostsTestScreen extends ConsumerStatefulWidget {
  const TravelPostsTestScreen({super.key});

  @override
  ConsumerState<TravelPostsTestScreen> createState() => _TravelPostsTestScreenState();
}

class _TravelPostsTestScreenState extends ConsumerState<TravelPostsTestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _imagePicker = ImagePicker();
  
  // Form controllers
  final _titleController = TextEditingController();
  final _storyController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _tipsController = TextEditingController();
  
  String _selectedMood = 'happy';
  String _selectedPrivacy = 'public';
  int? _rating;
  final List<String> _selectedActivities = [];
  final List<String> _tags = [];
  final List<String> _photoFiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _storyController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _tipsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Travel Posts Test',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Feed'),
              Tab(text: 'Create'),
              Tab(text: 'Trending'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFeedTab(),
            _buildCreateTab(),
            _buildTrendingTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTab() {
    final feedPosts = ref.watch(feedPostsProvider);
    
    return feedPosts.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.travel_explore, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No travel posts yet!',
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('Create Post'),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () => ref.read(feedPostsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) => _buildPostCard(posts[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text('Error: $error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(feedPostsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    final creationState = ref.watch(postCreationProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Travel Post',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Story
          TextField(
            controller: _storyController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Your story *',
              border: OutlineInputBorder(),
              hintText: 'Tell us about your travel experience...',
            ),
          ),
          const SizedBox(height: 16),
          
          // Location
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 16),
          
          // Mood selector
          Text('Mood', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: TravelPostConstants.moods.map((mood) {
              final isSelected = _selectedMood == mood;
              return GestureDetector(
                onTap: () => setState(() => _selectedMood = mood),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(mood),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          // Activities
          Text('Activities', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: TravelPostConstants.commonActivities.take(6).map((activity) {
              final isSelected = _selectedActivities.contains(activity);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedActivities.remove(activity);
                    } else {
                      _selectedActivities.add(activity);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(activity, style: const TextStyle(fontSize: 12)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          // Rating
          Text('Rating', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Icon(
                  index < (_rating ?? 0) ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          
          // Budget
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Budget spent (EUR)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.euro),
            ),
          ),
          const SizedBox(height: 32),
          
          // Travel tips
          TextField(
            controller: _tipsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Travel tips (optional)',
              border: OutlineInputBorder(),
              hintText: 'Share your tips for other travelers...',
            ),
          ),
          const SizedBox(height: 16),
          
          // Privacy
          Text('Privacy', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: TravelPostConstants.privacyLevels.map((privacy) {
              final isSelected = _selectedPrivacy == privacy;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPrivacy = privacy),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      privacy.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isSelected ? Colors.blue[800] : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          
          // Create button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: creationState.isLoading || _storyController.text.isEmpty
                  ? null
                  : _createPost,
              child: creationState.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create Post'),
            ),
          ),
          
          if (creationState.hasError) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Error: ${creationState.error}',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
          
          if (creationState.hasValue && creationState.value != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Post created successfully!',
                style: TextStyle(color: Colors.green.shade700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendingTab() {
    final trendingPosts = ref.watch(trendingPostsProvider);
    
    return trendingPosts.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Text(
              'No trending posts yet!',
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) => _buildPostCard(posts[index], showTrending: true),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildPostCard(TravelPost post, {bool showTrending = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  child: Text(post.userId.substring(0, 2).toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title ?? 'Travel Memory',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      if (post.location != null)
                        Text(
                          post.location!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (showTrending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Trending',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Mood
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '😊 ${post.mood}',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Story
            Text(post.story, style: GoogleFonts.poppins(fontSize: 14)),
            
            // Activities
            if (post.activities.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: post.activities.map((activity) => Chip(
                  label: Text(activity, style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.green.withOpacity(0.1),
                )).toList(),
              ),
            ],
            
            // Photos placeholder
            if (post.hasPhotos) ...[
              const SizedBox(height: 12),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo, size: 32, color: Colors.grey[600]),
                      Text(
                        '${post.photos.length} photo${post.photos.length > 1 ? 's' : ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Rating
            if (post.isRated) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  ...List.generate(5, (index) => Icon(
                    index < post.rating! ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  )),
                  const SizedBox(width: 8),
                  Text('${post.rating}/5'),
                ],
              ),
            ],
            
            // Budget
            if (post.hasBudget) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.euro, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    post.formattedBudget,
                    style: TextStyle(color: Colors.green[600]),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            const Divider(),
            
            // Stats
            Row(
              children: [
                Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${post.likesCount}'),
                const SizedBox(width: 16),
                Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${post.commentsCount}'),
                const SizedBox(width: 16),
                Icon(Icons.visibility_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${post.viewCount}'),
                const Spacer(),
                Text(
                  _formatDate(post.createdAt),
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _createPost() async {
    final postActions = ref.read(postActionsProvider);
    
    await postActions.createPost(
      title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      story: _storyController.text.trim(),
      mood: _selectedMood,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      activities: _selectedActivities,
      budgetSpent: _budgetController.text.trim().isEmpty ? null : double.tryParse(_budgetController.text.trim()),
      rating: _rating,
      travelTips: _tipsController.text.trim().isEmpty ? null : _tipsController.text.trim(),
      privacyLevel: _selectedPrivacy,
      photoFiles: _photoFiles,
    );
    
    // Clear form on success
    final result = ref.read(postCreationProvider);
    if (result.hasValue && result.value != null) {
      _titleController.clear();
      _storyController.clear();
      _locationController.clear();
      _budgetController.clear();
      _tipsController.clear();
      setState(() {
        _selectedMood = 'happy';
        _selectedPrivacy = 'public';
        _rating = null;
        _selectedActivities.clear();
        _tags.clear();
        _photoFiles.clear();
      });
      
      // Refresh feed and switch to feed tab
      await postActions.refreshFeed();
      _tabController.animateTo(0);
    }
  }
} 