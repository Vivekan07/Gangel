import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuardianManagementScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const GuardianManagementScreen({
    super.key,
    required this.userData,
  });

  @override
  State<GuardianManagementScreen> createState() => _GuardianManagementScreenState();
}

class _GuardianManagementScreenState extends State<GuardianManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> _guardians = [];
  final List<Map<String, dynamic>> _myGuardians = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadGuardians();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGuardians() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('\n=== DEBUG: Starting guardian loading process ===');
      final womenId = widget.userData['id'];
      final womenEmail = widget.userData['email'];
      print('Current women ID: $womenId');
      print('Current women email: $womenEmail');
      print('Current women data: ${widget.userData}');

      if (womenId == null || womenEmail == null) {
        throw Exception('Women ID and email are required');
      }

      // First load my guardians from women_guardian collection
      final myGuardiansSnapshot = await _firestore
          .collection('women_guardian')
          .where('womenId', isEqualTo: womenId)
          .get();

      print('Found ${myGuardiansSnapshot.docs.length} guardians in women_guardian collection');

      final List<Map<String, dynamic>> myGuardiansList = [];
      final Set<String> myGuardianIds = {};

      // Store my guardians and collect their IDs
      for (var doc in myGuardiansSnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        print('Guardian document data: $data');
        final guardianId = data['guardianId'];
        if (guardianId != null) {
          myGuardianIds.add(guardianId);
          myGuardiansList.add({
            'id': guardianId,
            'email': data['guardianEmail'] ?? '',
            'name': data['guardianName'] ?? 'No Name',
            'phone': data['guardianPhone'] ?? 'No Phone',
          });
          print('Added my guardian: ${data['guardianName']} (ID: $guardianId)');
        }
      }

      print('Starting guardian query...');
      
      // Load all guardians from users collection
      final QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'Guardian')
          .get();

      print('Query completed');
      print('Total guardian users found: ${querySnapshot.docs.length}');

      final List<Map<String, dynamic>> allGuardians = [];

      // Store all guardians from users collection
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('\nProcessing guardian document:');
        print('Document ID: ${doc.id}');
        print('Full data: $data');
        
        final guardianEmail = data['email'] ?? '';
        final guardianName = data['name'] ?? '';
        final guardianPhone = data['phone'] ?? '';
        
        if (guardianEmail.isNotEmpty) {
          final guardianData = {
            'id': doc.id,
            'email': guardianEmail,
            'name': guardianName,
            'phone': guardianPhone,
            'userType': data['userType'],
            'isAdded': myGuardianIds.contains(doc.id),
          };
          allGuardians.add(guardianData);
          print('Successfully added guardian to list: $guardianData');
        }
      }

      print('\nGuardian loading summary:');
      print('Total guardian users found: ${querySnapshot.docs.length}');
      print('Successfully processed guardians: ${allGuardians.length}');
      print('My guardians count: ${myGuardiansList.length}');

      if (mounted) {
        setState(() {
          _guardians.clear();
          _guardians.addAll(allGuardians);
          _myGuardians.clear();
          _myGuardians.addAll(myGuardiansList);
          _searchResults = List.from(_guardians);
          _isLoading = false;
        });
      }

      print('Final guardians count: ${_guardians.length}');
      print('Final my guardians count: ${_myGuardians.length}');
      
    } catch (e, stackTrace) {
      print('Error loading guardians: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _searchGuardians(String query) {
    print('Searching guardians with query: $query');
    print('Total guardians before search: ${_guardians.length}');

    if (query.isEmpty) {
      setState(() {
        _searchResults = List.from(_guardians);
      });
      print('Empty query, showing all guardians: ${_searchResults.length}');
      return;
    }

    final filteredList = _guardians.where((guardian) {
      final name = (guardian['name'] ?? '').toString().toLowerCase();
      final email = (guardian['email'] ?? '').toString().toLowerCase();
      final phone = (guardian['phone'] ?? '').toString().toLowerCase();
      final searchQuery = query.toLowerCase().trim();

      return name.contains(searchQuery) || 
             email.contains(searchQuery) ||
             phone.contains(searchQuery);
    }).toList();

    print('Filtered guardians count: ${filteredList.length}');
    
    setState(() {
      _searchResults = filteredList;
    });
  }

  Future<void> _addGuardian(Map<String, dynamic> guardian) async {
    try {
      final womenId = widget.userData['id'];
      final womenEmail = widget.userData['email'];
      
      if (womenId == null || womenEmail == null) {
        throw Exception('Women ID and email are required');
      }

      print('Adding guardian for women ID: $womenId');
      print('Guardian data to add: $guardian');

      // Check if guardian is already added
      final existingGuardian = await _firestore
          .collection('women_guardian')
          .where('womenId', isEqualTo: womenId)
          .where('guardianId', isEqualTo: guardian['id'])
          .get();

      if (existingGuardian.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This guardian is already in your list')),
          );
        }
        return;
      }

      // Add guardian to women_guardian collection
      final docRef = await _firestore.collection('women_guardian').add({
        'womenId': womenId,
        'womenEmail': womenEmail,
        'womenName': widget.userData['name'] ?? '',
        'guardianId': guardian['id'],
        'guardianEmail': guardian['email'],
        'guardianName': guardian['name'] ?? '',
        'guardianPhone': guardian['phone'] ?? '',
        'addedAt': FieldValue.serverTimestamp(),
      });

      print('Successfully added guardian with document ID: ${docRef.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardian added successfully')),
        );
        await _loadGuardians();
      }
    } catch (e) {
      print('Error adding guardian: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding guardian: $e')),
        );
      }
    }
  }

  Future<void> _removeGuardian(String guardianId) async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Remove Guardian'),
          content: const Text('Are you sure you want to remove this guardian?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final womenId = widget.userData['id'];
      if (womenId == null) {
        throw Exception('Women ID is required');
      }

      // Find and delete the women_guardian document
      final querySnapshot = await _firestore
          .collection('women_guardian')
          .where('womenId', isEqualTo: womenId)
          .where('guardianId', isEqualTo: guardianId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Guardian relationship not found');
      }

      // Delete the document
      await _firestore
          .collection('women_guardian')
          .doc(querySnapshot.docs.first.id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardian removed successfully')),
        );
        _loadGuardians(); // Reload the list
      }
    } catch (e) {
      print('Error removing guardian: $e'); // Debug print
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing guardian: $e')),
        );
      }
    }
  }

  void _showSearchDialog() {
    print('Opening search dialog'); // Debug print
    print('Available guardians: ${_guardians.length}'); // Debug print
    
    _searchController.clear();
    setState(() {
      _searchResults = List.from(_guardians);
    });
    print('Initial search results: ${_searchResults.length}'); // Debug print

    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
          children: [
                  Expanded(
                    child: Text(
                      'Available Guardians (${_guardians.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search by name, email or phone',
                  hintText: 'Type to search...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  print('Search text changed: $value'); // Debug print
                  _searchGuardians(value);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Builder(
                  builder: (context) {
                    print('Building search results list'); // Debug print
                    print('Current search results: ${_searchResults.length}'); // Debug print
                    
                    if (_guardians.isEmpty) {
                      print('No guardians available'); // Debug print
                      return const Center(
                        child: Text(
                          'No guardians available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    if (_searchResults.isEmpty) {
                      print('No matching guardians found'); // Debug print
                      return const Center(
                        child: Text(
                          'No matching guardians found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final guardian = _searchResults[index];
                        final bool isAlreadyAdded = _myGuardians.any(
                          (g) => g['email'] == guardian['email']
                        );
                        
                        print('Rendering guardian: ${guardian['name']}'); // Debug print
                        print('Already added: $isAlreadyAdded'); // Debug print
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                (guardian['name']?[0] ?? '').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              guardian['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(guardian['email'] ?? ''),
                                Text(guardian['phone'] ?? ''),
                              ],
                            ),
                            trailing: isAlreadyAdded
                                ? const Tooltip(
                                    message: 'Already added',
                                    child: Icon(Icons.check_circle, color: Colors.green),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: Colors.blue,
                                    tooltip: 'Add guardian',
            onPressed: () {
                                      print('Adding guardian: ${guardian['name']}'); // Debug print
                                      _addGuardian(guardian);
              Navigator.pop(context);
            },
                                  ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Guardians'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'My Guardians (${_myGuardians.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _myGuardians.isEmpty
                      ? const Center(
                          child: Text(
                            'No guardians added yet.\nTap + to add guardians.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _myGuardians.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
                            final guardian = _myGuardians[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                                  child: Text(guardian['name'][0]),
              ),
                                title: Text(guardian['name'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                    Text(guardian['email'] ?? ''),
                                    Text(guardian['phone'] ?? ''),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _removeGuardian(guardian['id']),
              ),
              isThreeLine: true,
            ),
          );
        },
                        ),
                ),
              ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSearchDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
} 