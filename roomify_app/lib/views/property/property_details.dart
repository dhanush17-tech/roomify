import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/chat_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/views/home/home_screen.dart';
import 'package:roomify_app/views/messaging/message_screen.dart';
import 'package:roomify_app/views/roomate_match/roommate_match.dart';

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
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            slivers: [
              // App Bar with image
              SliverAppBar(
                pinned: true,
                expandedHeight: 400,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.only(left: 13),
                ),
                actions: [
                  Consumer<PropertyProvider>(
                      builder: (ctx, provider, _) => FavoriteButton(
                            isFavorite: provider.isFavorite(listing.id),
                            onTap: () => provider.toggleFavorite(listing),
                          )),
                  SizedBox(width: 13),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Main image
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40)),
                        child: Image.network(
                          listing.property!.imageUrls!.isEmpty
                              ? listing.imageUrls![0]
                              : listing.property!.imageUrls![0],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double
                              .infinity, // Set the height to match the expandedHeight of SliverAppBar
                        ),
                      ),
                      // Small images on the right
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Column(
                          children: [
                            ...listing.imageUrls.isNotEmpty
                                ? [
                                    Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.9),
                                          width: 3,
                                        ),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                              listing.imageUrls![1]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    if (listing.imageUrls!.length > 2)
                                      Container(
                                        margin: EdgeInsets.only(bottom: 8),
                                        width: 60,
                                        height: 60,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            width: 3,
                                          ),
                                        ),
                                        child: Text(
                                          '+${listing.imageUrls!.length - 2}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ]
                                : listing.property!.imageUrls!.isNotEmpty
                                    ? [
                                        Container(
                                          margin: EdgeInsets.only(bottom: 8),
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              width: 3,
                                            ),
                                            image: DecorationImage(
                                              image: NetworkImage(listing
                                                  .property!.imageUrls![1]),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        if (listing
                                                .property!.imageUrls!.length >
                                            2)
                                          Container(
                                            margin: EdgeInsets.only(bottom: 8),
                                            width: 60,
                                            height: 60,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                width: 3,
                                              ),
                                            ),
                                            child: Text(
                                              '+${listing.property!.imageUrls!.length - 2}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ]
                                    : [],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating and Title section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left side - Rating, title, location
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Rating
                                Row(
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.amber, size: 20),
                                    SizedBox(width: 4),
                                    Text(
                                      "4.9",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),

                                // Title
                                Text(
                                  listing.title,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                // Location
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        color: Colors.grey, size: 20),
                                    SizedBox(width: 4),
                                    Text(
                                      listing.location,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Right side - Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "\$ ${listing.price}",
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "per month",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Action buttons
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.bed_outlined),
                                        onPressed: () {},
                                      ),
                                      Text(
                                        listing.property!.numberOfBedrooms
                                            .toString(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.bathtub_outlined),
                                        onPressed: () {},
                                      ),
                                      Text(
                                        listing.property!.numberOfBathrooms
                                            .toString(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12.0, horizontal: 12.0),
                                    child: RichText(
                                      text: TextSpan(
                                        text: "Max occupancy of ",
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.black),
                                        children: <TextSpan>[
                                          TextSpan(
                                            text:
                                                "${listing.property!.maxOccupancy}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Agent info

                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        listing.description ?? '',
                        style: AppTextStyles.small(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text('Amenities',
                          style: AppTextStyles.title(
                              fontSize: 15, color: orangeColor)),
                      // Add preferences section
                      if (listing.property!.amenities!.isNotEmpty)
                        buildPreferencesSection(listing.property!.amenities!),

                      Row(children: [
                        Chip(
                          label: Text('Move-in on 2nd Feb 2025'),
                          backgroundColor: orangeColor.withOpacity(0.1),
                          labelStyle: AppTextStyles.small(
                              color: orangeColor, fontWeight: FontWeight.bold),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        SizedBox(width: 10),
                        Chip(
                          label: Text('Move-in on 2nd Feb 2025'),
                          backgroundColor: orangeColor.withOpacity(0.1),
                          labelStyle: AppTextStyles.small(
                              color: orangeColor, fontWeight: FontWeight.bold),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      ]),
                      SizedBox(height: 130),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ExpandableUserCard(user: listing.user!),
          ),
        ],
      ),
    );
  }

  Widget buildPreferencesSection(List preferences) {
    final preferencesList = preferences ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (preferencesList.isNotEmpty)
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: List<Widget>.generate(preferencesList.length, (index) {
              return Chip(
                label: Text('${preferencesList[index]}'),
                backgroundColor: Color(4293718257),
                labelStyle: AppTextStyles.small(
                    color: Colors.grey, fontWeight: FontWeight.normal),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              );
            }),
          ),
      ],
    );
  }
}

class ExpandableUserCard extends StatefulWidget {
  final User user;

  ExpandableUserCard({required this.user});

  @override
  _ExpandableUserCardState createState() => _ExpandableUserCardState();
}

class _ExpandableUserCardState extends State<ExpandableUserCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = Tween<double>(
      begin: 90,
      end: 300,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 26,
        right: 26,
        bottom: 26,
      ),
      child: GestureDetector(
        onTap: _toggleExpand,
        child: AnimatedBuilder(
          animation: _heightAnimation,
          builder: (context, child) {
            return Container(
              height: _heightAnimation.value,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade200,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 40.0,
                    blurRadius: 100.0,
                    offset: Offset(10, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.black,
                            backgroundImage:
                                NetworkImage(widget.user.profilePhotoUrl ?? ''),
                          ),
                        ),
                        SizedBox(width: 5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.displayName,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                "${widget.user.university} | ${widget.user.age}yo",
                                style: TextStyle(
                                  fontWeight: FontWeight.w200,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          duration: Duration(milliseconds: 300),
                          turns: isExpanded ? 0.25 : 0,
                          child: Icon(Icons.arrow_forward_ios_outlined),
                        ),
                      ],
                    ),
                    if (isExpanded) ...[
                      SizedBox(height: 16),
                      Divider(),
                      if (widget.user.bio != null) ...[
                        Text(
                          'Bio',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(widget.user.bio!),
                        SizedBox(height: 16),
                      ],
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoItem(Icons.language, widget.user.language),
                          _buildInfoItem(Icons.location_on,
                              widget.user.location ?? 'Not specified'),
                          _buildInfoItem(Icons.school,
                              widget.user.university ?? 'Not specified'),
                        ],
                      ),
                      SizedBox(height: 16),
                      //contact button
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: orangeColor,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 12.0),
                                child: Center(
                                  child: Text(
                                    'Contact',
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  width: 3, color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.arrow_forward_ios_rounded),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey),
      ],
    );
  }
}
