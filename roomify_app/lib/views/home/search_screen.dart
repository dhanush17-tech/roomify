import 'package:flutter/material.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';

class SearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16, top: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        color: Colors.black),
                    Text('Search', style: AppTextStyles.title()),
                    Icon(Icons.notifications_none, color: Colors.black),
                  ],
                ),
                SizedBox(height: 10),
                TextField(
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
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.grey.withOpacity(0.1),
                      ),
                      child: Text('Roommate',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.blue.withOpacity(0.1),
                        ),
                        child: Text('Property',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue))),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.grey.withOpacity(0.1),
                      ),
                      child: Text('Marketplace',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    Icon(
                      Icons.filter_list,
                      color: orangeColor,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ListView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    PropertyCard(
                      imagePath: 'assets/test_images/search_house.png',
                      title: 'Cozy 1-BR Apartment',
                      location: 'Akoka, Lagos',
                      price: '₦60,000/month',
                      rating: 4.5,
                      bathrooms: 2,
                      bedrooms: 2,
                    ),
                    PropertyCard(
                      imagePath: 'assets/test_images/search_house.png',
                      title: 'Furnished Studio Apartment',
                      location: 'Yaba, Lagos',
                      price: '₦75,000/month',
                      rating: 4.8,
                      bathrooms: 2,
                      bedrooms: 2,
                    ),
                    PropertyCard(
                      imagePath: 'assets/test_images/search_house.png',
                      title: 'Serene 1-BR Flat',
                      location: 'Onike, Lagos',
                      price: '₦50,000/month',
                      rating: 4.2,
                      bathrooms: 2,
                      bedrooms: 2,
                    ),
                    PropertyCard(
                      imagePath: 'assets/test_images/search_house.png',
                      title: 'Spacious 1-BR Apartment',
                      location: 'Abule Oja, Lagos',
                      price: '₦70,000/month',
                      rating: 4.7,
                      bathrooms: 2,
                      bedrooms: 2,
                    ),
                    PropertyCard(
                      imagePath: 'assets/test_images/search_house.png',
                      title: 'Compact Studio Flat',
                      location: 'Akoka, Lagos',
                      price: '₦45,000/month',
                      rating: 4.0,
                      bathrooms: 2,
                      bedrooms: 2,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PropertyCard extends StatelessWidget {
  final String title;
  final String location;
  final String price;
  final double rating;
  final int bathrooms;
  final int bedrooms;
  final String imagePath;

  PropertyCard({
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
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              imagePath,
              width: 100, // Fixed width
              height: 100, // Fixed height to avoid NaN issues
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body(
                      color: orangeColor.withOpacity(0.8),
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  location,
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 20),
                    SizedBox(width: 5),
                    Text(rating.toString(), style: TextStyle(fontSize: 12)),
                    Spacer(),
                    Icon(Icons.bed, color: Colors.grey, size: 20),
                    SizedBox(width: 5),
                    Text(bedrooms.toString(), style: TextStyle(fontSize: 12)),
                    Spacer(),
                    Icon(Icons.bathtub, color: Colors.grey, size: 20),
                    SizedBox(width: 5),
                    Text(bathrooms.toString(), style: TextStyle(fontSize: 12)),
                    SizedBox(width: 5),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.blue.withOpacity(0.1),
                  ),
                  child: Text(
                    price,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
