import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/chat_provider.dart';
import 'package:roomify_app/providers/roommateMatch_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/utils/circular_reveal_clipper.dart';
import 'package:roomify_app/views/home/home_screen.dart';
import 'package:roomify_app/views/messaging/message_screen.dart';
import 'package:roomify_app/views/profile/edit_profile.dart';
import 'package:roomify_app/views/property/property_details.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fade_shimmer/fade_shimmer.dart';
import 'package:roomify_app/widgets/tags.dart';

class RoommateMatchScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  RoommateMatchScreen(this.latitude, this.longitude);

  @override
  _RoommateMatchScreenState createState() => _RoommateMatchScreenState();
}

class _RoommateMatchScreenState extends State<RoommateMatchScreen>
    with TickerProviderStateMixin {
  final CardSwiperController controller = CardSwiperController();
  final ScrollController _mainScrollController = ScrollController();

  bool isSwiping = false;
  double? cardHeight;
  double swipeProgress = 0.0;
  CardSwiperDirection? currentDirection;

  late AnimationController _overlayController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _profileOverlayController;
  late Animation<double> _profileScaleAnimation;
  late Animation<double> _profileOpacityAnimation;

  bool isBioExpanded = false;

  @override
  void initState() {
    super.initState();
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeIn,
    ));

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

    _matchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _matchScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _matchAnimationController,
      curve: Curves.easeOutBack,
    ));

    _matchFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _matchAnimationController,
      curve: Curves.easeIn,
    ));

    _profileOverlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _profileScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _profileOverlayController,
      curve: Curves.easeOutBack,
    ));

    _profileOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _profileOverlayController,
      curve: Curves.easeIn,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatches();
    });
  }

  late AnimationController _matchAnimationController;
  late Animation<double> _matchScaleAnimation;
  late Animation<double> _matchFadeAnimation;

  @override
  void dispose() {
    _fadeController.dispose();
    _matchAnimationController.dispose();
    _mainScrollController.dispose();
    _overlayController.dispose();
    controller.dispose();
    _profileOverlayController.dispose();
    super.dispose();
  }

  void navigateToChat(BuildContext context, User otherUser) async {
    try {
      final chatRoom = await context.read<ChatProvider>().createOrGetChatRoom(
            otherUser.id,
          );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatMessageScreen(room: chatRoom),
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
  }

  Widget _buildMatchOverlay(User? matchedUser) {
    if (matchedUser == null) {
      return Center();
    }
    return GestureDetector(
      onTap: () {
        _matchAnimationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _matchAnimationController,
        builder: (context, child) {
          return BackdropFilter(
            filter: _matchAnimationController.value > 0
                ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Visibility(
              visible: _matchAnimationController.value > 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ScaleTransition(
                  scale: _matchScaleAnimation,
                  child: FadeTransition(
                    opacity: _matchFadeAnimation,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 150.0),
                                child: Transform.rotate(
                                  angle: -0.3,
                                  child: Container(
                                    margin: EdgeInsets.all(16),
                                    width: 150,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          spreadRadius: 20,
                                          color: Colors.orange.withOpacity(0.2),
                                          blurRadius: 20,
                                        ),
                                      ],
                                      border: Border.all(
                                          color: Colors.orange, width: 3),
                                      borderRadius: BorderRadius.circular(16),
                                      image: DecorationImage(
                                        image: CachedNetworkImageProvider(
                                            context
                                                    .read<AuthProvider>()
                                                    .user!
                                                    .profilePhotoUrl ??
                                                ''),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 150.0),
                                child: Transform.rotate(
                                  angle: 0.1,
                                  child: Container(
                                    margin: EdgeInsets.all(16),
                                    width: 150,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          spreadRadius: 20,
                                          color: Colors.orange.withOpacity(0.2),
                                          blurRadius: 20,
                                        ),
                                      ],
                                      border: Border.all(
                                          color: Colors.orange, width: 3),
                                      borderRadius: BorderRadius.circular(16),
                                      image: DecorationImage(
                                        image: CachedNetworkImageProvider(
                                            matchedUser!.profilePhotoUrl ?? ''),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'match',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'You can start chatting with your \nnew roommate',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: () {
                              navigateToChat(context, matchedUser!);
                              _matchAnimationController.reverse();
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Colors.orange,
                              minimumSize: Size(200, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              'Chat Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadMatches() async {
    context.read<RoommateMatchProvider>().clearMatches();
    await context.read<RoommateMatchProvider>().loadMatches();
    // Clear previous matches and shuffle the list
    setState(() {
      context.read<RoommateMatchProvider>().matches.shuffle();
    });
  }

  Widget _buildSwipeOverlay() {
    bool isLeft = currentDirection == CardSwiperDirection.left;
    bool isRight = currentDirection == CardSwiperDirection.right;

    return Positioned(
      bottom: 0,
      top: 0,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left swipe indicator (X)
          AnimatedBuilder(
            animation: _overlayController,
            builder: (context, child) {
              double opacity = _opacityAnimation.value;
              return Opacity(
                opacity: opacity,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Stack(
                    children: [
                      // Orange fill overlay
                      ClipPath(
                        clipper: CircularRevealClipper(
                          fraction: isLeft ? 1 - swipeProgress : 0.0,
                          fromLeft: true,
                        ),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Icon
                      Center(
                        child: Icon(
                          Icons.close,
                          color: isLeft && 1 - swipeProgress > 0.5
                              ? Colors.white
                              : Colors.orange,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Right swipe indicator (Check)
          AnimatedBuilder(
            animation: _overlayController,
            builder: (context, child) {
              double opacity = _opacityAnimation.value;
              return Opacity(
                opacity: opacity,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: Stack(
                    children: [
                      // Orange fill overlay
                      ClipPath(
                        clipper: CircularRevealClipper(
                          fraction: isRight ? swipeProgress : 0.0,
                          fromLeft: false,
                        ),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Icon
                      Center(
                        child: Icon(
                          Icons.check,
                          color: isRight && swipeProgress > 0.5
                              ? Colors.white
                              : Colors.orange,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletion(User user) {
    double completion = user.getProfileCompletion();
    bool isComplete = user.isProfileComplete();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Profile Completion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              if (!isComplete)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Required',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: completion / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? Colors.green : Colors.orange,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${completion.toStringAsFixed(0)}% Complete',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(User profile, RoommateMatchProvider provider) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Consumer<ChatProvider>(builder: (context, chatProvider, child) {
      return Listener(
        onPointerDown: (details) {
          setState(() {
            isSwiping = true;
            currentDirection = null;
          });
        },
        onPointerMove: (details) {
          double screenWidth = MediaQuery.of(context).size.width;
          double progress = details.localPosition.dx / screenWidth;

          setState(() {
            swipeProgress = progress.abs();
            currentDirection = details.localPosition.dx > screenWidth / 2
                ? CardSwiperDirection.right
                : CardSwiperDirection.left;

            if (!_overlayController.isAnimating) {
              _overlayController.forward();
            }
          });
        },
        onPointerUp: (details) {
          setState(() {
            isSwiping = false;
            _overlayController.reverse();

            Future.delayed(Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  swipeProgress = 0.0;
                  currentDirection = null;
                });
              }
            });
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background Image
                Container(
                  height: double.infinity,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: profile.profilePhotoUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          color: orangeColor,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child:
                          Icon(Icons.person, size: 50, color: Colors.grey[400]),
                    ),
                  ),
                ),
                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                // User Info and Listings
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: screenHeight * 0.3,
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${profile.displayName.capitalize()} · ${profile.age}',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (profile.status ==
                                        'Looking for a Roommate')
                                      Container(
                                        margin: EdgeInsets.only(left: 8),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: orangeColor.withOpacity(0.9),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '🔍 Looking',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.school,
                                        color: Colors.white70, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      profile.university ?? '',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                if (profile.bio != null) ...[
                                  Text(
                                    profile.bio!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    maxLines: isBioExpanded ? null : 3,
                                    overflow: isBioExpanded
                                        ? TextOverflow.visible
                                        : TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isBioExpanded = !isBioExpanded;
                                      });
                                    },
                                    child: Text(
                                      isBioExpanded ? 'View Less' : 'View More',
                                      style: TextStyle(
                                        color: Colors.orangeAccent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                if (profile.preferences.isNotEmpty) ...[
                                  SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: profile.preferences.map((pref) {
                                      return Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          pref.preference,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],

                                // Listings Section
                                if (profile.listings
                                    .where((listing) =>
                                        listing.type == ListingType.Property)
                                    .isNotEmpty) ...[
                                  SizedBox(height: 20),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Properties',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Container(
                                        height: 300,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: profile.listings
                                              .where((listing) =>
                                                  listing.type ==
                                                  ListingType.Property)
                                              .length,
                                          itemBuilder: (context, index) {
                                            final listing = profile.listings
                                                .where((listing) =>
                                                    listing.type ==
                                                    ListingType.Property)
                                                .toList()[index];
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        PropertyDetailsScreen(
                                                      listing,
                                                      0,
                                                      0,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: 340,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 8,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      child: AspectRatio(
                                                        aspectRatio: 16 / 9,
                                                        child:
                                                            CachedNetworkImage(
                                                          imageUrl: listing
                                                                  .property
                                                                  ?.imageUrls
                                                                  .first ??
                                                              listing.imageUrls!
                                                                  .first,
                                                          fit: BoxFit.cover,
                                                          placeholder:
                                                              (context, url) =>
                                                                  Container(
                                                            color: Colors
                                                                .grey[200],
                                                            child: Icon(
                                                                Icons
                                                                    .home_outlined,
                                                                color: Colors
                                                                    .grey[400],
                                                                size: 40),
                                                          ),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              Container(
                                                            color: Colors
                                                                .grey[200],
                                                            child: Icon(
                                                                Icons
                                                                    .home_outlined,
                                                                color: Colors
                                                                    .grey[400],
                                                                size: 40),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(12),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          // Left Column
                                                          Expanded(
                                                            flex: 2,
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  listing.title
                                                                      .trim()
                                                                      .capitalize(),
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                                SizedBox(
                                                                    height: 4),
                                                                Row(
                                                                  children: [
                                                                    Icon(
                                                                        Icons
                                                                            .location_on,
                                                                        color: Colors.grey[
                                                                            600],
                                                                        size:
                                                                            14),
                                                                    SizedBox(
                                                                        width:
                                                                            4),
                                                                    Expanded(
                                                                      child:
                                                                          Text(
                                                                        listing.location ??
                                                                            '',
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              Colors.grey[600],
                                                                          fontSize:
                                                                              12,
                                                                        ),
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                    height: 8),
                                                                Row(
                                                                  children: [
                                                                    Icon(
                                                                        Icons
                                                                            .bed_outlined,
                                                                        color: Colors.grey[
                                                                            600],
                                                                        size:
                                                                            16),
                                                                    SizedBox(
                                                                        width:
                                                                            4),
                                                                    Text(
                                                                      '${listing.property?.numberOfBedrooms} beds',
                                                                      style:
                                                                          TextStyle(
                                                                        color: Colors
                                                                            .grey[800],
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                        width:
                                                                            16),
                                                                    Icon(
                                                                        Icons
                                                                            .bathtub_outlined,
                                                                        color: Colors.grey[
                                                                            600],
                                                                        size:
                                                                            16),
                                                                    SizedBox(
                                                                        width:
                                                                            4),
                                                                    Text(
                                                                      '${listing.property?.numberOfBathrooms} baths',
                                                                      style:
                                                                          TextStyle(
                                                                        color: Colors
                                                                            .grey[800],
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          // Right Column
                                                          Container(
                                                            width: 130,
                                                            height: 80,
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  '\$${listing.price}/month',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    color: Colors
                                                                        .orange,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                                Spacer(),
                                                                Container(
                                                                    padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            10,
                                                                        vertical:
                                                                            4),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .blue
                                                                          .withOpacity(
                                                                              0.1),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              10),
                                                                    ),
                                                                    child: Text(
                                                                      'need ${listing.property?.maxOccupancy}\n${listing.property?.maxOccupancy == 1 ? 'roomate' : 'roomates'}',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      style:
                                                                          TextStyle(
                                                                        color: Colors
                                                                            .blue,
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                    )),
                                                              ],
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
                                  ),
                                ],
                                SizedBox(height: 30),
                                // Contact Button
                                GestureDetector(
                                  onTap: () async {
                                    final chatRoom = await context
                                        .read<ChatProvider>()
                                        .createOrGetChatRoom(profile.id);

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
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: orangeColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: chatProvider.isLoading
                                        ? Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'Contact',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
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
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  bool isExhausted = false;
  @override
  Widget build(BuildContext context) {
    return Consumer<RoommateMatchProvider>(
      builder: (context, provider, _) {
        final user = context.watch<AuthProvider>().user;

        if (provider.isLoading && provider.matches.isEmpty) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: orangeColor),
            ),
          );
        }

        _fadeController.forward();

        return Scaffold(
          body: Stack(
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 16, right: 16, top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                text: 'Roomate ',
                                style: GoogleFonts.poppins(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: orangeColor,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'Drama?\nNah, we\'ll find you a ',
                                    style: GoogleFonts.poppins(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'bestie!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                      color: orangeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: provider.matches.isEmpty || isExhausted
                            ? _buildNoMoreMatches()
                            : Stack(
                                children: [
                                  CardSwiper(
                                    maxAngle: 25,
                                    isLoop: false,
                                    controller: controller,
                                    cardsCount: provider.matches.length,
                                    numberOfCardsDisplayed:
                                        provider.matches.length >= 2 ? 2 : 1,
                                    backCardOffset: const Offset(0, 20),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 24,
                                    ),
                                    allowedSwipeDirection:
                                        AllowedSwipeDirection.only(
                                      left: true,
                                      right: true,
                                    ),
                                    onSwipe: (previousIndex, currentIndex,
                                        direction) async {
                                      if (previousIndex <
                                          provider.matches.length) {
                                        final match =
                                            provider.matches[previousIndex];
                                        if (direction ==
                                            CardSwiperDirection.left) {
                                          provider.swipeLeft(match.id);
                                        } else if (direction ==
                                            CardSwiperDirection.right) {
                                          final isMutualSwipe = await provider
                                              .swipeRight(match.id);
                                          if (isMutualSwipe) {
                                            _matchAnimationController.forward();
                                          }
                                        }

                                        if (currentIndex == null) {
                                          setState(() {
                                            isExhausted = true;
                                          });
                                        }
                                      }
                                      return true;
                                    },
                                    onSwipeDirectionChange:
                                        (direction, swipeP) {
                                      setState(() {
                                        currentDirection = direction;
                                      });
                                    },
                                    cardBuilder: (context,
                                        index,
                                        horizontalThresholdPercentage,
                                        verticalThresholdPercentage) {
                                      if (index >= provider.matches.length) {
                                        return Container();
                                      }
                                      return _buildProfileCard(
                                          provider.matches[index], provider);
                                    },
                                  ),
                                  _buildSwipeOverlay(),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildMatchOverlay(provider.matchedUser),
              if (user != null && !user.isProfileComplete()) ...[
                // Blurred background with animation
                AnimatedBuilder(
                  animation: _profileOverlayController,
                  builder: (context, child) {
                    _profileOverlayController.forward(); // Start the animation
                    return FadeTransition(
                      opacity: _profileOpacityAnimation,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: blackTextColor.withOpacity(0.5),
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    );
                  },
                ),
                Center(
                  child: AnimatedBuilder(
                    animation: _profileOverlayController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _profileScaleAnimation.value,
                        child: FadeTransition(
                          opacity: _profileOpacityAnimation,
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 40),
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Complete Your Profile',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 20),

                                // Profile completion indicator
                                _buildProfileCompletion(user),

                                SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProfileScreen(
                                          latitude: user.latitude,
                                          longitude: user.longitude,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoMoreMatches() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: 24),
          Text(
            'No more matches',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Check back later for new potential matches',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String capitalize() => "${this[0].toUpperCase()}${this.substring(1)}";
}

Widget buildPreferencesSection(List<UserPreference> preferences) {
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
              label: Text('${preferencesList[index].preference}'),
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
          }),
        ),
    ],
  );
}
