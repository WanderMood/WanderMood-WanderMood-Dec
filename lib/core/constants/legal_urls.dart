/// Public legal document URLs (privacy, terms, account deletion).
///
/// Hosted on the WanderMood landing deployment at `wandermood.com`.
class LegalUrls {
  LegalUrls._();

  /// Production legal pages on the WanderMood domain. The landing site serves
  /// per-locale pages under `/{locale}/privacy`, `/{locale}/terms`, and
  /// `/{locale}/account-deletion` (locales: en, nl, de, es, fr).
  static const String publicLegalBase = 'https://wandermood.com';

  static final Uri privacyPolicy =
      Uri.parse('$publicLegalBase/en/privacy');

  static final Uri termsOfService =
      Uri.parse('$publicLegalBase/en/terms');

  static final Uri accountDeletion =
      Uri.parse('$publicLegalBase/en/account-deletion');

  static const Set<String> _legalLocales = {'en', 'nl', 'de', 'es', 'fr'};

  static Uri privacyForLanguageCode(String languageCode) {
    final seg =
        _legalLocales.contains(languageCode) ? languageCode : 'en';
    return Uri.parse('$publicLegalBase/$seg/privacy');
  }

  static Uri termsForLanguageCode(String languageCode) {
    final seg =
        _legalLocales.contains(languageCode) ? languageCode : 'en';
    return Uri.parse('$publicLegalBase/$seg/terms');
  }
}
