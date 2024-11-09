import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';

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
      name: 'Nikki',
      age: 22,
      university: 'Computer Science, NYU',
      bio:
          'I\'m a final year student studying Computer Science at NYU. I\'m a quiet and tidy roommate who enjoys coding.',
      imageUrl:
          'https://www.geekydan.dev/_next/image?url=%2Fassets%2Fme2.png&w=1920&q=75',
    ),
    User(
      name: 'Jamla',
      age: 22,
      university: 'Computer Science, NYU',
      bio:
          'I\'m a final year student studying Computer Science at NYU. I\'m a quiet and tidy roommate who enjoys coding.',
      imageUrl:
          'https://www.geekydan.dev/_next/image?url=%2Fassets%2Fme2.png&w=1920&q=75',
    ),
    User(
      name: 'Dhanush',
      age: 22,
      university: 'Computer Science, NYU',
      bio:
          'I\'m a final year student studying Computer Science at NYU. I\'m a quiet and tidy roommate who enjoys coding.',
      imageUrl:
          'https://www.geekydan.dev/_next/image?url=%2Fassets%2Fme2.png&w=1920&q=75',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cardHeight = MediaQuery.of(context).size.height * 0.56;
    cards = profiles.map((profile) => buildExampleCard(profile)).toList();
  }

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

  Widget buildExampleCard(User profile) {
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
                    ],
                  ),
                ),
              ],
            ),
          ],
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
