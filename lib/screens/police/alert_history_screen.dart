import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String _currentFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      setState(() => _isLoading = true);

      QuerySnapshot alertsSnapshot;
      if (_currentFilter == 'active') {
        alertsSnapshot = await _firestore
            .collection('sos_alerts')
            .where('handledBy', isEqualTo: 'Police')
            .where('status', isEqualTo: 'Active')
            .orderBy('timestamp', descending: true)
            .get();
      } else if (_currentFilter == 'resolved') {
        alertsSnapshot = await _firestore
            .collection('sos_alerts')
            .where('handledBy', isEqualTo: 'Police')
            .where('status', isEqualTo: 'Resolved')
            .orderBy('timestamp', descending: true)
            .get();
      } else {
        alertsSnapshot = await _firestore
            .collection('sos_alerts')
            .where('handledBy', isEqualTo: 'Police')
            .orderBy('timestamp', descending: true)
            .get();
      }

      final List<Map<String, dynamic>> alerts = [];
      for (var doc in alertsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading alerts: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Active'),
                Tab(text: 'Resolved'),
              ],
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              onTap: (index) {
                setState(() {
                  _currentFilter = index == 0 ? 'all' : index == 1 ? 'active' : 'resolved';
                });
                _loadAlerts();
              },
            ),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _alerts.isEmpty
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
                          Text(
                            'No ${_currentFilter == "all" ? "" : "$_currentFilter "}alerts found',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _alerts.length,
                      itemBuilder: (context, index) {
                        final alert = _alerts[index];
                        final timestamp = alert['timestamp'] as Timestamp?;
                        final isResolved = alert['status'] == 'Resolved';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isResolved ? Colors.green : Colors.red,
                              child: Icon(
                                isResolved ? Icons.check : Icons.warning,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(alert['womenName']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Location: ${alert['address']}'),
                                if (timestamp != null)
                                  Text('Reported: ${timestamp.toDate().toString().substring(0, 16)}'),
                                Text(
                                  'Status: ${alert['status']}',
                                  style: TextStyle(
                                    color: isResolved ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
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

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Alerts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date Range'),
              onTap: () {
                Navigator.pop(context);
                _showDateRangePicker(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Location'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location filter coming soon')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (picked != null && context.mounted) {
      // TODO: Implement date range filtering
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selected range: ${picked.start.toString().substring(0, 10)} to ${picked.end.toString().substring(0, 10)}',
          ),
        ),
      );
    }
  }
} 