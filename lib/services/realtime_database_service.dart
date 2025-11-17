import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabaseService {
  RealtimeDatabaseService._();

  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  static DatabaseReference? _userRef() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return _database.ref('users/$uid');
  }

  static Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    final ref = _userRef();
    if (ref == null) return;

    await ref.update({'location': latitude, 'longitude': longitude});
  }

  static Future<void> updateShareWith(bool value) async {
    final ref = _userRef();
    if (ref == null) return;

    await ref.update({'shareWith': value});
  }

  static Future<void> initializeUserDocument() async {
    final ref = _userRef();
    if (ref == null) return;
    await ref.set({'location': 0.0, 'longitude': 0.0, 'shareWith': true});
  }

  static Future<void> clearUserData() async {
    final ref = _userRef();
    if (ref == null) return;
    await ref.remove();
  }
}
