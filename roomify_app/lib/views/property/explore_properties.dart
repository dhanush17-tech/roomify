import 'package:flutter/material.dart';
import 'package:roomify_app/views/property/property_details.dart';

class ExplorePropertiesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Explore Properties',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'single apartment near unilag',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Icon(Icons.search, color: Colors.grey),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Recommended", style: TextStyle(color: Colors.grey)),
                  Text("New", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Nearby", style: TextStyle(color: Colors.grey)),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.view_list, color: Colors.grey),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.filter_list, color: Colors.grey),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              PropertyCard(
                imagePath: 'assets/test_images/house.png',
                title: 'Cozy Studio Apartment',
                location: 'Yaba, Lagos',
                price: '\$45/month',
                rating: 4.3,
                bathrooms: 1,
                bedrooms: 1,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => PropertyDetailsScreen()));
                },
              ),
              SizedBox(height: 16),
              PropertyCard(
                imagePath: 'assets/test_images/house.png',
                title: 'Modern Studio Apartment',
                location: 'Ikeja, Lagos',
                price: '\$50/month',
                rating: 4.5,
                bathrooms: 1,
                bedrooms: 1,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => PropertyDetailsScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PropertyCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String location;
  final String price;
  final double rating;
  final int bathrooms;
  final int bedrooms;
  final Function onTap;

  PropertyCard({
    required this.imagePath,
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.bathrooms,
    required this.bedrooms,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: Image.asset(
                imagePath,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey, size: 16),
                      SizedBox(width: 4),
                      Text(location, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.orange, size: 16),
                          SizedBox(width: 4),
                          Text(rating.toString(),
                              style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.bathtub, color: Colors.grey, size: 16),
                          SizedBox(width: 4),
                          Text(bathrooms.toString(),
                              style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.bed, color: Colors.grey, size: 16),
                          SizedBox(width: 4),
                          Text(bedrooms.toString(),
                              style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.favorite_border, color: Colors.grey),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      price,
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
