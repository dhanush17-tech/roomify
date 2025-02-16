import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/auth_provider.dart';
import 'package:roomify_app/providers/editProfile_provider.dart';
import 'package:roomify_app/providers/properties_provider.dart';
import 'package:roomify_app/views/home/map_location_picker.dart';

class LocationPickerWrapper extends StatefulWidget {
  final double currentLat;
  final double currentLng;

  const LocationPickerWrapper({
    Key? key,
    required this.currentLat,
    required this.currentLng,
  }) : super(key: key);

  @override
  State<LocationPickerWrapper> createState() => _LocationPickerWrapperState();
}

class _LocationPickerWrapperState extends State<LocationPickerWrapper> {
  String? _displayLocation;

  @override
  void initState() {
    super.initState();
    _updateDisplayLocation();
  }

  Future<void> _updateDisplayLocation() async {
    final profileProvider = context.read<ProfileProvider>();
    final address = await profileProvider.getAddressFromCoordinates(
      widget.currentLat,
      widget.currentLng,
    );
    if (mounted) {
      setState(() {
        _displayLocation = address;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.read<AuthProvider>();
    final propertiesProvider = context.read<PropertyProvider>();

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (bottomSheetContext) => LocationPickerSheet(
            lat: widget.currentLat,
            lng: widget.currentLng,
            onLocationSelected: (lat, lng) async {
              try {
                await profileProvider.updateLocation(lat, lng, context);
                await authProvider.loadUserProfile();

                await profileProvider.getAddressFromCoordinates(lat, lng);
                await _updateDisplayLocation();
                await propertiesProvider.fetchRecommendations(lat, lng);
                if (bottomSheetContext.mounted) {
                  Navigator.pop(bottomSheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Location updated successfully')),
                  );
                }
              } catch (e) {
                if (bottomSheetContext.mounted) {
                  ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                    SnackBar(content: Text('Failed to update location: $e')),
                  );
                }
              }
            },
          ),
        );
      },
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
                _displayLocation ??
                    profileProvider.currentLocation ??
                    'Pick a location',
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
  }
}
