import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/userModel.dart';

class Property extends Listing {
  String location;
  int numberOfRooms;
  List<String> amenities;
  List<String> propertyTags;
  List<Comment> comments;
  List<String> imageUrls;

  Property({
    required int id,
    required String title,
    required String description,
    required DateTime createdAt,
    required String userId,
    required double price,
    required bool isFavorite,
    required this.imageUrls,
    required this.propertyTags,
    required this.location,
    required this.numberOfRooms,
    required this.amenities,
    required this.comments,
  }) : super(
            type: ListingType.Property,
            id: id,
            location: location,
            isFavourite: isFavorite,
            price: price,
            title: title,
            description: description,
            createdAt: createdAt,
            userId: userId);

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toString(),
      'location': location,
      'numberOfRooms': numberOfRooms,
    };
  }
}

class Comment {
  User user;
  String comment;

  Comment({
    required this.user,
    required this.comment,
  });
}
