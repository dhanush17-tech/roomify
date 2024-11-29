import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/chat_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/views/messaging/message_screen.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final Listing listing;
  PropertyDetailsScreen(this.listing);

  void navigateToChat(BuildContext context, User propertyOwner) async {
    try {
      // Get or create chat room with property owner
      final chatRoom = await context.read<ChatProvider>().createOrGetChatRoom(
            propertyOwner.id,
          );

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatMessageScreen(room: chatRoom),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open chat: $e')),
      );
    }
  }

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
          Consumer<PropertyProvider>(builder: (ctx, provider, g) {
            return IconButton(
              icon: Icon(provider.isFavorite(listing.id)
                  ? Icons.favorite_rounded
                  : Icons.favorite_border),
              onPressed: () {
                provider.toggleFavorite(listing);
              },
            );
          })
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                listing.property!.imageUrls!.isEmpty
                    ? listing.imageUrls![0]
                    : listing.property!
                        .imageUrls![0], // Replace with your image path
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 16),
            Text(
              listing.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey),
                SizedBox(width: 4),
                Text(listing.location, style: TextStyle(color: Colors.grey)),
                Spacer(),
                Icon(Icons.groups, color: Colors.grey),
                SizedBox(width: 4),
                Text(listing.property!.maxOccupancy.toString(),
                    style: TextStyle(color: Colors.grey)),
                SizedBox(width: 16),
                Icon(Icons.bed, color: Colors.grey),
                SizedBox(width: 4),
                Text(listing.property!.numberOfBedrooms.toString()),
                SizedBox(width: 16),
                Icon(Icons.bathtub_outlined, color: Colors.grey),
                SizedBox(width: 4),
                Text(listing.property!.numberOfBathrooms.toString()),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: listing.user!.profilePhotoUrl != null
                      ? NetworkImage(listing.user!.profilePhotoUrl!)
                      : null, // Replace with your image path
                  child: listing.user!.profilePhotoUrl == null
                      ? Icon(Icons.person, size: 25)
                      : null,
                  radius: 20,
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.user!.displayName,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        listing.user!.university == null
                            ? ""
                            : listing.user!.university!,
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
            listing.user!.status == "I'm looking for a roommate"
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
              listing.description!,
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    listing.property!.tags!.map((e) => _buildTag(e)).toList()),
            SizedBox(height: 16),
            Text("Amenities", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: listing.property!.amenities
                    .map((e) => _buildTag(e))
                    .toList()),
            SizedBox(height: 16),
            Text("About the Roomies",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              "Our current roommates are a mix of international students who enjoy a friendly, respectful living environment. They come from various backgrounds and are all studying at the University of Arizona. They value cleanliness and are excited to welcome new housemates.",
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            // Column(
            //   children: listing.comments!.map((e) {
            //     return _buildRoommateCard(
            //       name: e.user!.displayName,
            //       course: e.user!.university!,
            //       description: e.comment,
            //       imagePath: e.user!.profilePhotoUrl!,
            //       verified: true,
            //     );
            //   }).toList(),
            // ),
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
              "\$ ${listing.price}",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            TextButton(
              onPressed: () {
                navigateToChat(context, listing.user!);
              },
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
