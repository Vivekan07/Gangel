import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PoliceManagementScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String policeId;
  final String policeEmail;
  
  const PoliceManagementScreen({
    super.key,
    required this.userData,
    required this.policeId,
    required this.policeEmail,
  });

  @override
  State<PoliceManagementScreen> createState() => _PoliceManagementScreenState();
}

class _PoliceManagementScreenState extends State<PoliceManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Map<String, dynamic>> _contacts = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      setState(() => _isLoading = true);

      print('Loading contacts for police ID: ${widget.policeId}'); // Debug print

      // Get users who have added this police officer from women_police collection
      final usersSnapshot = await _firestore
          .collection('women_police')
          .where('policeId', isEqualTo: widget.policeId)
          .get();

      print('Found ${usersSnapshot.docs.length} users'); // Debug print

      final List<Map<String, dynamic>> contactsList = [];
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final womenId = data['womenId'];
        
        if (womenId == null) {
          print('Warning: Women ID is null for document ${doc.id}');
          continue;
        }

        // Get user details from users collection
        final userSnapshot = await _firestore
            .collection('users')
            .doc(womenId)
            .get();

        if (!userSnapshot.exists) {
          print('Warning: No user found with ID $womenId');
          continue;
        }

        final userData = userSnapshot.data()!;

        // Get last alert or status update
        final lastAlertSnapshot = await _firestore
            .collection('alerts')
            .where('womenId', isEqualTo: womenId)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        String lastStatus = 'No alerts';
        String time = '';
        
        if (lastAlertSnapshot.docs.isNotEmpty) {
          final alertData = lastAlertSnapshot.docs.first.data();
          lastStatus = alertData['type'] ?? 'Unknown alert';
          time = _formatTimestamp(alertData['timestamp'] as Timestamp);
        }

        contactsList.add({
          'id': womenId,
          'name': userData['name'] ?? 'Unknown',
          'phone': userData['phone'] ?? '',
          'email': userData['email'] ?? '',
          'address': userData['address'] ?? '',
          'lastStatus': lastStatus,
          'time': time,
          'status': userData['status'] ?? 'Unknown',
        });
      }

      print('Final contacts list: $contactsList'); // Debug print

      if (mounted) {
        setState(() {
          _contacts.clear();
          _contacts.addAll(contactsList);
          _isLoading = false;
        });
      }
      
    } catch (e, stackTrace) {
      print('Error loading contacts: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading contacts: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    
    if (now.difference(date).inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(date).inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Women'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
              ),
              child: _contacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No women assigned yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Women will appear here when they add you',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _contacts.length,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    (contact['name']?[0] ?? '').toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            contact['name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: contact['status'] == 'Safe'
                                                  ? Colors.green[100]
                                                  : Colors.orange[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              contact['status'] ?? 'Unknown',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: contact['status'] == 'Safe'
                                                    ? Colors.green[900]
                                                    : Colors.orange[900],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        contact['phone'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        contact['address'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              contact['lastStatus'] ?? 'No alerts',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            contact['time'] ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
} 