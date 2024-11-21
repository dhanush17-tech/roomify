enum ListingType { PROPERTY, MARKETPLACE }

class Property {
  final int? id;
  final String title;
  final String description;
  final String location;
  final double price;
  final int numberOfBedrooms;
  final int numberOfBathrooms;
  final int maxOccupancy;
  final ListingType type;
  final List<String> amenities;
  final List<String> categories;
  final List<String> imageUrls;
  final DateTime createdAt;

  Property({
    this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.price,
    required this.numberOfBedrooms,
    required this.numberOfBathrooms,
    required this.maxOccupancy,
    required this.type,
    required this.amenities,
    required this.categories,
    this.imageUrls = const [],
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'location': location,
        'price': price,
        'numberOfBedrooms': numberOfBedrooms,
        'numberOfBathrooms': numberOfBathrooms,
        'maxOccupancy': maxOccupancy,
        'type': type.toString().split('.').last,
        'amenities': amenities,
        'categories': categories
      };

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      price: json['price'].toDouble(),
      numberOfBedrooms: json['number_of_bedrooms'],
      numberOfBathrooms: json['number_of_bathrooms'],
      maxOccupancy: json['max_occupancy'],
      type: ListingType.PROPERTY,
      amenities: List<String>.from(json['amenities'] ?? []),
      categories: List<String>.from(json['categories'] ?? []),
      imageUrls: List<String>.from(json['images'] ?? []),
    );
  }
}

enum PropertyCategory {
  Apartment,
  Studio,
  SharedHouse,
  PrivateResidence,
  RoomForRent,
  Hostel,
  StudentHousing,
  Condo,
  Townhouse,
  Duplex
}

extension PropertyCategoryExtension on PropertyCategory {
  String get displayName {
    return this
        .toString()
        .split('.')
        .last
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim();
  }
}
