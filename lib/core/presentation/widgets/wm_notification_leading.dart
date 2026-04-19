import 'package:flutter/material.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';
import 'package:wandermood/features/realtime/domain/models/realtime_event.dart';

/// Leading slot for [WmNotificationCard]: sender photo when available, otherwise
/// the same [RealtimeEventType] emoji as rows without a sender (consistent iconography).
class WmNotificationLeading extends StatelessWidget {
  const WmNotificationLeading({
    super.key,
    required this.event,
    this.senderAvatarUrl,
    this.showSenderAvatar = false,
  });

  final RealtimeEvent event;
  final String? senderAvatarUrl;
  final bool showSenderAvatar;

  static const TextStyle _emojiStyle = TextStyle(fontSize: 16);

  Widget _typeEmoji() => Text(event.type.icon, style: _emojiStyle);

  @override
  Widget build(BuildContext context) {
    final url = senderAvatarUrl?.trim();
    if (showSenderAvatar && url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 36,
          height: 36,
          child: WmNetworkImage(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _typeEmoji(),
          ),
        ),
      );
    }
    return _typeEmoji();
  }
}
