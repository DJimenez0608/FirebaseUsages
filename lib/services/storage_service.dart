import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube la imagen de perfil del usuario a Firebase Storage
  /// 
  /// [uid] - ID del usuario autenticado
  /// [imageFile] - Archivo de imagen (XFile) a subir
  /// 
  /// Retorna la URL de descarga de la imagen subida
  static Future<String> uploadUserProfileImage({
    required String uid,
    required XFile imageFile,
  }) async {
    try {
      final Reference ref = _storage.ref().child('users/$uid/profile_image.jpg');
      
      final UploadTask uploadTask = ref.putFile(File(imageFile.path));
      
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading profile image: $e');
    }
  }

  /// Obtiene la URL de descarga de la imagen de perfil del usuario desde Storage
  /// 
  /// [uid] - ID del usuario
  /// 
  /// Retorna la URL de descarga o null si no existe
  static Future<String?> getUserProfileImageUrl(String uid) async {
    try {
      final Reference ref = _storage.ref().child('users/$uid/profile_image.jpg');
      final String url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      // Si el archivo no existe, retorna null
      return null;
    }
  }
}

