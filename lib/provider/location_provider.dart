import 'dart:async';

import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:mini_flutter_proyect/model/location.dart' as model;

class LocationProvider extends ChangeNotifier {
  final loc.Location _locationService = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSubscription;

  model.Location? _location;
  model.Location? get location => _location;

  Future<void> startLocationUpdates() async {
    if (_locationSubscription != null) return;

    // Verificar permisos antes de intentar usar la ubicación
    loc.PermissionStatus permissionStatus = await _locationService.hasPermission();
    if (permissionStatus == loc.PermissionStatus.denied ||
        permissionStatus == loc.PermissionStatus.deniedForever) {
      // Si no hay permiso, no intentar iniciar actualizaciones
      return;
    }

    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    await _locationService.changeSettings(
      accuracy: loc.LocationAccuracy.high,
      interval: 5000,
      distanceFilter: 5,
    );

    // Verificar permisos nuevamente antes de obtener ubicación
    permissionStatus = await _locationService.hasPermission();
    if (permissionStatus != loc.PermissionStatus.granted &&
        permissionStatus != loc.PermissionStatus.grantedLimited) {
      return;
    }

    try {
      await _updateLocation();
      _locationSubscription =
          _locationService.onLocationChanged.listen(_handleLocationData);
    } catch (e) {
      // Si falla al obtener ubicación (por ejemplo, sin permisos), no hacer nada
      return;
    }
  }

  Future<void> _updateLocation() async {
    try {
      // Verificar permisos antes de obtener ubicación
      final permissionStatus = await _locationService.hasPermission();
      if (permissionStatus != loc.PermissionStatus.granted &&
          permissionStatus != loc.PermissionStatus.grantedLimited) {
        return;
      }

      final data = await _locationService.getLocation();
      _handleLocationData(data);
    } catch (e) {
      // Si falla (por ejemplo, sin permisos), no hacer nada
      return;
    }
  }

  void _handleLocationData(loc.LocationData data) {
    final latitude = data.latitude;
    final longitude = data.longitude;

    if (latitude == null || longitude == null) {
      return;
    }

    if (_location != null &&
        _location!.latitude == latitude &&
        _location!.longitude == longitude) {
      return;
    }

    _location = model.Location(latitude: latitude, longitude: longitude);
    notifyListeners();
  }

  void stopLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  @override
  void dispose() {
    stopLocationUpdates();
    super.dispose();
  }
}
