/// Fixed Supabase Auth user used for App Store review (`demo@wandermood.com`).
/// Keep in sync with the account you give Apple; UUID is stable per project user row.
const String kAppStoreDemoReviewUserId =
    '66615dcb-f227-4c96-82c2-965f5f9fcbdd';

const String kAppStoreDemoReviewEmail = 'demo@wandermood.com';

/// Demo / review login only — do not use for feature gating of real users.
bool isAppStoreDemoReviewAccount({
  required String userId,
  String? email,
}) {
  if (userId == kAppStoreDemoReviewUserId) return true;
  final e = email?.trim().toLowerCase();
  return e == kAppStoreDemoReviewEmail.toLowerCase();
}
