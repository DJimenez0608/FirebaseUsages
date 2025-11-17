import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:location/location.dart';
import 'package:mini_flutter_proyect/model/shared_location.dart';
import 'package:mini_flutter_proyect/navigation/routes.dart';
import 'package:mini_flutter_proyect/provider/location_provider.dart';
import 'package:mini_flutter_proyect/provider/shared_location_provider.dart';
import 'package:mini_flutter_proyect/provider/user_provider.dart';
import 'package:mini_flutter_proyect/services/available_users_service.dart';
import 'package:mini_flutter_proyect/services/realtime_database_service.dart';
import 'package:mini_flutter_proyect/utils/distance_utils.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Location _location = Location();
  late final MapController _mapController;
  int _denials = 0;
  bool _isMapReady = false;
  bool _isAvailable = true;
  bool _staticMarkersLoaded = false;
  GeoPoint? _userMarker;
  final Map<String, GeoPoint> _sharedUserMarkers = {};
  double? _currentDistanceKm;
  double? _queuedDistanceKm;
  bool _distanceUpdateScheduled = false;

  @override
  void initState() {
    super.initState();
    // Inicializar el mapa con una ubicación por defecto (Bogotá)
    // Usar withUserPosition pero sin tracking externo para evitar problemas con el timer
    _mapController = MapController.withUserPosition(
      trackUserLocation: const UserTrackingOption(
        enableTracking: true,
        unFollowUser: false,
      ),
      useExternalTracking:
          false, // No usar tracking externo para evitar problemas con el timer
    );
    // Esperar a que el widget esté completamente construido antes de pedir permisos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestLocationPermission();
        RealtimeDatabaseService.updateShareWith(true);
      }
    });
  }

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.grey),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Disponible',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch(
                            value: _isAvailable,
                            onChanged: (value) async {
                              setState(() {
                                _isAvailable = value;
                              });
                              setSheetState(() {});
                              await RealtimeDatabaseService.updateShareWith(
                                value,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 32),
                    ListTile(
                      leading: const Icon(Icons.people_alt_outlined),
                      title: const Text('Usuarios disponibles'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _navigateToAvailableUsers();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Cerrar sesión'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _handleLogout();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    await RealtimeDatabaseService.clearUserData();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    context.read<UserProvider>().clear();
    context.read<SharedLocationProvider>().clear();
    Navigator.of(context).pushReplacementNamed(Routes.login);
  }

  Future<void> _navigateToAvailableUsers() async {
    final result = await Navigator.of(context).pushNamed(Routes.availableUsers);
    if (!mounted) return;
    if (result is AvailableUser) {
      final sharedProvider = context.read<SharedLocationProvider>();
      await sharedProvider.trackUser(
        SharedLocation(
          latitude: result.latitude,
          longitude: result.longitude,
          userId: result.user.id,
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    if (!mounted || _denials >= 2) return;

    PermissionStatus status = await _location.hasPermission();
    if (status == PermissionStatus.granted ||
        status == PermissionStatus.grantedLimited) {
      if (mounted) {
        context.read<LocationProvider>().startLocationUpdates();
      }
      return;
    }

    status = await _location.requestPermission();
    if (status == PermissionStatus.granted ||
        status == PermissionStatus.grantedLimited) {
      if (mounted) {
        context.read<LocationProvider>().startLocationUpdates();
      }
      return;
    }

    _denials += 1;
    if (!mounted) return;

    final isFirstDenial = _denials == 1;
    final String message =
        isFirstDenial
            ? 'Es necesario dar permisos de localización para garantizar el funcionamiento correcto de la aplicación.'
            : 'Diríjase a configuraciones y dé permisos de localización si desea usar la aplicación.';

    // Verificar nuevamente que el widget esté montado antes de mostrar el diálogo
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Permiso de ubicación'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isFirstDenial ? 'Intentar de nuevo' : 'Entendido'),
            ),
          ],
        );
      },
    );

    if (isFirstDenial && mounted) {
      await _requestLocationPermission();
    }
  }

  Future<void> _updateUserMarker(LocationProvider provider) async {
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;
    if (!_isMapReady) return;
    final currentLocation = provider.location;
    if (currentLocation == null) return;

    final newPoint = GeoPoint(
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude,
    );

    final hasChanged =
        _userMarker == null ||
        _userMarker!.latitude != newPoint.latitude ||
        _userMarker!.longitude != newPoint.longitude;

    if (hasChanged) {
      // El plugin maneja automáticamente el marcador del usuario cuando enableTracking: true
      // Solo actualizamos la posición de la cámara y guardamos la referencia
      _userMarker = newPoint;
      if (mounted && _isMapReady) {
        await _mapController.moveTo(newPoint, animate: true);
      }
    }

    if (!mounted) return;
    await RealtimeDatabaseService.updateLocation(
      latitude: newPoint.latitude,
      longitude: newPoint.longitude,
    );

    if (!mounted) return;
    final focusedId = context.read<SharedLocationProvider>().focusedUserId;
    if (focusedId != null) {
      final shared = context.read<SharedLocationProvider>().sharedLocations;
      final target = shared[focusedId];
      if (target != null) {
        _maybeUpdateDistance(
          GeoPoint(latitude: target.latitude, longitude: target.longitude),
        );
      }
    } else {
      _scheduleDistanceUpdate(null);
    }
  }

  Future<void> _updateSharedUserMarkers(
    Map<String, SharedLocation> sharedLocations,
  ) async {
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;
    final currentIds = sharedLocations.keys.toSet();

    for (final entry in sharedLocations.entries) {
      final userId = entry.key;
      final sharedLocation = entry.value;
      final newPoint = GeoPoint(
        latitude: sharedLocation.latitude,
        longitude: sharedLocation.longitude,
      );

      final previous = _sharedUserMarkers[userId];
      if (previous == null) {
        if (mounted && _isMapReady) {
          await _mapController.addMarker(
            newPoint,
            markerIcon: const MarkerIcon(
              icon: Icon(
                Icons.person_pin_circle,
                color: Colors.blueAccent,
                size: 60,
              ),
            ),
          );
        }
      } else if (previous.latitude != newPoint.latitude ||
          previous.longitude != newPoint.longitude) {
        if (mounted && _isMapReady) {
          await _mapController.changeLocationMarker(
            oldLocation: previous,
            newLocation: newPoint,
            markerIcon: const MarkerIcon(
              icon: Icon(
                Icons.person_pin_circle,
                color: Colors.blueAccent,
                size: 60,
              ),
            ),
          );
        }
      }
      _sharedUserMarkers[userId] = newPoint;
    }

    final toRemove =
        _sharedUserMarkers.keys
            .where((userId) => !currentIds.contains(userId))
            .toList();

    for (final userId in toRemove) {
      final point = _sharedUserMarkers.remove(userId);
      if (point != null && mounted && _isMapReady) {
        await _mapController.removeMarker(point);
      }
    }

    if (!mounted) return;
    final focusedId = context.read<SharedLocationProvider>().focusedUserId;
    if (focusedId != null) {
      final focusedPoint = sharedLocations[focusedId];
      if (focusedPoint != null) {
        _maybeUpdateDistance(
          GeoPoint(
            latitude: focusedPoint.latitude,
            longitude: focusedPoint.longitude,
          ),
        );
      }
    } else {
      _scheduleDistanceUpdate(null);
    }
  }

  void _maybeUpdateDistance(GeoPoint otherPoint) {
    if (!mounted) return;
    final userLocation = context.read<LocationProvider>().location;
    if (userLocation == null) return;

    final distance = haversineDistance(
      startLatitude: userLocation.latitude,
      startLongitude: userLocation.longitude,
      endLatitude: otherPoint.latitude,
      endLongitude: otherPoint.longitude,
    );

    _scheduleDistanceUpdate(distance);
  }

  Future<void> _maybeFitCamera(SharedLocation target) async {
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;
    if (!_isMapReady) return;
    if (!mounted) return;
    final userLocation = context.read<LocationProvider>().location;
    if (userLocation == null) return;

    final bounds = BoundingBox.fromGeoPoints([
      GeoPoint(
        latitude: userLocation.latitude,
        longitude: userLocation.longitude,
      ),
      GeoPoint(latitude: target.latitude, longitude: target.longitude),
    ]);

    if (!mounted) return;
    try {
      await _mapController.zoomToBoundingBox(bounds, paddinInPixel: 64);
    } catch (_) {
      // ignore errors (e.g., identical points)
    }
  }

  void _scheduleDistanceUpdate(double? distance) {
    final bool sameAsCurrent =
        _currentDistanceKm != null && distance != null
            ? (distance - _currentDistanceKm!).abs() <= 0.001
            : _currentDistanceKm == null && distance == null;

    if (sameAsCurrent) return;

    _queuedDistanceKm = distance;
    if (_distanceUpdateScheduled) return;
    _distanceUpdateScheduled = true;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _distanceUpdateScheduled = false;
      if (_currentDistanceKm != _queuedDistanceKm) {
        setState(() {
          _currentDistanceKm = _queuedDistanceKm;
        });
      }
    });
  }

  Future<void> _loadStaticMarkers() async {
    if (!_isMapReady || _staticMarkersLoaded) return;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/locations - Copy (5).json',
      );
      final Map<String, dynamic> raw =
          jsonDecode(jsonString) as Map<String, dynamic>;
      final List<dynamic> locations =
          (raw['locationsArray'] as List<dynamic>?) ?? <dynamic>[];

      for (final dynamic entry in locations) {
        if (entry is! Map<String, dynamic>) continue;
        final latitude = (entry['latitude'] as num?)?.toDouble();
        final longitude = (entry['longitude'] as num?)?.toDouble();
        final String? name = entry['name'] as String?;

        if (latitude == null || longitude == null || name == null) {
          continue;
        }

        final point = GeoPoint(latitude: latitude, longitude: longitude);
        await _mapController.addMarker(
          point,
          markerIcon: MarkerIcon(iconWidget: _buildStaticMarker(name)),
        );
      }

      _staticMarkersLoaded = true;
    } catch (_) {
      // Ignore parsing/loading errors for now.
    }
  }

  Widget _buildStaticMarker(String name) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        const Icon(Icons.location_on, color: Colors.blueAccent, size: 46),
      ],
    );
  }

  Future<void> _centerCameraOnUser() async {
    if (!_isMapReady || !mounted) return;
    if (!mounted) return;
    final provider = context.read<LocationProvider>();
    if (_userMarker == null && provider.location != null) {
      await _updateUserMarker(provider);
    }

    if (_userMarker != null) {
      await _mapController.moveTo(_userMarker!, animate: true);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ubicación del usuario no disponible.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final userLocation = locationProvider.location;
    final sharedLocations =
        context.watch<SharedLocationProvider>().sharedLocations;
    final focusedUserId = context.watch<SharedLocationProvider>().focusedUserId;

    if (userLocation != null && _isMapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isMapReady) {
          _updateUserMarker(locationProvider);
        }
      });
    }

    // Actualizar marcadores cuando cambian las ubicaciones compartidas o el usuario enfocado
    // Esto asegura que se eliminen marcadores de usuarios anteriores cuando se cambia de usuario
    if (_isMapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isMapReady) {
          _updateSharedUserMarkers(sharedLocations);
        }
      });
    }
    if (focusedUserId != null && _isMapReady) {
      final focusedPoint = sharedLocations[focusedUserId];
      if (focusedPoint != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isMapReady) {
            _maybeFitCamera(focusedPoint);
          }
        });
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          OSMFlutter(
            controller: _mapController,
            osmOption: OSMOption(
              zoomOption: const ZoomOption(initZoom: 16),
              userTrackingOption: const UserTrackingOption(
                enableTracking: true,
                unFollowUser: false,
              ),
            ),
            mapIsLoading: const Center(child: CircularProgressIndicator()),
            onMapIsReady: (isReady) async {
              if (!isReady) {
                print('Mapa no está listo');
                return;
              }
              print('Mapa está listo');
              if (!mounted) return;
              setState(() {
                _isMapReady = true;
              });
              if (!mounted) return;
              final locationProvider = context.read<LocationProvider>();
              if (locationProvider.location != null) {
                await _updateUserMarker(locationProvider);
              }
              if (!mounted) return;
              await _loadStaticMarkers();
            },
            onGeoPointClicked: (point) {
              showDialog<void>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Ubicación del marcador'),
                    content: Text(
                      'Latitud: ${point.latitude.toStringAsFixed(6)}\n'
                      'Longitud: ${point.longitude.toStringAsFixed(6)}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          Positioned(
            top: 48,
            left: 16,
            child: FloatingActionButton.small(
              heroTag: 'menuFab',
              onPressed: _openMenu,
              child: const Icon(Icons.menu),
            ),
          ),
          if (_currentDistanceKm != null)
            Positioned(
              top: 48,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentDistanceKm!.toStringAsFixed(2)} km',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerCameraOnUser,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
