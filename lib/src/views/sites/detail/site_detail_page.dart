import 'dart:async';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lmt/core/constants/app_functions.dart';
import 'package:lmt/core/services/site_service.dart';
import 'package:lmt/src/models/site_detail_model.dart';
import 'package:lmt/src/views/_widgets/image_viewer_page.dart';
import 'package:lmt/src/views/_widgets/section_card.dart';
import 'package:lmt/src/views/_widgets/site_map_widget.dart';
import 'package:lmt/src/views/sites/detail/site_detail_kmz_export.dart';
import 'package:lmt/src/views/sites/detail/site_detail_pdf_view_page.dart';
import 'package:lmt/src/views/sites/detail/site_map_edit_page.dart';
import 'package:lmt/src/views/sites/list/site_list_page.dart';
import 'package:http/http.dart' as http;
import 'package:screenshot/screenshot.dart';

String _buildStaticMapUrl({
  required SiteDetailModel site,
  int width = 600,
  int height = 400,
  String apiKey = 'YOUR_API_KEY',
}) {
  final poles = site.poles ?? [];
  final params = StringBuffer();

  params.write('https://maps.googleapis.com/maps/api/staticmap?');
  params.write('size=${width}x$height');
  params.write('&maptype=roadmap');

  // FAT marker — green
  if (site.fatLat != null) {
    params.write('&markers=color:green|${site.fatLat},${site.fatLng}');
  }

  // Customer marker — also green (home)
  if (site.customerLat != null) {
    params.write('&markers=color:green|${site.customerLat},${site.customerLng}');
  }

  // Pole markers by type
  for (final p in poles.where((e) => e.hasLocations)) {
    final color = switch (p.enumPoleType) {
      EnumPoleType.epc => 'red',
      EnumPoleType.mpt => 'green',
      EnumPoleType.other => 'blue',
      _ => 'gray',
    };
    params.write('&markers=color:$color|${p.lat},${p.lng}');
  }

  // Polyline through all points
  final polylinePoints = [
    if (site.fatLat != null) '${site.fatLat},${site.fatLng}',
    ...poles.where((e) => e.hasLocations).map((p) => '${p.lat},${p.lng}'),
    if (site.customerLat != null) '${site.customerLat},${site.customerLng}',
  ];
  if (polylinePoints.length > 1) {
    params.write('&path=color:0x2196F3FF|weight:3|${polylinePoints.join('|')}');
  }

  params.write('&key=$apiKey');
  return params.toString();
}

Future<Uint8List?> _fetchStaticMapImage(SiteDetailModel site) async {
  final url = _buildStaticMapUrl(site: site, apiKey: 'AIzaSyCiDbggAf3yFr-r9IxcIDUOKieHMs7mPIE');
  superPrint(url);
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) return response.bodyBytes;
  } catch (e) {
    debugPrint('Static map fetch failed: $e');
  }
  return null;
}

class SiteDetailPage extends StatefulWidget {
  final String circuitId;
  final SiteDetailModel? siteDetailModel;

  const SiteDetailPage({
    super.key,
    required this.circuitId,
    this.siteDetailModel,
  });

  @override
  State<SiteDetailPage> createState() => _SiteDetailPageState();
}

