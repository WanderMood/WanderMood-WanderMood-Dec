import 'package:flutter/material.dart';
import 'package:wandermood/core/utils/moody_toast.dart';

void showOfflineSnackBar(BuildContext context) {
  showMoodyToast(context, 'This feature needs an internet connection');
}
