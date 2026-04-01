import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] in the external browser. Does not rely on [canLaunchUrl], which
/// often returns false on iOS for https and causes false "link broken" UX.
Future<bool> launchExternalLegalUrl(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
