import 'package:intl/intl.dart';
import 'package:roomify_app/models/userModel.dart';

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
  User? user;
  String location;
  int price;
  bool isFavourite;
  double? latitude;
  double? longitude;

  Listing({
    required this.type,
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    required this.location,
    required this.price,
    required this.isFavourite,
    required this.user,
    this.latitude = 0.0,
    this.longitude = 0.0,
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
    User? user,
    required int price,
    required String location,
    bool? isFavourite,
    double? latitude,
    double? longitude,
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
            user: user,
            latitude: latitude,
            longitude: longitude);

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      // user: User.fromJson(json["user"] as Map<String, dynamic>),
      price: json['price'],
      location: json['location'],
      isFavourite: json['isFavorite'],
      category: json['category'],
      longitude: json["longitude"] != null
          ? double.tryParse(json["longitude"].toString()) ??
              double.tryParse(int.parse(json["longitude"]).toString()) ??
              0.0
          : 0.0,
      latitude: json["latitude"] != null
          ? double.tryParse(json["latitude"].toString()) ??
              double.tryParse(int.parse(json["latitude"]).toString()) ??
              0.0
          : 0.0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_at': DateFormat('yyyy-MM-ddTHH:mm:ss').format(createdAt),
      'user': user,
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
    int? price,
    String? location,
    bool? isFavourite,
    String? category,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
      price: price ?? this.price,
      location: location ?? this.location,
      isFavourite: isFavourite ?? this.isFavourite,
      category: category ?? this.category,
    );
  }
}
