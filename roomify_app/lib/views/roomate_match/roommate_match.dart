import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/views/onboarding/main_onboarding.dart';

class RoommateMatchScreen extends StatefulWidget {
  const RoommateMatchScreen({super.key});

  @override
  State<RoommateMatchScreen> createState() => _RoommateMatchScreenState();
}

class _RoommateMatchScreenState extends State<RoommateMatchScreen>
    with TickerProviderStateMixin {
  final CardSwiperController controller = CardSwiperController();
  bool isSwiping = false;
  double? cardHeight;
  List<Widget> cards = [];
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
  }

  @override
  void dispose() {
    _overlayController.dispose();
    super.dispose();
  }

  void _updateSwipeProgress(CardSwiperDirection direction, double progress) {
    setState(() {
      swipeProgress = progress.abs();
      currentDirection = direction;
    });
  }

  // Update the setter for isSwiping
  set _isSwiping(bool value) {
    if (value) {
      _overlayController.forward();
    } else {
      _overlayController.reverse();
    }
    setState(() {
      isSwiping = value;
    });
  }

  final List<User> profiles = [
    User(
      name: 'Dhanush Vardhan',
      age: 19,
      university: 'Computer Science, ASU',
      bio:
          'I\'m a sophomore studying Computer Science at ASU. I\'m a quiet and tidy roommate who enjoys coding.',
      imageUrl: 'https://dhanush.wtf/media/9v1i1598nhf.JPG?file=',
    ),
    User(
      name: 'Tanu',
      age: 19,
      university: 'Computer Science, ASU',
      bio:
          'I\'m a sophomore  student studying Computer Science at ASU. I prefer vegan who prefers.',
      imageUrl: 'https://dhanush.wtf/media/bzeveb2gu0h.png?file=',
    ),
    User(
      name: 'Danya',
      age: 19,
      university: 'Computer Science, ASU',
      bio:
          "I am a friendly and laid-back roommate who enjoys creative projects, weekend adventures, and cozy nights in with a good book or movie",
      imageUrl: 'https://dhanush.wtf/media/qy6ad3134ui.png?file=',
    ),
    User(
      name: 'Laksh',
      age: 19,
      university: 'Robotics, ASU',
      bio:
          "I am a friendly and love making friends. I love weekend adventures, and cozy nights in with a good book or movie",
      imageUrl: 'https://dhanush.wtf/media/856iexr7fck.jpeg?file=',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cardHeight = MediaQuery.of(context).size.height * 0.56;
    cards = profiles.map((profile) => bulidProfileCard(profile)).toList();
  }

  List<Property> properties = [
    Property(
      name: 'Furnished Home in Downtown',
      imageUrl:
          'https://bridgedalehomebuyers.ca/wp-content/uploads/2019/04/Average-time-to-sell-a-house-in-Calgary.jpg',
      location: 'Tucson, AZ',
      price: '450/month',
    ),
    Property(
      name: 'Cozy Studio',
      imageUrl:
          'https://bridgedalehomebuyers.ca/wp-content/uploads/2019/04/Average-time-to-sell-a-house-in-Calgary.jpg',
      location: 'Tucson, AZ',
      price: '300/month',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                children: [
                  _buildAppBar(),
                  Flexible(
                    child: CardSwiper(
                      maxAngle: 40,
                      controller: controller,
                      cardsCount: profiles.length,
                      numberOfCardsDisplayed: 3,
                      backCardOffset: const Offset(40, 16),
                      allowedSwipeDirection: AllowedSwipeDirection.only(
                          left: true, right: true, up: false, down: false),
                      padding: const EdgeInsets.all(4.0),
                      // onSwipeDirectionChange: (direction, swipeProgress) {
                      //   _updateSwipeProgress(direction, swipeProgress);
                      //   return swipeProgress;
                      // },
                      cardBuilder: (context,
                          index,
                          horizontalThresholdPercentage,
                          verticalThresholdPercentage) {
                        return cards[index];
                      },
                    ),
                  ),
                ],
              ),
              _buildSwipeOverlay()
            ],
          ),
        ),
      ),
    );
  }

  Widget bulidProfileCard(User profile) {
    return Listener(
      onPointerDown: (details) {
        print("The pointer is down");
        setState(() {
          isSwiping = true;
          currentDirection = null; // Reset direction at the start of a swipe
        });
      },
      onPointerMove: (details) {
        // Calculate the swipe progress based on screen width
        double screenWidth = MediaQuery.of(context).size.width;
        double progress = details.localPosition.dx / screenWidth;

        setState(() {
          swipeProgress = progress.abs();
          currentDirection = details.localPosition.dx > screenWidth / 2
              ? CardSwiperDirection.right
              : CardSwiperDirection.left;

          // Trigger the overlay animation
          if (!_overlayController.isAnimating) {
            _overlayController.forward();
          }
        });
        print(swipeProgress);
      },
      onPointerUp: (details) {
        setState(() {
          isSwiping = false;
          _overlayController.reverse();

          // Don't reset progress immediately for smooth animation
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
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      profile.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: cardHeight,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${profile.name} · ${profile.age}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          profile.university,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          profile.bio,
                          style: AppTextStyles.small(
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Row(
                          children: [
                            SocialIcon(
                                icon: "assets/icons/facebook_icon.svg",
                                color: orangeColor),
                            SizedBox(width: 20),
                            SocialIcon(
                                icon: "assets/icons/google_icon.svg",
                                color: orangeColor),
                            SizedBox(width: 20),
                            SocialIcon(
                                icon: "assets/icons/apple_icon.svg",
                                color: orangeColor),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text('Interest',
                            style: AppTextStyles.title(
                                fontSize: 15, color: orangeColor)),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: List<Widget>.generate(3, (index) {
                            return Chip(
                              label: Text('🚀 Interest $index'),
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              labelStyle: AppTextStyles.small(
                                  fontWeight: FontWeight.normal,
                                  color: Colors.blue),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            );
                          }),
                        ),
                        SizedBox(height: 20),
                        Text('Prefrences',
                            style: AppTextStyles.title(
                                fontSize: 15, color: orangeColor)),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: List<Widget>.generate(5, (index) {
                            return Chip(
                              label: Text('Interest $index'),
                              backgroundColor: Color(4293718257),
                              labelStyle: AppTextStyles.small(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.normal),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            );
                          }),
                        ),
                        SizedBox(height: 20),
                        Text('Currently living in...',
                            style: AppTextStyles.title(
                                fontSize: 15, color: orangeColor)),
                        Text('(looking for a roomate for)',
                            style: AppTextStyles.small(
                                fontWeight: FontWeight.normal)),
                        SizedBox(height: 15),
                        Container(
                          height: 400,
                          child: ListView.separated(
                            separatorBuilder: (ctx, i) => SizedBox(width: 10),
                            scrollDirection: Axis.horizontal,
                            itemCount: properties.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 300,
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                  elevation: 0,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(15),
                                            topRight: Radius.circular(15),
                                          ),
                                          child: Image.network(
                                            properties[index].imageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Column(
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    flex: 1,
                                                    child: Text(
                                                      properties[index].name,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  Spacer(),
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        Image.asset(
                                                          "assets/icons/location.png",
                                                          width: 10,
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          properties[index]
                                                              .location,
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[700],
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Icon(Icons.star,
                                                      color: Colors.orange,
                                                      size: 14),
                                                  SizedBox(width: 5),
                                                  Text(2.toString(),
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                  Spacer(),
                                                  Icon(Icons.bathtub,
                                                      color: Colors.grey,
                                                      size: 14),
                                                  SizedBox(width: 5),
                                                  Text(3.toString(),
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                  Spacer(),
                                                  Icon(Icons.bed,
                                                      color: Colors.grey,
                                                      size: 14),
                                                  SizedBox(width: 5),
                                                  Text(3.toString(),
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                ],
                                              ),
                                              SizedBox(height: 15),
                                              Align(
                                                alignment: Alignment.topLeft,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 5,
                                                      horizontal: 8),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    color: Colors.blue
                                                        .withOpacity(0.1),
                                                  ),
                                                  child: Text(
                                                    "\$30/month ",
                                                    style: AppTextStyles.small(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.blue,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
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
                  ),
                ],
              ),
            ],
          ),
        ),
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

  void onSwipe() {
    setState(() {
      isSwiping = true;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          isSwiping = false;
        });
      }
    });
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Find a Roommate',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

// Custom clipper for circular reveal effect
class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final bool fromLeft;

  CircularRevealClipper({
    required this.fraction,
    required this.fromLeft,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    if (fraction == 0.0) {
      return path;
    }

    final center = Offset(
      fromLeft ? 0 : size.width,
      size.height / 2,
    );

    final radius = size.width * fraction;

    path.addOval(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
    );

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
