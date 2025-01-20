class FilterOptions {
  final String? gender;
  final double? minCompatibility;
  final double? maxCompatibility;
  final List<String> lifestylePreferences;
  final double? proximity;
  final String? location;
  final double? minPrice;
  final double? maxPrice;
  final int? numberOfBedrooms;
  final int? numberOfBathrooms;
  final int? rating;
  final int? maxOccupancy;
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
    this.maxOccupancy,
    this.numberOfBedrooms,
    this.numberOfBathrooms,
    this.rating,
    this.maxPrice,
    this.propertyTypes = const [],
    this.amenities = const [],
    this.itemCategories = const [],
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
        numberOfBedrooms: null,
        numberOfBathrooms: null,
        rating: 0,
        maxOccupancy: null,
        propertyTypes: [],
        amenities: [],
        itemCategories: []);
  }
}
