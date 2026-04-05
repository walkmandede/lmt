import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lmt/core/constants/app_functions.dart';
import 'package:lmt/core/services/site_service.dart';
import 'package:lmt/src/models/site_detail_model.dart';
import 'package:lmt/src/views/_widgets/image_viewer_page.dart';
import 'package:lmt/src/views/_widgets/section_card.dart';
import 'package:lmt/src/views/sites/detail/site_detail_pdf_view_page.dart';
import 'package:lmt/src/views/sites/detail/site_map_edit_page.dart';
import 'package:screenshot/screenshot.dart';

class SiteDetailPage extends StatefulWidget {
  final String circuitId;
  const SiteDetailPage({super.key, required this.circuitId});

  @override
  State<SiteDetailPage> createState() => _SiteDetailPageState();
}

class _SiteDetailPageState extends State<SiteDetailPage> {
  final _service = SupabaseSiteService();
  SiteDetailModel? _site;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final model = await _service.getSite(widget.circuitId);
    setState(() => _site = model);
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
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () async {
              final mapImg = await _screenshotController.capture();
              await Future.delayed(const Duration(milliseconds: 200));
              superPrint(mapImg?.length);
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return SiteDetailPdfViewPage(
                        siteDetailModel: _site!,
                        mapImage: mapImg,
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
            _mapSection(context, site),
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

  // - map ---
  Widget _mapSection(BuildContext context, SiteDetailModel site) {
    final poles = site.poles ?? [];
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.aspectRatio > 1 ? min(200, size.width) : size.width,
      height: size.aspectRatio > 1 ? min(400, (size.width / 2)) : size.width,

      child: Screenshot(
        controller: _screenshotController,
        child: LayoutBuilder(
          builder: (a1, c1) {
            return Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCameraFit: !site.hasLocations
                          ? null
                          : CameraFit.bounds(bounds: LatLngBounds(site.fatLatLng!, site.customerLatLng!), padding: EdgeInsets.all(32)),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
                        userAgentPackageName: 'LMT',
                      ),
                      PolylineLayer(
                        polylines: [
                          if (site.canDrawPolyLine)
                            Polyline(
                              color: Colors.blue,
                              pattern: StrokePattern.solid(),
                              strokeWidth: 2,
                              points: [
                                if (site.customerLatLng != null) site.customerLatLng!,
                                ...(poles.where((e) => e.hasLocations)).map((p) {
                                  return LatLng(p.lat!, p.lng!);
                                }),
                                if (site.fatLat != null) site.fatLatLng!,
                              ],
                            ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          if (site.customerLatLng != null)
                            Marker(
                              width: 25,
                              height: 25,
                              point: site.customerLatLng!,
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: 25,
                                height: 25,
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  elevation: 0,
                                  shape: CircleBorder(),
                                  color: Colors.green,
                                  child: Icon(
                                    Icons.home,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          if (site.fatLatLng != null)
                            Marker(
                              width: 30,
                              height: 30,
                              point: site.fatLatLng!,
                              alignment: Alignment.topCenter,
                              child: Icon(
                                Icons.location_on_rounded,
                                color: Colors.green,
                                size: 30,
                              ),
                            ),
                          ...(site.poles ?? []).map((p) {
                            Color color = Colors.black;
                            if (p.enumPoleType != null) {
                              switch (p.enumPoleType) {
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
                            return Marker(
                              width: 25,
                              height: 25,
                              point: LatLng(p.lat ?? 0, p.lng ?? 0),
                              alignment: Alignment.center,
                              child: Card(
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
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: AlignmentGeometry.bottomLeft,
                  child: SizedBox(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 3,
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
                                decoration: BoxDecoration(color: Colors.lightBlue.withAlpha((0.9 * 255).toInt())),
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
                                      padding: const EdgeInsets.symmetric(vertical: 6),
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
                                        style: TextStyle(color: Colors.black, fontSize: 12),
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
                                      '150m',
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
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              spacing: 8,
                              children: [
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Column(
                                      children: [
                                        Text(
                                          'N: ${_site?.customerLat.toString().substring(0, min((_site?.customerLat ?? '-').toString().length, 7)) ?? '-'}',
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'E: ${_site?.customerLng.toString().substring(0, min((_site?.customerLng ?? '-').toString().length, 7)) ?? '-'}',
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                        ),
                                        FittedBox(
                                          child: Text(
                                            _site?.circuitId ?? '-',
                                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Column(
                                      children: [
                                        Text(
                                          'N: ${_site?.fatLat.toString().substring(0, min((_site?.fatLat ?? '-').toString().length, 7)) ?? '-'}',
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'E: ${_site?.fatLng.toString().substring(0, min((_site?.fatLng ?? '-').toString().length, 7)) ?? '-'}',
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          _site?.fatName ?? '-',
                                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      _site?.lspName ?? '-',
                                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