class _SiteDetailPageState extends State<SiteDetailPage> {
  final _service = SupabaseSiteService();
  SiteDetailModel? _site;
  // final ScreenshotController _screenshotController = ScreenshotController();
  Completer<GoogleMapController> _googleMapController = Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.siteDetailModel != null) {
      _site = widget.siteDetailModel!.copyWith();
    } else {
      final model = await _service.getSite(widget.circuitId);
      _site = model;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_site == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final site = _site!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.circuitId, style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
        actions: widget.siteDetailModel != null
            ? []
            : [
                IconButton(
                  icon: Icon(Icons.print),
                  onPressed: () async {
                    // final mapCtrl = await _googleMapController.future;
                    // superPrint(mapCtrl.mapId);
                    // final mapImg = await (await _googleMapController.future).takeSnapshot();

                    // final mapImg = await _fetchStaticMapImage(site);
                    final mapTableImage = await ScreenshotController().captureFromWidget(_mapSection(context, site));
                    await Future.delayed(const Duration(milliseconds: 200));
                    superPrint(mapTableImage.length);

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            // return Scaffold(
                            //   appBar: AppBar(),
                            //   body: SizedBox.expand(
                            //     child: Center(
                            //       child: DecoratedBox(
                            //         decoration: BoxDecoration(
                            //           border: Border.all(),
                            //         ),
                            //         child: Padding(padding: EdgeInsetsGeometry.all(4), child: Image.memory(mapTableImage)),
                            //       ),
                            //     ),
                            //   ),
                            // );
                            return SiteDetailPdfViewPage(
                              siteDetailModel: _site!,
                              mapTableImage: mapTableImage,
                            );
                          },
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/update', arguments: widget.circuitId);
                    _load();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return SiteMapEditPage(siteDetailModel: _site!);
                        },
                      ),
                    );
                    _load();
                  },
                ),
                TextButton(
                  onPressed: () async {
                    await _site!.shareKMZ();
                    // try {
                    //   final kmzPath = await _site!.exportToKMZ();
                    //   await SharePlus.instance.share(
                    //     ShareParams(
                    //       subject: '${_site?.circuitId} - Circuit Map',

                    //       files: [XFile(kmzPath)],
                    //     ),
                    //   );
                    // } catch (e) {
                    //   print('Error exporting KMZ: $e');
                    // }
                  },
                  child: Text(
                    'Export KMZ',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _confirmDelete,
                ),
              ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _statusSection(site),
            _sectionA(site),
            _sectionB(site),
            _sectionC(site),
            _sectionD(site),
            _sectionE(site),
            _sectionF(site),
            _sectionG(site),
          ],
        ),
      ),
    );
  }

  Widget _statusSection(SiteDetailModel site) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const Text('Status:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          SiteStatusBadge(status: site.siteStatus),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: const Text('Change'),
            onPressed: () => _showStatusPicker(site),
          ),
        ],
      ),
    );
  }

  Future<void> _showStatusPicker(SiteDetailModel site) async {
    EnumSiteStatus? selected = site.siteStatus;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Update Status', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...EnumSiteStatus.values.map((s) {
                    return RadioListTile<EnumSiteStatus>(
                      dense: true,
                      value: s,
                      groupValue: selected,
                      title: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: s.badgeColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(s.label),
                        ],
                      ),
                      onChanged: (v) => setSheet(() => selected = v),
                    );
                  }),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: selected == null ? null : () => Navigator.pop(ctx, true),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed == true && selected != null) {
      try {
        await _service.updateSiteStatus(site.circuitId, selected!);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
  }

  // - map ---
  Widget _mapSection(BuildContext context, SiteDetailModel site) {
    final poles = site.poles ?? [];
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                ),
              ),
              // width: size.height * 0.6,
              // height: size.height * 0.72,
              child: LayoutBuilder(
                builder: (a1, c1) {
                  return SizedBox(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Table(
                            border: TableBorder.all(color: Colors.black.withAlpha((0.6 * 255).toInt())),
                            columnWidths: {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(3),
                              2: FlexColumnWidth(4),
                              3: FlexColumnWidth(2),
                              4: FlexColumnWidth(3),
                            },
                            children: [
                              TableRow(
                                children: [
                                  Center(
                                    child: Text(
                                      'No',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      'Outline',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                  Center(
                                    child: FittedBox(
                                      child: Text(
                                        'Description',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      'Unit',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      'Qty',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                              TableRow(
                                decoration: BoxDecoration(color: Colors.white.withAlpha((0.9 * 255).toInt())),
                                children: [
                                  Center(
                                    child: Text('1'),
                                  ),
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Container(
                                        height: 2,
                                        width: 20,
                                        decoration: BoxDecoration(color: Colors.blue),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        'Drop Cable Length',
                                        style: TextStyle(color: Colors.black, fontSize: 9),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      'Meter',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      _site?.dropCableLengthInMeter ?? '-',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                              TableRow(
                                decoration: BoxDecoration(color: Colors.white.withAlpha((0.9 * 255).toInt())),
                                children: [
                                  Center(
                                    child: Text('2'),
                                  ),
                                  Center(
                                    child: SizedBox(
                                      width: 25,
                                      height: 25,
                                      child: Card(
                                        elevation: 0,
                                        shape: CircleBorder(),
                                        color: Colors.blue,
                                        child: Center(
                                          child: Container(
                                            height: 3,
                                            width: 35,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        'Other Pole',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      'Pcs',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      poles.where((p) => p.enumPoleType == EnumPoleType.other).length.toString(),
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                              TableRow(
                                decoration: BoxDecoration(color: Colors.white.withAlpha((0.9 * 255).toInt())),
                                children: [
                                  Center(
                                    child: Text('3'),
                                  ),
                                  Center(
                                    child: SizedBox(
                                      width: 25,
                                      height: 25,
                                      child: Card(
                                        elevation: 0,
                                        shape: CircleBorder(),
                                        color: Colors.red,
                                        child: Center(
                                          child: Container(
                                            height: 3,
                                            width: 35,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        'EPC Pole',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      'Pcs',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      poles.where((p) => p.enumPoleType == EnumPoleType.epc).length.toString(),
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),

                              TableRow(
                                decoration: BoxDecoration(color: Colors.white.withAlpha((0.9 * 255).toInt())),
                                children: [
                                  Center(
                                    child: Text('4'),
                                  ),
                                  Center(
                                    child: SizedBox(
                                      width: 25,
                                      height: 25,
                                      child: Card(
                                        elevation: 0,
                                        shape: CircleBorder(),
                                        color: Colors.green,
                                        child: Center(
                                          child: Container(
                                            height: 3,
                                            width: 35,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        'MPT Pole',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      'Pcs',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      poles.where((p) => p.enumPoleType == EnumPoleType.mpt).length.toString(),
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(flex: 1, child: const SizedBox.shrink()),
                        Expanded(
                          flex: 3,
                          child: Container(
                            margin: EdgeInsets.all(4),
                            decoration: BoxDecoration(border: Border.all()),
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Text('LSP Name: ${_site?.lspName ?? '-'}'),
                          ),
                        ),
                      ],
                    ),
                  );
                  return SiteMapWidget(
                    width: double.infinity,
                    height: double.infinity,
                    onMapCreated: (gMapController) {
                      _googleMapController.complete(gMapController);
                      superPrint('created ${_googleMapController.toString()}');
                    },
                    site: site,
                  );
                  // return Column(
                  //   children: [
                  //     Expanded(
                  //       flex: 2,
                  //       child: FlutterMap(
                  //         options: MapOptions(
                  //           initialCameraFit: !site.hasLocations
                  //               ? null
                  //               : CameraFit.bounds(bounds: LatLngBounds(site.fatLatLng!, site.customerLatLng!), padding: EdgeInsets.all(32)),
                  //         ),
                  //         children: [
                  //           TileLayer(
                  //             urlTemplate: 'https://mt0.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                  //             // urlTemplate: 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
                  //             userAgentPackageName: 'LMT',
                  //           ),
                  //           PolylineLayer(
                  //             polylines: [
                  //               if (site.canDrawPolyLine)
                  //                 Polyline(
                  //                   color: Colors.blue,
                  //                   pattern: StrokePattern.solid(),
                  //                   strokeWidth: 2,
                  //                   points: [
                  //                     if (site.customerLatLng != null) site.customerLatLng!,
                  //                     ...(poles.where((e) => e.hasLocations)).map((p) {
                  //                       return LatLng(p.lat!, p.lng!);
                  //                     }),
                  //                     if (site.fatLat != null) site.fatLatLng!,
                  //                   ],
                  //                 ),
                  //             ],
                  //           ),

                  //           MarkerLayer(
                  //             markers: [
                  //               //cus pin
                  //               if (site.customerLatLng != null)
                  //                 Marker(
                  //                   width: 50,
                  //                   height: 30,
                  //                   point: site.customerLatLng!,
                  //                   alignment: Alignment.topCenter,
                  //                   child: Column(
                  //                     children: [
                  //                       Expanded(
                  //                         child: Text(
                  //                           site.circuitId,
                  //                           style: TextStyle(
                  //                             fontSize: 5,
                  //                             foreground: Paint()
                  //                               ..style = PaintingStyle.stroke
                  //                               ..strokeWidth = 0.8
                  //                               ..color = Colors.black,
                  //                           ),
                  //                         ),
                  //                       ),
                  //                       SizedBox(
                  //                         width: 15,
                  //                         height: 15,
                  //                         child: Card(
                  //                           margin: EdgeInsets.zero,
                  //                           elevation: 0,
                  //                           shape: CircleBorder(),
                  //                           color: Colors.green,
                  //                           child: Icon(
                  //                             Icons.home,
                  //                             color: Colors.white,
                  //                             size: 12,
                  //                           ),
                  //                         ),
                  //                       ),
                  //                     ],
                  //                   ),
                  //                 ),
                  //               //cus info
                  //               if (site.customerLatLng != null)
                  //                 Marker(
                  //                   width: 80,
                  //                   height: 40,
                  //                   point: site.customerLatLng!,
                  //                   alignment: Alignment.bottomCenter,
                  //                   child: DecoratedBox(
                  //                     decoration: BoxDecoration(
                  //                       border: Border.all(),
                  //                       color: Colors.white.withAlpha((0.7 * 255).toInt()),
                  //                     ),
                  //                     child: SizedBox.expand(
                  //                       child: LayoutBuilder(
                  //                         builder: (a1, c1) {
                  //                           return Padding(
                  //                             padding: EdgeInsets.symmetric(
                  //                               horizontal: c1.maxWidth * 0.05,
                  //                               vertical: c1.maxHeight * 0.05,
                  //                             ),
                  //                             child: Column(
                  //                               children: [
                  //                                 Expanded(
                  //                                   child: FittedBox(child: Text('N: ${_site?.customerLatLabel ?? '-'}')),
                  //                                 ),
                  //                                 Expanded(
                  //                                   child: FittedBox(child: Text('E: ${_site?.customerLngLabel ?? '-'}')),
                  //                                 ),
                  //                                 Expanded(
                  //                                   child: FittedBox(
                  //                                     alignment: Alignment.center,
                  //                                     child: Text(_site?.circuitId ?? ''),
                  //                                   ),
                  //                                 ),
                  //                               ],
                  //                             ),
                  //                           );
                  //                         },
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ),
                  //               //fatPin
                  //               if (site.fatLatLng != null)
                  //                 Marker(
                  //                   width: 50,
                  //                   height: 30,
                  //                   point: site.fatLatLng!,
                  //                   alignment: Alignment.topCenter,
                  //                   child: Column(
                  //                     children: [
                  //                       Expanded(
                  //                         child: Text(
                  //                           site.fatName ?? '-',
                  //                           style: TextStyle(
                  //                             fontSize: 10,
                  //                             foreground: Paint()
                  //                               ..style = PaintingStyle.stroke
                  //                               ..strokeWidth = 0.8
                  //                               ..color = Colors.black,
                  //                           ),
                  //                         ),
                  //                       ),
                  //                       SizedBox(
                  //                         width: 15,
                  //                         height: 15,
                  //                         child: Icon(
                  //                           Icons.location_on_rounded,
                  //                           color: Colors.green,
                  //                           size: 12,
                  //                         ),
                  //                       ),
                  //                     ],
                  //                   ),
                  //                 ),
                  //               //fat info
                  //               if (site.fatLatLng != null)
                  //                 Marker(
                  //                   width: 80,
                  //                   height: 40,
                  //                   point: site.fatLatLng!,
                  //                   alignment: Alignment.bottomCenter,
                  //                   child: DecoratedBox(
                  //                     decoration: BoxDecoration(
                  //                       border: Border.all(),
                  //                       color: Colors.white.withAlpha((0.7 * 255).toInt()),
                  //                     ),
                  //                     child: SizedBox.expand(
                  //                       child: LayoutBuilder(
                  //                         builder: (a1, c1) {
                  //                           return Padding(
                  //                             padding: EdgeInsets.symmetric(
                  //                               horizontal: c1.maxWidth * 0.05,
                  //                               vertical: c1.maxHeight * 0.05,
                  //                             ),
                  //                             child: Column(
                  //                               children: [
                  //                                 Expanded(
                  //                                   child: FittedBox(
                  //                                     alignment: Alignment.center,
                  //                                     child: Text('Lat: ${_site?.fatLatLabel ?? '-'}'),
                  //                                   ),
                  //                                 ),
                  //                                 Expanded(
                  //                                   child: FittedBox(
                  //                                     alignment: Alignment.center,
                  //                                     child: Text('Lat: ${_site?.fatLngLabel ?? '-'}'),
                  //                                   ),
                  //                                 ),
                  //                                 Expanded(
                  //                                   child: FittedBox(
                  //                                     alignment: Alignment.center,
                  //                                     child: Text(_site?.fatName ?? ''),
                  //                                   ),
                  //                                 ),
                  //                               ],
                  //                             ),
                  //                           );
                  //                         },
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ),
                  //               //cable marker
                  //               Marker(
                  //                 width: 50,
                  //                 height: 35,
                  //                 point: site.hasPole
                  //                     ? LatLng(poles.first.lat ?? 0, poles.first.lng ?? 0)
                  //                     : AppFunctions.getMidPointSimple(
                  //                         site.customerLatLng ?? LatLng(0, 0),
                  //                         site.fatLatLng ?? LatLng(0, 0),
                  //                       ),
                  //                 alignment: Alignment.bottomCenter,
                  //                 child: Padding(
                  //                   padding: EdgeInsets.only(
                  //                     top: 15,
                  //                   ),
                  //                   child: DecoratedBox(
                  //                     decoration: BoxDecoration(
                  //                       color: Colors.white.withAlpha((0.7 * 255).toInt()),
                  //                     ),
                  //                     child: SizedBox.expand(
                  //                       child: LayoutBuilder(
                  //                         builder: (a1, c1) {
                  //                           return Center(
                  //                             child: Text('${site.dropCableLengthInMeter ?? 0}'),
                  //                           );
                  //                         },
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ),
                  //               ),

                  //               ...(site.poles ?? []).map((p) {
                  //                 Color color = Colors.black;
                  //                 if (p.enumPoleType != null) {
                  //                   switch (p.enumPoleType) {
                  //                     case null:
                  //                       color = Colors.black;
                  //                     case EnumPoleType.epc:
                  //                       color = Colors.red;
                  //                     case EnumPoleType.mpt:
                  //                       color = Colors.green;
                  //                     case EnumPoleType.other:
                  //                       color = Colors.blue;
                  //                   }
                  //                 }
                  //                 return Marker(
                  //                   width: 25,
                  //                   height: 25,
                  //                   point: LatLng(p.lat ?? 0, p.lng ?? 0),
                  //                   alignment: Alignment.center,
                  //                   child: Card(
                  //                     elevation: 0,
                  //                     shape: CircleBorder(),
                  //                     color: color,
                  //                     child: Center(
                  //                       child: Container(
                  //                         height: 3,
                  //                         width: 35,
                  //                         color: Colors.black,
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 );
                  //               }),
                  //             ],
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  // SizedBox(
                  //   child: Row(
                  //     crossAxisAlignment: CrossAxisAlignment.end,
                  //     children: [
                  //       Expanded(
                  //         flex: 3,
                  //         child: Table(
                  //           border: TableBorder.all(color: Colors.black.withAlpha((0.6 * 255).toInt())),
                  //           columnWidths: {
                  //             0: FlexColumnWidth(1),
                  //             1: FlexColumnWidth(3),
                  //             2: FlexColumnWidth(4),
                  //             3: FlexColumnWidth(2),
                  //             4: FlexColumnWidth(3),
                  //           },
                  //           children: [
                  //             TableRow(
                  //               decoration: BoxDecoration(color: Colors.lightBlue.withAlpha((0.9 * 255).toInt())),
                  //               children: [
                  //                 Center(
                  //                   child: Text(
                  //                     'No',
                  //                     style: TextStyle(color: Colors.black),
                  //                   ),
                  //                 ),
                  //                 Center(
                  //                   child: Text(
                  //                     'Outline',
                  //                     style: TextStyle(color: Colors.black),
                  //                   ),
                  //                 ),
                  //                 Center(
                  //                   child: FittedBox(
                  //                     child: Text(
                  //                       'Description',
                  //                       style: TextStyle(color: Colors.black),
                  //                     ),
                  //                   ),
                  //                 ),
                  //                 Center(
                  //                   child: Text(
                  //                     'Unit',
                  //                     style: TextStyle(color: Colors.black),
                  //                   ),
                  //                 ),
                  //                 Center(
                  //                   child: Text(
                  //                     'Qty',
                  //                     style: TextStyle(color: Colors.black),
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //             TableRow(
                  //               decoration: BoxDecoration(color: Colors.white.withAlpha((0.9 * 255).toInt())),
                  //               children: [
                  //                 Center(
                  //                   child: Text('1'),
                  //                 ),
                  //                 Center(
                  //                   child: Padding(
                  //                     padding: const EdgeInsets.symmetric(vertical: 8),
                  //                     child: Container(
                  //                       height: 2,
                  //                       width: 20,
                  //                       decoration: BoxDecoration(color: Colors.blue),
                  //                     ),
                  //                   ),
                  //                 ),
                  //                 Center(
                  //                   child: Padding(
                  //                     padding: EdgeInsets.symmetric(horizontal: 4),
                  //                     child: Text(
                  //                       'Drop Cable Length',
                  //                       style: TextStyle(color: Colors.black, fontSize: 12),
                  //                     ),
                  //                   ),
                  //                 ),
                  //                 Center(
                  //                   child: Text(
                  //                     'Meter',
                  //                     style: TextStyle(color: Colors.black),
                  //                   ),
                  //                 ),
                  //                 Center(
                  //                   child: Text(
                  //                     _site?.dropCableLengthInMeter ?? '-',
                  //                     style: TextStyle(color: Colors.black),
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //             TableRow(
                  //               decoration: BoxDecoration(color: Colors.white.withAlpha((0.9 * 255).toInt())),
                  //               children: [
                  //                 Center(
                  //                   child: Text('2'),
                  //                 ),
                  //                 Center(
                  //                   child: SizedBox(
                  //                     width: 25,
                  //                     height: 25,
                  //                     child: Card(
                  //                       elevation: 0,
                  //                       shape: CircleBorder(),
                  //                       color: Colors.blue,
                  //                       child: Center(
                  //                         child: Container(
                  //                           height: 3,
                  //                           width: 35,
                  //                           color: Colors.black,
                  //                         ),
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ),
                  //                 Center(
                  //                   child: Padding(
                  //                     padding: EdgeInsets.symmetric(horizontal: 4),
                  //                     child: Text(
                  //                       'Other Pole',
                  //                       style: TextStyle(color: Colors.black),
                  //                     ),
                  //                   ),
                  //                 ),
                  //                 Center(
                  //                   child: Text(
                  //                     'Pcs',
                  //                     style: TextStyle(color: Colors.black),
                  //                   ),
                  //                 ),
                  //                 Center(
                  //                   child: Text(
                  //                     poles.where((p) => p.enumPoleType == EnumPoleType.other).length.toString(),
                  //                     style: TextStyle(color: Colors.black),
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //             TableRow(
                  //               decoration: BoxDecoration(color: Colors.white.withAlpha((0.9 * 255).toInt())),
                  //               children: [
                  //                 Center(
                  //                   child: Text('3'),
                  //                 ),
                  //                 Center(
                  //                   child: SizedBox(
                  //                     width: 25,
                  //                     height: 25,
                  //                     child: Card(
                  //                       elevation: 0,
                  //                       shape: CircleBorder(),
                  //                       color: Colors.red,
                  //                       child: Center(
                  //                         child: Container(
                  //                           height: 3,
                  //                           width: 35,
                  //                           color: Colors.black,
                  //                         ),
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ),
                  //                 Center(
                  //                   child: Padding(
                  //                     padding: EdgeInsets.symmetric(horizontal: 4),
                  //                     child: Text(
                  //                       'EPC Pole',
                  //                       style: TextStyle(color: Colors.black),
                  //                     ),
                  //                   ),
                  //                 ),
                  //                 Center(
                  //                   child: Text(
                  //                     'Pcs',
                  //                     style: TextStyle(color: Colors.black),
                  //                   ),
                  //                 ),
                  //                 Center(
                  //                   child: Text(
                  //                     poles.where((p) => p.enumPoleType == EnumPoleType.epc).length.toString(),
                  //                     style: TextStyle(color: Colors.black),
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),

                  //             TableRow(
                  //               decoration: BoxDecoration(color: Colors.white.withAlpha((0.9 * 255).toInt())),
                  //               children: [
                  //                 Center(
                  //                   child: Text('4'),
                  //                 ),
                  //                 Center(
                  //                   child: SizedBox(
                  //                     width: 25,
                  //                     height: 25,
                  //                     child: Card(
                  //                       elevation: 0,
                  //                       shape: CircleBorder(),
                  //                       color: Colors.green,
                  //                       child: Center(
                  //                         child: Container(
                  //                           height: 3,
                  //                           width: 35,
                  //                           color: Colors.black,
                  //                         ),
                  //                       ),
                  //                     ),
                  //                   ),
                  //                 ),
                  //                 Center(
                  //                   child: Padding(
                  //                     padding: EdgeInsets.symmetric(horizontal: 4),
                  //                     child: Text(
                  //                       'MPT Pole',
                  //                       style: TextStyle(color: Colors.black),
                  //                     ),
                  //                   ),
                  //                 ),
                  //                 Center(
                  //                   child: Text(
                  //                     'Pcs',
                  //                     style: TextStyle(color: Colors.black),
                  //                   ),
                  //                 ),
                  //                 Center(
                  //                   child: Text(
                  //                     poles.where((p) => p.enumPoleType == EnumPoleType.mpt).length.toString(),
                  //                     style: TextStyle(color: Colors.black),
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  //   ],
                  // );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── A ────────────────────────────────────────────────────────────────────

  Widget _sectionA(SiteDetailModel s) {
    return SectionCard(
      title: 'A  Circuit ID Information',
      child: Column(
        children: [
          _row('Circuit ID', s.circuitId),
          _row('Customer', s.customerName),
          _row('LSP Name', s.lspName),
          _row('Location', s.customerLat != null ? '${s.customerLat}, ${s.customerLng}' : null),
          _row('Work Order', _fmt(s.workOrderDateTime)),
          _row('Activation', _fmt(s.activationDateTime)),
        ],
      ),
    );
  }

  // ── B ────────────────────────────────────────────────────────────────────

  Widget _sectionB(SiteDetailModel s) {
    return SectionCard(
      title: 'B  Site / FAT Information',
      child: Column(
        children: [
          _row('Survey Result', _fmt(s.surveyResultDateTime)),
          _row('FAT Name', s.fatName),
          _row('FAT Port', s.fatPortNumber),
          _row('FAT Location', s.fatLat != null ? '${s.fatLat}, ${s.fatLng}' : null),
          _divider('Optical Level – FAT Port'),
          _row('1310nm', s.opticalLevelFatPort1310nm != null ? '${s.opticalLevelFatPort1310nm} dBm' : null),
          _row('1490nm', s.opticalLevelFatPort1490nm != null ? '${s.opticalLevelFatPort1490nm} dBm' : null),
          _divider('Optical Level – ATB Port'),
          _row('1310nm', s.opticalLevelAtbPort1310nm != null ? '${s.opticalLevelAtbPort1310nm} dBm' : null),
          _row('1490nm', s.opticalLevelAtbPort1490nm != null ? '${s.opticalLevelAtbPort1490nm} dBm' : null),
          _row('Drop Cable', s.dropCableLengthInMeter != null ? '${s.dropCableLengthInMeter} m' : null),
          _row('Start Meter', s.cableDrumStart != null ? '${s.cableDrumStart} m' : null),
          _row('End Meter', s.cableDrumEnd != null ? '${s.cableDrumEnd} m' : null),
          _row('ROW Issue', s.rowIssue),
        ],
      ),
    );
  }

  // ── C ────────────────────────────────────────────────────────────────────

  Widget _sectionC(SiteDetailModel s) {
    final poles = s.poles ?? [];
    return SectionCard(
      title: 'C  Cable Route / Poles',
      child: poles.isEmpty
          ? const Text('No poles recorded.', style: TextStyle(color: Colors.grey))
          : Column(
              children: poles.asMap().entries.map((e) {
                final p = e.value;
                final label = 'P_${(e.key + 1).toString().padLeft(3, '0')}  (${p.enumPoleType?.name.toUpperCase() ?? '?'})';
                return ListTile(
                  dense: true,
                  leading: _poleIcon(p.enumPoleType),
                  title: Text(label),
                  subtitle: p.lat != null ? Text('${p.lat}, ${p.lng}', style: const TextStyle(fontSize: 12)) : null,
                  trailing: p.image != null
                      ? GestureDetector(
                          onTap: () => _openPhoto(p.image!, title: s.circuitId),
                          child: _thumb(p.image!),
                        )
                      : null,
                );
              }).toList(),
            ),
    );
  }

  Widget _poleIcon(EnumPoleType? t) {
    Color color;
    switch (t) {
      case EnumPoleType.epc:
        color = Colors.red;
        break;
      case EnumPoleType.mpt:
        color = Colors.green;
        break;
      default:
        color = Colors.blue;
    }
    return CircleAvatar(radius: 8, backgroundColor: color);
  }

  // ── D ────────────────────────────────────────────────────────────────────

  // Replace _sectionD to include D4
  Widget _sectionD(SiteDetailModel s) {
    final g = s.gallery;
    return SectionCard(
      title: 'D  Onsite Installation – FAT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _photoGroup('AN  Node', [g?.anNode], ['']),
          _photoGroup('Map Image', [g?.mapImage], ['']),
          _photoGroup('D1  Before installation', [g?.d1_1, g?.d1_2], ['FAT Closed', 'FAT Open']),
          _photoGroup('D2  After installation', [g?.d2_1, g?.d2_2], ['View 1', 'View 2']),
          _photoGroup('D3  Cable label inside FAT', [g?.d3_1, g?.d3_2], ['Label 1', 'Label 2']),
          // D4 — dynamic list, generate index-based captions
          if (g?.d4 != null && g!.d4!.isNotEmpty)
            _photoGroup(
              'D4  Accessories',
              g.d4!,
              List.generate(g.d4!.length, (i) => '${i + 1}'),
            ),
        ],
      ),
    );
  }

  // ── E ────────────────────────────────────────────────────────────────────

  Widget _sectionE(SiteDetailModel s) {
    final g = s.gallery;
    return SectionCard(
      title: 'E  Onsite Installation – Customer Site',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _photoGroup('E1  Outdoor cable', [g?.e1], ['']),
          _photoGroup('E2  Home entrance', [g?.e2], ['']),
          _photoGroup('E3  Indoor cable', [g?.e3], ['']),
          _photoGroup('E4  Cable coils', [g?.e4_1, g?.e4_2], ['Customer side', 'FAT side']),
          _photoGroup('E5  ATB', [g?.e5], ['']),
          _photoGroup('E6  Other remarks', [g?.e6_1, g?.e6_2, g?.e6_3], ['1', '2', '3']),
        ],
      ),
    );
  }

  // ── F ────────────────────────────────────────────────────────────────────

  Widget _sectionF(SiteDetailModel s) {
    final g = s.gallery;
    return SectionCard(
      title: 'F  ONT Test & Service Test',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('ONT S/N', s.ontSnNumber),
          _row('Splitter No', s.splitterNo),
          _row('WiFi SSID', s.wifiSsid),
          _row('MSAN', s.msan),
          const SizedBox(height: 8),
          _photoGroup('F1  ONT device', [g?.f1], ['']),
          _photoGroup('F2  S/N label', [g?.f2], ['']),
          _photoGroup('F3  Environment', [g?.f3], ['']),
          _photoGroup('F4  Ping test', [g?.f4_1, g?.f4_2], ['1', '2']),
          _photoGroup('F5  Speed test', [g?.f5], ['']),
          _photoGroup('F6  Call / IPTV test', [g?.f6_1, g?.f6_2], ['1', '2']),
        ],
      ),
    );
  }

  // ── G ────────────────────────────────────────────────────────────────────

  Widget _sectionG(SiteDetailModel s) {
    return SectionCard(
      title: 'G  Cable Laying Check-list',
      child: Column(
        children: [
          _row('Link ID', s.linkId),
          _row('Check Area', s.poleRange ?? s.checkArea),
          if (s.conclusionAndComments != null) ...[
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Conclusion & Comments', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 4),
            Text(s.conclusionAndComments!),
          ],
        ],
      ),
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _divider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
      ),
    );
  }

  Widget _photoGroup(String title, List<String?> urls, List<String> captions) {
    final valid = urls.where((u) => u != null && u.isNotEmpty).toList();
    if (valid.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: urls.asMap().entries.where((e) => e.value != null && e.value!.isNotEmpty).map((e) {
              final url = e.value!;
              final cap = e.key < captions.length ? captions[e.key] : '';
              return GestureDetector(
                onTap: () => _openPhoto(url, title: title),
                child: Column(
                  children: [
                    _thumb(url),
                    if (cap.isNotEmpty) Text(cap, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _thumb(String url) {
    return Hero(
      tag: url,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          url,
          width: 100,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 100,
            height: 80,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image),
          ),
        ),
      ),
    );
  }

  void _openPhoto(String url, {String? title}) {
    openImageViewer(
      context: context,
      url: url,
      title: title ?? 'Photo',
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete site?'),
        content: Text('Delete ${widget.circuitId}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _service.deleteSite(widget.circuitId);
      if (mounted) Navigator.pop(context);
    }
  }

  String? _fmt(DateTime? dt) {
    if (dt == null) return null;
    return '${dt.year}/${_p(dt.month)}/${_p(dt.day)}  ${_p(dt.hour)}:${_p(dt.minute)}';
  }

  String _p(int n) => n.toString().padLeft(2, '0');
}
