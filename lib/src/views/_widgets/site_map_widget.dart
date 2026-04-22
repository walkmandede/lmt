import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    as gmaps
    show GoogleMap, GoogleMapController, CameraPosition, LatLng, Marker, MarkerId, Polyline, PolylineId, BitmapDescriptor, CameraUpdate, LatLngBounds;
import 'package:lmt/src/models/site_detail_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppMapWidget
// Usage: AppMapWidget(width: 600, height: 400, site: siteDetailModel)
// ─────────────────────────────────────────────────────────────────────────────

class SiteMapWidget extends StatefulWidget {
  final double width;
  final double height;
  final SiteDetailModel site;
  final void Function(gmaps.GoogleMapController gMapController)? onMapCreated;

  const SiteMapWidget({
    super.key,
    required this.width,
    required this.height,
    required this.site,
    required this.onMapCreated,
  });

  @override
  State<SiteMapWidget> createState() => _SiteMapWidgetState();
}

class _SiteMapWidgetState extends State<SiteMapWidget> {
  Completer<gmaps.GoogleMapController?> _controller = Completer<gmaps.GoogleMapController>();

  Set<gmaps.Marker> _markers = {};
  Set<gmaps.Polyline> _polylines = {};

  // Screen-space positions for overlay widgets
  Offset? _fatOffset;
  Offset? _customerOffset;
  Offset? _distanceOffset;

  // Hide overlays while camera is moving to avoid jitter
  bool _cameraMoving = false;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _buildMarkersAndPolylines();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  // ── Marker & polyline setup ─────────────────────────────────────────────────

