import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mini_flutter_proyect/model/user.dart';
import 'package:mini_flutter_proyect/services/storage_service.dart';

class AvailableUser {
  AvailableUser({
    required this.user,
    required this.latitude,
    required this.longitude,
  });

  final User user;
  final double latitude;
  final double longitude;
}

class AvailableUsersService {
  AvailableUsersService._();

  static Future<List<AvailableUser>> fetchAvailableUsers() async {
    final firestore = FirebaseFirestore.instance;
    final realtime = FirebaseDatabase.instance;

    final QuerySnapshot<Map<String, dynamic>> usersSnapshot =
        await firestore.collection('users').get();

    final Map<String, User> users = {
      for (final doc in usersSnapshot.docs)
        doc.id: User.fromMap(doc.id, doc.data()),
    };

    final DataSnapshot rtdbSnapshot = await realtime.ref('users').get();
    final value = rtdbSnapshot.value;

    if (value is! Map) {
      return [];
    }

    final List<AvailableUser> availableUsers = [];

    value.forEach((key, dynamic data) {
      if (data is Map) {
        final bool shareWith = data['shareWith'] == true;
        if (!shareWith) return;

        final double latitude =
            (data['location'] as num?)?.toDouble() ?? 0.0;
        final double longitude =
            (data['longitude'] as num?)?.toDouble() ?? 0.0;

        final user = users[key];
        if (user != null) {
          availableUsers.add(
            AvailableUser(
              user: user,
              latitude: latitude,
              longitude: longitude,
            ),
          );
        }
      }
    });

    // Obtener URLs de imágenes desde Storage para cada usuario
    final List<AvailableUser> availableUsersWithImages = [];

    for (final availableUser in availableUsers) {
      // Intentar obtener imagen desde Storage si no está en Firestore
      String? imageUrl = availableUser.user.imageUrl;

      if (imageUrl == null || imageUrl.isEmpty) {
        try {
          imageUrl = await StorageService.getUserProfileImageUrl(
            availableUser.user.id,
          );
        } catch (e) {
          // Si falla, imageUrl queda como null
        }
      }

      // Crear nuevo User con la URL de imagen
      final userWithImage = User(
        id: availableUser.user.id,
        name: availableUser.user.name,
        lastName: availableUser.user.lastName,
        email: availableUser.user.email,
        idNumber: availableUser.user.idNumber,
        imageUrl: imageUrl,
      );

      availableUsersWithImages.add(
        AvailableUser(
          user: userWithImage,
          latitude: availableUser.latitude,
          longitude: availableUser.longitude,
        ),
      );
    }

    return availableUsersWithImages;
  }
}

