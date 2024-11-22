import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/views/home/favourites.dart';
import 'package:roomify_app/views/messaging/message_home.dart';
import 'package:roomify_app/views/property/property_details.dart';
import 'package:roomify_app/views/home/search_screen.dart';
import 'package:roomify_app/views/roomate_match/roommate_match.dart';

class HomeScreen extends StatefulWidget {
  User user;
  HomeScreen({required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hi Anika!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.favorite_outline_rounded,
                            color: Colors.grey),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (c) => FavoritesScreen()));
                        },
                      ),
                      IconButton(
                        icon:
                            Icon(Icons.chat_bubble_outline, color: Colors.grey),
                        onPressed: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (c) => MessageHome()));
                        },
                      ),
                    ],
                  ),
                ],
              ),
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: "Search for rooms, roommates or items...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Recommended Section
              SectionHeader(
                  title: "Recommended",
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (c) => SearchScreen()));
                  }),
              Text("based on your preferences",
                  style: TextStyle(color: Colors.grey)),
              SizedBox(height: 10),
              Consumer<PropertyProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Text(provider.error!);
                  }

                  if (provider.recommendations.isEmpty) {
                    return Text('No recommendations found nearby');
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: provider.recommendations.map((property) {
                        return Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: ItemCard(
                            title: property.title,
                            location: property.location,
                            price: "\$${property.price}/month",
                            rating: property.rating?.toDouble() ?? 0.0,
                            bathrooms: property.numberOfBathrooms,
                            bedrooms: property.numberOfBedrooms,
                            imagePath: property.imageUrls.isNotEmpty
                                ? property.imageUrls.first
                                : "assets/test_images/house.png",
                            property: property,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),

              // Recommended Section

              // // Find Your Ideal Roommate Section
              // SectionHeader(title: "Find Your Ideal Roommate", onTap: () {}),
              // SizedBox(height: 20),
              // SingleChildScrollView(
              //   scrollDirection: Axis.horizontal,
              //   child: Row(
              //     children: [
              //       RoommateCard(
              //           name: "David E.",
              //           age: 22,
              //           university: "ASU",
              //           imagePath: "assets/test_images/house.png"),
              //       SizedBox(width: 40),
              //       RoommateCard(
              //           name: "Fatima K.",
              //           age: 20,
              //           university: "NYU",
              //           imagePath: "assets/test_images/house.png"),
              //     ],
              //   ),
              // ),
              SectionHeader(
                  title: "Pair up",
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (c) => SearchScreen()));
                  }),
              SizedBox(
                height: 10,
              ),
              Consumer<PropertyProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Center(child: Text(provider.error!));
                  }

                  final matches = provider.pairUpListings;

                  if (matches.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No matches found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.all(0),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return MatchCard(property: match);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MatchCard extends StatelessWidget {
  final Property property;

  const MatchCard({required this.property});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (C) => PropertyDetailsScreen(property)));
      },
      child: Container(
        height: 16 * 7,
        width: 9 * 7,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            // User Info Section

            // Property Preview
            Container(
              width: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(
                    property.imageUrls.isNotEmpty
                        ? property.imageUrls.first
                        : 'https://placeholder.com/300x200',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(
              width: 20,
            ),
            // Property Details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: property.user?.profilePhotoUrl != null
                      ? NetworkImage(property.user!.profilePhotoUrl!)
                      : null,
                  child: property.user?.profilePhotoUrl == null
                      ? Text(
                          property.user?.displayName
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                              '?',
                          style: TextStyle(fontSize: 24),
                        )
                      : null,
                ),
                Text(
                  property.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      property.location,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyFeature(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        SizedBox(height: 4),
        Text(text),
      ],
    );
  }
}

class ItemCard extends StatelessWidget {
  final String title;
  final String location;
  final String price;
  final double rating;
  final int bathrooms;
  final int bedrooms;
  final String imagePath;
  final Property property;

  ItemCard({
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.bathrooms,
    required this.bedrooms,
    required this.imagePath,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (c) => PropertyDetailsScreen(property)));
      },
      child: Container(
        width: 250,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: imagePath.contains("assets/")
                  ? Image.asset(
                      imagePath,
                      height: 120,
                    )
                  : Image.network(imagePath,
                      height: 120, width: double.infinity, fit: BoxFit.cover),
            ),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text(location, style: TextStyle(color: Colors.grey)),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.star, color: Colors.orange, size: 14),
                SizedBox(width: 5),
                Text(rating.toString(), style: TextStyle(fontSize: 12)),
                Spacer(),
                Icon(Icons.bathtub, color: Colors.grey, size: 14),
                SizedBox(width: 5),
                Text(bathrooms.toString(), style: TextStyle(fontSize: 12)),
                Spacer(),
                Icon(Icons.bed, color: Colors.grey, size: 14),
                SizedBox(width: 5),
                Text(bedrooms.toString(), style: TextStyle(fontSize: 12)),
              ],
            ),
            SizedBox(height: 10),
            Container(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.blue.withOpacity(0.1)),
                child: Text(price,
                    style: AppTextStyles.small(
                      color: Colors.blue,
                    ))),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  SectionHeader({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (c) => SearchScreen()));
          },
          child: Text(
            "View All",
            style: TextStyle(
              color: Colors.blue,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class RoommateCard extends StatelessWidget {
  final String name;
  final int age;
  final String university;
  final String imagePath;

  RoommateCard({
    required this.name,
    required this.age,
    required this.university,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 70,
          height: 60,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                fit: BoxFit.cover,
                image: AssetImage(imagePath),
              )),
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
            Text('$age', style: TextStyle(color: Colors.grey)),
            Text(university, style: TextStyle(color: Colors.grey)),
          ],
        )
      ],
    );
  }
}

class FeaturedItemCard extends StatelessWidget {
  final String title;
  final String location;
  final String price;
  final String imagePath;

  FeaturedItemCard({
    required this.title,
    required this.location,
    required this.price,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(imagePath,
                height: 100, width: double.infinity, fit: BoxFit.cover),
          ),
          SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(location, style: TextStyle(color: Colors.grey)),
          Text(price,
              style:
                  TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
