import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'police/alert_history_screen.dart';
import 'police/profile_management_screen.dart';

class PoliceHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const PoliceHomeScreen({super.key, required this.userData});

  @override
  State<PoliceHomeScreen> createState() => _PoliceHomeScreenState();
}

class _PoliceHomeScreenState extends State<PoliceHomeScreen> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _screens = [
      PoliceHomeContent(userData: widget.userData),
      const AlertHistoryScreen(),
      ProfileManagementScreen(userData: widget.userData),
    ];
    _loadAlerts();
    _setupAlertListener();
  }

  void _setupAlertListener() {
    _firestore
        .collection('sos_alerts')
        .where('handledBy', isEqualTo: 'Police')
        .where('status', isEqualTo: 'Active')
        .snapshots()
        .listen((snapshot) {
      _loadAlerts();
    });
  }

  Future<void> _loadAlerts() async {
    try {
      setState(() => _isLoading = true);

      final alertsSnapshot = await _firestore
          .collection('sos_alerts')
          .where('handledBy', isEqualTo: 'Police')
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
          'escalatedBy': data['escalatedBy'] ?? '',
          'escalatedAt': data['escalatedAt'] as Timestamp?,
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
        'notes': FieldValue.arrayUnion([
          '$note (Police: ${widget.userData['name']})',
        ]),
      });
      _loadAlerts();
    } catch (e) {
      print('Error adding note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding note: $e')),
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
      _loadAlerts();
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

  Future<void> _viewLocation(GeoPoint? location) async {
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
      return;
    }

    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
    );
    
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
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
        // Navigate to Alert History screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AlertHistoryScreen(),
          ),
        );
        break;
      case 2:
        // Navigate to Profile screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileManagementScreen(
              userData: widget.userData,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Welcome, ${widget.userData['name']}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          if (widget.userData['profileImageUrl'] != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileManagementScreen(
                      userData: widget.userData,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(widget.userData['profileImageUrl']),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileManagementScreen(
                      userData: widget.userData,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAlerts,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
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
                  ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.warning,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    alert['womenName'],
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Alerted at $timeString',
                                                    style: TextStyle(
                                                      color: Colors.grey.shade600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              'SOS',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            color: Colors.red,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
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
                                      if (alert['notes'].isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Notes:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...List<String>.from(alert['notes']).map(
                                          (note) => Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('• '),
                                                Expanded(
                                                  child: Text(
                                                    note,
                                                    style: const TextStyle(fontSize: 14),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildActionButton(
                                              icon: Icons.phone,
                                              label: 'Call',
                                              color: Colors.blue,
                                              onPressed: () => _makePhoneCall(alert['womenPhone']),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildActionButton(
                                              icon: Icons.location_on,
                                              label: 'Location',
                                              color: Colors.green,
                                              onPressed: () => _viewLocation(alert['location']),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildActionButton(
                                              icon: Icons.note_add,
                                              label: 'Add Note',
                                              color: Colors.orange,
                                              onPressed: () => _showAddNoteDialog(alert['id']),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildActionButton(
                                              icon: Icons.check_circle,
                                              label: 'Resolve',
                                              color: Colors.green,
                                              onPressed: () => _markAsResolved(alert['id']),
                                            ),
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
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Alert History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }
}

class PoliceHomeContent extends StatelessWidget {
  final Map<String, dynamic> userData;
  
  const PoliceHomeContent({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final String userName = userData['name'] ?? 'Officer';
    final String? profileImageUrl = userData['profileImageUrl'];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $userName'),
        actions: [
          if (profileImageUrl != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(profileImageUrl),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Alerts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 10, // Mock data count
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(
                          index % 2 == 0 ? Icons.warning : Icons.check_circle,
                          color: Colors.white,
                        ),
                      ),
                      title: Text('Emergency Alert ${index + 1}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Location: Mock Location ${index + 1}'),
                          Text('Status: ${index % 2 == 0 ? "Active" : "Resolved"}'),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${index + 1} min ago'),
                          const SizedBox(height: 4),
                          Icon(
                            index % 2 == 0 ? Icons.circle : Icons.check_circle,
                            color: index % 2 == 0 ? Colors.red : Colors.green,
                            size: 12,
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 