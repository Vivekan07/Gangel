import 'package:flutter/material.dart';

class PoliceManagementScreen extends StatefulWidget {
  const PoliceManagementScreen({super.key});

  @override
  State<PoliceManagementScreen> createState() => _PoliceManagementScreenState();
}

class _PoliceManagementScreenState extends State<PoliceManagementScreen> {
  final List<Map<String, dynamic>> _policeList = [
    {
      'name': 'Police Station 1',
      'location': 'Jaffna Central',
      'contact': '+94 21 222 2222',
      'officer': 'Inspector John Doe',
      'badge': 'PS001',
    },
    {
      'name': 'Police Station 2',
      'location': 'Nallur',
      'contact': '+94 21 333 3333',
      'officer': 'Inspector Jane Smith',
      'badge': 'PS002',
    },
    {
      'name': 'Police Station 3',
      'location': 'Kopay',
      'contact': '+94 21 444 4444',
      'officer': 'Inspector Mike Johnson',
      'badge': 'PS003',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Police Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddPoliceDialog();
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _policeList.length,
        itemBuilder: (context, index) {
          final police = _policeList[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.local_police, color: Colors.white),
              ),
              title: Text(police['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location: ${police['location']}'),
                  Text('Officer: ${police['officer']}'),
                  Text('Badge: ${police['badge']}'),
                  Text('Contact: ${police['contact']}'),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  _showDeleteConfirmation(index);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddPoliceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Police Station'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Station Name'),
                onChanged: (value) {
                  // Handle name input
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Location'),
                onChanged: (value) {
                  // Handle location input
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Contact Number'),
                onChanged: (value) {
                  // Handle contact input
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Officer Name'),
                onChanged: (value) {
                  // Handle officer input
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Badge Number'),
                onChanged: (value) {
                  // Handle badge input
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle add police station
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Police Station Added')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Police Station'),
        content: const Text('Are you sure you want to delete this police station?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _policeList.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Police Station Deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 