import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/providers/marketplace_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/views/home/favourites.dart';
import 'package:roomify_app/views/marketplace/marketplace_search.dart';
import 'package:roomify_app/widgets/pinterest_grid.dart';

class MarketplaceScreen extends StatefulWidget {
  final List<Listing>? searchResultsList;
  final String searchQuery;

  const MarketplaceScreen({
    Key? key,
    this.searchResultsList,
    this.searchQuery = '',
  }) : super(key: key);

  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late TextEditingController _searchController;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  // Filter items based on selected category
  List<Listing> _getFilteredItems(List<Listing> items, String? category) {
    if (category == null) return items;
    return items.where((item) {
      return item.marketplaceItem?.categories.contains(category) ?? false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
            child: Consumer<MarketplaceProvider>(
              builder: (context, provider, _) {
                // Get filtered items based on category
                final filteredItems = _getFilteredItems(
                  widget.searchResultsList ?? provider.items,
                  _selectedCategory,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('Marketplace',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20)),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.favorite_outline,
                                  color: Colors.black),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (c) => FavoritesScreen()));
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    TextField(
                      controller: _searchController,
                      readOnly: true,
                      onTap: () async {
                        final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => MarketplaceSearchScreen(
                                      searchQuery: _searchController.text,
                                    )));

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
                    const SizedBox(height: 20),
                    const Text("Categories",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
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
                                _selectedCategory = _selectedCategory == "Books"
                                    ? null
                                    : "Books";
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    PinterestGrid(
                      items: filteredItems,
                      physics: NeverScrollableScrollPhysics(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryIcon extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey.shade200 : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              imagePath,
              width: 30,
            ),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
