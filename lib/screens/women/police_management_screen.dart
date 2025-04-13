import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PoliceManagementScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const PoliceManagementScreen({
    super.key,
    this.userData,
  });

  @override
  State<PoliceManagementScreen> createState() => _PoliceManagementScreenState();
}

class _PoliceManagementScreenState extends State<PoliceManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> _policeOfficers = [];
  final List<Map<String, dynamic>> _myPoliceOfficers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    print('Initializing Police Management Screen');
    print('User Data: ${widget.userData}');
    _loadPoliceOfficers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPoliceOfficers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('Loading police officers...'); // Debug print
      print('Current user ID: ${widget.userData?['id']}'); // Debug user ID

      // First load my police officers from women_police collection
      final myPoliceSnapshot = await _firestore
          .collection('women_police')
          .where('womenId', isEqualTo: widget.userData?['id'])
          .get();

      print('Found ${myPoliceSnapshot.docs.length} police officers in women_police collection'); // Debug print

      final List<Map<String, dynamic>> myPoliceList = [];
      final Set<String> myPoliceIds = {};

      // Store my police officers and collect their IDs
      for (var doc in myPoliceSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final policeId = data['policeId'] ?? '';
        if (policeId.isNotEmpty) {
          myPoliceIds.add(policeId);
          myPoliceList.add({
            'id': doc.id,
            'policeId': policeId,
            'name': data['name'] ?? 'No Name',
            'phone': data['phone'] ?? 'No Phone',
            'email': data['email'] ?? 'No Email',
            'policeStation': data['stationAddress'] ?? 'No Station',
            'badgeNumber': data['badgeNumber'] ?? 'No Badge',
          });
          print('Added my police officer: ${data['name']} (ID: $policeId)'); // Debug print
        }
      }

      // Load all police officers from users collection
      final QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .get();

      print('Total users found: ${querySnapshot.docs.length}'); // Debug print

      final List<Map<String, dynamic>> allPoliceOfficers = [];

      // Store all police officers from users collection
      for (var doc in querySnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          final policeId = doc.id;
          
          print('Processing user: ${data['name']} (ID: $policeId)'); // Debug print
          print('User type: ${data['userType']}'); // Debug print
          
          // Case insensitive comparison for userType
          final userType = (data['userType'] ?? '').toString().toLowerCase();
          if (userType == 'police') {
            print('Found police officer: ${data['name']}'); // Debug print
            final policeData = {
              'id': policeId,
              'name': data['name'] ?? 'No Name',
              'phone': data['phone'] ?? 'No Phone',
              'email': data['email'] ?? 'No Email',
              'userType': data['userType'] ?? 'Police',
              'policeStation': data['stationAddress'] ?? 'No Station',
              'badgeNumber': data['badgeNumber'] ?? 'No Badge',
              'isAdded': myPoliceIds.contains(policeId),
            };
            allPoliceOfficers.add(policeData);
            print('Added police officer to list: $policeData'); // Debug print
          }
        } catch (e) {
          print('Error processing user document: $e'); // Debug print
          continue;
        }
      }

      print('Found ${allPoliceOfficers.length} total police officers'); // Debug print

      if (mounted) {
        setState(() {
          _policeOfficers.clear();
          _policeOfficers.addAll(allPoliceOfficers);
          _myPoliceOfficers.clear();
          _myPoliceOfficers.addAll(myPoliceList);
          _searchResults = List.from(_policeOfficers);
          _isLoading = false;
        });
      }

      print('Final police officers count: ${_policeOfficers.length}'); // Debug print
      print('Final my police officers count: ${_myPoliceOfficers.length}'); // Debug print
      
    } catch (e, stackTrace) {
      print('Error loading police officers: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      if (mounted) {
        setState(() {
          _isLoading = false;
          _policeOfficers.clear();
          _myPoliceOfficers.clear();
          _searchResults.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading police officers: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _searchPoliceOfficers(String query) {
    print('Searching police officers with query: $query');
    print('Total police officers before search: ${_policeOfficers.length}');

    if (query.isEmpty) {
      setState(() {
        _searchResults = List.from(_policeOfficers);
      });
      print('Empty query, showing all police officers: ${_searchResults.length}');
      return;
    }

    final filteredList = _policeOfficers.where((officer) {
      final name = (officer['name'] ?? '').toString().toLowerCase();
      final email = (officer['email'] ?? '').toString().toLowerCase();
      final phone = (officer['phone'] ?? '').toString().toLowerCase();
      final policeStation = (officer['policeStation'] ?? '').toString().toLowerCase();
      final badgeNumber = (officer['badgeNumber'] ?? '').toString().toLowerCase();
      final searchQuery = query.toLowerCase().trim();

      return name.contains(searchQuery) || 
             email.contains(searchQuery) ||
             phone.contains(searchQuery) ||
             policeStation.contains(searchQuery) ||
             badgeNumber.contains(searchQuery);
    }).toList();

    print('Filtered police officers count: ${filteredList.length}');
    
    setState(() {
      _searchResults = filteredList;
    });
  }

  Future<void> _addPoliceOfficer(Map<String, dynamic> officer) async {
    try {
      print('\n============= ADDING POLICE OFFICER =============');
      print('Officer data to add: $officer');

      // Check if police officer is already added
      final existingOfficer = await _firestore
          .collection('women_police')
          .where('womenId', isEqualTo: widget.userData?['id'])
          .where('policeId', isEqualTo: officer['id'])
          .get();

      if (existingOfficer.docs.isNotEmpty) {
        print('Police officer already added');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This police officer is already in your list')),
          );
        }
        return;
      }

      print('Adding new police officer to women_police collection');
      // Add police officer to women_police collection
      await _firestore.collection('women_police').add({
        'womenId': widget.userData?['id'],
        'policeId': officer['id'],
        'name': officer['name'] ?? '',
        'email': officer['email'] ?? '',
        'phone': officer['phone'] ?? '',
        'stationAddress': officer['policeStation'] ?? '',
        'badgeNumber': officer['badgeNumber'] ?? '',
        'addedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Police officer added successfully')),
        );
        _loadPoliceOfficers(); // Reload the list
      }
    } catch (e) {
      print('Error adding police officer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding police officer: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _removePoliceOfficer(String officerId) async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Remove Police Officer'),
          content: const Text('Are you sure you want to remove this police officer?'),
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

      await _firestore
          .collection('women_police')
          .doc(officerId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Police officer removed successfully')),
        );
        _loadPoliceOfficers(); // Reload the list
      }
    } catch (e) {
      print('Error removing police officer: $e'); // Debug print
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing police officer: $e')),
        );
      }
    }
  }

  void _showSearchDialog() {
    print('\n--- Opening search dialog ---'); // Debug print
    print('Available police officers: ${_policeOfficers.length}'); // Debug print
    for (var officer in _policeOfficers) {
      print('Available officer: ${officer['name']} (${officer['id']})'); // Debug print
    }
    
    _searchController.clear();
    setState(() {
      _searchResults = List.from(_policeOfficers);
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
                      'Available Police Officers (${_policeOfficers.length})',
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
                  labelText: 'Search by name, badge number, or station',
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
                onChanged: _searchPoliceOfficers,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Builder(
                  builder: (context) {
                    print('\nBuilding search results list'); // Debug print
                    print('Current search results: ${_searchResults.length}'); // Debug print
                    
                    if (_policeOfficers.isEmpty) {
                      print('No police officers available'); // Debug print
                      return const Center(
                        child: Text(
                          'No police officers available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    if (_searchResults.isEmpty) {
                      print('No matching police officers found'); // Debug print
                      return const Center(
                        child: Text(
                          'No matching police officers found',
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
                        final officer = _searchResults[index];
                        final bool isAlreadyAdded = _myPoliceOfficers.any(
                          (p) => p['policeId'] == officer['id']
                        );
                        
                        print('Rendering police officer: ${officer['name']}'); // Debug print
                        print('Already added: $isAlreadyAdded'); // Debug print
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                (officer['name']?[0] ?? '').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              officer['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Badge: ${officer['badgeNumber'] ?? 'N/A'}'),
                                Text('Station: ${officer['policeStation'] ?? 'N/A'}'),
                                Text(officer['email'] ?? ''),
                                Text(officer['phone'] ?? ''),
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
                                    tooltip: 'Add police officer',
                                    onPressed: () {
                                      print('Adding police officer: ${officer['name']}'); // Debug print
                                      _addPoliceOfficer(officer);
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
        title: const Text('Manage Police Officers'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'My Police Officers (${_myPoliceOfficers.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _myPoliceOfficers.isEmpty
                      ? const Center(
                          child: Text(
                            'No police officers added yet.\nTap + to add police officers.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _myPoliceOfficers.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final officer = _myPoliceOfficers[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    (officer['name']?[0] ?? '').toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(officer['name'] ?? ''),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Badge: ${officer['badgeNumber'] ?? 'N/A'}'),
                                    Text('Station: ${officer['policeStation'] ?? 'N/A'}'),
                                    Text(officer['email'] ?? ''),
                                    Text(officer['phone'] ?? ''),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: Colors.red,
                                  onPressed: () => _removePoliceOfficer(officer['id']),
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