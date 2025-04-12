import 'package:flutter/material.dart';
import 'women/guardian_management_screen.dart';
import 'women/messages_screen.dart';
import 'women/incident_history_screen.dart';
import 'women/profile_management_screen.dart';
import 'women/police_management_screen.dart';

class WomenHomeScreen extends StatefulWidget {
  const WomenHomeScreen({super.key});

  @override
  State<WomenHomeScreen> createState() => _WomenHomeScreenState();
}

class _WomenHomeScreenState extends State<WomenHomeScreen> {
  int _selectedIndex = 0;

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
          MaterialPageRoute(builder: (context) => const GuardianManagementScreen()),
        );
        break;
      case 2:
        // Navigate to Police screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PoliceManagementScreen()),
        );
        break;
      case 3:
        // Navigate to Messages screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MessagesScreen()),
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
                      builder: (context) => const ProfileManagementScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
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
        title: const Text('Home'),
        actions: [
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
            // SOS Button
            GestureDetector(
              onTap: () {
                // Handle SOS action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('SOS Alert Sent!')),
                );
              },
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