// lib/features/profile/screens/account_settings_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fintrack/core/services/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  late TextEditingController _nameController;
  bool _isLoading = false;

  XFile? _newImageFile;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _existingImageUrl = user?.photoURL;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    XFile? pickedFile = await _cloudinaryService.pickImage();
    if (pickedFile != null) {
      setState(() {
        _newImageFile = pickedFile;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    String newName = _nameController.text;
    String? finalPhotoUrl = _existingImageUrl;

    try {
      if (_newImageFile != null) {
        finalPhotoUrl = await _cloudinaryService.uploadImage(_newImageFile!);
        if (finalPhotoUrl == null) {
          throw Exception('Gagal mengupload gambar');
        }
      }

      final user = _auth.currentUser;
      if (user == null) return;

      await user.updateProfile(
        displayName: newName,
        photoURL: finalPhotoUrl,
      );

      await _firestore.collection('users').doc(user.uid).update({
        'name': newName,
        'profileImageUrl': finalPhotoUrl,
      });
      
      await user.reload();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengaturan Akun"),
        // --- PERBAIKAN DI SINI ---
        foregroundColor: Colors.white,
        // -------------------------
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildProfilePicture(),
          const SizedBox(height: 32),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nama Lengkap",
                prefixIcon: Icon(LucideIcons.user),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama tidak boleh kosong';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 32),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  icon: const Icon(LucideIcons.save),
                  label: const Text("SIMPAN PERUBAHAN"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _saveSettings,
                )
        ],
      ),
    );
  }

  // ... (Sisa kode sama)
  Widget _buildProfilePicture() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 70,
            backgroundColor: Theme.of(context).colorScheme.surface,
            backgroundImage: _buildProfileImageProvider(),
            child: _newImageFile == null && _existingImageUrl == null
                ? const Icon(LucideIcons.user, size: 70)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(LucideIcons.pencil),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _pickImage,
            ),
          )
        ],
      ),
    );
  }

  ImageProvider? _buildProfileImageProvider() {
    if (_newImageFile != null) {
      if (kIsWeb) {
        return NetworkImage(_newImageFile!.path);
      }
      return FileImage(File(_newImageFile!.path));
    }
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return NetworkImage(_existingImageUrl!);
    }
    return null;
  }
}