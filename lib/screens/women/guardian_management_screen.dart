import 'package:flutter/material.dart';

class GuardianManagementScreen extends StatefulWidget {
  const GuardianManagementScreen({super.key});

  @override
  State<GuardianManagementScreen> createState() => _GuardianManagementScreenState();
}

class _GuardianManagementScreenState extends State<GuardianManagementScreen> {
  final List<Map<String, String>> _guardians = [
    {
      'name': 'John Doe',
      'phone': '+1234567890',
      'relation': 'Father',
    },
    {
      'name': 'Jane Smith',
      'phone': '+0987654321',
      'relation': 'Sister',
    },
  ];

  void _showAddGuardianDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Guardian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(
                labelText: 'Relation',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _guardians.add({
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'relation': relationController.text,
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditGuardianDialog(int index) {
    final nameController = TextEditingController(text: _guardians[index]['name']);
    final phoneController = TextEditingController(text: _guardians[index]['phone']);
    final relationController = TextEditingController(text: _guardians[index]['relation']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Guardian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(
                labelText: 'Relation',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _guardians[index] = {
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'relation': relationController.text,
                };
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Guardians'),
      ),
      body: ListView.builder(
        itemCount: _guardians.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final guardian = _guardians[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(guardian['name']![0]),
              ),
              title: Text(guardian['name']!),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guardian['phone']!),
                  Text('Relation: ${guardian['relation']}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditGuardianDialog(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _guardians.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGuardianDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
} 