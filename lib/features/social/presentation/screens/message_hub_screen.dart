import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:wandermood/features/social/domain/models/social_post.dart';
import 'package:wandermood/features/social/domain/providers/social_providers.dart';

// Provider for mock conversations
final mockConversationsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final profiles = ref.watch(socialProfilesProvider);
  
  return profiles.map((profile) {
    final randomTimestamp = DateTime.now().subtract(
      Duration(minutes: (profile.id.hashCode % 500) + 5)
    );
    
    final messages = [
      'Hi there! How are you doing?',
      'The weather is amazing today!',
      'Have you seen the new museum exhibition?',
      "I'm planning to visit Amsterdam next weekend.",
      'Check out this amazing place I discovered!',
      'Any recommendations for hikes near Eindhoven?',
      'Thanks for sharing your travel tips!',
      'The festival was incredible!',
    ];
    
    return {
      'profile': profile,
      'lastMessage': messages[profile.id.hashCode % messages.length],
      'timestamp': randomTimestamp,
      'unread': profile.id.hashCode % 3 == 0, // Some conversations are unread
    };
  }).toList();
});

class MessageHubScreen extends ConsumerStatefulWidget {
  const MessageHubScreen({super.key});

  @override
  ConsumerState<MessageHubScreen> createState() => _MessageHubScreenState();
}

class _MessageHubScreenState extends ConsumerState<MessageHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  String _getTimeString(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(mockConversationsProvider);
    
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Messages',
            style: GoogleFonts.museoModerno(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF12B347),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF12B347)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.edit_square,
                color: Color(0xFF12B347),
                size: 24,
              ),
              onPressed: () {
                // Open new message composer
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New message feature coming soon!')),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search messages',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            
            // Conversation List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  final profile = conversation['profile'] as SocialProfile;
                  final lastMessage = conversation['lastMessage'] as String;
                  final timestamp = conversation['timestamp'] as DateTime;
                  final isUnread = conversation['unread'] as bool;
                  
                  return InkWell(
                    onTap: () {
                      // Navigate to conversation detail
                      _openConversation(profile);
                    },
                    splashColor: Colors.grey.withOpacity(0.1),
                    highlightColor: Colors.grey.withOpacity(0.05),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isUnread ? const Color(0xFF12B347).withOpacity(0.05) : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Profile Image
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: NetworkImage(profile.avatar),
                              ),
                              if (isUnread)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF12B347),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          
                          // Message Preview
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      profile.fullName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      _getTimeString(timestamp),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: isUnread ? const Color(0xFF12B347) : Colors.grey,
                                        fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lastMessage,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: isUnread ? Colors.black87 : Colors.grey.shade600,
                                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
            ),
          ],
        ),
      ),
    );
  }
  
  void _openConversation(SocialProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(profile: profile),
      ),
    );
  }
}

// Chat Detail Screen
class ChatDetailScreen extends ConsumerStatefulWidget {
  final SocialProfile profile;
  
  const ChatDetailScreen({super.key, required this.profile});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
  }
  
  Future<void> _loadMessages() async {
    // Simulate loading messages
    await Future.delayed(const Duration(seconds: 1));
    
    // Generate mock messages
    final List<String> messageTexts = [
      'Hi there!',
      'How are you doing?',
      'I loved the photos from your trip!',
      'Have you been to the new café near the central station?',
      'The weather is perfect for hiking today.',
      'Are you planning any trips this summer?',
      "I'll be visiting Amsterdam next weekend, any recommendations?",
      'Check out this amazing place I discovered yesterday!',
      'Did you see the festival announcement?',
      'Thanks for your travel tips, they were super helpful!',
    ];
    
    // Create some mock messages, alternating between sent and received
    final mockMessages = List.generate(10, (index) {
      final isMe = index % 2 == 0;
      final message = messageTexts[(index + widget.profile.id.hashCode) % messageTexts.length];
      final timeOffset = (10 - index) * 10; // Older messages are further back in time
      
      return {
        'text': message,
        'isMe': isMe,
        'timestamp': DateTime.now().subtract(Duration(minutes: timeOffset)),
      };
    });
    
    setState(() {
      _messages.addAll(mockMessages);
      _isLoading = false;
    });
    
    // Scroll to bottom after messages are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({
        'text': _messageController.text.trim(),
        'isMe': true,
        'timestamp': DateTime.now(),
      });
      
      _messageController.clear();
    });
    
    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    
    // Simulate received message
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': "Thanks for your message! I'll get back to you soon.",
            'isMe': false,
            'timestamp': DateTime.now(),
          });
        });
        
        // Scroll to bottom after receiving
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });
  }
  
  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF12B347)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(widget.profile.avatar),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.profile.fullName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Online',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF12B347),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.call,
              color: Color(0xFF12B347),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.videocam,
              color: Color(0xFF12B347),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF12B347)),
              ),
            )
          : Column(
              children: [
                // Messages List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message['isMe'] as bool;
                      final text = message['text'] as String;
                      final timestamp = message['timestamp'] as DateTime;
                      
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF12B347) : Colors.white,
                            borderRadius: BorderRadius.circular(20).copyWith(
                              bottomRight: isMe ? const Radius.circular(0) : null,
                              bottomLeft: !isMe ? const Radius.circular(0) : null,
                            ),
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
                              Text(
                                text,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: isMe ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(timestamp),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: isMe ? Colors.white70 : Colors.black54,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Message Input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.photo,
                            color: Color(0xFF12B347),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Photo sharing coming soon!')),
                            );
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: const Color(0xFF12B347),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: _sendMessage,
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
} 