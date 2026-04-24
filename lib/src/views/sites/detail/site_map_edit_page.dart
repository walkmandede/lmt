import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lmt/core/repositories/site_repository.dart';
import 'package:lmt/core/services/site_service.dart';
import 'package:lmt/src/models/site_detail_model.dart';
import 'dart:math' as math;

class SiteMapEditPage extends StatefulWidget {
  final SiteDetailModel siteDetailModel;

  const SiteMapEditPage({
    super.key,
    required this.siteDetailModel,
  });

  @override
  State<SiteMapEditPage> createState() => _SiteMapEditPageState();
}

class _SiteMapEditPageState extends State<SiteMapEditPage> {
  late SiteDetailModel _sd;

  final MapController _mapController = MapController();

  // ─────────────────────────────────────────────
  // INFO BOX MARKER POSITIONS
  // Each box is independently draggable for screenshot layout adjustments.
  // ─────────────────────────────────────────────
  LatLng? _customerBoxPos;
  LatLng? _fatBoxPos;
  LatLng? _cableBoxPos;

  static const double _boxOffset = 0.0025; // initial offset from its marker

  @override
  void initState() {
    super.initState();
    _sd = widget.siteDetailModel.copyWith();
    _initBoxPositions();
  }

  // ── Initialise box positions offset from their respective markers ──────────
  void _initBoxPositions() {
    if (_sd.customerLatLng != null) {
      _customerBoxPos = LatLng(
        _sd.customerLatLng!.latitude + _boxOffset,
        _sd.customerLatLng!.longitude,
      );
    }

    if (_sd.fatLatLng != null) {
      _fatBoxPos = LatLng(
        _sd.fatLatLng!.latitude + _boxOffset,
        _sd.fatLatLng!.longitude,
      );
    }

    final mid = _polylineMidpoint();
    if (mid != null) {
      _cableBoxPos = LatLng(
        mid.latitude - _boxOffset,
        mid.longitude,
      );
    }
  }

  // ── Haversine distance (metres) ────────────────────────────────────────────
  double _distanceMetres(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final x =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(a.latitude * math.pi / 180) * math.cos(b.latitude * math.pi / 180) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }

  // ── Walk along segments to find the midpoint of the full polyline ──────────
  LatLng? _polylineMidpoint() {
    final poles = _sd.poles ?? [];
    final List<LatLng> pts = [
      if (_sd.customerLatLng != null) _sd.customerLatLng!,
      ...poles.where((p) => p.hasLocations).map((p) => LatLng(p.lat!, p.lng!)),
      if (_sd.fatLatLng != null) _sd.fatLatLng!,
    ];
    if (pts.length < 2) return pts.isNotEmpty ? pts.first : null;

    final segLens = <double>[];
    double total = 0;
    for (int i = 1; i < pts.length; i++) {
      final d = _distanceMetres(pts[i - 1], pts[i]);
      segLens.add(d);
      total += d;
    }

    double half = total / 2;
    for (int i = 0; i < segLens.length; i++) {
      if (half <= segLens[i]) {
        final t = half / segLens[i];
        return LatLng(
          pts[i].latitude + t * (pts[i + 1].latitude - pts[i].latitude),
          pts[i].longitude + t * (pts[i + 1].longitude - pts[i].longitude),
        );
      }
      half -= segLens[i];
    }
    return pts.last;
  }

  // ── Total cable length label ───────────────────────────────────────────────
  String _cableLengthLabel() {
    return '${_sd.dropCableLengthInMeter ?? '-'} m';
  }

  // ─────────────────────────────────────────────
  // SAVE
  // ─────────────────────────────────────────────
  Future<void> onClickSave() async {
    final _service = SupabaseSiteService();
    late final _repo = SiteRepository(_service);
    await _repo.saveSite(_sd);
    Navigator.pop(context, _sd);
  }

