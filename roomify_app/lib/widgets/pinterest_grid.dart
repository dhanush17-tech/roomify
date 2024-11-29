import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:roomify_app/models/itemModel.dart';
import 'package:roomify_app/models/propertyModel.dart';
import 'package:roomify_app/utils/text_styles.dart';
import 'package:roomify_app/views/marketplace/item_details.dart';
import 'package:roomify_app/views/property/property_details.dart';

class PinterestGrid extends StatelessWidget {
  final List<Listing> items;
  final ScrollPhysics physics;
  final bool showDeleteIcon;
  final Function(Listing item)? onTapDelete;

  const PinterestGrid({
    Key? key,
    required this.items,
    this.physics = const NeverScrollableScrollPhysics(),
    this.onTapDelete,
    this.showDeleteIcon = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MasonryGridView.count(
        padding: const EdgeInsets.all(0),
        scrollDirection: Axis.vertical,
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        shrinkWrap: true,
        physics: physics,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return FeaturedItemCard(
            item: items[index],
            onTap: () {
              if (items[index].property is Property) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PropertyDetailsScreen(items[index]),
                  ),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ItemDetailsScreen(item: items[index]),
                  ),
                );
              }
            },
            showDeleteIcon: showDeleteIcon,
            onTapDelete: onTapDelete,
          );
        },
      ),
    );
  }
}

class FeaturedItemCard extends StatelessWidget {
  final VoidCallback? onTap;
  final Listing item;
  final bool showDeleteIcon;
  final Function(Listing item)? onTapDelete;

  const FeaturedItemCard({
    Key? key,
    required this.item,
    this.onTap,
    this.onTapDelete,
    this.showDeleteIcon = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    item.property?.imageUrls?.isNotEmpty == true
                        ? item.property!.imageUrls!.first
                        : 'https://via.placeholder.com/180',
                    width: 180,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 180,
                        height: 120,
                        color: Colors.grey[200],
                        child: Icon(Icons.error),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.title,
                  style: AppTextStyles.subtitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.location,
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '\$${item.price}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDeleteIcon)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => onTapDelete?.call(item),
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete, color: Colors.red, size: 20),
              ),
            ),
          ),
      ],
    );
  }
}
