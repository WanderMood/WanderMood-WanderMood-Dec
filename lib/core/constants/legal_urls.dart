/// Public legal document URLs (privacy, terms, account deletion).
///
/// Hosted on the WanderMood landing deployment. When [publicLegalBase] is also
/// served at `wandermood.com`, you can switch the base to that domain.
class LegalUrls {
  LegalUrls._();

  /// Production legal pages (Vercel). Change to `https://wandermood.com` when
  /// DNS points the domain at this deployment.
  static const String publicLegalBase =
      'https://wandermood-landing.vercel.app';

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
