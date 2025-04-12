import 'package:flutter/material.dart';

class AlertManagementScreen extends StatefulWidget {
  final int alertId;

  const AlertManagementScreen({
    super.key,
    required this.alertId,
  });

  @override
  State<AlertManagementScreen> createState() => _AlertManagementScreenState();
}

class _AlertManagementScreenState extends State<AlertManagementScreen> {
  bool _isResolved = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showActionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Take Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.local_police),
              title: const Text('Contact Police'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contacting police...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_hospital),
              title: const Text('Contact Emergency Services'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contacting emergency services...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alert #${widget.alertId} Management'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _isResolved ? Colors.green : Colors.red,
                  child: Icon(
                    _isResolved ? Icons.check : Icons.warning,
                    color: Colors.white,
                  ),
                ),
                title: Text('Emergency Alert #${widget.alertId}'),
                subtitle: Text(
                  _isResolved ? 'Status: Resolved' : 'Status: Active',
                  style: TextStyle(
                    color: _isResolved ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Location Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Address: Sample Street, Jaffna, Sri Lanka'),
                    Text('Coordinates: 9.6615, 80.0255'),
                    Text('Last Updated: 2 minutes ago'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Person Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Name: Jane Doe'),
                    Text('Phone: +94 77 123 4567'),
                    Text('Age: 25'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Add notes about the incident...',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showActionDialog,
                    icon: const Icon(Icons.warning),
                    label: const Text('Take Action'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isResolved = !_isResolved;
                      });
                      if (_isResolved) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alert marked as resolved')),
                        );
                      }
                    },
                    icon: Icon(_isResolved ? Icons.refresh : Icons.check),
                    label: Text(_isResolved ? 'Reopen' : 'Mark as Resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isResolved ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 