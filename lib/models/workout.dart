class Workout {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String location;
  final DateTime dateTime;
  final DateTime createdAt;

  Workout({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.location,
    required this.dateTime,
    required this.createdAt,
  });

  // Convertir les données JSON de Supabase vers l'objet Workout
  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      location: map['location'] as String,
      dateTime: DateTime.parse(map['date_time']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  // Convertir l'objet Workout en Map pour l'envoyer à Supabase
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'location': location,
      'date_time': dateTime.toIso8601String(),
    };
  }
}