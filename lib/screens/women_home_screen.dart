import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'women/guardian_management_screen.dart';
import 'women/messages_screen.dart';
import 'women/incident_history_screen.dart';
import 'women/profile_management_screen.dart';
import 'women/police_management_screen.dart';
import 'login_screen.dart';
import 'guardian/map_screen.dart';

class WomenHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const WomenHomeScreen({super.key, required this.userData});

  @override
  State<WomenHomeScreen> createState() => _WomenHomeScreenState();
}

class _WomenHomeScreenState extends State<WomenHomeScreen> {
  int _selectedIndex = 0;
  late String _userName;
  String? _profileImageUrl;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userName = widget.userData['name'] ?? 'User';
    _profileImageUrl = widget.userData['profileImageUrl'];
    _checkLocationServices();
  }

  Future<void> _checkLocationServices() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable them for SOS alerts.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking location services: $e');
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
        // Navigate to Guardians screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GuardianManagementScreen(
              userData: {
                'id': widget.userData['id'],
                'name': widget.userData['name'],
                'email': widget.userData['email'],
                'phone': widget.userData['phone'],
              },
            ),
          ),
        );
        break;
      case 2:
        // Navigate to Police screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PoliceManagementScreen(
              userData: widget.userData,
            ),
          ),
        );
        break;
      case 3:
        // Navigate to Messages screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesScreen(
              userData: widget.userData,
            ),
          ),
        );
        break;
      case 4:
        // Navigate to History screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const IncidentHistoryScreen()),
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
                      builder: (context) => ProfileManagementScreen(userData: widget.userData),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
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

  Future<void> _sendSOSAlert() async {
    if (_isLoading) {
      print('SOS alert already in progress');
      return;
    }

    try {
      setState(() => _isLoading = true);
      print('\n=== Starting SOS Alert Process ===');

      // Check if location services are enabled
      print('Checking if location services are enabled...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services to send SOS alert'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Request location permission
      print('Checking location permission...');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print('Location permission denied, requesting...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied after request');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required to send SOS alert'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied. Please enable them in settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }

      print('Getting current location...');
      // Get current location with timeout
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      ).catchError((error) {
        print('Error getting location: $error');
        throw Exception('Failed to get location: $error');
      });
      
      print('Location obtained: ${position.latitude}, ${position.longitude}');

      // Verify user data
      if (widget.userData['id'] == null) {
        throw Exception('User ID is null');
      }

      print('Fetching guardians...');
      // Get all guardians for this woman
      final guardiansSnapshot = await _firestore
          .collection('women_guardian')
          .where('womenId', isEqualTo: widget.userData['id'])
          .get();

      print('Found ${guardiansSnapshot.docs.length} guardians');

      if (guardiansSnapshot.docs.isEmpty) {
        print('No guardians found for this user');
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add guardians before sending SOS alert'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Prepare guardian information first
      print('Preparing guardian information...');
      final List<String> guardianIds = [];
      final List<String> guardianNames = [];
      
      for (var doc in guardiansSnapshot.docs) {
        final guardianData = doc.data();
        print('Processing guardian: ${guardianData['guardianName']} (${guardianData['guardianId']})');
        guardianIds.add(guardianData['guardianId'] ?? '');
        guardianNames.add(guardianData['guardianName'] ?? '');
      }

      print('Creating SOS alert...');
      // Create SOS alert
      final alertData = {
        'womenId': widget.userData['id'],
        'womenName': widget.userData['name'],
        'womenEmail': widget.userData['email'],
        'womenPhone': widget.userData['phone'],
        'location': GeoPoint(position.latitude, position.longitude),
        'address': 'Location being fetched...',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Active',
        'handledBy': 'Guardian',
        'notes': [],
        'resolvedBy': null,
        'resolvedAt': null,
        'guardianIds': guardianIds,
        'guardianNames': guardianNames,
      };

      print('Alert data prepared: $alertData');

      // Create the alert document
      final alertRef = await _firestore.collection('sos_alerts').add(alertData);
      print('Alert document created with ID: ${alertRef.id}');

      // No need to update guardian information separately since we included it in the initial data
      print('=== SOS Alert Process Completed Successfully ===');

      // Close loading dialog and show success message
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS Alert sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e, stackTrace) {
      print('Error sending SOS alert: $e');
      print('Stack trace: $stackTrace');
      
      if (context.mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close loading dialog
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send SOS alert: $e'),
            backgroundColor: Colors.red,
          ),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _sendSOSAlert,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Guardians',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_police),
            label: 'Police',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
} 