import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/core/presentation/widgets/wm_toast.dart';
import 'package:wandermood/l10n/app_localizations.dart';

/// v2 notification sheet + list chrome
const Color _wmCream = Color(0xFFF5F0E8);
const Color _wmWhite = Color(0xFFFFFFFF);
const Color _wmParchment = Color(0xFFE8E2D8);
const Color _wmForest = Color(0xFF2A6049);
const Color _wmCharcoal = Color(0xFF1E1C18);
const Color _wmStone = Color(0xFF8C8780);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'All';
  
  final List<String> _filterOptions = ['All', 'Likes', 'Comments', 'Follows', 'Posts', 'Mentions'];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Notifications',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Color(0xFF2D3748)),
              onPressed: () => _showNotificationSettings(),
            ),
            IconButton(
              icon: const Icon(Icons.done_all, color: Color(0xFF2A6049)),
              onPressed: () => _markAllAsRead(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Filter tabs
            _buildFilterTabs(),
            
            // Notifications list
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Today section
                  SliverToBoxAdapter(
                    child: _buildSectionHeader('Today'),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final todayNotifications = _getTodayNotifications();
                        if (index >= todayNotifications.length) return null;
                        return _buildNotificationCard(todayNotifications[index], index);
                      },
                      childCount: _getTodayNotifications().length,
                    ),
                  ),
                  
                  // This week section
                  SliverToBoxAdapter(
                    child: _buildSectionHeader('This Week'),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final weekNotifications = _getThisWeekNotifications();
                        if (index >= weekNotifications.length) return null;
                        return _buildNotificationCard(weekNotifications[index], index + 100);
                      },
                      childCount: _getThisWeekNotifications().length,
                    ),
                  ),
                  
                  // Earlier section
                  SliverToBoxAdapter(
                    child: _buildSectionHeader('Earlier'),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final earlierNotifications = _getEarlierNotifications();
                        if (index >= earlierNotifications.length) return null;
                        return _buildNotificationCard(earlierNotifications[index], index + 200);
                      },
                      childCount: _getEarlierNotifications().length,
                    ),
                  ),
                  
                  // Bottom spacing
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((filter) => _buildFilterChip(filter)).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => _onFilterChanged(filter),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A6049) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2A6049) : Colors.grey[300]!,
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
          filter,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF2D3748),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final isUnread = notification['isUnread'] ?? false;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: isUnread ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isUnread ? const BorderSide(color: Color(0xFF2A6049), width: 1) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _onNotificationTapped(notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar/Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getNotificationColor(notification['type']),
                  ),
                  child: Center(
                    child: notification['type'] == 'user_action'
                        ? Text(
                            notification['userName']?[0]?.toUpperCase() ?? 'U',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _getNotificationIcon(notification['type']),
                            color: Colors.white,
                            size: 24,
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
                        notification['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            notification['time'],
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          const Spacer(),
                          if (notification['hasAction'] == true)
                            _buildActionButton(notification),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Unread indicator
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF2A6049),
                    ),
                  ),
                
                // More options
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 16, color: Colors.grey[400]),
                  onSelected: (value) => _onNotificationAction(notification, value),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(isUnread ? Icons.mark_email_read : Icons.mark_email_unread, size: 16),
                          const SizedBox(width: 8),
                          Text(isUnread ? 'Mark as read' : 'Mark as unread'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideX(begin: 0.1);
  }

  Widget _buildActionButton(Map<String, dynamic> notification) {
    final actionType = notification['actionType'];
    String buttonText = '';
    Color buttonColor = const Color(0xFF2A6049);
    
    switch (actionType) {
      case 'follow_back':
        buttonText = 'Follow Back';
        break;
      case 'view_post':
        buttonText = 'View Post';
        break;
      case 'reply':
        buttonText = 'Reply';
        break;
      case 'accept':
        buttonText = 'Accept';
        break;
      case 'view':
        buttonText = 'View';
        break;
      default:
        buttonText = 'View';
    }
    
    return ElevatedButton(
      onPressed: () => _handleNotificationAction(notification, actionType),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        buttonText,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'like':
        return Colors.red[400]!;
      case 'comment':
        return Colors.blue[400]!;
      case 'follow':
        return Colors.purple[400]!;
      case 'post':
        return Colors.orange[400]!;
      case 'mention':
        return Colors.teal[400]!;
      case 'user_action':
        return Colors.green[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'follow':
        return Icons.person_add;
      case 'post':
        return Icons.photo;
      case 'mention':
        return Icons.alternate_email;
      case 'system':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  List<Map<String, dynamic>> _getTodayNotifications() {
    return [
      {
        'type': 'user_action',
        'userName': 'Sarah Miller',
        'title': 'Sarah Miller liked your post',
        'message': 'Your "Hidden Café in Jordaan" post got a new like',
        'time': '2 hours ago',
        'isUnread': true,
        'hasAction': true,
        'actionType': 'view_post',
      },
      {
        'type': 'comment',
        'title': 'New comment on your post',
        'message': 'marco_explorer: "This place looks amazing! Adding to my list 📝"',
        'time': '4 hours ago',
        'isUnread': true,
        'hasAction': true,
        'actionType': 'reply',
      },
      {
        'type': 'follow',
        'title': 'luna_beachlover started following you',
        'message': 'You have a new follower who loves beach destinations',
        'time': '6 hours ago',
        'isUnread': false,
        'hasAction': true,
        'actionType': 'follow_back',
      },
      {
        'type': 'like',
        'title': '5 new likes on your story',
        'message': 'Your "Rotterdam Morning Run" story is getting love',
        'time': '8 hours ago',
        'isUnread': false,
        'hasAction': true,
        'actionType': 'view_post',
      },
    ];
  }

  List<Map<String, dynamic>> _getThisWeekNotifications() {
    return [
      {
        'type': 'mention',
        'title': 'You were mentioned in a post',
        'message': 'alex_travels mentioned you in "Best Travel Companions"',
        'time': '2 days ago',
        'isUnread': false,
        'hasAction': true,
        'actionType': 'view_post',
      },
      {
        'type': 'post',
        'title': 'Your post is trending',
        'message': 'Your "Hidden Gems in Utrecht" is trending with 47 likes',
        'time': '3 days ago',
        'isUnread': false,
        'hasAction': true,
        'actionType': 'view',
      },
      {
        'type': 'follow',
        'title': 'david_photographer started following you',
        'message': 'A photography enthusiast joined your travel circle',
        'time': '4 days ago',
        'isUnread': false,
        'hasAction': true,
        'actionType': 'follow_back',
      },
      {
        'type': 'comment',
        'title': 'New comment thread',
        'message': 'foodie_sara and 3 others are discussing your food post',
        'time': '5 days ago',
        'isUnread': false,
        'hasAction': true,
        'actionType': 'view_post',
      },
    ];
  }

  List<Map<String, dynamic>> _getEarlierNotifications() {
    return [
      {
        'type': 'system',
        'title': 'Welcome to WanderMood!',
        'message': 'Start sharing your travel moments and connect with fellow wanderers',
        'time': '2 weeks ago',
        'isUnread': false,
        'hasAction': false,
      },
      {
        'type': 'like',
        'title': 'Your first post got 12 likes',
        'message': 'Great start! Keep sharing your travel adventures',
        'time': '2 weeks ago',
        'isUnread': false,
        'hasAction': true,
        'actionType': 'view_post',
      },
      {
        'type': 'follow',
        'title': 'emma_wanderlust started following you',
        'message': 'Your first follower! Welcome to the community',
        'time': '2 weeks ago',
        'isUnread': false,
        'hasAction': true,
        'actionType': 'follow_back',
      },
    ];
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    
    showWanderMoodToast(
      context,
      message: 'Filtering by: $filter',
      backgroundColor: const Color(0xFF2A6049),
      duration: const Duration(seconds: 1),
    );
  }

  void _onNotificationTapped(Map<String, dynamic> notification) {
    // Mark as read
    setState(() {
      notification['isUnread'] = false;
    });
    
    // Handle different notification types
    final type = notification['type'];
    switch (type) {
      case 'user_action':
      case 'like':
      case 'comment':
        _openPost(notification);
        break;
      case 'follow':
        _openUserProfile(notification);
        break;
      case 'post':
        _openTrendingPost(notification);
        break;
      case 'mention':
        _openMentionPost(notification);
        break;
      default:
        _showNotificationDetails(notification);
    }
  }

  void _onNotificationAction(Map<String, dynamic> notification, String action) {
    switch (action) {
      case 'mark_read':
        setState(() {
          notification['isUnread'] = !(notification['isUnread'] ?? false);
        });
        break;
      case 'delete':
        _deleteNotification(notification);
        break;
    }
  }

  void _handleNotificationAction(Map<String, dynamic> notification, String actionType) {
    switch (actionType) {
      case 'follow_back':
        _followUser(notification);
        break;
      case 'view_post':
        _openPost(notification);
        break;
      case 'reply':
        _replyToComment(notification);
        break;
      case 'accept':
        _acceptRequest(notification);
        break;
      case 'view':
        _viewContent(notification);
        break;
    }
  }

  void _openPost(Map<String, dynamic> notification) {
    showWanderMoodToast(
      context,
      message: 'Opening post...',
      backgroundColor: const Color(0xFF2A6049),
    );
  }

  void _openUserProfile(Map<String, dynamic> notification) {
    showWanderMoodToast(
      context,
      message: 'Opening ${notification['userName'] ?? 'user'} profile...',
      backgroundColor: const Color(0xFF2A6049),
    );
  }

  void _openTrendingPost(Map<String, dynamic> notification) {
    showWanderMoodToast(
      context,
      message: 'Opening trending post...',
      backgroundColor: const Color(0xFF2A6049),
    );
  }

  void _openMentionPost(Map<String, dynamic> notification) {
    showWanderMoodToast(
      context,
      message: 'Opening mention...',
      backgroundColor: const Color(0xFF2A6049),
    );
  }

  void _followUser(Map<String, dynamic> notification) {
    showWanderMoodToast(
      context,
      message: 'Following ${notification['userName'] ?? 'user'}!',
      backgroundColor: const Color(0xFF2A6049),
    );
  }

  void _replyToComment(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Comment'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Write your reply...',
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
                message: 'Reply sent!',
                backgroundColor: const Color(0xFF2A6049),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _acceptRequest(Map<String, dynamic> notification) {
    showWanderMoodToast(
      context,
      message: 'Request accepted!',
      backgroundColor: const Color(0xFF2A6049),
    );
  }

  void _viewContent(Map<String, dynamic> notification) {
    showWanderMoodToast(
      context,
      message: 'Opening content...',
      backgroundColor: const Color(0xFF2A6049),
    );
  }

  void _deleteNotification(Map<String, dynamic> notification) {
    showWanderMoodToast(
      context,
      message: 'Notification deleted',
      backgroundColor: Colors.red,
      actionLabel: 'Undo',
      onAction: () {
        // Restore notification
      },
    );
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title']),
        content: Text(notification['message']),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    bool push = true;
    bool email = false;
    bool likesComments = true;
    bool newFollowers = true;
    bool mentions = true;
    bool travelUpdates = false;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        final bottomInset = MediaQuery.of(sheetContext).viewPadding.bottom;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget row(String title, bool value, ValueChanged<bool> onChanged) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: _wmWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _wmParchment, width: 0.5),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    switchTheme: SwitchThemeData(
                      thumbColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return _wmWhite;
                        }
                        return _wmStone;
                      }),
                      trackColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return _wmForest;
                        }
                        return _wmParchment;
                      }),
                      trackOutlineColor: WidgetStateProperty.all(_wmParchment),
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _wmCharcoal,
                      ),
                    ),
                    value: value,
                    onChanged: (v) {
                      setModalState(() => onChanged(v));
                      if (context.mounted) {
                        showWanderMoodToast(
                          context,
                          message: '$title ${v ? 'on' : 'off'}',
                        );
                      }
                    },
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 16),
              child: Container(
                decoration: const BoxDecoration(
                  color: _wmCream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: _wmParchment,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n?.settingsNotificationsTitle ?? 'Notifications',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _wmCharcoal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n?.settingsNotificationsSubtitle ?? 'Choose how we reach you',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _wmStone,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          (l10n?.notificationsMethodsTitle ?? 'How we notify you').toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                            color: _wmStone,
                          ),
                        ),
                        const SizedBox(height: 10),
                        row('Push notifications', push, (v) => push = v),
                        row('Email notifications', email, (v) => email = v),
                        const SizedBox(height: 16),
                        Text(
                          (l10n?.notificationsWhatToNotifyTitle ?? 'What to notify').toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                            color: _wmStone,
                          ),
                        ),
                        const SizedBox(height: 10),
                        row('Likes & comments', likesComments, (v) => likesComments = v),
                        row('New followers', newFollowers, (v) => newFollowers = v),
                        row('Mentions', mentions, (v) => mentions = v),
                        row('Travel updates', travelUpdates, (v) => travelUpdates = v),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _markAllAsRead() {
    showWanderMoodToast(
      context,
      message: 'All notifications marked as read',
      backgroundColor: const Color(0xFF2A6049),
    );
  }
} 