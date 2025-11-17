import 'dart:math';

double haversineDistance({
  required double startLatitude,
  required double startLongitude,
  required double endLatitude,
  required double endLongitude,
}) {
  const double earthRadiusKm = 6371.0;

  final double dLat = _degreesToRadians(endLatitude - startLatitude);
  final double dLon = _degreesToRadians(endLongitude - startLongitude);

  final double lat1 = _degreesToRadians(startLatitude);
  final double lat2 = _degreesToRadians(endLatitude);

  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadiusKm * c;
}

double _degreesToRadians(double degrees) => degrees * (pi / 180);

