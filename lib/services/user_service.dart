import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create user in Firestore (no authentication)
  Future<String> createUser({
    required String name,
    required String email,
    required String phone,
    required String userType,
    required String password,
    String? address,
    String? badgeNumber,
    String? stationAddress,
    String? profileImagePath,
  }) async {
    print('------- UserService.createUser started -------');
    
    try {
      // Generate a unique ID for the user
      final String userId = DateTime.now().millisecondsSinceEpoch.toString();
      print('Generated userId: $userId');
      
      // Prepare user data
      final Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'userType': userType,
        'password': password,
        'createdAt': FieldValue.serverTimestamp(),
      };
      print('Basic user data prepared');

      // Add optional fields
      if (address != null && address.isNotEmpty) {
        userData['address'] = address;
        print('Added address to userData');
      }
      if (badgeNumber != null && badgeNumber.isNotEmpty) {
        userData['badgeNumber'] = badgeNumber;
        print('Added badgeNumber to userData');
      }
      if (stationAddress != null && stationAddress.isNotEmpty) {
        userData['stationAddress'] = stationAddress;
        print('Added stationAddress to userData');
      }

      // Save to Firestore with timeout
      print('Attempting to save to Firestore collection "users", document: $userId');
      try {
        await _firestore.collection('users').doc(userId).set(userData)
          .timeout(const Duration(seconds: 15));
        print('✓ User data successfully saved to Firestore');
      } catch (e) {
        if (e is TimeoutException) {
          print('⚠️ Firestore set operation timed out after 15 seconds');
          throw Exception('Firestore document creation timed out');
        }
        rethrow;
      }

      // Skip profile image upload if path is null or empty
      if (profileImagePath == null || profileImagePath.isEmpty) {
        print('No profile image path provided - skipping image upload');
        print('------- UserService.createUser completed successfully -------');
        return userId;
      }
      
      print('Profile image path provided: $profileImagePath');
      // Check if file exists
      final imageFile = File(profileImagePath);
      if (!imageFile.existsSync()) {
        print('⚠️ Profile image file does not exist at path: $profileImagePath - skipping upload');
        print('------- UserService.createUser completed without image -------');
        return userId;
      }

      // Handle profile image upload
      try {
        print('Starting profile image upload...');
        final profileImageUrl = await uploadProfileImage(
          userId,
          imageFile,
        );
        print('Image upload result: ${profileImageUrl != null ? 'SUCCESS' : 'FAILED'}');
        
        // Update the user document with the profile image URL
        if (profileImageUrl != null) {
          print('Updating Firestore document with profile image URL');
          try {
            await _firestore.collection('users').doc(userId).update({
              'profileImageUrl': profileImageUrl,
            }).timeout(const Duration(seconds: 10));
            print('✓ Profile image URL saved to Firestore');
          } catch (e) {
            if (e is TimeoutException) {
              print('⚠️ Firestore update operation timed out after 10 seconds');
              // Continue without failing - we've already created the user
            } else {
              print('⚠️ Error updating profile image URL: $e');
            }
          }
        }
      } catch (e) {
        print('⚠️ Error uploading profile image: $e');
        print('Stack trace: ${StackTrace.current}');
        // Continue and return userId even if image upload fails
      }
      
      print('------- UserService.createUser completed successfully -------');
      return userId;
    } catch (e) {
      print('❌ ERROR creating user: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Upload profile image to Firebase Storage
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    print('------- uploadProfileImage started for userId: $userId -------');
    
    try {
      // Check if file exists and is valid
      if (!imageFile.existsSync()) {
        print('❌ ERROR: Image file does not exist at path: ${imageFile.path}');
        return null;
      }
      
      print('Image file exists: ${imageFile.existsSync()}');
      print('Image file path: ${imageFile.path}');
      print('Image file size: ${await imageFile.length()} bytes');
      
      // Create a reference to the location you want to upload to
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      print('Storage reference created');
      
      // Upload the file with a simple approach
      print('Starting file upload...');
      try {
        // Set a timeout using Future.timeout instead of directly on the task
        final uploadTask = ref.putFile(imageFile);
        await uploadTask.timeout(const Duration(seconds: 30));
        print('✓ File uploaded successfully');
      } catch (e) {
        if (e is TimeoutException) {
          print('⚠️ Upload timed out after 30 seconds');
          return null;
        }
        rethrow;
      }
      
      // Get the download URL
      print('Requesting download URL...');
      try {
        final downloadURL = await ref.getDownloadURL()
            .timeout(const Duration(seconds: 15));
        print('✓ Got download URL: $downloadURL');
        print('------- uploadProfileImage completed successfully -------');
        return downloadURL;
      } catch (e) {
        if (e is TimeoutException) {
          print('⚠️ getDownloadURL timed out after 15 seconds');
          return null;
        }
        rethrow;
      }
    } catch (e) {
      print('❌ ERROR uploading image: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Delete profile image from Firebase Storage
  Future<void> deleteProfileImage(String userId) async {
    try {
      // Create a reference to the file
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      
      // Delete the file
      await ref.delete();
      print('Profile image deleted successfully');
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  // Update user profile in Firestore
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? phone,
    String? address,
    String? badgeNumber,
    String? stationAddress,
    String? profileImagePath,
    String? password,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      
      final Map<String, dynamic> updates = {};
      
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      if (badgeNumber != null) updates['badgeNumber'] = badgeNumber;
      if (stationAddress != null) updates['stationAddress'] = stationAddress;
      if (password != null) updates['password'] = password;

      // Handle profile image update
      if (profileImagePath != null) {
        // Upload new image
        final newImageUrl = await uploadProfileImage(
          userId,
          File(profileImagePath),
        );
        
        // Update URL in Firestore
        if (newImageUrl != null) {
          updates['profileImageUrl'] = newImageUrl;
        }
      }

      // Update user data in Firestore
      if (updates.isNotEmpty) {
        await userRef.update(updates);
        print('User profile updated successfully');
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
} 