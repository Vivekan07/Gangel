import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gangel/screens/guardian/messages_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  bool _isMapReady = false;
  
  // Jaffna, Sri Lanka coordinates
  static const LatLng _jaffnaLocation = LatLng(9.6615, 80.0255);
  
  // Mock protected contacts data
  final List<Map<String, dynamic>> _protectedContacts = [
    {
      'name': 'Jane Doe',
      'location': LatLng(9.6650, 80.0280),
      'status': 'Safe',
      'lastUpdate': '5 mins ago',
    },
    {
      'name': 'Sarah Smith',
      'location': LatLng(9.6580, 80.0230),
      'status': 'In Transit',
      'lastUpdate': '2 mins ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeMapFeatures();
  }

  void _initializeMapFeatures() {
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      // Show error for unsupported platforms
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maps are not supported on this platform'),
            duration: Duration(seconds: 3),
          ),
        );
      });
      return;
    }
    _initializeMarkers();
    setState(() {
      _isMapReady = true;
    });
  }

  void _initializeMarkers() {
    for (var contact in _protectedContacts) {
      _markers.add(
        Marker(
          markerId: MarkerId(contact['name']),
          position: contact['location'],
          infoWindow: InfoWindow(
            title: contact['name'],
            snippet: '${contact['status']} • ${contact['lastUpdate']}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            contact['status'] == 'Safe'
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Widget _buildMap() {
    if (!_isMapReady) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: const CameraPosition(
        target: _jaffnaLocation,
        zoom: 14,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      zoomControlsEnabled: true,
      zoomGesturesEnabled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing locations...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMap(),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _protectedContacts.map((contact) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: contact['status'] == 'Safe'
                            ? Colors.green
                            : Colors.orange,
                        child: Icon(
                          contact['status'] == 'Safe'
                              ? Icons.check
                              : Icons.directions_walk,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(contact['name']),
                      subtitle: Text(
                        '${contact['status']} • ${contact['lastUpdate']}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.message),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                contactName: contact['name'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Contacts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Show Safe Contacts'),
              value: true,
              onChanged: (value) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filter applied')),
                );
              },
            ),
            CheckboxListTile(
              title: const Text('Show In Transit Contacts'),
              value: true,
              onChanged: (value) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filter applied')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filters applied')),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
} 