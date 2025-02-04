import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/providers/chat_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/views/messaging/message_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
        body: SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Leads",
                style: TextStyle(
                  color: orangeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  padding: EdgeInsets.all(10),
                  backgroundColor: Colors.grey[200],
                ),
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close),
              ),
            ],
          ),
          Consumer<PropertyProvider>(
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
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 10),
                itemCount: provider.leads.length,
                itemBuilder: (context, index) {
                  final lead = provider.leads[index];
                  return !lead.user.isProfessional
                      ? _buildLeadCard(lead)
                      : SizedBox();
                },
              );
            },
          ),
        ],
      ),
    ));
  }

  Widget _buildLeadCard(PropertyLead lead) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 30.0,
            blurRadius: 100.0,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey[200],
                      image: lead.user.profilePhotoUrl != null
                          ? DecorationImage(
                              fit: BoxFit.cover,
                              image: NetworkImage(lead.user.profilePhotoUrl!),
                            )
                          : null,
                    ),
                    child: lead.user.profilePhotoUrl == null
                        ? Icon(Icons.person, color: Colors.grey[400], size: 28)
                        : null,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          lead.user.displayName,
                          style: AppTextStyles.subtitle().copyWith(
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          lead.user.email ?? 'No email',
                          style: AppTextStyles.caption().copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Viewed ${lead.viewCount} times',
                          style: AppTextStyles.caption().copyWith(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatTimestamp(lead.lastViewed),
                        style: AppTextStyles.caption().copyWith(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (lead.user.phoneNumber != null) ...[
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    try {
                      final chatProvider =
                          Provider.of<ChatProvider>(context, listen: false);
                      final chatRoom =
                          await chatProvider.createOrGetChatRoom(lead.user.id);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChatMessageScreen(room: chatRoom),
                          settings: RouteSettings(
                            name: 'ChatMessageScreen',
                            arguments: ChatMessageScreen(room: chatRoom),
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to open chat: $e')),
                      );
                    }
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: Colors.orange[700],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Chat',
                          style: AppTextStyles.caption().copyWith(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 16),
              Row(
                children: [
                  if (lead.user.email != null) ...[
                    SizedBox(height: 12),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.45,
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lead.user.email!,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption().copyWith(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (lead.user.phoneNumber != null) ...[
                    SizedBox(width: 16),
                    GestureDetector(
                      onTap: () async {
                        final url = 'tel:${lead.user.phoneNumber}';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: Colors.green[700],
                            ),
                            SizedBox(width: 8),
                            Text(
                              lead.user.phoneNumber!,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption().copyWith(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          try {
                            final chatProvider = Provider.of<ChatProvider>(
                                context,
                                listen: false);
                            final chatRoom = await chatProvider
                                .createOrGetChatRoom(lead.user.id);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatMessageScreen(room: chatRoom),
                                settings: RouteSettings(
                                  name: 'ChatMessageScreen',
                                  arguments: ChatMessageScreen(room: chatRoom),
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to open chat: $e')),
                            );
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 16,
                                color: Colors.orange[700],
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Chat',
                                style: AppTextStyles.caption().copyWith(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          )),
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
