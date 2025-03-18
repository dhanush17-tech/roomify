import 'dart:math';

double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
  const double earthRadius = 6371; // Radius of the Earth in kilometers

  double dLat = _toRadians(lat2 - lat1);
  double dLng = _toRadians(lng2 - lng1);

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLng / 2) *
          sin(dLng / 2);

  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c; // Distance in kilometers
}

double _toRadians(double degree) {
  return degree * pi / 180;
}
