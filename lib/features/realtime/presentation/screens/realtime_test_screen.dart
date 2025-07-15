import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../application/realtime_service.dart';
import '../../domain/models/realtime_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeTestScreen extends ConsumerStatefulWidget {
  const RealtimeTestScreen({super.key});

  @override
  ConsumerState<RealtimeTestScreen> createState() => _RealtimeTestScreenState();
}

class _RealtimeTestScreenState extends ConsumerState<RealtimeTestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  RealtimeEventType _selectedEventType = RealtimeEventType.postLike;
  bool _isSendingNotification = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Features Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Notifications', icon: Icon(Icons.notifications)),
            Tab(text: 'Live Updates', icon: Icon(Icons.update)),
            Tab(text: 'Presence', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsTab(),
          _buildLiveUpdatesTab(),
          _buildPresenceTab(),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    final notificationsAsync = ref.watch(realtimeServiceProvider);

    return Column(
      children: [
        // Send notification form
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Send Test Notification',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RealtimeEventType>(
                  value: _selectedEventType,
                  decoration: const InputDecoration(
                    labelText: 'Notification Type',
                    border: OutlineInputBorder(),
                  ),
                  items: RealtimeEventType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Text(type.icon),
                          const SizedBox(width: 8),
                          Text(type.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedEventType = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Notification title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Notification message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSendingNotification ? null : _sendTestNotification,
                  child: _isSendingNotification
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Test Notification'),
                ),
              ],
            ),
          ),
        ),

        // Notifications list
        Expanded(
          child: notificationsAsync.when(
            data: (notifications) => _buildNotificationsList(notifications),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Error: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(realtimeServiceProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsList(List<RealtimeEvent> notifications) {
    if (notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No notifications yet'),
            Text('Send a test notification to see it here'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: notification.isRead 
                  ? Colors.grey.shade300 
                  : Theme.of(context).primaryColor,
              child: Text(notification.type.icon),
            ),
            title: Text(notification.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.message),
                const SizedBox(height: 4),
                Text(
                  notification.timeAgo,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: notification.isRead
                ? const Icon(Icons.check, color: Colors.green)
                : IconButton(
                    icon: const Icon(Icons.mark_email_read),
                    onPressed: () => _markAsRead([notification.id]),
                  ),
            onTap: () => _showNotificationDetails(notification),
          ),
        );
      },
    );
  }

  Widget _buildLiveUpdatesTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.update, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Live Updates'),
          Text('Real-time database updates will appear here'),
        ],
      ),
    );
  }

  Widget _buildPresenceTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('User Presence'),
          Text('Online users and status will appear here'),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and message')),
      );
      return;
    }

    setState(() {
      _isSendingNotification = true;
    });

    try {
      final realtimeService = ref.read(realtimeServiceProvider.notifier);
      final user = Supabase.instance.client.auth.currentUser;
      
      if (user == null) {
        throw Exception('No authenticated user');
      }
      
      final notificationId = await realtimeService.sendNotification(
        targetUserId: user.id, // Send to self for testing
        type: _selectedEventType,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        data: {'testData': 'This is a test notification'},
        priority: _selectedEventType.defaultPriority,
      );

      if (notificationId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test notification sent!')),
        );
        
        // Clear form
        _titleController.clear();
        _messageController.clear();
      } else {
        throw Exception('Failed to send notification');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSendingNotification = false;
      });
    }
  }

  Future<void> _markAsRead(List<String> eventIds) async {
    try {
      final realtimeService = ref.read(realtimeServiceProvider.notifier);
      await realtimeService.markAsRead(eventIds);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking as read: $e')),
      );
    }
  }

  void _showNotificationDetails(RealtimeEvent notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${notification.type.displayName}'),
              const SizedBox(height: 8),
              Text('Message: ${notification.message}'),
              const SizedBox(height: 8),
              Text('Time: ${notification.timeAgo}'),
              const SizedBox(height: 8),
              Text('Read: ${notification.isRead ? 'Yes' : 'No'}'),
              const SizedBox(height: 16),
              Text(
                'Data:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  const JsonEncoder.withIndent('  ').convert(notification.data),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!notification.isRead)
            TextButton(
              onPressed: () {
                _markAsRead([notification.id]);
                Navigator.of(context).pop();
              },
              child: const Text('Mark as Read'),
            ),
        ],
      ),
    );
  }
} 