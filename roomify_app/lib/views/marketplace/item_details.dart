import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/userModel.dart';
import 'package:roomify_app/providers/chat_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/views/home/home_screen.dart';
import 'package:roomify_app/views/messaging/message_screen.dart';
import 'package:roomify_app/views/property/property_details.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ItemDetailsScreen extends StatelessWidget {
  final Listing item;

  ItemDetailsScreen({required this.item});

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
                    child: Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.only(left: 13),
                ),
                actions: [
                  Consumer<PropertyProvider>(
                      builder: (ctx, provider, _) => FavoriteButton(
                            isFavorite: provider.isFavorite(item.id),
                            onTap: () => provider.toggleFavorite(item),
                          )),
                  SizedBox(width: 13),
                  SizedBox(width: 13),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                        child: CachedNetworkImage(
                          imageUrl:
                              item.marketplaceItem?.imageUrls?.isNotEmpty ==
                                      true
                                  ? item.marketplaceItem!.imageUrls!.first
                                  : 'https://via.placeholder.com/180',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                        ),
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
                                    color: Colors.black.withOpacity(0.4),
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
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
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
                              Text(
                                "\$${item.price}",
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.bold,
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
          builder: (_) => ChatMessageScreen(room: chatRoom),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open chat: $e')),
      );
    }
  }
}
