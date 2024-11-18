import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/roommateMatchModel.dart';
import 'package:roomify_app/providers/roommateMatch_provider.dart';

class RoommateMatchScreen extends StatefulWidget {
  @override
  _RoommateMatchScreenState createState() => _RoommateMatchScreenState();
}

class _RoommateMatchScreenState extends State<RoommateMatchScreen> {
  final CardSwiperController _cardController = CardSwiperController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatches();
    });
  }

  Future<void> _loadMatches() async {
    await context.read<RoommateMatchProvider>().loadMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoommateMatchProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text(provider.error!));
        }

        // Handle no matches
        final hasMatches = provider.matches.isNotEmpty;
        final cardsCount = hasMatches ? provider.matches.length : 1;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: CardSwiper(
                    controller: _cardController,
                    cardsCount: cardsCount,
                    numberOfCardsDisplayed: 1,
                    cardBuilder: (context, index, i, p) {
                      if (!hasMatches) {
                        return Center(
                          child: Text(
                            'No matches found',
                            style: TextStyle(fontSize: 18),
                          ),
                        );
                      }
                      return _buildProfileCard(provider.matches[index]);
                    },
                    onSwipe: (previousIndex, currentIndex, direction) {
                      // Prevent swiping on the last card
                      if (previousIndex == provider.matches.length - 1) {
                        return false; // Stop swipe action for the last card
                      }

                      if (hasMatches &&
                          previousIndex < provider.matches.length) {
                        final match = provider.matches[previousIndex];
                        if (direction == CardSwiperDirection.left) {
                          provider.swipeLeft(match.id);
                        } else if (direction == CardSwiperDirection.right) {
                          provider.swipeRight(match.id);
                        }
                        provider.matches.removeAt(previousIndex);
                      }
                      return true;
                    },
                  ),
                ),
                if (hasMatches) _buildSwipeButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Find a Roommate',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: () => _cardController.swipe(CardSwiperDirection.left),
            child: Icon(Icons.close),
            backgroundColor: Colors.red,
          ),
          FloatingActionButton(
            onPressed: () => _cardController.swipe(CardSwiperDirection.right),
            child: Icon(Icons.favorite),
            backgroundColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(RoommateMatch profile) {
    return Card(
      elevation: 5,
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              profile.profileImageUrl ?? '',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.username} · ${profile.age}',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  profile.university ?? '',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  profile.bio ?? '',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
