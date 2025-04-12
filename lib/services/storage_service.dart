import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload profile image to Firebase Storage
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    if (!imageFile.existsSync()) {
      print('Error: Image file does not exist');
      return null;
    }

    try {
      // Create a reference to the location you want to upload to
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      
      // Upload the file
      await ref.putFile(imageFile);
      
      // Get the download URL
      final downloadURL = await ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Delete profile image from Firebase Storage
  Future<bool> deleteProfileImage(String userId, [String? imageUrl]) async {
    try {
      // If an imageUrl is provided, extract the file name from it
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final fileName = path.basename(Uri.parse(imageUrl).path);
        final ref = _storage.ref().child('profile_images').child(fileName);
        await ref.delete();
        return true;
      } else {
        // Otherwise delete by userId
        final ref = _storage.ref().child('profile_images/$userId.jpg');
        await ref.delete();
        return true;
      }
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
} 