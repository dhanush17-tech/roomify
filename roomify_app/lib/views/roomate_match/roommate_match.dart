import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/roommateMatch_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/utils/circular_reveal_clipper.dart';
import 'package:roomify_app/views/profile/edit_profile.dart';
import 'package:roomify_app/views/property/property_details.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';

class RoommateMatchScreen extends StatefulWidget {
  @override
  _RoommateMatchScreenState createState() => _RoommateMatchScreenState();
}

class _RoommateMatchScreenState extends State<RoommateMatchScreen>
    with TickerProviderStateMixin {
  final CardSwiperController controller = CardSwiperController();

  bool isSwiping = false;
  double? cardHeight;
  double swipeProgress = 0.0;
  CardSwiperDirection? currentDirection;

  late AnimationController _overlayController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatches();
    });
  }

  @override
  void dispose() {
    _overlayController.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    await context.read<RoommateMatchProvider>().loadMatches();
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Find Roommates',
            style: AppTextStyles.title(fontSize: 24),
          ),
        ],
      ),
    );
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
              double scale = _scaleAnimation.value;
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
              double scale = _scaleAnimation.value;
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

  Widget _buildProfileCard(User profile) {
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
      child: Card(
        elevation: 5,
        color: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: profile.profilePhotoUrl ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.56,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${profile.displayName.capitalize()} · ${profile.age}',
                      style: AppTextStyles.title(fontSize: 24),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          profile.university ?? '',
                          style: AppTextStyles.small(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 10),
                        if (profile.status == 'Looking for a Roommate')
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Looking for a Roommate",
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      profile.bio ?? '',
                      style: AppTextStyles.small(
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Preferences',
                      style:
                          AppTextStyles.title(fontSize: 15, color: orangeColor),
                    ),
                    if (profile.preferences.isNotEmpty) ...[
                      buildPreferencesSection(profile.preferences),
                      SizedBox(height: 20),
                    ],
                    if (profile.listings
                        .where(
                            (listing) => listing.type == ListingType.Property)
                        .isNotEmpty)
                      _buildPropertyCard(profile.listings
                          .where(
                              (listing) => listing.type == ListingType.Property)
                          .first),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Listing listing) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailsScreen(listing),
          ),
        );
      },
      child: Container(
        width: 300,
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  imageUrl: listing.property?.imageUrls?.first ?? '',
                  fit: BoxFit.cover,
                  height: 120,
                  width: double.infinity,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title ?? '',
                      style: AppTextStyles.subtitle(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.orange, size: 14),
                        SizedBox(width: 5),
                        Text(listing.property!.rating.toString(),
                            style: TextStyle(fontSize: 12)),
                        Spacer(),
                        Icon(Icons.bathtub, color: Colors.grey, size: 14),
                        SizedBox(width: 5),
                        Text(listing.property!.numberOfBathrooms.toString(),
                            style: TextStyle(fontSize: 12)),
                        Spacer(),
                        Icon(Icons.bed, color: Colors.grey, size: 14),
                        SizedBox(width: 5),
                        Text(listing.property!.numberOfBedrooms.toString(),
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 15),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.blue.withOpacity(0.1),
                        ),
                        child: Text(
                          "\$${listing.price}/month ",
                          style: AppTextStyles.small(
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                            fontSize: 15,
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
    );
  }

  bool isExhausted = false;
  @override
  Widget build(BuildContext context) {
    return Consumer<RoommateMatchProvider>(
      builder: (context, provider, _) {
        final user = context.watch<AuthProvider>().user;

        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text(provider.error!));
        }

        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          _buildHeader(),
                          Flexible(
                            child: Stack(
                              children: [
                                isExhausted
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.people_outline,
                                                size: 64, color: Colors.grey),
                                            SizedBox(height: 16),
                                            Text(
                                              'No more matches',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w500,
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
                                      )
                                    : CardSwiper(
                                        maxAngle: 40,
                                        isLoop: false,
                                        controller: controller,
                                        cardsCount: provider.matches.length,
                                        numberOfCardsDisplayed:
                                            provider.matches.isEmpty
                                                ? 1
                                                : provider.matches.length >= 3
                                                    ? 3
                                                    : provider.matches.length,
                                        backCardOffset: const Offset(40, 16),
                                        allowedSwipeDirection:
                                            AllowedSwipeDirection.only(
                                          left: true,
                                          right: true,
                                          up: false,
                                          down: false,
                                        ),
                                        onSwipe: (previousIndex, currentIndex,
                                            direction) {
                                          if (previousIndex <
                                              provider.matches.length) {
                                            final match =
                                                provider.matches[previousIndex];
                                            if (direction ==
                                                CardSwiperDirection.left) {
                                              provider.swipeLeft(match.id);
                                            } else if (direction ==
                                                CardSwiperDirection.right) {
                                              provider.swipeRight(match.id);
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
                                        cardBuilder:
                                            (context, index, idt, ins) {
                                          if (index >=
                                              provider.matches.length) {
                                            return Container();
                                          }
                                          return _buildProfileCard(
                                              provider.matches[index]);
                                        },
                                      ),
                                _buildSwipeOverlay(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
              backgroundColor: Color(4293718257),
              labelStyle: AppTextStyles.small(
                color: Colors.grey,
                fontWeight: FontWeight.normal,
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
