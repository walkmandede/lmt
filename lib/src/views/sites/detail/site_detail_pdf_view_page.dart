import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lmt/src/models/site_detail_model.dart';
import 'package:lmt/src/views/sites/detail/pdf_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ---------------------------------------------------------------------------
// PDF generation — runs in background isolate via compute().
// ---------------------------------------------------------------------------

Future<Uint8List> _buildPdf(Map<String, dynamic> p) async {
  final doc = pw.Document(title: 'Site Detail Report', author: 'Galaxia Net');

  final mpt = p['imgMpt'] as Uint8List;
  final ksgm = p['imgKsgm'] as Uint8List;
  final mapImg = p['mapImage'] as Uint8List?;
  final circuitId = p['circuitId'] as String;
  final d4Bytes = (p['d4'] as List<dynamic>).cast<Uint8List>();

  final poles = (p['poles'] as List<dynamic>).cast<Map<String, dynamic>>();

  pw.ImageProvider? img(String key) {
    final b = p[key] as Uint8List?;
    return b == null ? null : pw.MemoryImage(b);
  }

  String s(String key) => (p[key] as String?) ?? '-';

  // ── Page 1: Cover ─────────────────────────────────────────────────────────
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      build: (_) => pw.SizedBox.expand(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pageHeader(mpt, ksgm),
            pw.SizedBox(height: 16),
            txt('Galaxia @ Net CO.,LTD'.toUpperCase(), size: 18, color: PdfColors.blue),
            pw.SizedBox(height: 32),
            txt('MPT-KSGM FTTH Project'.toUpperCase(), size: 18),
            pw.SizedBox(height: 32),
            txt('Circuit ID: $circuitId', size: 18),
            pw.SizedBox(height: 32),
            txt('Final Acceptance', size: 18),
            txt('Documentation', size: 18),
            pw.SizedBox(height: 32),
            txt('Table of contents'.toUpperCase(), size: 16),
            pw.SizedBox(height: 96),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(10),
                2: const pw.FlexColumnWidth(3),
              },
              children: [
                for (final r in [
                  ['Page', 'Item Description', 'Format'],
                  ['1', 'Document Cover Page', 'PDF'],
                  ['2', 'Advice Note', 'PDF'],
                  [
                    '3-9',
                    'Construction Report\n'
                        '  A. Circuit ID Information\n'
                        '  B. Site/FAT Information\n'
                        '  C. Cable Route Diagram\n'
                        '  D. Onsite Installation Photo & Termination for FAT\n'
                        '  E. Onsite Installation Photo & Termination customer site\n'
                        '  F. ONT test and service test result\n'
                        '  G. Cable Laying Check-list for Existing Pole',
                    'PDF',
                  ],
                ])
                  pw.TableRow(children: r.map((c) => cell(c)).toList()),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  // // ── Page 2: Advice Note ───────────────────────────────────────────────────
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      build: (_) => pw.SizedBox.expand(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pageHeader(mpt, ksgm),
            pw.SizedBox(height: 16),
            txt('Advise Note Information'.toUpperCase(), size: 14),
            pw.SizedBox(height: 32),
            pw.Expanded(child: img('anNode') == null ? pw.SizedBox.expand() : pw.Image(img('anNode')!)),
            pageFooter(2),
          ],
        ),
      ),
    ),
  );

  // ── Page 3: Construction Report (A, B, C) ─────────────────────────────────
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      build: (_) => pw.SizedBox(
        width: double.infinity,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pageHeader(mpt, ksgm),
            pw.SizedBox(height: 16),
            pw.Center(child: txt('Construction Report'.toUpperCase(), size: 14)),
            pw.SizedBox(height: 16),
            band('A', 'Circuit ID information'),
            dataRow('1', 'Circuit ID', circuitId),
            dataRow2('2', 'Location (Coordinates)', 'Lat', s('customerLat'), 'Long', s('customerLng')),
            dataRow('3', 'Work Order Date/Time', s('workOrderDateTime')),
            dataRow('4', 'Activation/Relocated Date/Time', s('activationDateTime')),
            pw.SizedBox(height: 16),
            band('B', 'Site/FAT information'),
            dataRow('1', 'Survey Result (Feasible)', s('surveyResultDateTime')),
            dataRow('2', 'FAT Name', s('fatName')),
            dataRow('3', 'FAT Port No', s('fatPortNumber')),
            dataRow2('4', 'FAT Location (Coordinates)', 'Lat', s('fatLat'), 'Long', s('fatLng')),
            dataRow2('5', 'Optical Level at FAT port', '1310nm', s('opticalLevelFatPort1310nm'), '1490nm', s('opticalLevelFatPort1490nm')),
            dataRow2('6', 'Optical Level at ATB port', '1310nm', s('opticalLevelAtbPort1310nm'), '1490nm', s('opticalLevelAtbPort1490nm')),
            dataRow('7', 'Drop Cable Length (m)', s('dropCableLengthInMeter')),
            dataRow('8', 'ROW issue', s('rowIssue')),
            pw.SizedBox(height: 16),
            band('C', 'Cable Route Diagram'),
            if (mapImg != null) pw.Expanded(child: pw.Image(pw.MemoryImage(mapImg))),
            pageFooter(3),
          ],
        ),
      ),
    ),
  );

  // ── Page 4: Section D (Page 1) — d1, d2 ──────────────────────────────────
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      build: (_) => pw.SizedBox.expand(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pageHeader(mpt, ksgm),
            pw.SizedBox(height: 16),
            band('D', 'Onsite Installation Photo & Termination for FAT'),
            band('I', 'Photos of FAT before installation', color: PdfColors.green200),
            // D1:
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.topCenter,
                            child: txt('1'),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 10,
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            txt('Photo of FAT before installation'),
                            pw.Expanded(
                              child: pw.Row(
                                children: [
                                  pw.Expanded(
                                    child: pw.Column(
                                      children: [
                                        txt('FAT with close status'),
                                        pw.Expanded(child: img('d1_1') == null ? pw.SizedBox.shrink() : pw.Image(img('d1_1')!)),
                                      ],
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Column(
                                      children: [
                                        txt('FAT with open status'),
                                        pw.Expanded(child: img('d1_2') == null ? pw.SizedBox.shrink() : pw.Image(img('d1_2')!)),
                                      ],
                                    ),
                                  ),
                                ],
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
            // D2:
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.topCenter,
                            child: txt('2'),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 10,
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            txt('Photo of FAT after installation (FAT closed properly and coil properly)'),
                            pw.Expanded(
                              child: pw.Row(
                                children: [
                                  pw.Expanded(child: img('d2_1') == null ? pw.SizedBox.shrink() : pw.Image(img('d2_1')!)),
                                  pw.Expanded(child: img('d2_2') == null ? pw.SizedBox.shrink() : pw.Image(img('d2_2')!)),
                                ],
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
            pw.SizedBox(height: 16),
            pageFooter(4),
          ],
        ),
      ),
    ),
  );

  // ── Page 5: Section D (Page 2) — d3, d4 ──────────────────────────────────
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      build: (_) => pw.SizedBox.expand(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pageHeader(mpt, ksgm),
            pw.SizedBox(height: 16),
            band('D', 'Onsite Installation Photo & Termination for FAT'),
            band('II', 'FAT photo & Accessories Photo', color: PdfColors.blue50),
            // D3: Cable label inside FAT — pair
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.topCenter,
                            child: txt('3'),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 10,
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            txt('Photo of Cable label (inside FAT) after installation'),
                            pw.Expanded(
                              child: pw.Row(
                                children: [
                                  pw.Expanded(child: img('d3_1') == null ? pw.SizedBox.shrink() : pw.Image(img('d3_1')!)),
                                  pw.Expanded(child: img('d3_1') == null ? pw.SizedBox.shrink() : pw.Image(img('d3_2')!)),
                                ],
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
            // D4: Accessories
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.topCenter,
                            child: txt('4'),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 10,
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            txt('Other Accessoires Photo (Tension Clamp, Hook, Stainless Buckle)'),
                            pw.Expanded(
                              child: pw.Row(
                                children: [
                                  ...d4Bytes.map((d) {
                                    return pw.Expanded(child: pw.Image(pw.MemoryImage(d)));
                                  }),
                                ],
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
            pw.SizedBox(height: 16),
            pageFooter(5),
          ],
        ),
      ),
    ),
  );

  // ── Page 6: Section E - page1 — e1,e2,e3
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      build: (_) => pw.SizedBox.expand(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pageHeader(mpt, ksgm),
            pw.SizedBox(height: 16),
            band('E', 'Onsite Installation Photo & Termination customer site'),
            band('I', 'Drop cable photo and other facilities', color: PdfColors.blue50),
            // e1
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.topCenter,
                            child: txt('1'),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 10,
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            txt('Photo of Outdoor Cable (Drop cable laid through route) Remark :Please take photo including FAT)'),
                            pw.Expanded(
                              child: img('e1') == null ? pw.SizedBox.shrink() : pw.Image(img('e1')!),
                            ),
                            txt('Whether there are any other fibers or not, please show/point out the related fiber clearly.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // e2
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.topCenter,
                            child: txt('2'),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 10,
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            txt('Photo of Customer Home entrance cable'),
                            pw.Expanded(
                              child: img('e2') == null ? pw.SizedBox.shrink() : pw.Image(img('e2')!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // e2
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.topCenter,
                            child: txt('3'),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 10,
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            txt('Photo of Indoor Cable (Drop cable laid between customer entrance and ATB)'),
                            pw.Expanded(
                              child: img('e3') == null ? pw.SizedBox.shrink() : pw.Image(img('e3')!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 16),
            pageFooter(6),
          ],
        ),
      ),
    ),
  );

  // ── Page 7: Section E - page2 — e1,e2,e3
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      build: (_) => pw.SizedBox.expand(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pageHeader(mpt, ksgm),
            pw.SizedBox(height: 16),
            band('E', 'Onsite Installation Photo & Termination customer site'),
            // e4
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.topCenter,
                            child: txt('4'),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 10,
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            txt('Photo of Cable Coils(At customer side and FAT side)'),
                            pw.Expanded(
                              child: pw.Row(
                                children: [
                                  pw.Expanded(child: img('e4_1') == null ? pw.SizedBox.shrink() : pw.Image(img('e4_1')!)),
                                  pw.Expanded(child: img('e4_2') == null ? pw.SizedBox.shrink() : pw.Image(img('e4_2')!)),
                                ],
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
            // e5
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.topCenter,
                            child: txt('5'),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 10,
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            txt('Photo of ATB'),
                            pw.Expanded(
                              child: img('e5') == null ? pw.SizedBox.shrink() : pw.Image(img('e5')!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // row remark
            pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.black,
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      width: double.infinity,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Align(
                          alignment: pw.Alignment.topCenter,
                          child: txt('6'),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      width: double.infinity,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Align(
                          alignment: pw.Alignment.topCenter,
                          child: txt('ROW Remark'),
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 8,
                    child: pw.Container(
                      width: double.infinity,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          right: pw.BorderSide(
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Align(
                          alignment: pw.Alignment.topCenter,
                          child: txt(s('rowIssue')),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            //e6
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.topCenter,
                            child: txt('7'),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 10,
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            txt('Photo of Cable Coils(At customer side and FAT side)'),
                            pw.Expanded(
                              child: pw.Row(
                                children: [
                                  pw.Expanded(child: img('e6_1') == null ? pw.SizedBox.shrink() : pw.Image(img('e6_1')!)),
                                  pw.Expanded(child: img('e6_2') == null ? pw.SizedBox.shrink() : pw.Image(img('e6_2')!)),
                                  pw.Expanded(child: img('e6_3') == null ? pw.SizedBox.shrink() : pw.Image(img('e6_3')!)),
                                ],
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
            pw.SizedBox(height: 16),
            pageFooter(7),
          ],
        ),
      ),
    ),
  );

  // ── Page 8: Section F - page1 — f1,f2,f3
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      build: (_) => pw.SizedBox.expand(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pageHeader(mpt, ksgm),
            pw.SizedBox(height: 16),
            band('F', 'ONT test and service test result'),
            band('I', 'ONT information', color: PdfColors.blue50),
            // e1
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.topCenter,
                            child: txt('2'),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 10,
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            txt('Photo of ONT'),
                            pw.Expanded(
                              child: img('f1') == null ? pw.SizedBox.shrink() : pw.Image(img('f1')!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // e2
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.topCenter,
                            child: txt('3'),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 10,
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            txt('Photo of S/N Number of ONT'),
                            pw.Expanded(
                              child: img('f2') == null ? pw.SizedBox.shrink() : pw.Image(img('f2')!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // e2
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.topCenter,
                            child: txt('4'),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 10,
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            txt('Photo of ONT installation environment'),
                            txt('(*) Do not put in places where are exposed to direct sunlight or extreme temperatures'),
                            pw.Expanded(
                              child: img('f3') == null ? pw.SizedBox.shrink() : pw.Image(img('f3')!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 16),
            pageFooter(8),
          ],
        ),
      ),
    ),
  );

  // ── Page 9: Section F - page2 — f4,f5,f6
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      build: (_) => pw.SizedBox.expand(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pageHeader(mpt, ksgm),
            pw.SizedBox(height: 16),
            band('F', 'ONT test and service test result'),
            band('II', 'Service test result', color: PdfColors.blue50),
            // f4
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.topCenter,
                            child: txt('1'),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 10,
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            txt('Internet Service Test (Ping Test)'),
                            pw.Expanded(
                              child: pw.Row(
                                children: [
                                  pw.Expanded(child: img('f4_1') == null ? pw.SizedBox.shrink() : pw.Image(img('f4_1')!)),
                                  pw.Expanded(child: img('f4_2') == null ? pw.SizedBox.shrink() : pw.Image(img('f4_2')!)),
                                ],
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
            // f5
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.topCenter,
                            child: txt('2'),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 10,
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            txt('Internet Service test (Speed Test)'),
                            pw.Expanded(
                              child: img('f5') == null ? pw.SizedBox.shrink() : pw.Image(img('f5')!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            //f6
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.topCenter,
                            child: txt('3'),
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 10,
                      child: pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            txt('Call Test result or IPTV Test Result (If has)'),
                            pw.Expanded(
                              child: pw.Row(
                                children: [
                                  pw.Expanded(child: img('f6_1') == null ? pw.SizedBox.shrink() : pw.Image(img('f6_1')!)),
                                  pw.Expanded(child: img('f6_2') == null ? pw.SizedBox.shrink() : pw.Image(img('f6_2')!)),
                                ],
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
            pw.SizedBox(height: 16),
            pageFooter(9),
          ],
        ),
      ),
    ),
  );

  // ── Page 10: Poles
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      header: (context) => pageHeader(mpt, ksgm),
      footer: (context) => pageFooter(context.pageNumber),
      build: (context) {
        return [
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              border: pw.Border.all(
                color: PdfColors.black,
              ),
            ),
            padding: pw.EdgeInsets.all(8),
            alignment: pw.Alignment.center,
            child: txt('Cable Laying Check-list for Exisiting Pole'),
          ),
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColors.yellow200,
              border: pw.Border.all(
                color: PdfColors.black,
              ),
            ),
            alignment: pw.Alignment.center,
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    width: double.infinity,
                    decoration: pw.BoxDecoration(),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: txt('Link ID:'),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                      ),
                    ),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: txt(s('circuitId'), size: 8),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                      ),
                    ),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: txt('Customer Name:'),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                      ),
                    ),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: txt(s('customerName')),
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColors.yellow200,
              border: pw.Border.all(
                color: PdfColors.black,
              ),
            ),
            alignment: pw.Alignment.center,
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                      ),
                    ),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: txt('LSP\'s Name:'),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                      ),
                    ),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: txt(s('lspName'), size: 10),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                      ),
                    ),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: txt('Check Area:'),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                      ),
                    ),
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: txt(poles.isEmpty ? '-' : 'P_001 to P_${poles.length.toString().padLeft(3, '0')}'),
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.GridView(
            crossAxisCount: 2,
            childAspectRatio: 6 / 5,
            children: poles.map((pole) {
              return pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                  ),
                ),
                alignment: pw.Alignment.center,
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Container(
                        width: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.black,
                          ),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Container(
                              width: double.infinity,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(
                                  color: PdfColors.black,
                                ),
                              ),
                              child: pw.Padding(
                                padding: pw.EdgeInsets.all(8),
                                child: txt('Pole Condition'),
                              ),
                            ),
                            pw.Row(
                              children: [
                                pw.Expanded(
                                  child: pw.Container(
                                    width: double.infinity,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(
                                        color: PdfColors.black,
                                      ),
                                    ),
                                    child: pw.Padding(
                                      padding: pw.EdgeInsets.all(4),
                                      child: txt('Pole No:', size: 10),
                                    ),
                                  ),
                                ),
                                pw.Expanded(
                                  child: pw.Container(
                                    width: double.infinity,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(
                                        color: PdfColors.black,
                                      ),
                                    ),
                                    child: pw.Padding(
                                      padding: pw.EdgeInsets.all(4),
                                      child: txt('P_${(poles.indexOf(pole) + 1).toString().padLeft(3, '0')}', size: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            pw.Row(
                              children: [
                                pw.Expanded(
                                  child: pw.Container(
                                    width: double.infinity,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(
                                        color: PdfColors.black,
                                      ),
                                    ),
                                    child: pw.Padding(
                                      padding: pw.EdgeInsets.all(4),
                                      child: txt('Latitude:', size: 10),
                                    ),
                                  ),
                                ),
                                pw.Expanded(
                                  child: pw.Container(
                                    width: double.infinity,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(
                                        color: PdfColors.black,
                                      ),
                                    ),
                                    child: pw.Padding(
                                      padding: pw.EdgeInsets.all(4),
                                      child: txt(pole['lat'].toString().substring(0, min(pole['lat'].toString().length, 7)), size: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            pw.Row(
                              children: [
                                pw.Expanded(
                                  child: pw.Container(
                                    width: double.infinity,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(
                                        color: PdfColors.black,
                                      ),
                                    ),
                                    child: pw.Padding(
                                      padding: pw.EdgeInsets.all(4),
                                      child: txt('Longitude:', size: 10),
                                    ),
                                  ),
                                ),
                                pw.Expanded(
                                  child: pw.Container(
                                    width: double.infinity,
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(
                                        color: PdfColors.black,
                                      ),
                                    ),
                                    child: pw.Padding(
                                      padding: pw.EdgeInsets.all(4),
                                      child: txt(pole['lng'].toString().substring(0, min(pole['lng'].toString().length, 7)), size: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Container(
                        width: double.infinity,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.black,
                          ),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Container(
                              width: double.infinity,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(
                                  color: PdfColors.black,
                                ),
                              ),
                              child: pw.Padding(
                                padding: pw.EdgeInsets.all(8),
                                child: txt('Picture'),
                              ),
                            ),
                            pw.Expanded(
                              child: pole['imageBytes'] == null
                                  ? pw.Center(child: txt('No Image', size: 10))
                                  : pw.Image(
                                      pw.MemoryImage(pole['imageBytes'] as Uint8List),
                                      fit: pw.BoxFit.contain,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ];
      },
    ),
  );

  return await doc.save();
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class SiteDetailPdfViewPage extends StatefulWidget {
  final SiteDetailModel siteDetailModel;
  final Uint8List? mapImage;

  const SiteDetailPdfViewPage({
    super.key,
    required this.siteDetailModel,
    required this.mapImage,
  });

  @override
  State<SiteDetailPdfViewPage> createState() => _SiteDetailPdfViewPageState();
}

class _SiteDetailPdfViewPageState extends State<SiteDetailPdfViewPage> {
  Uint8List? _docData;
  bool _isLoading = true;
  double _progress = 0.0;
  String _progressLabel = 'Starting...';

  SiteDetailModel get _sd => widget.siteDetailModel;

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  // Flat list of every named network image.
  List<(String key, String? url)> get _imageEntries {
    final g = _sd.gallery;
    return [
      ('anNode', g?.anNode),
      // D
      ('d1_1', g?.d1_1), ('d1_2', g?.d1_2),
      ('d2_1', g?.d2_1), ('d2_2', g?.d2_2),
      ('d3_1', g?.d3_1), ('d3_2', g?.d3_2),
      // E
      ('e1', g?.e1), ('e2', g?.e2), ('e3', g?.e3),
      ('e4_1', g?.e4_1), ('e4_2', g?.e4_2),
      ('e5', g?.e5),
      ('e6_1', g?.e6_1), ('e6_2', g?.e6_2), ('e6_3', g?.e6_3),
      // F
      ('f1', g?.f1), ('f2', g?.f2), ('f3', g?.f3),
      ('f4_1', g?.f4_1), ('f4_2', g?.f4_2),
      ('f5', g?.f5),
      ('f6_1', g?.f6_1), ('f6_2', g?.f6_2),
    ];
  }

  Future<void> _initLoad() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _progressLabel = 'Loading assets...';
      _docData = null;
    });

    // 1. Local assets.
    final imgMptData = await rootBundle.load('assets/mptlogo.jpg');
    final imgKsgmData = await rootBundle.load('assets/ksgm.jpg');

    // 2. All named network images in parallel with per-image progress updates.
    final entries = _imageEntries;

    final namedResults = await Future.wait(
      entries.map((e) async {
        final bytes = await fetchBytes(e.$2);
        return (e.$1, bytes);
      }),
    );

    // 3. d4 list (variable length).
    final d4Urls = _sd.gallery?.d4 ?? [];
    final d4Bytes = await Future.wait(d4Urls.map(fetchBytes));

    // 4. Assemble the params map for compute(). //majorParams
    final params = <String, dynamic>{
      'imgMpt': imgMptData.buffer.asUint8List(),
      'imgKsgm': imgKsgmData.buffer.asUint8List(),
      'mapImage': widget.mapImage,
      // Text fields
      'circuitId': _sd.circuitId,
      'customerLat': _sd.customerLat?.toString(),
      'customerLng': _sd.customerLng?.toString(),
      'workOrderDateTime': _sd.workOrderDateTime?.toString().substring(0, 16),
      'activationDateTime': _sd.activationDateTime?.toString().substring(0, 16),
      'surveyResultDateTime': _sd.surveyResultDateTime?.toString(),
      'fatName': _sd.fatName,
      'fatPortNumber': _sd.fatPortNumber,
      'fatLat': _sd.fatLat?.toString(),
      'fatLng': _sd.fatLng?.toString(),
      'opticalLevelFatPort1310nm': _sd.opticalLevelFatPort1310nm?.toString(),
      'opticalLevelFatPort1490nm': _sd.opticalLevelFatPort1490nm?.toString(),
      'opticalLevelAtbPort1310nm': _sd.opticalLevelAtbPort1310nm?.toString(),
      'opticalLevelAtbPort1490nm': _sd.opticalLevelAtbPort1490nm?.toString(),
      'dropCableLengthInMeter': _sd.dropCableLengthInMeter,
      'rowIssue': _sd.rowIssue,
      'ontSerialNumber': _sd.ontSnNumber ?? '-',
      'lspName': _sd.lspName ?? '-',

      // d4
      'd4': d4Bytes.whereType<Uint8List>().toList(),
      //poles
      'poles': await Future.wait(
        (_sd.poles ?? []).map((pole) async {
          final imageBytes = await fetchBytes(pole.image);
          return {
            'poleId': pole.id ?? '-',
            'poleType': pole.enumPoleType?.name ?? '-',
            'lat': pole.lat ?? 0,
            'lng': pole.lng ?? 0,
            'imageBytes': imageBytes, // Uint8List? — safe to pass to compute()
          };
        }),
      ),
    };

    // Add all named image bytes.
    for (final r in namedResults) {
      params[r.$1] = r.$2;
    }

    // 5. Build + encode PDF in a background isolate.
    await Future.delayed(const Duration(milliseconds: 500));

    final pdfBytes = await compute(_buildPdf, params);

    await Future.delayed(const Duration(milliseconds: 250));

    if (mounted) {
      setState(() {
        _docData = pdfBytes;
        _isLoading = false;
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _initLoad,
          ),
        ],
      ),
      body: SizedBox.expand(
        child: _isLoading ? _loadingView() : _pdfView(),
      ),
    );
  }

  Widget _loadingView() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _progress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(_progressLabel, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            '${(_progress * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );

  Widget _pdfView() {
    if (_docData == null) {
      return const Center(child: Text('Something went wrong'));
    }
    return InteractiveViewer(
      minScale: 0.2,
      maxScale: 5,
      child: PdfPreview(
        initialPageFormat: PdfPageFormat.a4,
        build: (_) => _docData!,
      ),
    );
  }
}
