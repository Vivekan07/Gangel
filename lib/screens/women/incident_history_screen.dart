import 'package:flutter/material.dart';

class IncidentHistoryScreen extends StatelessWidget {
  const IncidentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident History'),
      ),
      body: ListView.builder(
        itemCount: 10,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final bool isResolved = index % 3 == 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isResolved ? Colors.green : Colors.red,
                    child: Icon(
                      isResolved ? Icons.check : Icons.warning,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    'Emergency Alert #${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Status: ${isResolved ? "Resolved" : "Active"}',
                    style: TextStyle(
                      color: isResolved ? Colors.green : Colors.red,
                    ),
                  ),
                  trailing: Text(
                    '${DateTime.now().subtract(Duration(days: index)).day}/${DateTime.now().subtract(Duration(days: index)).month}/${DateTime.now().subtract(Duration(days: index)).year}',
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Mock Location ${index + 1}'),
                      const SizedBox(height: 16),
                      const Text(
                        'Responded By',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.person, size: 16),
                            label: Text('Guardian ${index + 1}'),
                          ),
                          if (index % 2 == 0)
                            const Chip(
                              avatar: Icon(Icons.local_police, size: 16),
                              label: Text('Local Police'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Actions Taken',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isResolved
                            ? '• Emergency response team dispatched\n• Guardian notified\n• Situation resolved'
                            : '• Alert sent to guardians\n• Emergency contacts notified\n• Awaiting response',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 