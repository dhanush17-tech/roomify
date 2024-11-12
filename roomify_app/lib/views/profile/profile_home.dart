import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:roomify_app/utils/text_styles.dart'; // For iOS style icons and widgets

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            _buildHeader(),
            SizedBox(height: 20),
            _buildQuickAccessSection(),
            SizedBox(height: 20),
            _buildSectionTitle("Account Settings"),
            _buildListItem("Edit Account Info", Icons.account_circle_outlined),
            _buildListItem("Preferences", Icons.tune),
            _buildListItem("Notifications", Icons.notifications_none),
            _buildListItem("Payment Methods", Icons.payment),
            _buildSectionTitle("App Management"),
            _buildListItem("Help & Support", Icons.help_outline),
            _buildListItem(
                "Terms of Service & Privacy Policy", Icons.article_outlined),
            _buildListItem("Report a Problem", Icons.report_problem_outlined),
            SizedBox(height: 20),
            _buildLogoutButton(context),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.grey[200], // Background color
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                    "https://via.placeholder.com/150"), // Replace with actual image URL
              ),
              DropdownButton<String>(
                value: "English",
                icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                underline: Container(),
                onChanged: (String? newValue) {},
                items: <String>['English', 'Spanish', 'French']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text("Anika",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text("Computer Science, NYU",
              style: TextStyle(color: Colors.grey[600])),
          TextButton(
            onPressed: () {},
            child: Text("Edit Profile", style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickAccessIcon(Icons.list_alt, "My Listings"),
          _quickAccessIcon(Icons.favorite_border, "Favorites"),
          _quickAccessIcon(Icons.people_alt_outlined, "Matches"),
        ],
      ),
    );
  }

  Widget _quickAccessIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 28),
        Text(label),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800])),
    );
  }

  Widget _buildListItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {}, // Add navigation or functionality
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange, // Button color
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        ),
        child: Text(
          'Log Out',
          style: AppTextStyles.body(color: Colors.white),
        ),
        onPressed: () {
          // Handle log out logic here
        },
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: ProfileScreen()));
