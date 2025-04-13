import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gangel/screens/guardian/guardian_messages_screen.dart' show ChatScreen;

class MapScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String guardianId;
  
  const MapScreen({
    super.key,
    required this.userData,
    required this.guardianId,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _alertsSubscription;
  Position? _currentPosition;
  
  // Jaffna, Sri Lanka coordinates as default center
  static const LatLng _defaultCenter = LatLng(9.6615, 80.0255);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _setupAlertsListener();
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      if (_mapController != null && mounted) {
        _mapController.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  void _setupAlertsListener() {
    _alertsSubscription = FirebaseFirestore.instance
        .collection('sos_alerts')
        .where('status', isEqualTo: 'Active')
        .snapshots()
        .listen(
          (snapshot) => _updateMarkers(snapshot),
          onError: (error) {
            print('Error listening to alerts: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading alerts: $error')),
              );
            }
          },
        );
  }

  void _updateMarkers(QuerySnapshot snapshot) {
    try {
      setState(() {
        _markers.clear();
        
        // Add active SOS alert markers
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final GeoPoint? location = data['location'] as GeoPoint?;
          
          if (location != null) {
            final timestamp = data['timestamp'] as Timestamp?;
            final timeString = _formatTimestamp(timestamp);
            
            _markers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(location.latitude, location.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(
                  title: 'SOS Alert: ${data['womenName'] ?? 'Unknown'}',
                  snippet: 'Alerted $timeString\n${data['address'] ?? 'Location being fetched...'}',
                ),
              ),
            );
          }
        }

        // Add current location marker if available
        if (_currentPosition != null) {
          _markers.add(
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              infoWindow: const InfoWindow(
                title: 'Your Location',
                snippet: 'You are here',
              ),
            ),
          );
        }

        _isLoading = false;
      });

      if (_markers.isNotEmpty) {
        _fitMarkersOnMap();
      }
    } catch (e) {
      print('Error updating markers: $e');
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    final DateTime now = DateTime.now();
    final DateTime alertTime = timestamp.toDate();
    final Duration difference = now.difference(alertTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _fitMarkersOnMap() {
    if (_markers.isEmpty || _mapController == null) return;

    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (Marker marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      
      minLat = lat < minLat ? lat : minLat;
      maxLat = lat > maxLat ? lat : maxLat;
      minLng = lng < minLng ? lng : minLng;
      maxLng = lng > maxLng ? lng : maxLng;
    }

    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.01, minLng - 0.01),
          northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
        ),
        50,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_markers.isNotEmpty) {
      _fitMarkersOnMap();
    } else if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active SOS Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _setupAlertsListener();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : _defaultCenter,
                    zoom: 15,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapType: MapType.normal,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                ),
                if (_markers.isEmpty && !_isLoading)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Active SOS Alerts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Active alerts will appear on the map',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
} 