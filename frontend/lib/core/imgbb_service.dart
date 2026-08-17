import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

/// Servicio para subir imágenes a ImgBB y obtener la URL pública.
class ImgBBService {
  ImgBBService._();
  static final instance = ImgBBService._();

  static const _apiKey = '36eaed76952b26c5c35263e22ae8597c';
  static const _albumId = 'pnbTTy'; // Álbum Vitrina Deportiva
  static const _uploadUrl = 'https://api.imgbb.com/1/upload';

  final _dio = Dio();
  final _picker = ImagePicker();

  /// Abre el selector de imagen (galería o cámara) y sube a ImgBB.
  /// Retorna la URL pública o null si el usuario canceló o hubo error.
  Future<String?> pickAndUpload({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 85,
    double? maxWidth = 1200,
  }) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
    );
    if (file == null) return null;
    return uploadFile(File(file.path));
  }

  /// Sube un [File] a ImgBB y devuelve la URL pública.
  Future<String?> uploadFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final res = await _dio.post(
        _uploadUrl,
        data: FormData.fromMap({
          'key': _apiKey,
          'album': _albumId,
          'image': base64Image,
        }),
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      if (res.data['success'] == true) {
        return res.data['data']['url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Sube bytes directamente (útil para web o si ya tienes el buffer).
  Future<String?> uploadBytes(List<int> bytes, {String name = 'image'}) async {
    try {
      final base64Image = base64Encode(bytes);
      final res = await _dio.post(
        _uploadUrl,
        data: FormData.fromMap({
          'key': _apiKey,
          'album': _albumId,
          'image': base64Image,
          'name': name,
        }),
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      if (res.data['success'] == true) {
        return res.data['data']['url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
