import 'package:flutter/material.dart';
import 'alert_management_screen.dart';

class AlertHistoryScreen extends StatelessWidget {
  const AlertHistoryScreen({super.key});

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
            const TabBar(
              tabs: [
                Tab(text: 'All'),
                Tab(text: 'Active'),
                Tab(text: 'Resolved'),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAlertList(context, 'all'),
                  _buildAlertList(context, 'active'),
                  _buildAlertList(context, 'resolved'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertList(BuildContext context, String filter) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 20,
      itemBuilder: (context, index) {
        final bool isResolved = index % 3 == 0;
        if (filter == 'active' && isResolved) return const SizedBox.shrink();
        if (filter == 'resolved' && !isResolved) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isResolved ? Colors.green : Colors.red,
              child: Icon(
                isResolved ? Icons.check : Icons.warning,
                color: Colors.white,
              ),
            ),
            title: Text('Emergency Alert #${1000 + index}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location: Mock Location ${index + 1}'),
                Text('Reported: ${DateTime.now().subtract(Duration(days: index)).toString().substring(0, 16)}'),
                Text(
                  'Status: ${isResolved ? "Resolved" : "Active"}',
                  style: TextStyle(
                    color: isResolved ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlertManagementScreen(
                      alertId: 'ALERT${1000 + index}',
                    ),
                  ),
                );
              },
            ),
            isThreeLine: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlertManagementScreen(
                    alertId: 'ALERT${1000 + index}',
                  ),
                ),
              );
            },
          ),
        );
      },
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
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Alert Type'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alert type filter coming soon')),
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