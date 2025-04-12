import 'package:flutter/material.dart';
import 'police/alert_history_screen.dart';
import 'police/profile_management_screen.dart';
import 'police/alert_management_screen.dart';

class PoliceHomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const PoliceHomeScreen({super.key, required this.userData});

  @override
  State<PoliceHomeScreen> createState() => _PoliceHomeScreenState();
}

class _PoliceHomeScreenState extends State<PoliceHomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _screens = [
      PoliceHomeContent(userData: widget.userData),
      const AlertHistoryScreen(),
      ProfileManagementScreen(userData: widget.userData),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
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
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(Icons.warning, color: Colors.white),
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlertManagementScreen(
                              alertId: 'ALERT${index + 1}',
                            ),
                          ),
                        );
                      },
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