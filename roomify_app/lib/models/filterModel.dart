class FilterOptions {
  final String? gender;
  final double? minCompatibility;
  final double? maxCompatibility;
  final List<String> lifestylePreferences;
  final double? proximity;
  final String? location;
  final double? minPrice;
  final double? maxPrice;
  final int? bedrooms;
  final int? bathrooms;
  final int? rating;
  final int? maxOccupancy;
  final List<String> propertyTypes;
  final List<String> amenities;
  final List<String> itemCategories;
  final double? radius;

  FilterOptions({
    this.gender,
    this.minCompatibility,
    this.maxCompatibility,
    this.lifestylePreferences = const [],
    this.proximity,
    this.location,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.bathrooms,
    this.rating,
    this.maxOccupancy,
    this.propertyTypes = const [],
    this.amenities = const [],
    this.itemCategories = const [],
    this.radius,
  });

  factory FilterOptions.defaultValues() {
    return FilterOptions(
        gender: null,
        minCompatibility: 0,
        maxCompatibility: 100,
        lifestylePreferences: [],
        proximity: 3.0,
        location: null,
        minPrice: 0,
        maxPrice: 3000,
        bedrooms: null,
        bathrooms: null,
        rating: 0,
        maxOccupancy: null,
        propertyTypes: [],
        amenities: [],
        itemCategories: [],
        radius: null);
  }

  Map<String, dynamic> toJson() {
    return {
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'radius': radius,
    };
  }
}
