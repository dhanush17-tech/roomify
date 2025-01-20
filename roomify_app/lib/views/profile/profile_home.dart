import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/views/auth/login.dart';
import 'package:roomify_app/views/home/favourites.dart';
import 'package:roomify_app/views/profile/edit_preferences.dart';
import 'package:roomify_app/views/profile/edit_profile.dart';
import 'package:roomify_app/views/profile/leads_screen.dart';
import 'package:roomify_app/views/profile/user_listings.dart';
import 'package:roomify_app/views/roomate_match/user_matches.dart'; // For iOS style icons and widgets

class ProfileScreen extends StatelessWidget {
  double latitude;
  double longitude;
  ProfileScreen(this.latitude, this.longitude);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(builder: (context, userProvider, _) {
          return ListView(
            children: [
              _buildHeader(context, userProvider),
              SizedBox(height: 10),
              _buildQuickAccessSection(
                context,
              ),
              SizedBox(height: 20),
              _buildSectionTitle("Account Settings"),
              _buildListItem(
                  "Edit Account Info",
                  showWarning: !userProvider.user!.isProfileComplete(),
                  Icons.account_circle_outlined, onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (c) => EditProfileScreen()));
              }),
              _buildListItem("Notifications", Icons.notifications_none),
              _buildListItem("Payment Methods", Icons.payment),
              _buildSectionTitle("App Management"),
              _buildListItem("Help & Support", Icons.help_outline),
              _buildListItem(
                  "Terms of Service & Privacy Policy", Icons.article_outlined),
              _buildListItem("Report a Problem", Icons.report_problem_outlined),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: Text("Logout"),
                onTap: () async {
                  try {
                    await userProvider.signOut(context);
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => SignUpLoginScreen(
                          latitude,
                          longitude,
                        ),
                      ),
                      (route) => false,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }, // Add navigation or functionality
              ),
              SizedBox(height: 20),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Color(4281282608), // Background color
        ),
        padding: EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0),
              child: CircleAvatar(
                radius: 45,
                backgroundImage: (user.user?.profilePhotoUrl != null
                    ? NetworkImage(user.user!.profilePhotoUrl!)
                    : null) as ImageProvider?,
                child: user.user?.profilePhotoUrl == null
                    ? Icon(Icons.person, size: 50)
                    : null, // Replace with actual image URL
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 0.0),
                    child: Text(user.user?.displayName ?? "",
                        style: AppTextStyles.button(fontSize: 18)),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text("${user.user!.university}",
                      style: AppTextStyles.caption(color: Colors.white)),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (c) => EditProfileScreen()));
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("Edit Profile",
                            style: TextStyle(color: Colors.orange)),
                        SizedBox(
                          width: 3,
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: orangeColor,
                          size: 14,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: Provider.of<AuthProvider>(context, listen: false)
                .user!
                .isProfessional
            ? MainAxisAlignment.spaceEvenly
            : MainAxisAlignment.spaceAround,
        children: [
          _quickAccessIcon(Icons.list_alt, "My Listings", onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) => UserListingScreen(latitude, longitude)));
          }),
          _quickAccessIcon(Icons.favorite_border, "Favorites", onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) => FavoritesScreen(latitude, longitude)));
          }),
          _quickAccessIcon(Icons.people_alt_outlined, "Matches", onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (c) => UserMatchesScreen()));
          }),
          if (Provider.of<AuthProvider>(context, listen: false)
              .user!
              .isProfessional)
            _quickAccessIcon(Icons.leaderboard_outlined, "Leads", onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (c) => LeadsScreen()));
            }),
        ],
      ),
    );
  }

  Widget _quickAccessIcon(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 28),
          Text(label),
        ],
      ),
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

  Widget _buildListItem(String title, IconData icon,
      {VoidCallback? onTap, bool showWarning = false}) {
    return ListTile(
      onTap: onTap ?? () {},
      leading: Icon(icon, color: Colors.orange),
      title: Text(title),
      trailing: showWarning
          ? Icon(Icons.warning_amber_rounded, color: Colors.red)
          : Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}
