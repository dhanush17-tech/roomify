abstract class Suggestion {
  String get displayName;
  String get placeName;
}

class LocationSuggestion implements Suggestion {
  final String id;
  final String name;
  final String fullName;
  final String type;
  final List<double> coordinates;
  final String? context;

  LocationSuggestion({
    required this.id,
    required this.name,
    required this.fullName,
    required this.type,
    required this.coordinates,
    this.context,
  });

  @override
  String get displayName => name;

  @override
  String get placeName => fullName;

  double get latitude => coordinates[1];
  double get longitude => coordinates[0];

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      id: json['id'] as String,
      name: json['text'] as String,
      fullName: json['place_name'] as String,
      type: json['place_type'][0] as String,
      coordinates: List<double>.from(json['center']),
      context: json['context']?.map((c) => c['text']).join(', '),
    );
  }
}

class PropertySuggestion implements Suggestion {
  final String id;
  final String title;
  final String? location;

  PropertySuggestion({
    required this.id,
    required this.title,
    this.location,
  });

  @override
  String get displayName => title;

  @override
  String get placeName => location != null ? '$title ($location)' : title;
}
