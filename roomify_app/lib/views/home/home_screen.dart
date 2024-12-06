import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/views/home/favourites.dart';
import 'package:roomify_app/views/messaging/chat_home.dart';
import 'package:roomify_app/views/messaging/message_screen.dart';
import 'package:roomify_app/views/property/property_details.dart';
import 'package:roomify_app/views/home/search_screen.dart';
import 'package:roomify_app/views/roomate_match/roommate_match.dart';
import 'package:roomify_app/widgets/location_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fade_shimmer/fade_shimmer.dart';

class HomeScreen extends StatefulWidget {
  User user;
  HomeScreen({required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load favorites when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().loadFavorites();
    });
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
                      Text(
                        'Find Your Best',
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
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: ' & ',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.black,
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
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[200],
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChatListScreen()));
                      },
                      child: Image.asset(
                        'assets/icons/send.png',
                        width: 20,
                        color: Colors.orange,
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
                              builder: (context) =>
                                  SearchMapScreen(query: '')));
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

                  return AnimationLimiter(
                    child: ListView.separated(
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 20),
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(),
                      itemCount: provider.pairUpListings.length,
                      itemBuilder: (BuildContext context, int index) {
                        final listing = provider.pairUpListings[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          delay: Duration(milliseconds: 00),
                          child: SlideAnimation(
                            duration: Duration(milliseconds: 2000),
                            curve: Curves.fastLinearToSlowEaseIn,
                            horizontalOffset: 0,
                            verticalOffset: 300.0,
                            child: FlipAnimation(
                              duration: Duration(milliseconds: 3000),
                              curve: Curves.fastLinearToSlowEaseIn,
                              flipAxis: FlipAxis.y,
                              child: PropertyCard(listing: listing),
                            ),
                          ),
                        );
                      },
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

// New Property Card Widget
class PropertyCard extends StatelessWidget {
  final Listing listing;

  const PropertyCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyDetailsScreen(listing),
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
                    child: CachedNetworkImage(
                      imageUrl: listing.property!.imageUrls!.isEmpty
                          ? listing.imageUrls![0]
                          : listing.property!.imageUrls![0],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
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

              SizedBox(height: 8),

              // Property Details
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${listing.price}/year',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 18),
                        Text(' ${listing.property?.rating ?? 4.0}',
                            style: TextStyle(color: Colors.amber)),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 4),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  listing.title,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
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
                    Text('${listing.property?.numberOfBedrooms}'),
                    SizedBox(width: 16),
                    Icon(Icons.bathtub_outlined, color: Colors.grey, size: 20),
                    SizedBox(width: 4),
                    Text('${listing.property?.numberOfBathrooms}'),
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
                color: Colors.black.withOpacity(0.1),
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
