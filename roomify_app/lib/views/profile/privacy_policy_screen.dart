import 'package:flutter/material.dart';
import 'package:roomify_app/utils/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms & Privacy Policy'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: orangeColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: orangeColor,
                tabs: [
                  Tab(text: 'Terms of Service'),
                  Tab(text: 'Privacy Policy'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTermsOfService(),
                  _buildPrivacyPolicy(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsOfService() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildSection(
          'Terms of Service',
          'Last updated: ${DateTime.now().toString().split(' ')[0]}',
          [
            _buildParagraph(
              '1. Acceptance of Terms',
              'By accessing and using Roomify, you agree to be bound by these Terms of Service and all applicable laws and regulations.',
            ),
            _buildParagraph(
              '2. User Accounts',
              'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.',
            ),
            _buildParagraph(
              '3. Listing Guidelines',
              'All listings must be accurate and truthful. Users must have the right to list properties and must comply with all applicable laws and regulations.',
            ),
            _buildParagraph(
              '4. User Conduct',
              'Users agree to use the service in a manner consistent with all applicable laws and regulations. Harassment, abuse, or discriminatory behavior is not tolerated.',
            ),
            _buildParagraph(
              '5. Content Ownership',
              'Users retain ownership of their content but grant Roomify a license to use, modify, and display the content for service-related purposes.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrivacyPolicy() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildSection(
          'Privacy Policy',
          'Last updated: ${DateTime.now().toString().split(' ')[0]}',
          [
            _buildParagraph(
              '1. Information Collection',
              'We collect information you provide directly, including personal details, preferences, and listing information. We also collect usage data and device information.',
            ),
            _buildParagraph(
              '2. Use of Information',
              'We use collected information to provide and improve our services, personalize your experience, and communicate with you about our services.',
            ),
            _buildParagraph(
              '3. Information Sharing',
              'We do not sell your personal information. We share information only as described in this policy and with your consent.',
            ),
            _buildParagraph(
              '4. Data Security',
              'We implement appropriate security measures to protect your personal information from unauthorized access or disclosure.',
            ),
            _buildParagraph(
              '5. Your Rights',
              'You have the right to access, correct, or delete your personal information. Contact us to exercise these rights.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(String title, String date, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          date,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        SizedBox(height: 24),
        ...children,
      ],
    );
  }

  Widget _buildParagraph(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