  // ─────────────────────────────────────────────
  // INFO BOX WIDGET
  // ─────────────────────────────────────────────
  Widget _infoBox(List<String> lines) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black54, width: 1),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(1, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (line) => Text(
                line,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final poles = _sd.poles ?? [];

    final List<LatLng> allPoints = [
      if (_sd.customerLatLng != null) _sd.customerLatLng!,
      if (_sd.fatLatLng != null) _sd.fatLatLng!,
      ...poles.where((p) => p.hasLocations).map((p) => LatLng(p.lat!, p.lng!)),
    ];

    final markerSize = 22.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_sd.circuitId),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: onClickSave,
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: allPoints.isNotEmpty ? allPoints.first : LatLng(16.8, 96.15),
          initialZoom: 15,
        ),
        children: [
          // ──────────────── TILE ────────────────
          TileLayer(
            urlTemplate: 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
            userAgentPackageName: 'LMT',
          ),

          // ──────────────── POLYLINE ────────────────
          PolylineLayer(
            polylines: [
              if (_sd.canDrawPolyLine)
                Polyline(
                  points: [
                    if (_sd.customerLatLng != null) _sd.customerLatLng!,
                    ...poles.where((e) => e.hasLocations).map((p) => LatLng(p.lat!, p.lng!)),
                    if (_sd.fatLatLng != null) _sd.fatLatLng!,
                  ],
                  color: Colors.blue,
                  strokeWidth: 3,
                ),
            ],
          ),

          // ──────────────── DRAG MARKERS ────────────────
          DragMarkers(
            markers: [
              // ── Customer marker ──────────────────────────────────────────
              if (_sd.customerLatLng != null)
                DragMarker(
                  point: _sd.customerLatLng!,
                  size: Size(markerSize, markerSize),
                  alignment: Alignment.topCenter,
                  builder: (_, __, ___) => Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: const CircleBorder(),
                    color: Colors.green,
                    child: const Icon(Icons.home, color: Colors.white, size: 14),
                  ),
                  onDragEnd: (details, point) {
                    setState(() {
                      _sd.customerLat = point.latitude;
                      _sd.customerLng = point.longitude;
                    });
                  },
                ),

              // ── FAT marker ───────────────────────────────────────────────
              if (_sd.fatLatLng != null)
                DragMarker(
                  point: _sd.fatLatLng!,
                  size: Size(markerSize, markerSize),
                  alignment: Alignment.center,
                  builder: (_, __, ___) => Card(
                    elevation: 0,
                    shape: const CircleBorder(),
                    color: Colors.green,
                    child: Center(
                      child: Container(
                        height: 3,
                        width: 35,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  onDragEnd: (details, point) {
                    setState(() {
                      _sd.fatLat = point.latitude;
                      _sd.fatLng = point.longitude;
                    });
                  },
                ),

              // ── Pole markers ─────────────────────────────────────────────
              ...poles.asMap().entries.map((entry) {
                final index = entry.key;
                final pole = entry.value;
                if (!pole.hasLocations) return null;

                Color color = Colors.black;
                if (pole.enumPoleType != null) {
                  switch (pole.enumPoleType) {
                    case null:
                      color = Colors.black;
                    case EnumPoleType.epc:
                      color = Colors.red;
                    case EnumPoleType.mpt:
                      color = Colors.green;
                    case EnumPoleType.other:
                      color = Colors.blue;
                  }
                }
                return DragMarker(
                  point: LatLng(pole.lat!, pole.lng!),
                  size: Size(markerSize, markerSize),
                  builder: (_, __, ___) => Card(
                    elevation: 0,
                    shape: const CircleBorder(),
                    color: color,
                    child: Center(
                      child: Container(
                        height: 3,
                        width: 35,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  onDragEnd: (details, point) {
                    setState(() {
                      _sd.poles![index].lat = point.latitude;
                      _sd.poles![index].lng = point.longitude;
                    });
                  },
                );
              }).whereType<DragMarker>(),

              // ── Customer info box marker ─────────────────────────────────
              // Shown only when customer location is available.
              // Draggable for screenshot layout — no business logic.
              if (_sd.customerLatLng != null && _customerBoxPos != null)
                DragMarker(
                  point: _customerBoxPos!,
                  // Size matches the visual box so the hit area covers it fully.
                  size: const Size(240, 70),
                  alignment: Alignment.center,
                  builder: (_, __, ___) => _infoBox([
                    'N : ${_sd.customerLatLng!.latitude.toStringAsFixed(6)}',
                    'E : ${_sd.customerLatLng!.longitude.toStringAsFixed(6)}',
                    _sd.circuitId,
                  ]),
                  onDragEnd: (details, point) {
                    setState(() => _customerBoxPos = point);
                  },
                ),

              // ── FAT info box marker ──────────────────────────────────────
              // Shown only when FAT location is available.
              if (_sd.fatLatLng != null && _fatBoxPos != null)
                DragMarker(
                  point: _fatBoxPos!,
                  size: const Size(160, 70),
                  alignment: Alignment.center,
                  builder: (_, __, ___) => _infoBox([
                    'N : ${_sd.fatLatLng!.latitude.toStringAsFixed(6)}',
                    'E : ${_sd.fatLatLng!.longitude.toStringAsFixed(6)}',
                    _sd.fatName ?? 'N/A',
                  ]),
                  onDragEnd: (details, point) {
                    setState(() => _fatBoxPos = point);
                  },
                ),

              // ── Cable route info box marker ──────────────────────────────
              // Shown only when the polyline has at least 2 points.
              if (_sd.canDrawPolyLine && _cableBoxPos != null)
                DragMarker(
                  point: _cableBoxPos!,
                  size: const Size(100, 50),
                  alignment: Alignment.center,
                  builder: (_, __, ___) => Center(child: _infoBox([_cableLengthLabel()])),
                  onDragEnd: (details, point) {
                    setState(() => _cableBoxPos = point);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
