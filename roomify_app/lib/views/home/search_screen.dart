import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/providers/search_provider.dart';
import 'package:roomify_app/views/property/explore_properties.dart';
import 'package:roomify_app/views/property/property_details.dart';

import '../../widgets/filter_bottom_sheet.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<SearchProvider>().search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // IconButton(
                      //   icon: Icon(Icons.arrow_back),
                      //   onPressed: () => Navigator.pop(context),
                      // ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (query) {
                            _onSearchChanged(query);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search for more...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            fillColor: Colors.grey[200],
                            filled: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.notifications_none),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                _buildTabBar(searchProvider),
                if (searchProvider.isLoading)
                  CircularProgressIndicator()
                else
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: searchProvider.searchResults.length,
                      itemBuilder: (context, index) {
                        final item = searchProvider.searchResults[index];
                        return _buildSearchResult(
                            item, searchProvider.activeTab);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar(SearchProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTab('Roommate', provider),
          _buildTab('Property', provider),
          _buildTab('Marketplace', provider),
          IconButton(
            icon: Icon(Icons.filter_list, color: orangeColor),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, SearchProvider provider) {
    final isActive = provider.activeTab == title;
    return GestureDetector(
      onTap: () => provider.setActiveTab(title),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isActive
              ? Colors.blue.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(),
    );
  }
}

Widget _buildSearchResult(dynamic item, String activeTab) {
  switch (activeTab) {
    case 'Property':
      return PropertyCard(item);
    case 'Marketplace':
      return MarketplaceCard(item);
    case 'Roommate':
      return RoommateCard(item);
    default:
      return SizedBox.shrink();
  }
}

// Property Card Widget
class PropertyCard extends StatelessWidget {
  final Property property;

  const PropertyCard(this.property);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (C) => PropertyDetailsScreen(property)));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: property.imageUrls.isNotEmpty
                      ? Image.network(
                          property.imageUrls[0],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/test_images/house.png',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.favorite_border,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        property.location ?? '',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            '${0.0}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(width: 16),
                      Row(
                        children: [
                          Icon(Icons.bed_outlined, size: 16),
                          SizedBox(width: 4),
                          Text('${property.numberOfBedrooms ?? 1}'),
                        ],
                      ),
                      SizedBox(width: 16),
                      Row(
                        children: [
                          Icon(Icons.bathtub_outlined, size: 16),
                          SizedBox(width: 4),
                          Text('${property.numberOfBathrooms ?? 1}'),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '\$ ${property.price}/month',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Marketplace Card Widget
class MarketplaceCard extends StatelessWidget {
  final Property item;

  const MarketplaceCard(this.item);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (c) => PropertyDetailsScreen(item)));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrls[0] ?? '',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(
            item.title ?? '',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            item.price != null ? '₦${item.price}' : '',
            style: TextStyle(color: Colors.blue),
          ),
          trailing: Icon(Icons.favorite_border),
        ),
      ),
    );
  }
}

// Roommate Card Widget
class RoommateCard extends StatelessWidget {
  final dynamic roommate;

  const RoommateCard(this.roommate);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(roommate.profileImage ?? ''),
        ),
        title: Text(
          roommate.name ?? '',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(roommate.university ?? ''),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber),
                SizedBox(width: 4),
                Text(
                  '${roommate.compatibility ?? 0}% Match',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ],
        ),
        // trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
