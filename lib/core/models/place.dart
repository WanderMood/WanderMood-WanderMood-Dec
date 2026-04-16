class Place {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final double? rating;
  final String? address;
  final double? lat;
  final double? lng;
  final List<String> types;
  final List<String> tags;
  final bool isOpen;
  final String? priceLevel;
  final String? phoneNumber;
  final String? website;

  Place({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.rating,
    this.address,
    this.lat,
    this.lng,
    this.types = const [],
    this.tags = const [],
    this.isOpen = true,
    this.priceLevel,
    this.phoneNumber,
    this.website,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      address: json['address'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      types: List<String>.from(json['types'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      isOpen: json['isOpen'] as bool? ?? true,
      priceLevel: json['priceLevel'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      website: json['website'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'address': address,
      'lat': lat,
      'lng': lng,
      'types': types,
      'tags': tags,
      'isOpen': isOpen,
      'priceLevel': priceLevel,
      'phoneNumber': phoneNumber,
      'website': website,
    };
  }

  Place copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    double? rating,
    String? address,
    double? lat,
    double? lng,
    List<String>? types,
    List<String>? tags,
    bool? isOpen,
    String? priceLevel,
    String? phoneNumber,
    String? website,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      types: types ?? this.types,
      tags: tags ?? this.tags,
      isOpen: isOpen ?? this.isOpen,
      priceLevel: priceLevel ?? this.priceLevel,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Place &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
} 