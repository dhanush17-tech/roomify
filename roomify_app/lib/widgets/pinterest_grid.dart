import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:roomify_app/utils/text_styles.dart';

class PinterestGrid extends StatelessWidget {
  final List<FeaturedItemCard> items;
  final ScrollPhysics physics;
  const PinterestGrid({
    Key? key,
    required this.items,
    this.physics = const NeverScrollableScrollPhysics(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MasonryGridView.count(
        padding: EdgeInsets.all(0),
        scrollDirection: Axis.vertical,
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        shrinkWrap: true,
        physics: physics,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return items[index];
        },
      ),
    );
  }
}

class FeaturedItemCard extends StatelessWidget {
  final String title;
  final String location;
  final String price;
  final String imagePath;

  const FeaturedItemCard({
    Key? key,
    required this.title,
    required this.location,
    required this.price,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              imagePath,
              width: 180,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            title,
            style: AppTextStyles.subtitle(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
            height: 3,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(location, style: const TextStyle(color: Colors.grey)),
              SizedBox(
                width: 4,
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  price,
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
