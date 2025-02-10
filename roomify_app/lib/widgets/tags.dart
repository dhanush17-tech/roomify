import 'package:flutter/material.dart';

class RoomifyVerified extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.orange, size: 16),
          SizedBox(width: 4),
          Text(
            "Roomify's Choice",
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class RoomateTag extends StatelessWidget {
  final String noOfOccupants;

  RoomateTag({required this.noOfOccupants});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Text(
          "looking for $noOfOccupants occupants",
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
