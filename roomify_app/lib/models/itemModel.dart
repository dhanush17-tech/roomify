import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/models/userModel.dart';

enum ListingType {
  Marketplace,
  Property;
}

enum ReportStatus { pending, resolved, rejected }

class Report {
  final int id;
  final String reason;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      reason: json['reason'],
      status: ReportStatus.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() ==
            json['status'].toLowerCase(),
        orElse: () => ReportStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reason': reason,
        'status': status.toString().split('.').last.toLowerCase(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class Listing {
  ListingType type;
  int id;
  String title;
  String? description; // Made optional
  DateTime createdAt;
  User? user;
  String location;
  int price;
  bool isFavorite;
  double? latitude;
  double? longitude;
  List<String> imageUrls;
  Property? property;
  MarketplaceItem? marketplaceItem;
  final bool hasActiveReport;
  final List<Report> reports;

  Listing({
    required this.type,
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    required this.location,
    required this.price,
    required this.isFavorite,
    required this.user,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.property,
    this.marketplaceItem,
    required this.imageUrls,
    this.hasActiveReport = false,
    this.reports = const [],
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

  Map<String, dynamic> toJson() {
    return {
      'type': getListingTypeString(),
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'user': user?.toJson(),
      'location': location,
      'price': price,
      'isFavorite': isFavorite,
      if (property != null) 'property': property?.toJson(),
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls,
      'moveInDate': property?.moveInDate,
      'moveOutDate': property?.moveOutDate,
      'floorPlans':
          property?.floorPlans?.map((floorPlan) => floorPlan.toJson()).toList(),
      'reportStatus': {
        'hasActiveReport': hasActiveReport,
        'reports': reports.map((report) => report.toJson()).toList(),
      },
    };
  }

  Listing copyWith({
    ListingType? type,
    int? id,
    String? title,
    String? description,
    DateTime? createdAt,
    User? user,
    String? location,
    int? price,
    bool? isFavorite,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    Property? property,
    MarketplaceItem? marketplaceItem,
    bool? hasActiveReport,
    List<Report>? reports,
  }) {
    return Listing(
      type: type ?? this.type,
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
      location: location ?? this.location,
      price: price ?? this.price,
      isFavorite: isFavorite ?? this.isFavorite,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrls: imageUrls ?? List<String>.from(this.imageUrls),
      property: property ?? this.property,
      marketplaceItem: marketplaceItem ?? this.marketplaceItem,
      hasActiveReport: hasActiveReport ?? this.hasActiveReport,
      reports: reports ?? List<Report>.from(this.reports),
    );
  }

  static Listing fromJson(Map<String, dynamic> json) {
    return Listing(
      type: ListingType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ListingType
            .Marketplace, // Default to Marketplace if type is unknown
      ),
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      user: json["user"] != null
          ? User.fromJson(json["user"])
          : null, // Assuming User class exists
      location: json['location'] ?? '',
      price: json['price'] ?? 0,
      isFavorite: json['isFavorite'] ?? false,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      imageUrls:
          List<String>.from(json['images']?.map((x) => x['imageUrl']) ?? []),
      property: json["property"] != null
          ? Property.fromJson({
              ...json["property"],
              // Convert string categories to PropertyCategory enum
              'categories': (json['property']['categories'] as List<dynamic>?)
                      ?.map(
                          (cat) => PropertyCategory.fromString(cat.toString()))
                      .toList() ??
                  [],
            })
          : null,
      marketplaceItem: json["marketplace"] != null
          ? MarketplaceItem.fromJson(json["marketplace"])
          : null,
      hasActiveReport: json['reportStatus']?['hasActiveReport'] ?? false,
      reports: json['reportStatus']?['reports'] != null
          ? List<Report>.from((json['reportStatus']['reports'] as List)
              .map((report) => Report.fromJson(report)))
          : [],
    );
  }
}

class MarketplaceItem {
  final List<String> categories;
  final String? condition;
  final String? brand;
  final List<String> imageUrls;

  MarketplaceItem({
    required this.categories,
    this.condition,
    this.brand,
    required this.imageUrls,
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceItem(
      categories: json['categories'] != null
          ? json['categories']
              .map((e) => e['category'].toString())
              .cast<String>()
              .toList()
          : List<String>.from(json['categories']),
      condition: json['condition'],
      brand: json['brand'],
      imageUrls: json["images"]
          .map((e) => e["imageUrl"].toString())
          .cast<String>()
          .toList(),
    );
  }
}
