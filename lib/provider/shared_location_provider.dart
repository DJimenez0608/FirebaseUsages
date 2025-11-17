import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:mini_flutter_proyect/model/shared_location.dart';

class SharedLocationProvider extends ChangeNotifier {
  final Map<String, SharedLocation> _sharedLocations = {};
  final Map<String, StreamSubscription<DatabaseEvent>> _subscriptions = {};
  String? _focusedUserId;

  String? get focusedUserId => _focusedUserId;

  Map<String, SharedLocation> get sharedLocations =>
      Map.unmodifiable(_sharedLocations);

  Future<void> trackUser(SharedLocation initialLocation) async {
    final newUserId = initialLocation.userId;
    if (_focusedUserId != null && _focusedUserId != newUserId) {
      stopTracking(_focusedUserId!);
    }

    _focusedUserId = newUserId;
    _sharedLocations[newUserId] = initialLocation;
    notifyListeners();

    if (_subscriptions.containsKey(newUserId)) {
      return;
    }

    final ref = FirebaseDatabase.instance.ref('users/$newUserId');

    final StreamSubscription<DatabaseEvent> sub = ref.onValue.listen(
      (event) {
        final data = event.snapshot.value;
        if (data is! Map) {
          _sharedLocations.remove(newUserId);
          notifyListeners();
          return;
        }

        final shareWith = data['shareWith'] == true;
        if (!shareWith) {
          _sharedLocations.remove(newUserId);
          notifyListeners();
          return;
        }

        final latitude = (data['location'] as num?)?.toDouble();
        final longitude = (data['longitude'] as num?)?.toDouble();
        if (latitude == null || longitude == null) {
          return;
        }

        final existing = _sharedLocations[newUserId];
        if (existing == null ||
            existing.latitude != latitude ||
            existing.longitude != longitude) {
          _sharedLocations[newUserId] = SharedLocation(
            latitude: latitude,
            longitude: longitude,
            userId: newUserId,
          );
          notifyListeners();
        }
      },
      onError: (_) {
        _sharedLocations.remove(newUserId);
        notifyListeners();
      },
    );

    _subscriptions[newUserId] = sub;
  }

  void stopTracking(String userId) {
    _subscriptions.remove(userId)?.cancel();
    if (_sharedLocations.remove(userId) != null) {
      notifyListeners();
    }

    if (_focusedUserId == userId) {
      _focusedUserId = null;
      notifyListeners();
    }
  }

  void clear() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _sharedLocations.clear();
    _focusedUserId = null;
    notifyListeners();
  }
}
