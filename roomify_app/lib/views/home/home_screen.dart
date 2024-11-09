import 'package:flutter/material.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/views/home/property_detais.dart';
import 'package:roomify_app/views/home/search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Hi Anika!',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: null,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  Row(
                    children: [
                      ItemCard(
                        title: "Cozy Studio Apartment",
                        location: "Yaba, Lagos",
                        price: "\$40/month",
                        rating: 4.3,
                        bathrooms: 1,
                        bedrooms: 1,
                        imagePath: "assets/test_images/house.png",
                      ),
                      SizedBox(width: 10),
                      ItemCard(
                        title: "Cozy Single Apartment",
                        location: "Yaba, Lagos",
                        price: "\$45/month",
                        rating: 4.5,
                        bathrooms: 1,
                        bedrooms: 1,
                        imagePath: "assets/test_images/house.png",
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  )
                ],
              ),
            ),
            // SizedBox(height: 20),

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
            SizedBox(height: 20),

            // Featured Items Section
            SectionHeader(
                title: "Featured Items",
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (c) => SearchScreen()));
                }),
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FeaturedItemCard(
                    title: "Modern Desk",
                    location: "Boston, MA",
                    price: "\$100",
                    imagePath: "assets/test_images/house.png",
                  ),
                  SizedBox(width: 20),
                  FeaturedItemCard(
                    title: "Office Chair",
                    location: "San Franc., CA",
                    price: "\$75",
                    imagePath: "assets/test_images/house.png",
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

class ItemCard extends StatelessWidget {
  final String title;
  final String location;
  final String price;
  final double rating;
  final int bathrooms;
  final int bedrooms;
  final String imagePath;

  ItemCard({
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.bathrooms,
    required this.bedrooms,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (c) => PropertyDetailsScreen()));
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
              child: Image.asset(imagePath,
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
          onTap: onTap,
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
