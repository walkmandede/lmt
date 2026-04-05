import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lmt/src/models/site_detail_model.dart';

class SiteImportPage extends StatefulWidget {
  const SiteImportPage({super.key});

  @override
  State<SiteImportPage> createState() => _SiteImportPageState();
}

class _SiteImportPageState extends State<SiteImportPage> {
  List<SiteDetailModel> sites = [];
  String? error;
  bool isLoading = false;

  Future<void> pickAndParseFile() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['tsv'],
        withData: true,
      );

      if (result == null) {
        setState(() => isLoading = false);
        return;
      }

      final bytes = result.files.single.bytes;
      if (bytes == null) throw Exception("Cannot read file");

      final content = utf8.decode(bytes);

      final parsed = parseTsv(content);

      setState(() {
        sites = parsed;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        sites = [];
        error = e.toString();
        isLoading = false;
      });
    }
  }

  List<SiteDetailModel> parseTsv(String content) {
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) throw Exception("Empty file");

    final headers = lines.first.split('\t');

    final requiredHeaders = [
      'Circuit ID',
      'Customer Name',
      'Installation Latitude',
      'Installation Longitude',
    ];

    for (final h in requiredHeaders) {
      if (!headers.contains(h)) {
        throw Exception("Missing column: $h");
      }
    }

    final List<SiteDetailModel> result = [];

    for (int i = 1; i < lines.length; i++) {
      final row = lines[i].split('\t');
      if (row.length != headers.length) continue;

      final map = <String, String?>{};
      for (int j = 0; j < headers.length; j++) {
        map[headers[j]] = row[j].trim().isEmpty ? null : row[j].trim();
      }

      final fatOptical = _parseOptical(map['dB Loss At Splitter']);
      final atbOptical = _parseOptical(map['dB Loss At ATB']);

      /// 🔥 Build JSON that matches YOUR model
      final json = <String, dynamic>{
        'circuit_id': map['Circuit ID'],
        'customer_name': map['Customer Name'],
        'customer_lat': double.tryParse(map['Installation Latitude'] ?? ''),
        'customer_lng': double.tryParse(map['Installation Longitude'] ?? ''),
        'activation_datetime': _parseDate(map['Activation Date'])?.toIso8601String(),
        'work_order_datetime': _parseDate(map['Work Order Date'])?.toIso8601String(),
        'drop_cable_length': map['Actual Cable Length'],
        'ont_sn_number': map['serial'],
        'splitter_no': map['Splitter no.Key'],
        'fat_port_number': map['Splitter Port No.PortNo'],
        'cable_drum_start': double.tryParse(map['Start'] ?? ''),
        'cable_drum_end': double.tryParse(map['End'] ?? ''),
        'optical_level_fat_port_1310nm': fatOptical.$1,
        'optical_level_fat_port_1490nm': fatOptical.$2,
        'optical_level_atb_port_1310nm': atbOptical.$1,
        'optical_level_atb_port_1490nm': atbOptical.$2,
      };

      result.add(SiteDetailModel.fromJson(json));
    }

    if (result.isEmpty) throw Exception("No valid rows found");

    return result;
  }

  /// Parse: -19.34dBm(1310),-19.74dBm(1490)
  (double?, double?) _parseOptical(String? value) {
    if (value == null) return (null, null);

    try {
      final parts = value.split(',');

      double? v1310;
      double? v1490;

      for (final p in parts) {
        final clean = p.replaceAll('dBm', '');

        if (clean.contains('(1310)')) {
          v1310 = double.tryParse(clean.replaceAll('(1310)', ''));
        } else if (clean.contains('(1490)')) {
          v1490 = double.tryParse(clean.replaceAll('(1490)', ''));
        }
      }

      return (v1310, v1490);
    } catch (_) {
      return (null, null);
    }
  }

  DateTime? _parseDate(String? value) {
    if (value == null) return null;

    try {
      if (value.contains(',')) {
        return DateTime.parse(_convertToIso(value));
      }

      final parts = value.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }

      return DateTime.tryParse(value);
    } catch (_) {
      return null;
    }
  }

  String _convertToIso(String input) {
    final parts = input.split(',');

    final date = parts[0].trim().split('/');
    final time = parts[1].trim();

    final month = date[0].padLeft(2, '0');
    final day = date[1].padLeft(2, '0');
    final year = date[2];

    final isPM = time.contains('PM');
    final t = time.replaceAll(RegExp(r'AM|PM'), '').trim().split(':');

    int hour = int.parse(t[0]);
    final minute = t[1];

    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;

    return "$year-$month-$day ${hour.toString().padLeft(2, '0')}:$minute:00";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import TSV')),
      body: Column(
        children: [
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: isLoading ? null : pickAndParseFile,
            child: const Text("Upload TSV File"),
          ),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),

          if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: sites.length,
              itemBuilder: (context, index) {
                final site = sites[index];

                return ExpansionTile(
                  title: Text(site.circuitId),
                  subtitle: Text(
                    "${site.customerName ?? '-'}\n"
                    "LatLng: ${site.customerLat}, ${site.customerLng}",
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsetsGeometry.all(8),
                      child: Text(site.toJson().toString()),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
