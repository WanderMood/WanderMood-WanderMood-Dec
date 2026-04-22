import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wandermood/features/group_planning/presentation/share_sheet_origin.dart';
import '../models/place.dart';

class SharingService {
  static Future<void> sharePlace(Place place, {required BuildContext context}) async {
    try {
      final shareText = _buildShareText(place);
      final origin = sharePositionOriginForContext(context);
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Check out ${place.name}!',
          sharePositionOrigin: origin,
        ),
      );
    } catch (e) {
      print('Error sharing place: $e');
      rethrow;
    }
  }

  static String _buildShareText(Place place) {
    final buffer = StringBuffer();
    
    // Add place name and emoji
    buffer.write('${place.emoji ?? '📍'} ${place.name}\n\n');
    
    // Add rating if available
    if (place.rating > 0) {
      buffer.write('⭐ ${place.rating.toStringAsFixed(1)}/5\n\n');
    }
    
    // Add description if available
    if (place.description != null && place.description!.isNotEmpty) {
      buffer.write('${place.description!}\n\n');
    }
    
    // Add address
    buffer.write('📍 ${place.address}\n\n');
    
    // Add activities if available
    if (place.activities.isNotEmpty) {
      buffer.write('Activities: ${place.activities.take(3).join(', ')}\n\n');
    }
    
    // Add call to action
    buffer.write('Shared via WanderMood 🌟');
    
    return buffer.toString();
  }

  static Future<void> sharePlaceWithImage(
    Place place,
    String? imagePath, {
    required BuildContext context,
  }) async {
    try {
      final shareText = _buildShareText(place);
      final origin = sharePositionOriginForContext(context);
      if (imagePath != null) {
        await SharePlus.instance.share(
          ShareParams(
            text: shareText,
            subject: 'Check out ${place.name}!',
            sharePositionOrigin: origin,
            files: [XFile(imagePath)],
          ),
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            text: shareText,
            subject: 'Check out ${place.name}!',
            sharePositionOrigin: origin,
          ),
        );
      }
    } catch (e) {
      print('Error sharing place with image: $e');
      rethrow;
    }
  }
} 