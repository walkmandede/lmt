import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _controller;

  static const LatLng _start = LatLng(16.8409, 96.1735); // Yangon
  static const LatLng _end = LatLng(16.8661, 96.1951);

  final Set<Marker> _markers = {
    Marker(
      markerId: const MarkerId('start'),
      position: _start,
      infoWindow: const InfoWindow(title: 'Site A'),
    ),
    Marker(
      markerId: const MarkerId('end'),
      position: _end,
      infoWindow: const InfoWindow(title: 'Site B'),
    ),
  };

  final Set<Polyline> _polylines = {
    Polyline(
      polylineId: const PolylineId('route'),
      points: [_start, _end],
      color: Colors.blue,
      width: 4,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: _start,
          zoom: 13,
        ),
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (controller) => _controller = controller,
      ),
    );
  }
}
