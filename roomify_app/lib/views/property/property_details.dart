import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/chatModel.dart';
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
import 'package:cached_network_image/cached_network_image.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final Listing listing;
  PropertyDetailsScreen(this.listing);

  @override
  _PropertyDetailsScreenState createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
                            isFavorite: provider.isFavorite(widget.listing.id),
                            onTap: () =>
                                provider.toggleFavorite(widget.listing),
                          )),
                  SizedBox(width: 13),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Main image carousel
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: widget.listing.property!.imageUrls!.isEmpty
                            ? widget.listing.imageUrls!.length
                            : widget.listing.property!.imageUrls!.length,
                        itemBuilder: (context, index) {
                          final imageUrl =
                              widget.listing.property!.imageUrls!.isEmpty
                                  ? widget.listing.imageUrls![index]
                                  : widget.listing.property!.imageUrls![index];
                          return ClipRRect(
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(40),
                                bottomRight: Radius.circular(40)),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            ),
                          );
                        },
                      ),
                      // Image counter indicator
                      Positioned(
                        right: 16,
                        top: 16,
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentPage + 1}/${widget.listing.property!.imageUrls!.isEmpty ? widget.listing.imageUrls!.length : widget.listing.property!.imageUrls!.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Page indicators at bottom
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.listing.property!.imageUrls!.isEmpty
                                ? widget.listing.imageUrls!.length
                                : widget.listing.property!.imageUrls!.length,
                            (index) => Container(
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ),
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
                                  widget.listing.title,
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
                                      widget.listing.location,
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
                                "\$ ${widget.listing.price}",
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
                                        widget
                                            .listing.property!.numberOfBedrooms
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
                                        widget
                                            .listing.property!.numberOfBathrooms
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
                                                "${widget.listing.property!.maxOccupancy}",
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
                        widget.listing.description ?? '',
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
                      if (widget.listing.property!.amenities!.isNotEmpty)
                        buildPreferencesSection(
                            widget.listing.property!.amenities!),

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
            child: ExpandableUserCard(user: widget.listing.user!),
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
  final bool isMarketplace;
  final VoidCallback? onTap;

  ExpandableUserCard({
    required this.user,
    this.isMarketplace = false,
    this.onTap,
  });

  @override
  _ExpandableUserCardState createState() => _ExpandableUserCardState();
}

class _ExpandableUserCardState extends State<ExpandableUserCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    if (!widget.isMarketplace) {
      setState(() {
        isExpanded = !isExpanded;
        if (isExpanded) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      });
    }
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
        onTap: widget.isMarketplace ? widget.onTap : _toggleExpand,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 40.0,
                    blurRadius: 100.0,
                    offset: Offset(10, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                          backgroundImage: widget.user.profilePhotoUrl != null
                              ? CachedNetworkImageProvider(
                                  widget.user.profilePhotoUrl!,
                                )
                              : null,
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
                              widget.user.university != null
                                  ? "${widget.user.university} | ${widget.user.age}yo"
                                  : "${widget.user.age}yo",
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
                  SizeTransition(
                    sizeFactor: _controller,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 5),
                          Divider(),
                          if (widget.user.bio != null) ...[
                            Text(
                              'Bio',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: orangeColor,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(widget.user.bio!,
                                style: AppTextStyles.small(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                          if (widget.user.preferences!.isNotEmpty) ...[
                            SizedBox(height: 16),
                            Text(
                              'Preferences',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: orangeColor,
                                  fontWeight: FontWeight.bold),
                            ),
                            buildPreferencesSection(widget.user.preferences!),
                          ],
                          SizedBox(height: 16),
                          GestureDetector(
                            onTap: () async {
                              final chatRoom = await context
                                  .read<ChatProvider>()
                                  .createOrGetChatRoom(
                                    widget.user.id,
                                  );

                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatMessageScreen(
                                      room: chatRoom,
                                    ),
                                  ));
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      border: Border.all(
                                          color: Colors.grey.shade300),
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
                                    onPressed: null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
