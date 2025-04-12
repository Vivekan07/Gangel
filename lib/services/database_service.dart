import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Create a new record
  Future<void> createData(String path, Map<String, dynamic> data) async {
    await _database.child(path).set(data);
  }

  // Read data from a path
  Future<DataSnapshot> readData(String path) async {
    return await _database.child(path).get();
  }

  // Update data at a path
  Future<void> updateData(String path, Map<String, dynamic> data) async {
    await _database.child(path).update(data);
  }

  // Delete data at a path
  Future<void> deleteData(String path) async {
    await _database.child(path).remove();
  }

  // Listen to real-time updates
  DatabaseReference listenToData(String path) {
    return _database.child(path);
  }
} 