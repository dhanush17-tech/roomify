import 'package:flutter/material.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';

class ItemDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("Details", style: AppTextStyles.title()),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/test_images/marketplace.png', // Replace with your image path
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Cozy Apartment",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey),
                SizedBox(width: 4),
                Text("Tucson, AZ", style: TextStyle(color: Colors.grey)),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag("New"),
                _buildTag("120cm x 60cm"),
                _buildTag("Laundry facilities"),
                _buildTag("New"),
                _buildTag("Security personnel"),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(
                      'assets/test_images/person.png'), // Replace with your image path
                  radius: 20,
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Akinola Bidemi",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("AZU", style: TextStyle(color: Colors.grey)),
                  ],
                ),
                Spacer(),
                Icon(Icons.chat_bubble_outline, color: Colors.grey),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Text("Item Description",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              "A wooden study desk, perfect for dorm rooms. In good condition, used for one semester.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding:
            const EdgeInsets.only(left: 30, right: 30, bottom: 26.0, top: 26),
        child: Row(
          children: [
            Text(
              "\$100",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: orangeColor,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  "Contact Now",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.blue, fontSize: 12),
      ),
    );
  }
}
