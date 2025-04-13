class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  int _selectedIndex = 0;
  late String _userName;
  String? _profileImageUrl;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _alertsSubscription;

  @override
  void initState() {
    super.initState();
    print('Initializing GuardianHomeScreen for guardian ID: ${widget.userData['id']}');
    _userName = widget.userData['name'] ?? 'Guardian';
    _profileImageUrl = widget.userData['profileImageUrl'];
    _setupAlertsListener();
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }

  void _setupAlertsListener() {
    print('Setting up alerts listener...');
    try {
      final stream = _firestore
          .collection('sos_alerts')
          .where('guardianIds', arrayContains: widget.userData['id'])
          .where('status', isEqualTo: 'Active')
          .orderBy('timestamp', descending: true)
          .snapshots();

      _alertsSubscription = stream.listen(
        (snapshot) {
          print('Received alerts update. Document count: ${snapshot.docs.length}');
          _processAlertSnapshot(snapshot);
        },
        onError: (error) {
          print('Error in alerts stream: $error');
          setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      print('Error setting up alerts listener: $e');
      setState(() => _isLoading = false);
    }
  }

  void _processAlertSnapshot(QuerySnapshot snapshot) {
    try {
      final List<Map<String, dynamic>> alerts = [];
      
      for (var doc in snapshot.docs) {
        print('Processing alert document: ${doc.id}');
        final data = doc.data() as Map<String, dynamic>;
        
        // Debug print the full document data
        print('Alert data: $data');
        
        alerts.add({
          'id': doc.id,
          'womenId': data['womenId'] ?? 'Unknown',
          'womenName': data['womenName'] ?? 'Unknown',
          'womenPhone': data['womenPhone'] ?? '',
          'location': data['location'] as GeoPoint?,
          'address': data['address'] ?? 'Unknown location',
          'timestamp': data['timestamp'] as Timestamp?,
          'status': data['status'] ?? 'Unknown',
          'notes': List<String>.from(data['notes'] ?? []),
          'handledBy': data['handledBy'] ?? 'Guardian',
        });
      }

      print('Processed ${alerts.length} alerts');
      
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error processing alert snapshot: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAlerts() async {
    print('\n=== Manually refreshing alerts ===');
    try {
      setState(() => _isLoading = true);

      final alertsSnapshot = await _firestore
          .collection('sos_alerts')
          .where('guardianIds', arrayContains: widget.userData['id'])
          .where('status', isEqualTo: 'Active')
          .orderBy('timestamp', descending: true)
          .get();

      print('Found ${alertsSnapshot.docs.length} alerts');
      _processAlertSnapshot(alertsSnapshot);
      
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

  Future<void> _addNote(String alertId, String note) async {
    try {
      print('Adding note to alert $alertId: $note');
      await _firestore.collection('sos_alerts').doc(alertId).update({
        'notes': FieldValue.arrayUnion([
          '$note (Guardian: $_userName)',
        ]),
      });
      print('Note added successfully');
    } catch (e) {
      print('Error adding note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding note: $e')),
      );
    }
  }

  Future<void> _escalateToPolice(String alertId) async {
    try {
      print('Escalating alert $alertId to police');
      await _firestore.collection('sos_alerts').doc(alertId).update({
        'handledBy': 'Police',
        'escalatedAt': FieldValue.serverTimestamp(),
        'escalatedBy': widget.userData['id'],
        'escalatedByName': widget.userData['name'],
      });
      print('Alert escalated successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert escalated to police')),
      );
    } catch (e) {
      print('Error escalating to police: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error escalating to police: $e')),
      );
    }
  }

  Future<void> _markAsResolved(String alertId) async {
    try {
      print('Marking alert $alertId as resolved');
      await _firestore.collection('sos_alerts').doc(alertId).update({
        'status': 'Resolved',
        'resolvedBy': widget.userData['id'],
        'resolvedByName': widget.userData['name'],
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      print('Alert marked as resolved successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert marked as resolved')),
      );
    } catch (e) {
      print('Error resolving alert: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resolving alert: $e')),
      );
    }
  }

  // ... rest of the existing code ...
} 