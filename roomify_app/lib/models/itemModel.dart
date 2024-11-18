import 'package:intl/intl.dart';

enum ListingType {
  Marketplace,
  Property;
}

abstract class Listing {
  ListingType type;
  int id;
  String title;
  String? description; // Made optional
  DateTime createdAt;
  String userId; // Changed to String to match your DB schema
  String location;
  double price;
  bool isFavourite;

  Listing({
    required this.type,
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    required this.location,
    required this.price,
    required this.isFavourite,
    required this.userId,
  });

  String getListingTypeString() {
    return type.toString().split('.').last;
  }

  ListingType getListingTypeFromString(String typeString) {
    return ListingType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => ListingType.Marketplace,
    );
  }

  Map<String, dynamic> toJson();
}

class Item extends Listing {
  String? category;

  Item({
    required int id,
    required String title,
    String? description,
    DateTime? createdAt,
    required String userId,
    required double price,
    required String location,
    bool? isFavourite,
    this.category,
  }) : super(
          type: ListingType.Marketplace,
          id: id,
          location: location,
          price: price,
          title: title,
          description: description,
          createdAt: createdAt ?? DateTime.now(), // Default to current time
          isFavourite: isFavourite ?? false, // Default to false
          userId: userId,
        );

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Untitled',
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      userId: json['user_id'] ?? '', // Match DB column name
      price: (json['price'] ?? 0).toDouble(),
      location: json['location'] ?? 'Unknown',
      isFavourite: json['isFavorite'] ?? false,
      category: json['category'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_at': DateFormat('yyyy-MM-ddTHH:mm:ss').format(createdAt),
      'user_id': userId,
      'price': price,
      'location': location,
      'isFavorite': isFavourite,
      'category': category,
      'type': 'Marketplace', // Add type for database
    };
  }

  // Copy with method for immutability
  Item copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? createdAt,
    String? userId,
    double? price,
    String? location,
    bool? isFavourite,
    String? category,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      price: price ?? this.price,
      location: location ?? this.location,
      isFavourite: isFavourite ?? this.isFavourite,
      category: category ?? this.category,
    );
  }
}
