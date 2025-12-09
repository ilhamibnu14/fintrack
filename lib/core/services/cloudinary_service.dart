// lib/core/services/cloudinary_service.dart
// import 'dart:io'; // Hapus import dart:io
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // --- GANTI DENGAN INFO AKUN ANDA ---
  final String _cloudName = "dlnv23huo"; // Pastikan ini sudah diganti
  final String _uploadPreset = "fintrack_unsigned"; // Pastikan ini sudah diganti
  // -------------------------------------

  late final CloudinaryPublic _cloudinary;
  final ImagePicker _picker = ImagePicker();

  CloudinaryService() {
    _cloudinary = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  /// Membuka galeri/kamera untuk memilih gambar
  Future<XFile?> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    return image; // <-- Kembalikan XFile
  }

  /// Meng-upload gambar ke Cloudinary dan mengembalikan URL
  Future<String?> uploadImage(XFile imageFile) async { // <-- Terima XFile
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, // XFile.path berfungsi di web & mobile
            resourceType: CloudinaryResourceType.Image),
      );
      
      return response.secureUrl;

    } on CloudinaryException catch (e) {
      print(e.message);
      print(e.request);
      return null;
    }
  }
}