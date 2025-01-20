import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/providers/marketplace_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/views/home/favourites.dart';
import 'package:roomify_app/views/marketplace/marketplace_search.dart';
import 'package:roomify_app/widgets/pinterest_grid.dart';

class PriceRange {
  final double min;
  final double max;
  final String label;

  const PriceRange({
    required this.min,
    required this.max,
    required this.label,
  });

  bool includes(double price) {
    return price >= min && (max == -1 || price <= max);
  }
}

class MarketplaceHomeScreen extends StatefulWidget {
  double latitude;
  double longitude;
  MarketplaceHomeScreen(this.latitude, this.longitude);
  @override
  _MarketplaceHomeScreenState createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  late TextEditingController _searchController;
  String? _selectedCategory;
  PriceRange? _selectedPriceRange;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: '');
    _loadItems();
  }

  Future<void> _loadItems() async {
    await context.read<MarketplaceProvider>().refreshItems();
  }

  Future<void> _handleRefresh() async {
    await context.read<MarketplaceProvider>().refreshItems();
  }

  List<PriceRange> _generatePriceRanges(List<Listing> items) {
    if (items.isEmpty) return [];

    double minPrice =
        items.map((e) => e.price).reduce((a, b) => a < b ? a : b).toDouble();
    double maxPrice =
        items.map((e) => e.price).reduce((a, b) => a > b ? a : b).toDouble();

    // Determine the number of price ranges based on the number of items
    int rangeCount = items.length <= 2 ? items.length : 4;
    double range = (maxPrice - minPrice) / rangeCount;

    List<PriceRange> priceRanges = [
      PriceRange(min: 0, max: -1, label: 'All Prices'),
    ];

    for (int i = 0; i < rangeCount; i++) {
      double rangeMin = minPrice + (range * i);
      double rangeMax = (i == rangeCount - 1) ? maxPrice : rangeMin + range;
      priceRanges.add(PriceRange(
        min: rangeMin,
        max: rangeMax,
        label: '\$${rangeMin.toInt()}-\$${rangeMax.toInt()}',
      ));
    }

    return priceRanges;
  }

  List<Listing> _getFilteredItems(List<Listing> items, String? category) {
    List<Listing> filteredItems = items;

    if (category != null) {
      filteredItems = filteredItems.where((item) {
        return item.marketplaceItem?.categories.contains(category) ?? false;
      }).toList();
    }

    if (_selectedPriceRange != null &&
        _selectedPriceRange?.label != 'All Prices') {
      filteredItems = filteredItems
          .where((item) => _selectedPriceRange!.includes(item.price.toDouble()))
          .toList();
    }

    return filteredItems;
  }

  Widget _buildPriceRangeFilter(List<Listing> items) {
    final priceRanges = _generatePriceRanges(items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Price Range",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: priceRanges.map((range) {
              bool isSelected = _selectedPriceRange?.label == range.label;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(range.label),
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedPriceRange = selected ? range : null;
                    });
                  },
                  selectedColor: Colors.blue.withOpacity(0.2),
                  checkmarkColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue : blackTextColor,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: Consumer<MarketplaceProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              if (provider.error.isNotEmpty) {
                return Center(child: Text(provider.error));
              }

              return ListView(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('Marketplace',
                              style: TextStyle(
                                  color: blackTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite_outline_rounded,
                                color: blackTextColor),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (c) => FavoritesScreen(
                                          widget.latitude, widget.longitude)));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Hero(
                    tag: 'search_field',
                    child: Material(
                      color: Colors.transparent,
                      child: TextField(
                        controller: _searchController,
                        readOnly: true,
                        onTap: () async {
                          final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (c) => MarketplaceSearchScreen(
                                      _searchController.text,
                                      widget.latitude,
                                      widget.longitude)));

                          if (result != null && result is Map) {
                            setState(() {
                              _searchController.text = result['query'];
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: "Search for furniture, books...",
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Categories",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Text("browse specific types of items",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 25),
                  SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(width: 10),
                        CategoryIcon(
                          title: "Electronics",
                          icon: Icons.weekend,
                          imagePath: "assets/icons/electronics.png",
                          isSelected: _selectedCategory == "Electronics",
                          onTap: () {
                            setState(() {
                              _selectedCategory =
                                  _selectedCategory == "Electronics"
                                      ? null
                                      : "Electronics";
                            });
                          },
                        ),
                        SizedBox(width: 20),
                        CategoryIcon(
                          title: "Furniture",
                          icon: Icons.checkroom,
                          imagePath: "assets/icons/furniture.png",
                          isSelected: _selectedCategory == "Furniture",
                          onTap: () {
                            setState(() {
                              _selectedCategory =
                                  _selectedCategory == "Furniture"
                                      ? null
                                      : "Furniture";
                            });
                          },
                        ),
                        SizedBox(width: 20),
                        CategoryIcon(
                          title: "Clothing",
                          icon: Icons.kitchen,
                          imagePath: "assets/icons/clothing.png",
                          isSelected: _selectedCategory == "Clothing",
                          onTap: () {
                            setState(() {
                              _selectedCategory =
                                  _selectedCategory == "Clothing"
                                      ? null
                                      : "Clothing";
                            });
                          },
                        ),
                        SizedBox(width: 20),
                        CategoryIcon(
                          title: "Books",
                          icon: Icons.computer,
                          imagePath: "assets/icons/books.png",
                          isSelected: _selectedCategory == "Books",
                          onTap: () {
                            setState(() {
                              _selectedCategory =
                                  _selectedCategory == "Books" ? null : "Books";
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  provider.items.isEmpty
                      ? SizedBox()
                      : _buildPriceRangeFilter(provider.items),
                  _getFilteredItems(provider.items, _selectedCategory).isEmpty
                      ? SizedBox(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Nothing instore so far',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  'come back soon!',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : PinterestGrid(
                          _getFilteredItems(provider.items, _selectedCategory),
                          widget.latitude,
                          widget.longitude,
                          physics: NeverScrollableScrollPhysics(),
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class CategoryIcon extends StatefulWidget {
  final String title;
  final IconData icon;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryIcon({
    Key? key,
    required this.title,
    required this.icon,
    required this.imagePath,
    this.isSelected = false,
    required this.onTap,
  }) : super(key: key);

  @override
  State<CategoryIcon> createState() => _CategoryIconState();
}

class _CategoryIconState extends State<CategoryIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(CategoryIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      Theme.of(context).scaffoldBackgroundColor,
                      Colors.grey.shade200,
                      _opacityAnimation.value,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    widget.imagePath,
                    width: 30,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 12),
          Text(
            widget.title,
            style: TextStyle(
              color: widget.isSelected ? Colors.blue : blackTextColor,
              fontWeight:
                  widget.isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
