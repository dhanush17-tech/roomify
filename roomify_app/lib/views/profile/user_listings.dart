// lib/screens/my_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/widgets/pinterest_grid.dart';

class UserListingScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  UserListingScreen(this.latitude, this.longitude);
  @override
  _UserListingScreenState createState() => _UserListingScreenState();
}

class _UserListingScreenState extends State<UserListingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadUserListings();
    });
  }

  Widget _buildListingTab(List<Listing> listings) {
    final reportedListings = listings.where((l) => l.hasActiveReport).toList();
    final normalListings = listings.where((l) => !l.hasActiveReport).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          if (reportedListings.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Reported Listings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
            PinterestGrid(
              reportedListings,
              widget.latitude,
              widget.longitude,
              showDeleteIcon: true,
              onTapDelete: (listing) =>
                  _showDeleteConfirmation(context, listing),
            ),
          ],
          if (normalListings.isNotEmpty) ...[
            if (reportedListings.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Active Listings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            PinterestGrid(
              normalListings,
              widget.latitude,
              widget.longitude,
              showDeleteIcon: true,
              onTapDelete: (listing) =>
                  _showDeleteConfirmation(context, listing),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            bottom: false,
            child: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: blackTextColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: const Text('My Listings',
                        style: TextStyle(
                            color: blackTextColor,
                            fontWeight: FontWeight.bold)),
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
                        dividerHeight: 0,
                        controller: _tabController,
                        indicatorWeight: 0,
                        indicatorPadding: EdgeInsets.all(0),
                        indicator: BoxDecoration(
                          color: orangeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorColor: Colors.transparent,
                        labelColor: orangeColor,
                        unselectedLabelColor: blackTextColor,
                        labelStyle: TextStyle(fontWeight: FontWeight.w400),
                        tabs: user!.isProfessional
                            ? [
                                Tab(
                                    text:
                                        'Properties (${provider.properties.length})'),
                              ]
                            : [
                                Tab(
                                    text:
                                        'Properties (${provider.properties.length})'),
                                Tab(
                                    text:
                                        'Marketplace (${provider.marketplaceItems.length})'),
                              ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  if (provider.isLoading)
                    CircularProgressIndicator()
                  else
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildListingTab(provider.properties),
                          user!.isProfessional
                              ? Container()
                              : _buildListingTab(provider.marketplaceItems),
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

  Future<void> _showDeleteConfirmation(
      BuildContext context, Listing listing) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Listing',
              style: TextStyle(
                  color: blackTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete this listing?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: blackTextColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await context
                      .read<ProfileProvider>()
                      .deleteListing(listing.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Listing deleted successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete listing: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
