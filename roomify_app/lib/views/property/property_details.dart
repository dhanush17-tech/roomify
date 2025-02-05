import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
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
import 'package:roomify_app/views/property/add_property.dart';
import 'package:roomify_app/views/property/report_listing.dart';
import 'package:roomify_app/views/roomate_match/roommate_match.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

class PropertyDetailsScreen extends StatefulWidget {
  Listing listing;
  final double latitude;
  final double longitude;

  PropertyDetailsScreen(this.listing, this.latitude, this.longitude);

  @override
  _PropertyDetailsScreenState createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool isOwnListing() {
    final currentUserId = context.read<AuthProvider>().user?.id;
    return currentUserId == widget.listing.user?.id;
  }

  void navigateToChat(BuildContext context, User propertyOwner) async {
    if (!mounted) return;

    try {
      // Get or create chat room with property owner
      final chatRoom = await context.read<ChatProvider>().createOrGetChatRoom(
            propertyOwner.id,
          );

      if (!mounted) return;

      // Navigate to chat screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatMessageScreen(room: chatRoom),
          settings: RouteSettings(
            name: 'ChatMessageScreen',
            arguments: ChatMessageScreen(room: chatRoom),
          ),
        ),
      );

      // After returning from chat screen
      if (mounted) {
        setState(() {
          // Update any necessary state
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open chat: $e')),
        );
      }
    }
  }

  void _shareListing() {
    final String shareUrl =
        'http://roomify-landingpage.vercel.app/property/${widget.listing.id}';
    Share.share(
      'Check out this property on Roomify: $shareUrl',
      subject: widget.listing.title,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Schedule the loading after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocationDetails();
    });
  }

  Map<String, dynamic>? _locationDetails;
  bool _loadingLocationDetails = false;
  TransitDetails? _transitDetails;
  bool _isLoadingTransit = false;
  String? _error;

  Future<void> _loadLocationDetails() async {
    if (!mounted) return;

    setState(() {
      _loadingLocationDetails = true;
      _error = null;
    });

    try {
      final provider = Provider.of<PropertyProvider>(context, listen: false);
      final details = await provider.getLocationDetails(widget.listing.id);

      if (mounted) {
        setState(() {
          _locationDetails = details;
          _loadingLocationDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadingLocationDetails = false;
        });
      }
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
                expandedHeight: MediaQuery.of(context).size.height * 0.5,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_back, color: blackTextColor),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.share, color: blackTextColor),
                    ),
                    onPressed: () {
                      Share.share(
                        'Check out this property on Roomify!\n${widget.listing.title}\n\nroomify://app/property/${widget.listing.id}',
                      );
                    },
                  ),
                  if (isOwnListing() && !widget.listing.user!.isProfessional)
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit, color: Colors.grey),
                      ),
                      onPressed: () async {
                        final updatedListing = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddPropertyScreen(
                              existingListing: widget.listing,
                            ),
                          ),
                        );

                        // If we got an updated listing back, update the UI
                        if (updatedListing != null && mounted) {
                          setState(() {
                            widget.listing = updatedListing;
                          });
                        }
                      },
                    ),
                  if (!isOwnListing()) ...[
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.report_outlined, color: Colors.grey),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => ReportScreen(
                              listingId: widget.listing.id,
                              listingType: widget.listing.title,
                              latitude: widget.latitude,
                              longitude: widget.longitude,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  Consumer<PropertyProvider>(
                    builder: (ctx, provider, _) => AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: IconButton(
                        key: Key(
                            provider.isFavorite(widget.listing.id).toString()),
                        icon: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            provider.isFavorite(widget.listing.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: provider.isFavorite(widget.listing.id)
                                ? Colors.redAccent
                                : blackTextColor,
                          ),
                        ),
                        onPressed: () =>
                            provider.toggleFavorite(widget.listing),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
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
                        itemCount: widget.listing.imageUrls!.length > 0
                            ? widget.listing.imageUrls!.length
                            : widget.listing.property!.imageUrls!.length,
                        itemBuilder: (context, index) {
                          final imageUrl = widget.listing.imageUrls!.length > 0
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

                      // Page indicators at bottom
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.listing.imageUrls!.length > 0
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
                          SizedBox(width: 10),
                          // Right side - Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                widget.listing.user!.isProfessional
                                    ? widget.listing.property?.floorPlans !=
                                                null &&
                                            widget.listing.property!.floorPlans!
                                                .isNotEmpty
                                        ? "\$${widget.listing.property!.floorPlans!.map((fp) => fp.price).reduce((a, b) => a < b ? a : b)} - \$${widget.listing.property!.floorPlans!.map((fp) => fp.price).reduce((a, b) => a > b ? a : b)}"
                                        : "\$${widget.listing.price}"
                                    : "\$${widget.listing.price}",
                                style: TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.bold,
                                    color: orangeColor),
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
                                        _getBedroomText(),
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
                                        _getBathroomText(),
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
                                        text: "Max occupancy ",
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: blackTextColor),
                                        children: <TextSpan>[
                                          TextSpan(
                                            text: _getMaxOccupancyText(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: blackTextColor,
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

                      // Floor Plans Section
                      if (widget.listing.property?.floorPlans != null &&
                          widget.listing.property!.floorPlans!.isNotEmpty) ...[
                        SizedBox(height: 20),
                        Text(
                          'Floor Plans',
                          style: AppTextStyles.title(
                              fontSize: 15, color: orangeColor),
                        ),
                        SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount:
                              widget.listing.property!.floorPlans!.length,
                          itemBuilder: (context, index) {
                            final plan =
                                widget.listing.property!.floorPlans![index];
                            return _buildFloorPlan(plan);
                          },
                        ),
                      ],

                      if (widget.listing.property?.moveInDate != null ||
                          widget.listing.property?.moveOutDate != null) ...[
                        SizedBox(height: 20),
                        Text(
                          'Availability',
                          style: AppTextStyles.title(
                              fontSize: 15, color: orangeColor),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.listing.property?.moveInDate != null)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.login,
                                              size: 16, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text(
                                            'Move-in',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        widget.listing.property?.moveInDate ==
                                                'Anytime'
                                            ? 'Available Anytime'
                                            : widget.listing.property
                                                    ?.moveInDate ??
                                                'Not specified',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (widget.listing.property?.moveOutDate !=
                                  null) ...[
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: Colors.grey[300],
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 16.0),
                                        child: Row(
                                          children: [
                                            Icon(Icons.logout,
                                                size: 16, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text(
                                              'Move-out',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 16.0),
                                        child: Text(
                                          widget.listing.property?.moveOutDate
                                                  .toString() ??
                                              'Not specified',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (widget.listing.property?.isLookingForRoomate ==
                          true) ...[
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: orangeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: orangeColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.people_outline, color: orangeColor),
                              SizedBox(width: 8),
                              Text(
                                'Looking for Roommate',
                                style: TextStyle(
                                  color: orangeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      _buildLocationDetailsSection(),
                      SizedBox(height: 130),
                    ],
                  ),
                ),
              ),
            ],
          ),
          widget.listing.user?.id == context.read<AuthProvider>().user?.id
              ? SizedBox()
              : Align(
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

  Widget _buildFloorPlan(FloorPlan plan) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FloorPlanViewer(
                        imageUrl: plan.imageUrl,
                        planName: plan.name,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: plan.imageUrl,
                      height: 70,
                      width: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '\$${plan.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '/month',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '${plan.squareFeet} sq ft',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: 36,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bed_outlined,
                            size: 18, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          '${plan.bedrooms}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bathtub_outlined,
                            size: 18, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          '${plan.bathrooms}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.apartment,
                            size: 18, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${plan.availableUnits} available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatYearMonth(String? yearMonth) {
    if (yearMonth == null) return 'Not specified';
    final parts = yearMonth.split('-');
    final year = parts[0];
    final month = DateTime(0, int.parse(parts[1])).toString().split(' ')[1];
    return '$month $year';
  }

  Widget _buildLocationDetailsSection() {
    if (_loadingLocationDetails) {
      return Center(child: CircularProgressIndicator());
    }

    if (_locationDetails == null) {
      return SizedBox.shrink();
    }

    // Parse the transit details from the response
    final transitDetails = TransitDetails.fromJson(_locationDetails!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (transitDetails.walkScore > 0) ...[
          SizedBox(height: 24),
          Text(
            'Transit & Location',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: blackTextColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: orangeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_walk, color: orangeColor),
                    const SizedBox(width: 8),
                    Text(
                      'Walk Score ${transitDetails.walkScore}',
                      style: TextStyle(
                        color: orangeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 15),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: orangeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.train_rounded, color: orangeColor),
                    const SizedBox(width: 8),
                    Text(
                      'Transit Score ${transitDetails.transitScore}',
                      style: TextStyle(
                        color: orangeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        if (transitDetails.railLines.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Rail lines ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: blackTextColor,
                ),
              ),
              Icon(Icons.train, color: blackTextColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Column(children: [
              ...transitDetails.railLines
                  .map((route) => _buildTransitRouteItem(route)),
            ]),
          ),
        ],
        if (transitDetails.busLines.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Bus lines ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: blackTextColor,
                ),
              ),
              Icon(Icons.directions_bus, color: blackTextColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                ...transitDetails.busLines
                    .map((route) => _buildTransitRouteItem(route)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTransitRouteItem(TransitRoute route) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route.name),
                  Text(route.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              Text(
                '${route.distance.toStringAsFixed(1)} miles away',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ]));
  }

  Widget _buildFeatureIndicator(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getBedroomText() {
    if (widget.listing.property?.floorPlans == null ||
        widget.listing.property!.floorPlans!.isEmpty) {
      return widget.listing.property!.numberOfBedrooms.toString();
    }

    final bedrooms = widget.listing.property!.floorPlans!
        .map((plan) => plan.bedrooms)
        .toList();
    final minBedrooms = bedrooms.reduce(min);
    final maxBedrooms = bedrooms.reduce(max);

    return minBedrooms == maxBedrooms
        ? minBedrooms.toString()
        : '$minBedrooms-$maxBedrooms';
  }

  String _getBathroomText() {
    if (widget.listing.property?.floorPlans == null ||
        widget.listing.property!.floorPlans!.isEmpty) {
      return widget.listing.property!.numberOfBathrooms.toString();
    }

    final bathrooms = widget.listing.property!.floorPlans!
        .map((plan) => plan.bathrooms)
        .toList();
    final minBathrooms = bathrooms.reduce(min);
    final maxBathrooms = bathrooms.reduce(max);

    return minBathrooms == maxBathrooms
        ? minBathrooms.toString()
        : '$minBathrooms-$maxBathrooms';
  }

  String _getMaxOccupancyText() {
    if (widget.listing.property?.floorPlans == null ||
        widget.listing.property!.floorPlans!.isEmpty) {
      return widget.listing.property!.maxOccupancy.toString();
    }

    // Calculate max occupancy based on bedrooms (2 per bedroom)
    final occupancies = widget.listing.property!.floorPlans!
        .map((plan) => plan.bedrooms * 2)
        .toList();
    final minOccupancy = occupancies.reduce(min);
    final maxOccupancy = occupancies.reduce(max);

    return minOccupancy == maxOccupancy
        ? minOccupancy.toString()
        : '$minOccupancy-$maxOccupancy';
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
                    color: blackTextColor.withOpacity(0.2),
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
                    if (widget.user.isProfessional) ...[
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
                              builder: (context) =>
                                  ChatMessageScreen(room: chatRoom),
                              settings: RouteSettings(
                                name: 'ChatMessageScreen',
                                arguments: ChatMessageScreen(room: chatRoom),
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  border:
                                      Border.all(color: Colors.grey.shade300),
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
                    if (!widget.user.isProfessional) ...[
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
                              backgroundColor: blackTextColor,
                              backgroundImage:
                                  widget.user.profilePhotoUrl != null
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
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
                                buildPreferencesSection(
                                    widget.user.preferences!),
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
                                      builder: (context) =>
                                          ChatMessageScreen(room: chatRoom),
                                      settings: RouteSettings(
                                        name: 'ChatMessageScreen',
                                        arguments:
                                            ChatMessageScreen(room: chatRoom),
                                      ),
                                    ),
                                  );
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
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                                            width: 3,
                                            color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                            Icons.arrow_forward_ios_rounded),
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
                  ]),
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

class FloorPlanViewer extends StatelessWidget {
  final String imageUrl;
  final String planName;

  const FloorPlanViewer({
    Key? key,
    required this.imageUrl,
    required this.planName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          planName,
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: PhotoView(
        imageProvider: CachedNetworkImageProvider(imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        initialScale: PhotoViewComputedScale.contained,
        backgroundDecoration: BoxDecoration(
          color: Colors.black,
        ),
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            value: event == null
                ? 0
                : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
          ),
        ),
      ),
    );
  }
}
