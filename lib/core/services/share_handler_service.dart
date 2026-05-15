import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wandermood/core/navigation/root_navigator_key.dart';
import 'package:wandermood/features/wishlist/presentation/widgets/place_save_bottom_sheet.dart';

class ShareHandlerService {
  ShareHandlerService._();

  static const _channel = MethodChannel('com.wandermood/share');

  static String? _pendingUrl;

  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'handleSharedUrl') {
        final args = call.arguments;
        final url = args is Map ? args['url'] as String? : null;
        if (url != null && url.isNotEmpty) {
          await handleIncomingShareUrl(url);
        }
      }
    });
  }

  /// iOS share extension / `wandermood://share` deep link entry point.
  static Future<void> handleIncomingShareUrl(String url) async {
    _pendingUrl = url;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _showPlaceSaveSheet(url);
  }

  /// Call after the first frame when the app shell is ready (cold start deep link).
  static void flushPendingShareIfAny() {
    final url = _pendingUrl;
    if (url == null || url.isEmpty) return;
    _pendingUrl = null;
    _showPlaceSaveSheet(url);
  }

  static void _showPlaceSaveSheet(String url) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      _pendingUrl = url;
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => PlaceSaveBottomSheet(url: url),
    );
  }
}
