import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class ImageUtils {
  ImageUtils._();

  static Future<XFile> compressImage({
    required File imageFile,
    int quality = 30,
    CompressFormat format = CompressFormat.jpeg,
  }) async {
    // Verificar que el archivo existe
    if (!await imageFile.exists()) {
      throw Exception('El archivo de imagen no existe');
    }

    // Obtener directorio temporal del sistema
    final Directory tempDir = Directory.systemTemp;

    // Crear nombre único para el archivo comprimido
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String extension = format == CompressFormat.jpeg ? 'jpg' : 'png';
    final String fileName = 'compressed_$timestamp.$extension';

    final String targetPath = p.join(tempDir.path, fileName);

    try {
      final XFile? compressedImage =
          await FlutterImageCompress.compressAndGetFile(
            imageFile.absolute.path,
            targetPath,
            quality: quality,
            format: format,
          );

      if (compressedImage == null) {
        throw Exception(
          'Failed to compress the image: compressedImage is null',
        );
      }

      // Verificar que el archivo comprimido existe
      final File compressedFile = File(compressedImage.path);
      if (!await compressedFile.exists()) {
        throw Exception('El archivo comprimido no se creó correctamente');
      }

      return compressedImage;
    } catch (e) {
      throw Exception('Error al comprimir la imagen: $e');
    }
  }
}
