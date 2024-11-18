class FilterOptions {
  final String? gender;
  final double? minCompatibility;
  final double? maxCompatibility;
  final List<String> lifestylePreferences;
  final double? proximity;
  final String? location;
  final double? minPrice;
  final double? maxPrice;
  final List<String> propertyTypes;
  final List<String> amenities;
  final List<String> itemCategories;

  FilterOptions({
    this.gender,
    this.minCompatibility,
    this.maxCompatibility,
    this.lifestylePreferences = const [],
    this.proximity,
    this.location,
    this.minPrice,
    this.maxPrice,
    this.propertyTypes = const [],
    this.amenities = const [],
    this.itemCategories = const [],
  });
}
