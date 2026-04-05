import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lmt/core/repositories/site_repository.dart';
import 'package:lmt/core/services/site_service.dart';
import 'package:lmt/src/models/site_detail_model.dart';
// import 'package:lmt/core/services/site_service.dart'; // uncomment when needed

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

  @override
  void initState() {
    super.initState();
    _sd = widget.siteDetailModel.copyWith();
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
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final poles = _sd.poles ?? [];

    /// collect all points for camera
    List<LatLng> allPoints = [];

    if (_sd.customerLatLng != null) {
      allPoints.add(_sd.customerLatLng!);
    }
    if (_sd.fatLatLng != null) {
      allPoints.add(_sd.fatLatLng!);
    }
    for (var p in poles) {
      if (p.hasLocations) {
        allPoints.add(LatLng(p.lat!, p.lng!));
      }
    }

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
              /// CUSTOMER
              if (_sd.customerLatLng != null)
                DragMarker(
                  point: _sd.customerLatLng!,
                  size: Size(30, 30),
                  alignment: Alignment.topCenter,
                  builder: (_, __, ___) => Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: CircleBorder(),
                    color: Colors.green,
                    child: Icon(
                      Icons.home,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  onDragEnd: (details, point) {
                    setState(() {
                      _sd.customerLat = point.latitude;
                      _sd.customerLng = point.longitude;
                    });
                  },
                ),

              /// FAT
              if (_sd.fatLatLng != null)
                DragMarker(
                  point: _sd.fatLatLng!,
                  size: Size(30, 30),
                  alignment: Alignment.topCenter,
                  builder: (_, __, ___) => Icon(
                    Icons.location_on_rounded,
                    color: Colors.green,
                    size: 30,
                  ),
                  onDragEnd: (details, point) {
                    setState(() {
                      _sd.fatLat = point.latitude;
                      _sd.fatLng = point.longitude;
                    });
                  },
                ),

              /// POLES
              ...poles
                  .asMap()
                  .entries
                  .map((entry) {
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
                      size: Size(30, 30),
                      builder: (_, __, ___) => Card(
                        elevation: 0,
                        shape: CircleBorder(),
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
                  })
                  .whereType<DragMarker>()
                  .toList(),
            ],
          ),
        ],
      ),
    );
  }
}
