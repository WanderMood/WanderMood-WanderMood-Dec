/// Model for GetYourGuide affiliate links stored in Supabase.
class GygLink {
  final String destination;
  final String type;
  final String url;

  const GygLink({
    required this.destination,
    required this.type,
    required this.url,
  });

  factory GygLink.fromJson(Map<String, dynamic> json) {
    return GygLink(
      destination: json['destination'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'destination': destination,
        'type': type,
        'url': url,
      };
}
