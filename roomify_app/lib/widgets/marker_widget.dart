import 'package:flutter/material.dart';
import 'package:roomify_app/utils/colors.dart';

class MarkerWidget extends StatelessWidget {
  final String title;
  final double price;
  final VoidCallback onTap;

  const MarkerWidget({
    Key? key,
    required this.title,
    required this.price,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: blackTextColor.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: blackTextColor,
              ),
            ),
          ),
          Icon(
            Icons.location_on_rounded,
            color: orangeColor,
            size: 65,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: blackTextColor.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              '\$${price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: blackTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 