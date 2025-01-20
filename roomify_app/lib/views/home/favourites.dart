import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/utils/colors.dart'; // Ensure you have these files in your project
import 'package:roomify_app/utils/text_styles.dart'; // Ensure you have these files in your project
import 'package:roomify_app/widgets/pinterest_grid.dart'; // Ensure you have this widget in your project

class FavoritesScreen extends StatefulWidget {
  double latitude;
  double longitude;
  FavoritesScreen(this.latitude, this.longitude); 
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load favorites when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadFavorites();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, favoriteProvider, child) {
        // Filter favorites by type
        final propertyFavorites = favoriteProvider.favorites
            .where((item) => item.type == ListingType.Property)
            .toList();
        final marketplaceFavorites = favoriteProvider.favorites
            .where((item) => item.type == ListingType.Marketplace)
            .toList();

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: blackTextColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      if (favoriteProvider.favorites.isNotEmpty)
                        GestureDetector(
                          onTap: () => _showClearConfirmation(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 5, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Clear all",
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(width: 16)
                    ],
                    title: const Text(
                      'Favorites',
                      style: TextStyle(
                        color: blackTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ];
              },
              body: Column(
                children: [
                  SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 40,
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: TabBar(
                        controller: _tabController,
                        dividerHeight: 0,
                        indicatorWeight: 0,
                        indicatorPadding: EdgeInsets.zero,
                        indicator: BoxDecoration(
                          color: orangeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: orangeColor,
                        unselectedLabelColor: blackTextColor,
                        labelStyle: TextStyle(fontWeight: FontWeight.w400),
                        tabs: [
                          Tab(
                            text: 'Properties (${propertyFavorites.length})',
                          ),
                          Tab(
                            text:
                                'Marketplace (${marketplaceFavorites.length})',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  if (favoriteProvider.isLoading)
                    Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildFavoritesList(propertyFavorites),
                          _buildFavoritesList(marketplaceFavorites),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesList(List<Listing> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return PinterestGrid(
      items.map((item) => item).toList(),
      widget.latitude,
      widget.longitude,
    );
  }

  Future<void> _showClearConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear All Favorites',
              style: TextStyle(
                  color: blackTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          content: Text('Are you sure you want to remove all favorites?',
              style: TextStyle(color: blackTextColor, fontSize: 16)),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: blackTextColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: Text('Clear', style: TextStyle(color: Colors.white)),
              onPressed: () {
                context.read<PropertyProvider>().clearAll();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
