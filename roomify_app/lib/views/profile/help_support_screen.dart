import 'package:flutter/material.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSection(
            'Frequently Asked Questions',
            [
              _buildExpandableFAQ(
                'How do I create a listing?',
                'To create a listing, go to the home screen and tap the "+" button. Fill in the required information about your property, including photos, description, and pricing.',
              ),
              _buildExpandableFAQ(
                'How do I edit my profile?',
                'You can edit your profile by going to the Profile tab and tapping "Edit Account Info". Here you can update your personal information, preferences, and profile picture.',
              ),
              _buildExpandableFAQ(
                'How does the matching system work?',
                'Our matching system uses your preferences, location, and other factors to suggest compatible roommates and properties. The more information you provide, the better matches you\'ll receive.',
              ),
              _buildExpandableFAQ(
                'How can I reset my password?',
                'To reset your password, go to the login screen and tap "Forgot Password". Follow the instructions sent to your email to create a new password.',
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildSection(
            'Contact Support',
            [
              _buildContactOption(
                'Email Support',
                'support@roomify.com',
                Icons.email_outlined,
                () => _launchEmail('support@roomify.com'),
              ),
              _buildContactOption(
                'Live Chat',
                'Chat with our support team',
                Icons.chat_bubble_outline,
                () {
                  // Implement live chat functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Live chat coming soon!')),
                  );
                },
              ),
              _buildContactOption(
                'Phone Support',
                '+1 (555) 123-4567',
                Icons.phone_outlined,
                () => _launchPhone('+15551234567'),
              ),
            ],
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support Hours',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Monday - Friday: 9:00 AM - 6:00 PM EST\nWeekends: 10:00 AM - 4:00 PM EST',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildExpandableFAQ(String question, String answer) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 4),
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: orangeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: orangeColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }
} 