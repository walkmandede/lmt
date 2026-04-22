import 'package:archive/archive.dart';
import 'dart:typed_data';

import 'package:lmt/src/models/site_detail_model.dart';
import 'package:share_plus/share_plus.dart';

/// Service to export SiteDetailModel to KMZ format (Flutter Web)
class SiteDetailKMZExport {
  /// Generate KML content from SiteDetailModel
  static String generateKML({
    required String circuitId,
    String? customerName,
    String? fatName,
    double? customerLat,
    double? customerLng,
    double? fatLat,
    double? fatLng,
    List<({String? id, double? lat, double? lng})>? poles,
  }) {
    final StringBuffer kml = StringBuffer();

    kml.write('''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>$circuitId</name>
    <open>1</open>
    <Style id="customerStyle">
      <IconStyle>
        <scale>1.0</scale>
        <Icon>
          <href>https://maps.google.com/mapfiles/kml/pushpin/blue-pushpin.png</href>
        </Icon>
      </IconStyle>
    </Style>
    <Style id="fatStyle">
      <IconStyle>
        <scale>1.0</scale>
        <Icon>
          <href>https://maps.google.com/mapfiles/kml/pushpin/red-pushpin.png</href>
        </Icon>
      </IconStyle>
    </Style>
    <Style id="poleStyle">
      <IconStyle>
        <scale>0.8</scale>
        <Icon>
          <href>https://maps.google.com/mapfiles/kml/pushpin/grn-pushpin.png</href>
        </Icon>
      </IconStyle>
    </Style>
    <Style id="polylineStyle">
      <LineStyle>
        <color>ff0099ff</color>
        <width>3</width>
      </LineStyle>
    </Style>
    <Folder>
      <name>Markers</name>
''');

    // Customer marker (blue)
    if (customerLat != null && customerLng != null) {
      kml.write('''
      <Placemark>
        <name>Customer: ${customerName ?? 'N/A'}</name>
        <styleUrl>#customerStyle</styleUrl>
        <Point>
          <coordinates>$customerLng,$customerLat</coordinates>
        </Point>
      </Placemark>
''');
    }

    // FAT marker (red)
    if (fatLat != null && fatLng != null) {
      kml.write('''
      <Placemark>
        <name>FAT: ${fatName ?? 'N/A'}</name>
        <styleUrl>#fatStyle</styleUrl>
        <Point>
          <coordinates>$fatLng,$fatLat</coordinates>
        </Point>
      </Placemark>
''');
    }

    // Pole markers (green)
    if (poles != null && poles.isNotEmpty) {
      for (int i = 0; i < poles.length; i++) {
        final pole = poles[i];
        if (pole.lat != null && pole.lng != null) {
          kml.write('''
      <Placemark>
        <name>Pole ${i + 1}${pole.id != null ? ' (${pole.id})' : ''}</name>
        <styleUrl>#poleStyle</styleUrl>
        <Point>
          <coordinates>${pole.lng},${pole.lat}</coordinates>
        </Point>
      </Placemark>
''');
        }
      }
    }

    kml.write('''
    </Folder>
''');

    // Polyline (Customer -> Poles -> FAT)
    if (_hasPolylinePoints(customerLat, customerLng, fatLat, fatLng, poles)) {
      kml.write('''
    <Placemark>
      <name>Cable Route</name>
      <styleUrl>#polylineStyle</styleUrl>
      <LineString>
        <coordinates>
''');

      // Customer start
      if (customerLat != null && customerLng != null) {
        kml.write('          $customerLng,$customerLat\n');
      }

      // Poles in order
      if (poles != null && poles.isNotEmpty) {
        for (final pole in poles) {
          if (pole.lat != null && pole.lng != null) {
            kml.write('          ${pole.lng},${pole.lat}\n');
          }
        }
      }

      // FAT end
      if (fatLat != null && fatLng != null) {
        kml.write('          $fatLng,$fatLat\n');
      }

      kml.write('''        </coordinates>
      </LineString>
    </Placemark>
''');
    }

    kml.write('''  </Document>
</kml>
''');

    return kml.toString();
  }

