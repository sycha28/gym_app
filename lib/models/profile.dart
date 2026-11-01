class Profile {
  final String id;
  final String? username;
  final String? location;
  final List<String>? favoriteSports;
  final DateTime createdAt;

  Profile({
    required this.id,
    this.username,
    this.location,
    this.favoriteSports,
    required this.createdAt,
  });

  // Convertir les données de Supabase (JSON) vers un objet Profile
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String?,
      location: map['location'] as String?,
      favoriteSports: map['favorite_sports'] != null
          ? List<String>.from(map['favorite_sports'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // Convertir l'objet Profile en Map pour l'envoyer à Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'location': location,
      'favorite_sports': favoriteSports,
    };
  }
}