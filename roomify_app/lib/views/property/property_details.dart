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
import 'package:roomify_app/views/messaging/document_request_dialog.dart';
import 'package:roomify_app/views/messaging/message_screen.dart';
import 'package:roomify_app/views/property/add_property.dart';
import 'package:roomify_app/views/property/report_listing.dart';
import 'package:roomify_app/views/roomate_match/roommate_match.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationButton extends StatelessWidget {
  final String? location;
  final VoidCallback onTap;

  const LocationButton({
    Key? key,
    required this.location,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue, size: 16),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  location ?? '',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PropertyDetailsScreen extends StatefulWidget {
  Listing listing;
  final double latitude;
  final double longitude;

  PropertyDetailsScreen(this.listing, this.latitude, this.longitude);

  @override
  _PropertyDetailsScreenState createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    // Delay the location details loading to avoid build phase issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadLocationDetails();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
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
      context.read<PropertyProvider>().loadSimilarProperties(widget.listing.id);

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

  Future<void> _handlePropertyEdit() async {
    final updatedListing = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPropertyScreen(
          existingListing: widget.listing,
        ),
      ),
    );

    if (updatedListing != null && mounted) {
      // Start fade out animation
      await _animationController.forward();

      setState(() {
        widget.listing = updatedListing;
      });

      // Reset and play fade in animation
      await _animationController.reverse();
    }
  }

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

  Future<void> _openInGoogleMaps() async {
    final lat = widget.listing.latitude;
    final lng = widget.listing.longitude;

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location coordinates not available')),
      );
      return;
    }

    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 16,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back, color: Colors.black87),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Row(
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          child: IconButton(
                            icon: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.share_rounded,
                                  color: Colors.black87),
                            ),
                            onPressed: _shareListing,
                          ),
                        ),
                        if (isOwnListing() &&
                            !widget.listing.user!.isProfessional)
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            child: IconButton(
                              icon: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.edit_rounded,
                                    color: orangeColor),
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

                                if (updatedListing != null && mounted) {
                                  setState(() {
                                    widget.listing = updatedListing;
                                  });
                                }
                              },
                            ),
                          )
                        else ...[
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (C) => ReportScreen(
                                        listingId: widget.listing.id,
                                        listingType: widget.listing.title,
                                        latitude: widget.latitude,
                                        longitude: widget.longitude,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.flag_rounded,
                                        size: 18,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "Report",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            child: Consumer<PropertyProvider>(
                              builder: (ctx, provider, _) => FavoriteButton(
                                isFavorite:
                                    provider.isFavorite(widget.listing.id),
                                onTap: () =>
                                    provider.toggleFavorite(widget.listing),
                              ),
                            ),
                          ),
                        ],
                        SizedBox(width: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
                        child: Icon(Icons.arrow_back, color: blackTextColor),
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.only(left: 13),
                    ),
                    actions: [
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child:
                              Icon(Icons.share_rounded, color: blackTextColor),
                        ),
                        onPressed: _shareListing,
                      ),
                      if (isOwnListing() &&
                          !widget.listing.user!.isProfessional)
                        IconButton(
                          icon: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.edit_rounded, color: orangeColor),
                          ),
                          onPressed: _handlePropertyEdit,
                        ),
                      if (!isOwnListing())
                        IconButton(
                          icon: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.flag_rounded,
                                color: Colors.grey[600]),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (C) => ReportScreen(
                                  listingId: widget.listing.id,
                                  listingType: widget.listing.title,
                                  latitude: widget.latitude,
                                  longitude: widget.longitude,
                                ),
                              ),
                            );
                          },
                        ),
                      Consumer<PropertyProvider>(
                        builder: (ctx, provider, _) => FavoriteButton(
                          isFavorite: provider.isFavorite(widget.listing.id),
                          onTap: () => provider.toggleFavorite(widget.listing),
                        ),
                      ),
                      SizedBox(width: 10),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Hero(
                        tag: 'property-image-${widget.listing.id}',
                        child: Stack(
                          children: [
                            // Main image carousel
                            PageView.builder(
                              scrollDirection: Axis.horizontal,
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
                                final imageUrl =
                                    widget.listing.imageUrls!.length > 0
                                        ? widget.listing.imageUrls![index]
                                        : widget.listing.property!
                                            .imageUrls![index];
                                return ClipRRect(
                                  borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20)),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        (context),
                                        MaterialPageRoute(
                                          builder: (context) => PhotoView(
                                            imageProvider:
                                                NetworkImage(imageUrl),
                                          ),
                                        ),
                                      );
                                    },
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[200],
                                        child: Icon(Icons.home_outlined,
                                            color: Colors.grey[400], size: 50),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        color: Colors.grey[200],
                                        child: Icon(Icons.home_outlined,
                                            color: Colors.grey[400], size: 50),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Image gallery grid at bottom right
                            Positioned(
                              bottom: 16,
                              right: 10,
                              child: GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => Container(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.9,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'All Photos',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.close),
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: GridView.builder(
                                              padding: EdgeInsets.all(8),
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                mainAxisSpacing: 8,
                                                crossAxisSpacing: 8,
                                              ),
                                              itemCount: widget.listing
                                                          .imageUrls!.length >
                                                      0
                                                  ? widget
                                                      .listing.imageUrls!.length
                                                  : widget.listing.property!
                                                      .imageUrls!.length,
                                              itemBuilder: (context, index) {
                                                final imageUrl = widget.listing
                                                            .imageUrls!.length >
                                                        0
                                                    ? widget.listing
                                                        .imageUrls![index]
                                                    : widget.listing.property!
                                                        .imageUrls![index];
                                                return GestureDetector(
                                                  onTap: () {
                                                    _pageController
                                                        .animateToPage(
                                                      index,
                                                      duration: Duration(
                                                          milliseconds: 300),
                                                      curve: Curves.easeInOut,
                                                    );
                                                    Navigator.pop(context);
                                                  },
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    child: CachedNetworkImage(
                                                      imageUrl: imageUrl,
                                                      fit: BoxFit.cover,
                                                      placeholder:
                                                          (context, url) =>
                                                              Container(
                                                        color: Colors.grey[200],
                                                        child: Icon(
                                                            Icons.home_outlined,
                                                            color: Colors
                                                                .grey[400],
                                                            size: 30),
                                                      ),
                                                      errorWidget: (context,
                                                              url, error) =>
                                                          Container(
                                                        color: Colors.grey[200],
                                                        child: Icon(
                                                            Icons.home_outlined,
                                                            color: Colors
                                                                .grey[400],
                                                            size: 30),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_getTotalImages() > 1)
                                      Container(
                                        height: 80,
                                        width: 80,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: const Color.fromARGB(
                                                  179, 219, 219, 219),
                                              width: 3),
                                          image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: NetworkImage(widget.listing
                                                          .imageUrls!.length >
                                                      0
                                                  ? widget.listing.imageUrls![0]
                                                  : widget.listing.property!
                                                      .imageUrls![0])),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Stack(
                                          children: [
                                            Container(
                                              height: 80,
                                              width: 80,
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.5),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                            Center(
                                              child: DefaultTextStyle(
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                child: Text(
                                                  '+${(_getTotalImages() - 1).toString()}',
                                                ),
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
                      ),
                    )),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Hero(
                                    tag: 'property-title-${widget.listing.id}',
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Text(
                                        widget.listing.title
                                            .trim()
                                            .capitalize(),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
                                        ),
                                        overflow: TextOverflow.visible,
                                        softWrap: true,
                                        maxLines: null,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  LocationButton(
                                    location: widget.listing.location,
                                    onTap: _openInGoogleMaps,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Hero(
                              tag: 'property-price-${widget.listing.id}',
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          widget.listing.user!.isProfessional
                                              ? widget.listing.property!
                                                              .floorPlans !=
                                                          null &&
                                                      widget
                                                          .listing
                                                          .property!
                                                          .floorPlans!
                                                          .isNotEmpty
                                                  ? "\$${widget.listing.property!.floorPlans!.map((fp) => fp.price).reduce((a, b) => a < b ? a : b)} - \$${widget.listing.property!.floorPlans!.map((fp) => fp.price).reduce((a, b) => a > b ? a : b)}"
                                                  : "\$${widget.listing.price}"
                                              : "\$${widget.listing.price}",
                                          style: TextStyle(
                                            fontSize: 22,
                                            color: orangeColor,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'per month',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.normal,
                                          height: 1.0,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),

                        // Action buttons
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 20,
                                  alignment: WrapAlignment.spaceBetween,
                                  runAlignment: WrapAlignment.spaceBetween,
                                  direction: Axis.horizontal,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            width: 2,
                                            color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
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
                                    Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              width: 2,
                                              color: Colors.grey.shade300),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon:
                                                  Icon(Icons.bathtub_outlined),
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
                                        )),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            width: 2,
                                            color: Colors.grey.shade300),
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
                            widget
                                .listing.property!.floorPlans!.isNotEmpty) ...[
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
                        if (widget.listing.user?.isProfessional != true) ...[
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
                        SizedBox(height: 11),
                        _buildOffersSection(context),
                        _buildLocationDetailsSection(),
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
      ),
    );
  }

  int _getTotalImages() {
    final listingImages = widget.listing.imageUrls?.length ?? 0;
    final propertyImages = widget.listing.property?.imageUrls?.length ?? 0;
    return listingImages > 0 ? listingImages : propertyImages;
  }

  String _getImageUrl(int index) {
    return widget.listing.imageUrls!.length > 0
        ? widget.listing.imageUrls![index]
        : widget.listing.property!.imageUrls![index];
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
                        color: Colors.grey[200],
                        child: Icon(Icons.home_outlined,
                            color: Colors.grey[400], size: 30),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.home_outlined,
                            color: Colors.grey[400], size: 30),
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
          _buildSimilarProperties(),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 100),
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

  Widget _buildSimilarProperties() {
    return Consumer<PropertyProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingSimilar) {
          return Center(child: CircularProgressIndicator());
        }

        final similarProperties = provider.similarProperties;

        if (similarProperties.isEmpty) {
          return SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Similar Properties',
                style: AppTextStyles.title(fontSize: 15, color: orangeColor),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: similarProperties
                    .map(
                      (listing) => Container(
                        width: 280,
                        margin: EdgeInsets.only(right: 16),
                        child: PropertyCard(
                          listing,
                          widget.latitude,
                          widget.longitude,
                          isShadow: false,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
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

  Widget _buildOffersSection(BuildContext context) {
    final isProfessionalListing = widget.listing.user?.isProfessional ?? false;
    if (!isProfessionalListing) {
      return SizedBox.shrink();
    }

    final offers = widget.listing.property?.offers ?? [];
    if (offers.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Special Offers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${offers.length} ${offers.length == 1 ? 'Offer' : 'Offers'}',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              final isValid = offer.validUntil.isAfter(DateTime.now());

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isValid ? Colors.grey[200]! : Colors.red[100]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isValid)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Expired',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      offer.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Valid until: ${DateFormat('MMM d, y').format(offer.validUntil)}',
                      style: TextStyle(
                        color: isValid ? Colors.grey[500] : Colors.red[300],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
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
                                    child: context
                                            .read<ChatProvider>()
                                            .isLoading
                                        ? CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : Text(
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
                              backgroundColor: Colors.black,
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
                                          child: context
                                                  .read<ChatProvider>()
                                                  .isLoading
                                              ? Center(
                                                child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                  ),
                                              )
                                              : Center(
                                                  child: Text(
                                                    'Contact',
                                                    style: TextStyle(
                                                        fontSize: 20,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold),
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

class FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  _FavoriteButtonState createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _animateIconChange();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateIconChange() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
        _animateIconChange();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: blackTextColor.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 100),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
            child: Icon(
              widget.isFavorite ? Icons.favorite : Icons.favorite_border,
              key: ValueKey<bool>(widget.isFavorite),
              color: widget.isFavorite ? Colors.red : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
