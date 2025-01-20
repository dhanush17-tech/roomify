import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/views/home/map_location_picker.dart';

class LocationSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(builder: (context, provider, _) {
 
      return GestureDetector(
        onTap: () =>
            _showLocationPicker(context, provider.latitude, provider.longitude),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: Colors.orange, size: 18),
              SizedBox(width: 4),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 90),
                child: Text(
                  provider.currentLocation ?? 'Pick a location',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      );
    });
  }

  void _showLocationPicker(BuildContext context, double lat, double lng) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPickerSheet(
        lat: lat,
        lng: lng,
      ),
    );
  }
}
