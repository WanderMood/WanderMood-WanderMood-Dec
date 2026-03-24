import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class TravelerProfileScreen extends StatefulWidget {
  final Map<String, dynamic> traveler;

  const TravelerProfileScreen({
    Key? key,
    required this.traveler,
  }) : super(key: key);

  @override
  State<TravelerProfileScreen> createState() => _TravelerProfileScreenState();
}

class _TravelerProfileScreenState extends State<TravelerProfileScreen> {
  bool _isFollowing = false;

  @override
  Widget build(BuildContext context) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2A6049)),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFF2A6049)),
              onPressed: () => _showMoreOptions(),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '${widget.traveler['name']}\'s Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2A6049),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),
                
                const SizedBox(height: 20),
                
                // Profile Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Avatar with Online Status
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: _getTravelerColor(widget.traveler['name']),
                                child: Text(
                                  widget.traveler['name'][0].toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              
                              // Online status indicator
                              if (widget.traveler['isOnline'] == true)
                                Positioned(
                                  right: 4,
                                  bottom: 4,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A6049),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Name and Age
                          Text(
                            '${widget.traveler['name']}, ${widget.traveler['age']}',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          // Travel Style Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A6049),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.traveler['travelStyle'],
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Location
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.traveler['location'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '• ${widget.traveler['distance']} km away',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Bio
                          Text(
                            widget.traveler['bio'],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Mutual Friends
                          if (widget.traveler['mutualFriends'] > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A6049).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF2A6049).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '${widget.traveler['mutualFriends']} mutual friend${widget.traveler['mutualFriends'] > 1 ? 's' : ''}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2A6049),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 16),
                
                // Social Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '${_getPostCount()}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Posts',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.grey[300],
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${_getFollowerCount()}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Followers',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                height: 40,
                                width: 1,
                                color: Colors.grey[300],
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${_getFollowingCount()}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Following',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isFollowing = !_isFollowing;
                                    });
                                    showWanderMoodToast(
                                      context,
                                      message: _isFollowing
                                          ? 'Following ${widget.traveler['name']}'
                                          : 'Unfollowed ${widget.traveler['name']}',
                                      backgroundColor: const Color(0xFF2A6049),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isFollowing 
                                        ? Colors.grey[400] 
                                        : const Color(0xFF2A6049),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    _isFollowing ? 'Following' : 'Follow',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _sendMessage(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2A6049),
                                    side: const BorderSide(color: Color(0xFF2A6049)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    'Message',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Travel Interests
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Travel Interests',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _getTravelInterests().map((interest) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A6049).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF2A6049).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    interest,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2A6049),
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 16),
                
                // Recent Activity Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Activity',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._getRecentActivity().map((activity) => _buildActivityItem(activity)),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 1000.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2A6049).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity['icon'],
              color: const Color(0xFF2A6049),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                Text(
                  activity['subtitle'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity['time'],
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTravelerColor(String name) {
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

  List<String> _getTravelInterests() {
    final interests = {
      'Adventure Seekers': ['Hiking', 'Rock Climbing', 'Extreme Sports'],
      'Culture Explorers': ['Museums', 'History', 'Art Galleries'],
      'Beach Lovers': ['Surfing', 'Diving', 'Beach Volleyball'],
      'Solo Wanderers': ['Backpacking', 'Digital Nomad', 'Hostels'],
      'Food Enthusiasts': ['Local Cuisine', 'Street Food', 'Cooking Classes'],
      'Photography Lovers': ['Landscape', 'Street Photography', 'Portraits'],
    };
    return interests[widget.traveler['travelStyle']] ?? ['Travel', 'Adventure'];
  }

  int _getPostCount() => 12;
  int _getFollowerCount() => 156;
  int _getFollowingCount() => 89;

  List<Map<String, dynamic>> _getRecentActivity() {
    return [
      {
        'icon': Icons.photo_camera,
        'title': 'Shared a new photo',
        'subtitle': 'Beautiful sunset at Kinderdijk',
        'time': '2h ago',
      },
      {
        'icon': Icons.favorite,
        'title': 'Liked your post',
        'subtitle': 'Rotterdam street art discovery',
        'time': '1d ago',
      },
      {
        'icon': Icons.location_on,
        'title': 'Checked in',
        'subtitle': 'Markthal Rotterdam',
        'time': '3d ago',
      },
      {
        'icon': Icons.comment,
        'title': 'Left a comment',
        'subtitle': 'Great travel tip about Utrecht!',
        'time': '5d ago',
      },
    ];
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report),
              title: Text(AppLocalizations.of(context)!.socialReportUser),
              onTap: () {
                Navigator.pop(context);
                _reportUser();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(AppLocalizations.of(context)!.socialBlockUser),
              onTap: () {
                Navigator.pop(context);
                _blockUser();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(AppLocalizations.of(context)!.socialShareProfile),
              onTap: () {
                Navigator.pop(context);
                _shareProfile();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!
              .socialMessageTraveler((widget.traveler['name'] ?? '').toString()),
        ),
        content: TextField(
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.socialWriteMessageHint,
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showWanderMoodToast(
                context,
                message: AppLocalizations.of(context)!.socialMessageSentTo(
                  (widget.traveler['name'] ?? '').toString(),
                ),
                backgroundColor: const Color(0xFF2A6049),
              );
            },
            child: Text(AppLocalizations.of(context)!.socialSend),
          ),
        ],
      ),
    );
  }

  void _reportUser() {
    showWanderMoodToast(
      context,
      message:
          AppLocalizations.of(context)!.socialUserReportedThankYou,
      backgroundColor: const Color(0xFFFF6B6B),
    );
  }

  void _blockUser() {
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!.socialUserBlocked(
        (widget.traveler['name'] ?? '').toString(),
      ),
      backgroundColor: const Color(0xFF718096),
    );
  }

  void _shareProfile() {
    showWanderMoodToast(
      context,
      message: AppLocalizations.of(context)!.socialProfileShared(
        (widget.traveler['name'] ?? '').toString(),
      ),
      backgroundColor: const Color(0xFF2A6049),
    );
  }
} 