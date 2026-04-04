/// Central caps for paid API usage (Moody / OpenAI via Edge, etc.).
///
/// Premium users skip client-side chat caps (see [AiChatQuotaService]).
/// Tune these as you ship real IAP and measure Edge costs.
class ApiUsageLimits {
  ApiUsageLimits._();

  /// Successful Moody `chat` edge invocations per UTC day — signed-in free tier.
  static const int freeTierMoodyChatsPerDay = 50;

  /// Same, for guests (no Supabase session) — per device install.
  static const int guestMoodyChatsPerDay = 15;
}
