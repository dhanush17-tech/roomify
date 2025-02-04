import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/views/home/favourites.dart';
import 'package:roomify_app/views/home/property_search_screen.dart';
import 'package:roomify_app/views/messaging/chat_home.dart';
import 'package:roomify_app/views/messaging/message_screen.dart';
import 'package:roomify_app/views/property/property_details.dart';
import 'package:roomify_app/views/roomate_match/roommate_match.dart';
import 'package:roomify_app/widgets/location_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:roomify_app/providers/chat_provider.dart';
import 'package:roomify_app/widgets/roomify_verified.dart';

class HomeScreen extends StatefulWidget {
  User user;
  double latitude;
  double longitude;
  HomeScreen(
      {required this.user, required this.latitude, required this.longitude});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check if user has location set
      if (widget.user.latitude == 0.0 ||
          widget.user.longitude == 0.0 ||
          widget.user.latitude == null ||
          widget.user.longitude == null) {
        final profileProvider = context.read<ProfileProvider>();
        // Update user location with current location
        await profileProvider.updateUserLocation(
            widget.latitude, widget.longitude);
      }

      context.read<PropertyProvider>().loadFavorites();
      _requestNotificationPermission();
    });
  }

  Future<void> _requestNotificationPermission() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');

      // Get FCM token for this device
      String? token = await messaging.getToken();
      if (token != null) {
        // TODO: Send this token to your backend
        print('FCM Token: $token');
        await context.read<ProfileProvider>().updateFcmToken(token);
        print('FCM Token updated to Database');
        print('Subscribed to general topic');
        await FirebaseMessaging.instance.subscribeToTopic('general');
      }
    } catch (e) {
      print('Failed to get notification permission: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Profile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //an option to change the location
                      LocationSelector(),
                      SizedBox(height: 10),
                      Text(
                        'Find The Best',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Apartments',
                              style: TextStyle(
                                fontSize: 24,
                                color: blackTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: ' & ',
                              style: TextStyle(
                                fontSize: 24,
                                color: blackTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: 'Houses',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChatHome()));
                      },
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey[200],
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Image.asset(
                              'assets/icons/send.png',
                              width: 22,
                              color: Colors.orange,
                            ),
                            Positioned(
                              top: -20,
                              left: 20,
                              child: Consumer<ChatProvider>(
                                builder: (context, chatProvider, child) {
                                  final totalUnread =
                                      chatProvider.getTotalUnreadCount();
                                  if (totalUnread == 0)
                                    return SizedBox.shrink();

                                  return Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      totalUnread > 99
                                          ? '99+'
                                          : totalUnread.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Search Bar
              Hero(
                tag: 'home_search_field',
                child: Material(
                  color: Colors.transparent,
                  child: TextField(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SearchMapScreen(
                                    query: '',
                                  )));
                    },
                    decoration: InputDecoration(
                      hintText: "Search for apartments, houses...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Property Type Filter

              // Popular Section
              Text(
                'Popular',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 16),

              // Property Cards
              Consumer<PropertyProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return _fadeShimmerSearchListView();
                  }

                  _fadeController.forward();

                  if (!provider.isLoading && provider.recommendations.isEmpty) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.home_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No recommendations available',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Check back later for personalized property suggestions',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimationLimiter(
                      child: ListView.separated(
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 20),
                        shrinkWrap: true,
                        physics: BouncingScrollPhysics(),
                        itemCount: provider.recommendations.length,
                        itemBuilder: (BuildContext context, int index) {
                          final listing = provider.recommendations[index];
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            delay: Duration(milliseconds: 00),
                            child: SlideAnimation(
                              duration: Duration(milliseconds: 2000),
                              curve: Curves.fastLinearToSlowEaseIn,
                              horizontalOffset: 0,
                              verticalOffset: 150.0,
                              child: FlipAnimation(
                                duration: Duration(milliseconds: 2000),
                                curve: Curves.fastLinearToSlowEaseIn,
                                flipAxis: FlipAxis.y,
                                child: PropertyCard(
                                    listing, widget.latitude, widget.longitude),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fadeShimmerSearchListView() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: 5, // Number of shimmer items to show
      separatorBuilder: (context, index) => SizedBox(height: 20),
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeShimmer(
                height: 200,
                width: double.infinity,
                radius: 12,
                highlightColor: Colors.grey[200]!,
                baseColor: Colors.grey[300]!,
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FadeShimmer(
                    height: 15,
                    width: 100,
                    radius: 4,
                    highlightColor: Colors.grey[200]!,
                    baseColor: Colors.grey[300]!,
                  ),
                  FadeShimmer(
                    height: 15,
                    width: 50,
                    radius: 4,
                    highlightColor: Colors.grey[200]!,
                    baseColor: Colors.grey[300]!,
                  ),
                ],
              ),
              SizedBox(height: 8),
              FadeShimmer(
                height: 20,
                width: double.infinity,
                radius: 4,
                highlightColor: Colors.grey[200]!,
                baseColor: Colors.grey[300]!,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  FadeShimmer(
                    height: 15,
                    width: 150,
                    radius: 4,
                    highlightColor: Colors.grey[200]!,
                    baseColor: Colors.grey[300]!,
                  ),
                  Spacer(),
                  FadeShimmer(
                    height: 15,
                    width: 80,
                    radius: 4,
                    highlightColor: Colors.grey[200]!,
                    baseColor: Colors.grey[300]!,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

FloorPlan? getMinPriceFloorPlan(Listing listing) {
  if (listing.property?.floorPlans == null ||
      listing.property!.floorPlans!.isEmpty) {
    return null;
  }
  return listing.property!.floorPlans!
      .reduce((curr, next) => curr.price < next.price ? curr : next);
}

// New Property Card Widget
class PropertyCard extends StatelessWidget {
  final Listing listing;
  final double latitude;
  final double longitude;

  const PropertyCard(this.listing, this.latitude, this.longitude);

  // Helper method to get minimum floor plan details

  @override
  Widget build(BuildContext context) {
    // Get minimum price floor plan if it's a professional listing
    final minPriceFloorPlan = listing.user?.isProfessional == true
        ? getMinPriceFloorPlan(listing)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: GestureDetector(
        onTap: () {
          // Track the property view
          context.read<PropertyProvider>().trackPropertyView(listing.id);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyDetailsScreen(
                listing,
                latitude,
                longitude,
              ),
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Hero(
                      tag: 'property_image_${listing.id}',
                      child: listing.property?.imageUrls == null ||
                              listing.property?.imageUrls.length == 0
                          ? listing.imageUrls?.isEmpty ?? true
                              ? Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.grey,
                                  child: Center(
                                    child: Text('No Image'),
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: listing.imageUrls![0],
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                )
                          : CachedNetworkImage(
                              imageUrl: listing.property!.imageUrls[0],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  listing.property?.isRoomifyChoice == true
                      ? Positioned(
                          top: 8,
                          left: 8,
                          child: RoomifyVerified(),
                        )
                      : SizedBox.shrink(),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<PropertyProvider>(
                      builder: (context, provider, child) {
                        if (provider.isLoading) {
                          return Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.grey),
                              ),
                            ),
                          );
                        }

                        return FavoriteButton(
                          isFavorite: provider.isFavorite(listing.id),
                          onTap: () => provider.toggleFavorite(listing),
                        );
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Property Details
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 0),
                      child: Text(
                        listing.title.trim(),
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '\$${minPriceFloorPlan?.price.toStringAsFixed(0) ?? listing.price}/month',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 4),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.grey, size: 16),
                    SizedBox(width: 4),
                    Text(
                      listing.location,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Spacer(),
                    Icon(Icons.bed_outlined, color: Colors.grey, size: 20),
                    SizedBox(width: 4),
                    Text(
                        '${minPriceFloorPlan?.bedrooms ?? listing.property?.numberOfBedrooms}'),
                    SizedBox(width: 16),
                    Icon(Icons.bathtub_outlined, color: Colors.grey, size: 20),
                    SizedBox(width: 4),
                    Text(
                        '${minPriceFloorPlan?.bathrooms ?? listing.property?.numberOfBathrooms}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const FavoriteButton({
    required this.isFavorite,
    required this.onTap,
  });

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
