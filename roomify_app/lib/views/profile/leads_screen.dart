import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/utils/text_styles.dart';

class LeadsScreen extends StatefulWidget {
  @override
  _LeadsScreenState createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  @override
  void initState() {
    super.initState();
    // Load leads when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadLeads();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Property Leads'),
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
 

          if (provider.leads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_search, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No leads yet',
                    style: AppTextStyles.title(),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'When users view your properties,\nthey will appear here',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption(),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.leads.length,
            itemBuilder: (context, index) {
              final lead = provider.leads[index];
              return _buildLeadCard(lead);
            },
          );
        },
      ),
    );
  }

  Widget _buildLeadCard(PropertyLead lead) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: lead.user.profilePhotoUrl != null
                      ? NetworkImage(lead.user.profilePhotoUrl!)
                      : null,
                  child: lead.user.profilePhotoUrl == null
                      ? Icon(Icons.person)
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.user.displayName,
                        style: AppTextStyles.subtitle(),
                      ),
                      Text(
                        lead.user.university ?? 'No university',
                        style: AppTextStyles.caption(),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Viewed ${lead.viewCount} times',
                      style: AppTextStyles.caption(),
                    ),
                    Text(
                      _formatTimestamp(lead.lastViewed),
                      style: AppTextStyles.caption(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Interested in: ${lead.propertyTitle}',
              style: AppTextStyles.body(),
            ),
            if (lead.user.email != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    lead.user.email!,
                    style: AppTextStyles.caption(),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    try {
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      print('Error formatting timestamp: $e');
      return 'Recently';
    }
  }
}
