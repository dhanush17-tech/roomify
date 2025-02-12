import 'package:geolocator/geolocator.dart';

class LocationManager {
  static final LocationManager _instance = LocationManager._internal();
  bool _isRequestingPermission = false;

  factory LocationManager() {
    return _instance;
  }

  LocationManager._internal();

  Future<LocationPermission> requestPermission() async {
    if (_isRequestingPermission) {
      // Wait until the current request is complete
      while (_isRequestingPermission) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return await Geolocator.checkPermission();
    }

    _isRequestingPermission = true;
    try {
      return await Geolocator.requestPermission();
    } finally {
      _isRequestingPermission = false;
    }
  }

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
