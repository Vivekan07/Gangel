import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuardianManagementScreen extends StatefulWidget {
  // ... (existing code)
  @override
  _GuardianManagementScreenState createState() => _GuardianManagementScreenState();
}

class _GuardianManagementScreenState extends State<GuardianManagementScreen> {
  // ... (existing code)

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Guardians'),
        content: Container(
          width: double.maxFinite,
          height: 400, // Fixed height for the dialog
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search by name or email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _searchGuardians,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _searchController.text.isEmpty
                    ? ListView.builder(
                        itemCount: _guardians.length,
                        itemBuilder: (context, index) {
                          final guardian = _guardians[index];
                          final bool isAlreadyAdded = _myGuardians.any(
                            (g) => g['email'] == guardian['email'] && g['womenEmail'] == widget.userData['email']
                          );
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(guardian['name'][0]),
                            ),
                            title: Text(guardian['name']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(guardian['email']),
                                Text(guardian['phone']),
                              ],
                            ),
                            trailing: isAlreadyAdded
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      _addGuardian(guardian);
                                      Navigator.pop(context);
                                    },
                                  ),
                          );
                        },
                      )
                    : _searchResults.isEmpty
                        ? const Center(child: Text('No guardians found'))
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final guardian = _searchResults[index];
                              final bool isAlreadyAdded = _myGuardians.any(
                                (g) => g['email'] == guardian['email'] && g['womenEmail'] == widget.userData['email']
                              );
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(guardian['name'][0]),
                                ),
                                title: Text(guardian['name']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(guardian['email']),
                                    Text(guardian['phone']),
                                  ],
                                ),
                                trailing: isAlreadyAdded
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          _addGuardian(guardian);
                                          Navigator.pop(context);
                                        },
                                      ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _addGuardian(Map<String, dynamic> guardian) async {
    try {
      setState(() => _isLoading = true);

      // Get and validate women's data
      final womenEmail = widget.userData['email'];
      print('Current women email for adding guardian: $womenEmail'); // Debug print
      
      if (womenEmail == null || womenEmail.isEmpty) {
        throw Exception('Women email is required to add guardian');
      }

      // Validate guardian data
      if (guardian['email'] == null || guardian['email'].isEmpty) {
        throw Exception('Guardian email is required');
      }
      if (guardian['name'] == null || guardian['name'].isEmpty) {
        throw Exception('Guardian name is required');
      }
      if (guardian['phone'] == null || guardian['phone'].isEmpty) {
        throw Exception('Guardian phone is required');
      }

      print('Adding guardian with data: $guardian'); // Debug print
      print('For women with email: $womenEmail'); // Debug print

      // Check if relationship already exists
      final existingGuardian = await _firestore
          .collection('women_guardian')
          .where('guardianEmail', isEqualTo: guardian['email'])
          .where('womenEmail', isEqualTo: womenEmail)
          .get();

      if (existingGuardian.docs.isNotEmpty) {
        throw Exception('This guardian is already added to your list');
      }

      // Create guardian data
      final guardianData = {
        'guardianEmail': guardian['email'],
        'guardianName': guardian['name'],
        'guardianPhone': guardian['phone'],
        'womenEmail': womenEmail,
        'addedAt': FieldValue.serverTimestamp(),
      };

      print('Prepared guardian data for Firestore: $guardianData'); // Debug print

      // Add to women_guardian collection
      final docRef = await _firestore.collection('women_guardian').add(guardianData);
      
      // Verify the addition
      final addedDoc = await docRef.get();
      if (!addedDoc.exists) {
        throw Exception('Failed to verify guardian addition');
      }
      
      final addedData = addedDoc.data();
      print('Successfully added guardian with data: $addedData'); // Debug print

      // Refresh the guardians list
      await _loadGuardians();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guardian added successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error adding guardian: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding guardian: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeGuardian(String guardianEmail) async {
    try {
      setState(() => _isLoading = true);

      // Find the document in women_guardian collection that matches both emails
      final querySnapshot = await _firestore
          .collection('women_guardian')
          .where('email', isEqualTo: guardianEmail)
          .where('womenEmail', isEqualTo: widget.userData['email'])  // Added womenEmail check
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Guardian relationship not found');
      }

      // Delete the document
      await querySnapshot.docs.first.reference.delete();

      // Refresh the guardians list
      await _loadGuardians();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guardian removed successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error removing guardian: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing guardian: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadGuardians() async {
    try {
      setState(() => _isLoading = true);

      // Get women's email
      final womenEmail = widget.userData['email'];
      print('Loading guardians for women email: $womenEmail'); // Debug print

      if (womenEmail == null || womenEmail.isEmpty) {
        throw Exception('Women email is required to load guardians');
      }

      // Get guardians for current women
      final guardiansSnapshot = await _firestore
          .collection('women_guardian')
          .where('womenEmail', isEqualTo: womenEmail)
          .get();

      print('Found ${guardiansSnapshot.docs.length} guardians'); // Debug print

      final List<Map<String, dynamic>> guardiansList = [];
      
      for (var doc in guardiansSnapshot.docs) {
        final data = doc.data();
        print('Processing guardian document: $data'); // Debug print

        // Validate required fields
        if (data['guardianEmail'] == null || data['guardianName'] == null || 
            data['guardianPhone'] == null || data['womenEmail'] == null) {
          print('Warning: Guardian document ${doc.id} is missing required fields');
          continue;
        }

        guardiansList.add({
          'email': data['guardianEmail'],
          'name': data['guardianName'],
          'phone': data['guardianPhone'],
          'womenEmail': data['womenEmail'],
          'addedAt': data['addedAt'],
        });
      }

      print('Final guardians list: $guardiansList'); // Debug print

      if (mounted) {
        setState(() {
          _myGuardians = guardiansList;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading guardians: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading guardians: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _searchGuardians(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final results = _guardians.where((guardian) {
      final name = guardian['name'].toString().toLowerCase();
      final email = guardian['email'].toString().toLowerCase();
      final searchLower = query.toLowerCase();
      return name.contains(searchLower) || email.contains(searchLower);
    }).toList();

    setState(() => _searchResults = results);
  }

  // ... (rest of the existing code)
} 