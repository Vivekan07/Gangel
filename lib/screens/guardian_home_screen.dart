import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'guardian/guardian_messages_screen.dart';
import 'guardian/map_screen.dart';
import 'guardian/profile_management_screen.dart';
import 'guardian/alert_management_screen.dart';

class GuardianHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const GuardianHomeScreen({super.key, required this.userData});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  int _selectedIndex = 0;
  late String _userName;
  String? _profileImageUrl;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userName = widget.userData['name'] ?? 'Guardian';
    _profileImageUrl = widget.userData['profileImageUrl'];
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      setState(() => _isLoading = true);

      // Get all active alerts where this guardian is listed
      final alertsSnapshot = await _firestore
          .collection('sos_alerts')
          .where('guardianIds', arrayContains: widget.userData['id'])
          .where('status', isEqualTo: 'Active')
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> alerts = [];
      
      for (var doc in alertsSnapshot.docs) {
        final data = doc.data();
        alerts.add({
          'id': doc.id,
          'womenName': data['womenName'] ?? 'Unknown',
          'womenPhone': data['womenPhone'] ?? '',
          'location': data['location'] as GeoPoint?,
          'address': data['address'] ?? 'Unknown location',
          'timestamp': data['timestamp'] as Timestamp?,
          'status': data['status'] ?? 'Unknown',
          'notes': List<String>.from(data['notes'] ?? []),
        });
      }

      if (mounted) {
        setState(() {
          _alerts = alerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading alerts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addNote(String alertId, String note) async {
    try {
      await _firestore.collection('sos_alerts').doc(alertId).update({
        'notes': FieldValue.arrayUnion([note]),
      });
      _loadAlerts(); // Reload to show new note
    } catch (e) {
      print('Error adding note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding note: $e')),
      );
    }
  }

  Future<void> _escalateToPolice(String alertId) async {
    try {
      await _firestore.collection('sos_alerts').doc(alertId).update({
        'handledBy': 'Police',
        'escalatedAt': FieldValue.serverTimestamp(),
        'escalatedBy': widget.userData['id'],
      });
      _loadAlerts(); // Reload to reflect changes
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert escalated to police')),
      );
    } catch (e) {
      print('Error escalating to police: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error escalating to police: $e')),
      );
    }
  }

  Future<void> _markAsResolved(String alertId) async {
    try {
      await _firestore.collection('sos_alerts').doc(alertId).update({
        'status': 'Resolved',
        'resolvedBy': widget.userData['id'],
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      _loadAlerts(); // Reload to reflect changes
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert marked as resolved')),
      );
    } catch (e) {
      print('Error resolving alert: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resolving alert: $e')),
      );
    }
  }

  void _showAddNoteDialog(String alertId) {
    final TextEditingController noteController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Enter your note here',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (noteController.text.isNotEmpty) {
                _addNote(alertId, noteController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone call')),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        // Already on home screen
        setState(() => _selectedIndex = 0);
        break;
      case 1:
        // Navigate to Messages screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GuardianMessagesScreen(
              userData: widget.userData,
              guardianId: widget.userData['id'],
              guardianEmail: widget.userData['email'],
            ),
          ),
        );
        break;
      case 2:
        // Navigate to Map screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapScreen(
              userData: widget.userData,
              guardianId: widget.userData['id'],
            ),
          ),
        );
        break;
      case 3:
        // Navigate to Profile screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileManagementScreen(
              userData: widget.userData,
              guardianId: widget.userData['id'],
            ),
          ),
        );
        break;
    }
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile Management'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileManagementScreen(
                        userData: widget.userData,
                        guardianId: widget.userData['id'],
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  // Close the bottom sheet first
                  Navigator.pop(context);
                  // Navigate to login screen and remove all previous routes
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $_userName'),
        actions: [
          if (_profileImageUrl != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: _showProfileMenu,
                child: CircleAvatar(
                  backgroundImage: NetworkImage(_profileImageUrl!),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: _showProfileMenu,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAlerts,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Active SOS Alerts',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadAlerts,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _alerts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No Active Alerts',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Active SOS alerts will appear here',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _alerts.length,
                              itemBuilder: (context, index) {
                                final alert = _alerts[index];
                                final timestamp = alert['timestamp'] as Timestamp?;
                                final timeString = timestamp != null
                                    ? '${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                                    : 'Unknown time';
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              alert['womenName'],
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              timeString,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              color: Colors.red,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                alert['address'] ?? 'Location being fetched...',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildActionButton(
                                              icon: Icons.phone,
                                              label: 'Call',
                                              onPressed: () => _makePhoneCall(alert['womenPhone']),
                                              color: Colors.blue,
                                            ),
                                            _buildActionButton(
                                              icon: Icons.note_add,
                                              label: 'Add Note',
                                              onPressed: () => _showAddNoteDialog(alert['id']),
                                              color: Colors.grey.shade700,
                                            ),
                                            _buildActionButton(
                                              icon: Icons.local_police,
                                              label: 'Police',
                                              onPressed: () => _escalateToPolice(alert['id']),
                                              color: Colors.red,
                                            ),
                                            _buildActionButton(
                                              icon: Icons.check_circle,
                                              label: 'Resolve',
                                              onPressed: () => _markAsResolved(alert['id']),
                                              color: Colors.green,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return TextButton.icon(
      icon: Icon(icon, color: color, size: 20),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
} 