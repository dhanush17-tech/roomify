import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/chatModel.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/chat_provider.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/repository/auth_repo.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:roomify_app/views/property/property_details.dart';
import 'package:roomify_app/utils/text_styles.dart';

class ChatMessageScreen extends StatefulWidget {
  final ChatRoom room;

  ChatMessageScreen({required this.room});

  @override
  _ChatMessageScreenState createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  late User otherUser;
  bool _isExpanded = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isLoadingListings = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    final currentUserId = context.read<AuthProvider>().user?.id;
    otherUser = widget.room.participants.firstWhere(
      (user) => user.id != currentUserId,
      orElse: () => widget.room.participants[0],
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isLoadingListings) {
        _isLoadingListings = true;
        context.read<ProfileProvider>().loadUserListings(otherUser.id);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      context.read<ChatProvider>().sendMessage(
            widget.room.id,
            _messageController.text,
          );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF8F8F8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.black),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      width: 60,
                      height: 60,
                      child: Hero(
                        tag: 'profile-${widget.room.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                            image: otherUser.profilePhotoUrl != null
                                ? DecorationImage(
                                    fit: BoxFit.cover,
                                    image: CachedNetworkImageProvider(otherUser.profilePhotoUrl!))
                                : null,
                          ),
                          child: otherUser.profilePhotoUrl == null
                              ? Text(otherUser.displayName[0])
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUser.displayName,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          otherUser.age.toString() + ' years old',
                          style: TextStyle(
                            color: orangeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    Container(
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF8F8F8),
                      ),
                      child: IconButton(
                        icon: AnimatedRotation(
                          duration: Duration(milliseconds: 300),
                          turns: _isExpanded ? 0.5 : 0,
                          child: Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.black),
                        ),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                            if (_isExpanded) {
                              _expandController.forward();
                            } else {
                              _expandController.reverse();
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (otherUser.bio != null) ...[
                          Text(
                            'Bio',
                            style: AppTextStyles.title(
                                fontSize: 15, color: orangeColor),
                          ),
                          SizedBox(height: 8),
                          Text(
                            otherUser.bio!,
                            style: AppTextStyles.small(
                              fontWeight: FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                        if (otherUser.preferences.isNotEmpty) ...[
                          Text(
                            'Preferences',
                            style: AppTextStyles.title(
                                fontSize: 15, color: orangeColor),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: otherUser.preferences.map((pref) {
                              return Chip(
                                label: Text(pref.preference),
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                labelStyle: AppTextStyles.small(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 16),
                        ],
                        Consumer<ProfileProvider>(
                          builder: (context, provider, child) {
                            final cachedListings =
                                provider.getCachedListings(otherUser.id);
                            final properties = cachedListings
                                .where((listing) =>
                                    listing.type == ListingType.Property)
                                .toList();

                            if (properties.isNotEmpty) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Properties',
                                    style: AppTextStyles.title(
                                        fontSize: 15, color: orangeColor),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    height: 180,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: properties.length,
                                      itemBuilder: (context, index) {
                                        final property = properties[index];
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PropertyDetailsScreen(
                                                        property),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 200,
                                            margin: EdgeInsets.only(right: 16),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              color: Colors.white,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  child: CachedNetworkImage(
                                                    imageUrl: property
                                                            .property
                                                            ?.imageUrls
                                                            ?.first ??
                                                        '',
                                                    height: 120,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    placeholder: (context,
                                                            url) =>
                                                        buildPropertyImageShimmer(),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            Container(
                                                      height: 120,
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[300],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15),
                                                      ),
                                                      child: Icon(
                                                        Icons.error_outline,
                                                        color: Colors.grey[400],
                                                        size: 40,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        property.title,
                                                        style: AppTextStyles
                                                            .subtitle(
                                                                fontSize: 14),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        '\$${property.price}/month',
                                                        style:
                                                            AppTextStyles.small(
                                                          color: orangeColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                final messages = provider.getMessages(widget.room.id);
                messages.sort((a, b) => a.compareTo(b));

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessage(messages[messages.length - 1 - index]);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    final isMe = message.senderId == currentUserId;

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? Color(0xFF2B3F6C) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeago.format(message.createdAt, locale: 'en'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Say something...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: orangeColor,
                ),
                child: InkWell(
                  onTap: _sendMessage,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget buildPropertyImageShimmer() {
  return ClipRRect(
    borderRadius: BorderRadius.circular(15),
    child: FadeShimmer(
      height: 120,
      width: double.infinity,
      radius: 15,
      highlightColor: Colors.grey[200]!,
      baseColor: Colors.grey[300]!,
    ),
  );
}
