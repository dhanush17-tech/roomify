import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/chat_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/views/home/home_screen.dart';
import 'package:roomify_app/views/marketplace/add_marketplace.dart';
import 'package:roomify_app/views/messaging/message_screen.dart';
import 'package:roomify_app/views/property/property_details.dart';
import 'package:roomify_app/views/property/report_listing.dart';

class ItemDetailsScreen extends StatelessWidget {
  final Listing item;
  final double latitude;
  final double longitude;

  ItemDetailsScreen(this.item, this.latitude, this.longitude);

  bool isOwnListing(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id;
    return currentUserId == item.user?.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar with image
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.4,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'property-image-${item.id}',
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount: item.marketplaceItem!.imageUrls!.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(40),
                                bottomRight: Radius.circular(40),
                              ),
                              child: CachedNetworkImage(
                                imageUrl:
                                    item.marketplaceItem!.imageUrls![index],
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
                        // Small images on the right
                        if (item.imageUrls!.length > 1)
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: Column(
                              children: [
                                Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.9),
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(17),
                                    child: CachedNetworkImage(
                                      imageUrl: item.imageUrls![1],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                if (item.imageUrls!.length > 2)
                                  Container(
                                    margin: EdgeInsets.only(bottom: 8),
                                    width: 60,
                                    height: 60,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.9),
                                        width: 3,
                                      ),
                                      color: blackTextColor.withOpacity(0.4),
                                    ),
                                    child: Text(
                                      '+${item.imageUrls!.length - 2}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
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
                  if (isOwnListing(context))
                    // Show edit button for own listings
                    IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.edit, color: orangeColor),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddMarketplaceScreen(
                              existingListing: item,
                            ),
                          ),
                        );
                      },
                    )
                  else ...[
                    // Show report and favorite buttons for other listings
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (C) => ReportScreen(
                              listingId: item.id,
                              listingType: item.title,
                              latitude: latitude,
                              longitude: longitude,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            Text("Report listing",
                                style: TextStyle(color: Colors.grey)),
                            SizedBox(
                              width: 4,
                            ),
                            Icon(Icons.flag_outlined, color: Colors.grey)
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    Consumer<PropertyProvider>(
                      builder: (ctx, provider, _) => FavoriteButton(
                        isFavorite: provider.isFavorite(item.id),
                        onTap: () => provider.toggleFavorite(item),
                      ),
                    ),
                  ],
                  SizedBox(width: 13),
                ],
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Hero(
                                  tag: 'property-title-${item.id}',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        color: Colors.grey, size: 20),
                                    SizedBox(width: 4),
                                    Container(
                                      width: 150,
                                      child: Text(
                                        item.location,
                                        style: TextStyle(color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Hero(
                                tag: 'property-price-${item.id}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    "\$${item.price}",
                                    style: TextStyle(
                                      fontSize: 27,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Description
                      Text(
                        'Description',
                        style: AppTextStyles.title(
                            fontSize: 15, color: orangeColor),
                      ),
                      SizedBox(height: 8),
                      Text(
                        item.description ?? '',
                        style: AppTextStyles.small(
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),

                      SizedBox(height: 24),

                      // Tags/Categories
                      Text(
                        'Categories',
                        style: AppTextStyles.title(
                            fontSize: 15, color: orangeColor),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (item.marketplaceItem?.categories ?? [])
                            .map((category) => Chip(
                                  label: Text(category),
                                  backgroundColor: Color(4293718257),
                                  labelStyle: AppTextStyles.small(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ))
                            .toList(),
                      ),

                      SizedBox(height: 130),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // User card at bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: ExpandableUserCard(
                user: item.user!,
                isMarketplace: true,
                onTap: () => navigateToChat(context, item.user!)),
          ),
        ],
      ),
    );
  }

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
}