  /// Check if polyline has enough points (at least 2)
  static bool _hasPolylinePoints(
    double? customerLat,
    double? customerLng,
    double? fatLat,
    double? fatLng,
    List<({String? id, double? lat, double? lng})>? poles,
  ) {
    int count = 0;
    if (customerLat != null && customerLng != null) count++;
    if (fatLat != null && fatLng != null) count++;
    for (final pole in (poles ?? [])) {
      if (pole.lat != null && pole.lng != null) count++;
    }
    return count > 1;
  }

  /// Create KMZ bytes (ZIP archive)
  static Uint8List createKMZBytes(String kmlContent) {
    final archive = Archive();
    archive.addFile(
      ArchiveFile(
        'doc.kml',
        kmlContent.length,
        kmlContent.codeUnits,
      ),
    );

    final kmzBytes = ZipEncoder().encode(archive);
    // if (kmzBytes == null) {
    //   throw Exception('Failed to encode KMZ file');
    // }

    return Uint8List.fromList(kmzBytes);
  }

  /// Download KMZ file to user's device
  static void downloadKMZ({
    required String circuitId,
    required Uint8List kmzBytes,
  }) {
    // final blob = html.Blob([kmzBytes], 'application/vnd.google-earth.kmz');
    // final url = html.Url.createObjectUrl(blob);
    // final anchor = html.AnchorElement(href: url)
    //   ..setAttribute('download', '$circuitId.kmz')
    //   ..click();
    // html.Url.revokeObjectUrl(url);
  }

  /// Download KML file (uncompressed)
  static void downloadKML({
    required String circuitId,
    required String kmlContent,
  }) {
    // final blob = html.Blob([kmlContent], 'application/vnd.google-earth.kml+xml');
    // final url = html.Url.createObjectUrl(blob);
    // final anchor = html.AnchorElement(href: url)
    //   ..setAttribute('download', '$circuitId.kml')
    //   ..click();
    // html.Url.revokeObjectUrl(url);
  }

  /// Get KMZ as data URL (for preview or sharing)
  static String getKMZDataUrl(Uint8List kmzBytes) {
    final base64 = _bytesToBase64(kmzBytes);
    return 'data:application/vnd.google-earth.kmz;base64,$base64';
  }

  /// Convert bytes to base64 string
  static String _bytesToBase64(Uint8List bytes) {
    final chars = <String>[];
    for (int i = 0; i < bytes.length; i++) {
      chars.add(String.fromCharCode(bytes[i]));
    }
    return chars.join();
  }
}

// ── Extension on SiteDetailModel ──────────────────────────────────────────

extension SiteDetailModelKMZX on SiteDetailModel {
  /// Generate KML from this model
  String toKML() {
    final polesList = poles?.where((p) => p.lat != null && p.lng != null).map((p) => (id: p.id, lat: p.lat, lng: p.lng)).toList() ?? [];

    return SiteDetailKMZExport.generateKML(
      circuitId: circuitId,
      customerName: customerName,
      fatName: fatName,
      customerLat: customerLat,
      customerLng: customerLng,
      fatLat: fatLat,
      fatLng: fatLng,
      poles: polesList,
    );
  }

  /// Create KMZ bytes
  Uint8List toKMZBytes() {
    final kmlContent = toKML();
    return SiteDetailKMZExport.createKMZBytes(kmlContent);
  }

  /// Download KMZ file
  void downloadKMZ() {
    final kmlContent = toKML();
    final kmzBytes = SiteDetailKMZExport.createKMZBytes(kmlContent);
    SiteDetailKMZExport.downloadKMZ(
      circuitId: circuitId,
      kmzBytes: kmzBytes,
    );
  }

  Future<void> shareKMZ() async {
    final kmlContent = toKML();
    final kmzBytes = SiteDetailKMZExport.createKMZBytes(kmlContent);
    await SharePlus.instance.share(
      ShareParams(
        text: 'Share for site',
        files: [XFile.fromData(kmzBytes, name: '$circuitId.kmz')],
      ),
    );
  }

  /// Download KML file (uncompressed)
  void downloadKML() {
    final kmlContent = toKML();
    SiteDetailKMZExport.downloadKML(
      circuitId: circuitId,
      kmlContent: kmlContent,
    );
  }

  /// Get KMZ as data URL
  String getKMZDataUrl() {
    final kmzBytes = toKMZBytes();
    return SiteDetailKMZExport.getKMZDataUrl(kmzBytes);
  }
}
