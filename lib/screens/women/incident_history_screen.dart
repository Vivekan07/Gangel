import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentHistoryScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const IncidentHistoryScreen({
    super.key,
    this.userData,
  });

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _incidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    try {
      setState(() => _isLoading = true);

      final QuerySnapshot snapshot = await _firestore
          .collection('sos_alerts')
          .where('womenId', isEqualTo: widget.userData?['id'])
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> incidents = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        incidents.add({
          'id': doc.id,
          'timestamp': data['timestamp'] as Timestamp?,
          'status': data['status'] ?? 'Unknown',
          'location': data['location'] as GeoPoint?,
          'address': data['address'] ?? 'Unknown location',
          'handledBy': data['handledBy'] ?? 'Guardians',
          'resolvedBy': data['resolvedBy'],
          'resolvedAt': data['resolvedAt'] as Timestamp?,
          'escalatedBy': data['escalatedBy'],
          'escalatedAt': data['escalatedAt'] as Timestamp?,
          'notes': List<String>.from(data['notes'] ?? []),
        });
      }

      if (mounted) {
        setState(() {
          _incidents = incidents;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading incidents: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading incidents: $e')),
        );
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIncidents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _incidents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Incident History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your SOS alert history will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadIncidents,
                  child: ListView.builder(
                    itemCount: _incidents.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final incident = _incidents[index];
                      final isResolved = incident['status'] == 'Resolved';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                                'Emergency Alert',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Status: ${incident['status']}',
                                style: TextStyle(
                                  color: isResolved ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Text(
                                _formatTimestamp(incident['timestamp']),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
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
                                  Text(incident['address']),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Handled By',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      const Chip(
                                        avatar: Icon(Icons.people, size: 16),
                                        label: Text('Guardians'),
                                      ),
                                      if (incident['handledBy'] == 'Police')
                                        const Chip(
                                          avatar: Icon(Icons.local_police, size: 16),
                                          label: Text('Police'),
                                        ),
                                    ],
                                  ),
                                  if (incident['notes'].isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Notes',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...List<String>.from(incident['notes']).map(
                                      (note) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('• '),
                                            Expanded(child: Text(note)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
} 