  Future<void> _buildMarkersAndPolylines() async {
    final site = widget.site;
    final markers = <gmaps.Marker>{};
    final polylinePoints = <gmaps.LatLng>[];

    // FAT — green location pin (standard Google Maps default green)
    if (site.fatLat != null && site.fatLng != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('fat'),
          position: gmaps.LatLng(site.fatLat!, site.fatLng!),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen),
          anchor: const Offset(0.5, 1.0),
        ),
      );
      polylinePoints.add(gmaps.LatLng(site.fatLat!, site.fatLng!));
    }

    // Poles — drawn colored circles
    int poleIndex = 0;
    for (final pole in (site.poles ?? [])) {
      if (!pole.hasLocations) continue;
      final color = _poleColor(pole.enumPoleType);
      final icon = await _drawPoleMarker(color);
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('pole_$poleIndex'),
          position: gmaps.LatLng(pole.lat!, pole.lng!),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
        ),
      );
      polylinePoints.add(gmaps.LatLng(pole.lat!, pole.lng!));
      poleIndex++;
    }

    // Customer — green home circle
    if (site.customerLat != null && site.customerLng != null) {
      final icon = await _drawHomeMarker();
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('customer'),
          position: gmaps.LatLng(site.customerLat!, site.customerLng!),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
        ),
      );
      polylinePoints.add(gmaps.LatLng(site.customerLat!, site.customerLng!));
    }

    final polylines = <gmaps.Polyline>{};
    if (polylinePoints.length > 1) {
      polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route'),
          points: polylinePoints,
          color: const Color(0xFF2196F3),
          width: 3,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
        _polylines = polylines;
      });
    }
  }

  // ── Custom marker drawing ───────────────────────────────────────────────────

  Color _poleColor(EnumPoleType? type) {
    switch (type) {
      case EnumPoleType.epc:
        return const Color(0xFFDD2222);
      case EnumPoleType.mpt:
        return const Color(0xFF1a7a3a);
      case EnumPoleType.other:
        return const Color(0xFF00AADD);
      default:
        return Colors.grey;
    }
  }

  /// Colored circle with a horizontal black stripe — matches EPC/MPT/Other icons
  Future<gmaps.BitmapDescriptor> _drawPoleMarker(Color color) async {
    const double size = 36;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    // Fill circle
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = color,
    );
    // Black border
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 1.5,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Horizontal stripe
    canvas.drawLine(
      const Offset(5, size / 2),
      const Offset(size - 5, size / 2),
      Paint()
        ..color = Colors.black
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return gmaps.BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  /// Dark-green circle with a small white house shape inside
  Future<gmaps.BitmapDescriptor> _drawHomeMarker() async {
    const double size = 38;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    // Fill circle
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = const Color(0xFF1a7a3a),
    );
    // Black border
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 1.5,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Simple house shape (roof triangle + body rect)
    final whitePaint = Paint()..color = Colors.white;
    final cx = size / 2;

    // Roof triangle
    final roofPath = Path()
      ..moveTo(cx, 9)
      ..lineTo(cx - 9, 19)
      ..lineTo(cx + 9, 19)
      ..close();
    canvas.drawPath(roofPath, whitePaint);

    // Body rectangle
    canvas.drawRect(const Rect.fromLTWH(size / 2 - 7, 19, 14, 10), whitePaint);

    // Door
    canvas.drawRect(
      Rect.fromLTWH(cx - 2.5, 23, 5, 6),
      Paint()..color = const Color(0xFF1a7a3a),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return gmaps.BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  // ── Overlay position calculation ────────────────────────────────────────────

  Future<void> _updateOverlayPositions() async {
    final ctrl = await _controller.future;
    if (ctrl == null) return;

    final site = widget.site;

    Offset? fatOff;
    Offset? custOff;
    Offset? distOff;

    if (site.fatLat != null && site.fatLng != null) {
      final sc = await ctrl.getScreenCoordinate(gmaps.LatLng(site.fatLat!, site.fatLng!));
      fatOff = Offset(sc.x.toDouble(), sc.y.toDouble());
    }

    if (site.customerLat != null && site.customerLng != null) {
      final sc = await ctrl.getScreenCoordinate(gmaps.LatLng(site.customerLat!, site.customerLng!));
      custOff = Offset(sc.x.toDouble(), sc.y.toDouble());
    }

    // Distance label at the midpoint of the polyline
    final allPoints = <gmaps.LatLng>[];
    if (site.fatLat != null && site.fatLng != null) {
      allPoints.add(gmaps.LatLng(site.fatLat!, site.fatLng!));
    }
    for (final p in (site.poles ?? [])) {
      if (p.hasLocations) allPoints.add(gmaps.LatLng(p.lat!, p.lng!));
    }
    if (site.customerLat != null && site.customerLng != null) {
      allPoints.add(gmaps.LatLng(site.customerLat!, site.customerLng!));
    }
    if (allPoints.length >= 2 && site.dropCableLengthInMeter != null) {
      final midPoint = allPoints[allPoints.length ~/ 2];
      final sc = await ctrl.getScreenCoordinate(midPoint);
      distOff = Offset(sc.x.toDouble(), sc.y.toDouble());
    }

    if (mounted) {
      setState(() {
        _fatOffset = fatOff;
        _customerOffset = custOff;
        _distanceOffset = distOff;
      });
    }
  }

  void _onCameraMove(_) {
    if (!_cameraMoving) {
      setState(() => _cameraMoving = true);
    }
    _idleTimer?.cancel();
  }

  void _onCameraIdle() {
    _idleTimer = Timer(const Duration(milliseconds: 100), () async {
      await _updateOverlayPositions();
      if (mounted) setState(() => _cameraMoving = false);
    });
  }

  // ── Initial camera bounds ───────────────────────────────────────────────────

  gmaps.LatLng _initialCenter() {
    final site = widget.site;
    if (site.fatLat != null && site.fatLng != null) {
      return gmaps.LatLng(site.fatLat!, site.fatLng!);
    }
    if (site.customerLat != null && site.customerLng != null) {
      return gmaps.LatLng(site.customerLat!, site.customerLng!);
    }
    return const gmaps.LatLng(16.8409, 96.1735); // default Yangon
  }

  /// After map is ready, fit camera to show all points
  Future<void> _fitBounds() async {
    final ctrl = await _controller.future;
    if (ctrl == null) return;

    final site = widget.site;
    final lats = <double>[];
    final lngs = <double>[];

    if (site.fatLat != null) lats.add(site.fatLat!);
    if (site.fatLng != null) lngs.add(site.fatLng!);
    if (site.customerLat != null) lats.add(site.customerLat!);
    if (site.customerLng != null) lngs.add(site.customerLng!);
    for (final p in (site.poles ?? [])) {
      if (p.lat != null) lats.add(p.lat!);
      if (p.lng != null) lngs.add(p.lng!);
    }

    if (lats.length < 2) return;

    lats.sort();
    lngs.sort();

    final bounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(lats.first, lngs.first),
      northeast: gmaps.LatLng(lats.last, lngs.last),
    );

    await ctrl.animateCamera(
      gmaps.CameraUpdate.newLatLngBounds(bounds, 60),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final site = widget.site;
    final showOverlays = !_cameraMoving;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRect(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  // ── Google Map ──────────────────────────────────────────────────
                  // gmaps.GoogleMap(
                  //   initialCameraPosition: gmaps.CameraPosition(
                  //     target: _initialCenter(),
                  //     zoom: 15,
                  //   ),
                  //   markers: _markers,
                  //   polylines: _polylines,
                  //   myLocationButtonEnabled: false,
                  //   zoomControlsEnabled: true,
                  //   onMapCreated: (ctrl) async {
                  //     if (widget.onMapCreated != null) {
                  //       widget.onMapCreated!(ctrl);
                  //     }

                  //     _controller.complete(ctrl);
                  //     await _fitBounds();
                  //     await _updateOverlayPositions();
                  //   },
                  //   onCameraMove: _onCameraMove,
                  //   onCameraIdle: _onCameraIdle,
                  // ),

                  // // ── FAT info box ────────────────────────────────────────────────
                  if (showOverlays && _fatOffset != null && site.fatLat != null && site.fatLng != null)
                    Positioned(
                      left: _fatOffset!.dx + 12,
                      top: _fatOffset!.dy - 70,
                      child: IgnorePointer(
                        child: _InfoBox(
                          lat: site.fatLat!,
                          lng: site.fatLng!,
                          label: site.fatName,
                        ),
                      ),
                    ),

                  // ── Customer info box ───────────────────────────────────────────
                  if (showOverlays && _customerOffset != null && site.customerLat != null && site.customerLng != null)
                    Positioned(
                      left: _customerOffset!.dx + 12,
                      top: _customerOffset!.dy - 70,
                      child: IgnorePointer(
                        child: _InfoBox(
                          lat: site.customerLat!,
                          lng: site.customerLng!,
                          label: site.circuitId,
                        ),
                      ),
                    ),

                  // ── Distance label ──────────────────────────────────────────────
                  if (showOverlays && _distanceOffset != null && site.dropCableLengthInMeter != null)
                    Positioned(
                      left: _distanceOffset!.dx - 25,
                      top: _distanceOffset!.dy - 36,
                      child: IgnorePointer(
                        child: _DistanceLabel(
                          label: _formatDistance(site.dropCableLengthInMeter!),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: const Placeholder(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(String raw) {
    final trimmed = raw.trim();
    return trimmed.toLowerCase().endsWith('m') ? trimmed : '${trimmed}m';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  final double lat;
  final double lng;
  final String? label;

  const _InfoBox({required this.lat, required this.lng, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          height: 1.5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('N : ${lat.toStringAsFixed(7)}'),
            Text('E : ${lng.toStringAsFixed(7)}'),
            if (label != null && label!.isNotEmpty) Text(label!),
          ],
        ),
      ),
    );
  }
}

class _DistanceLabel extends StatelessWidget {
  final String label;
  const _DistanceLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}
