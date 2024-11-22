import 'package:flutter/material.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final Property property;
  PropertyDetailsScreen(this.property);
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
                'assets/test_images/house.png', // Replace with your image path
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 16),
            Text(
              property.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey),
                SizedBox(width: 4),
                Text(property.location, style: TextStyle(color: Colors.grey)),
                Spacer(),
                Icon(Icons.groups, color: Colors.grey),
                SizedBox(width: 4),
                Text(property.maxOccupancy.toString(),
                    style: TextStyle(color: Colors.grey)),
                SizedBox(width: 16),
                Icon(Icons.bed, color: Colors.grey),
                SizedBox(width: 4),
                Text(property.numberOfBedrooms.toString()),
                SizedBox(width: 16),
                Icon(Icons.bathtub_outlined, color: Colors.grey),
                SizedBox(width: 4),
                Text(property.numberOfBathrooms.toString()),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: property.user!.profilePhotoUrl != null
                      ? NetworkImage(property.user!.profilePhotoUrl!)
                      : null, // Replace with your image path
                  child: property.user!.profilePhotoUrl == null
                      ? Icon(Icons.person, size: 50)
                      : null,
                  radius: 20,
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property.user!.displayName,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(property.user!.university!,
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
                Spacer(),
                Icon(Icons.chat_bubble_outline, color: Colors.grey),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            property.isLookingForRoomate! == true
                ? Container(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Looking for a Roommate",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ))
                : Container(),
            SizedBox(height: 10),
            Divider(),
            SizedBox(height: 8),
            Text("Property Overview",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              property.description,
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    property.categories.map((e) => _buildTag(e)).toList()),
            SizedBox(height: 16),
            Text("Amenities", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: property.amenities.map((e) => _buildTag(e)).toList()),
            SizedBox(height: 16),
            Text("About the Roomies",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              "Our current roommates are a mix of international students who enjoy a friendly, respectful living environment. They come from various backgrounds and are all studying at the University of Arizona. They value cleanliness and are excited to welcome new housemates.",
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Column(
              children: property.comments!.map((e) {
                return _buildRoommateCard(
                  name: e.user!.displayName,
                  course: e.user!.university!,
                  description: e.comment,
                  imagePath: e.user!.profilePhotoUrl!,
                  verified: true,
                );
              }).toList(),
            ),
            SizedBox(height: 80),
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

  Widget _buildRoommateCard({
    required String name,
    required String course,
    required String description,
    required String imagePath,
    bool verified = false,
  }) {
    return Column(
      children: [
        SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(imagePath),
              radius: 20,
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                    if (verified) ...[
                      SizedBox(width: 4),
                      Icon(Icons.verified, color: Colors.blue, size: 16),
                    ],
                  ],
                ),
                Text(course, style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(description, style: TextStyle(color: Colors.grey)),
        SizedBox(height: 16),
      ],
    );
  }
}
