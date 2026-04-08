import 'package:flutter/services.dart';
import 'package:lmt/src/views/sites/detail/site_detail_pdf_view_page.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Top-level helpers — outside the class so compute() can access them.
// ---------------------------------------------------------------------------

Future<Uint8List?> fetchBytes(String? url) async {
  if (url == null) return null;
  try {
    final res = await http.get(Uri.parse(url));
    return res.statusCode == 200 ? res.bodyBytes : null;
  } catch (_) {
    return null;
  }
}

// ── Text ─────────────────────────────────────────────────────────────────────

pw.Widget txt(String s, {double size = 12, PdfColor? color}) => pw.Text(
  s,
  style: pw.TextStyle(fontSize: size, color: color ?? PdfColors.black),
);

// ── Table cell ────────────────────────────────────────────────────────────────

pw.Widget cell(
  String content, {
  PdfColor? bg,
  pw.AlignmentGeometry? align,
  pw.Widget? child,
}) {
  return pw.DecoratedBox(
    decoration: pw.BoxDecoration(color: bg ?? PdfColors.white),
    child: pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Align(
        alignment: align ?? pw.Alignment.center,
        child: child ?? pw.Text(content, style: pw.TextStyle(fontSize: 12, color: PdfColors.black)),
      ),
    ),
  );
}

// ── Page header (two logos) ───────────────────────────────────────────────────

pw.Widget pageHeader(Uint8List mpt, Uint8List ksgm) => pw.Row(
  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  children: [
    pw.Image(pw.MemoryImage(mpt), width: 56),
    pw.Image(pw.MemoryImage(ksgm), width: 56),
  ],
);

pw.Widget pageFooter(int pageNo) => pw.Row(
  mainAxisAlignment: pw.MainAxisAlignment.end,
  children: [txt(pageNo.toString())],
);

// ── Section / sub-section band ────────────────────────────────────────────────

pw.Widget band(String label, String title, {PdfColor? color}) => pw.Table(
  border: pw.TableBorder.all(color: PdfColors.black),
  columnWidths: {
    0: const pw.FlexColumnWidth(1),
    1: const pw.FlexColumnWidth(10),
  },
  children: [
    pw.TableRow(
      children: [
        cell(label, bg: color ?? pdfColorBlue1),
        cell(title, bg: color ?? pdfColorBlue1, align: pw.Alignment.centerLeft),
      ],
    ),
  ],
);

// ── Data rows ─────────────────────────────────────────────────────────────────

pw.Widget dataRow(String num, String label, String value) => pw.Table(
  border: pw.TableBorder.all(color: PdfColors.black),
  columnWidths: {
    0: const pw.FlexColumnWidth(1),
    1: const pw.FlexColumnWidth(4),
    2: const pw.FlexColumnWidth(6),
  },
  children: [
    pw.TableRow(
      children: [
        cell(num, bg: pdfColorBlue2),
        cell(label, bg: pdfColorBlue2, align: pw.Alignment.centerLeft),
        cell(value, align: pw.Alignment.centerLeft),
      ],
    ),
  ],
);

pw.Widget dataRow2(String num, String label, String k1, String v1, String k2, String v2) => pw.Table(
  border: pw.TableBorder.all(color: PdfColors.black),
  columnWidths: {
    0: const pw.FlexColumnWidth(1),
    1: const pw.FlexColumnWidth(4),
    2: const pw.FlexColumnWidth(1),
    3: const pw.FlexColumnWidth(2),
    4: const pw.FlexColumnWidth(1),
    5: const pw.FlexColumnWidth(2),
  },
  children: [
    pw.TableRow(
      children: [
        cell(num, bg: pdfColorBlue2),
        cell(label, bg: pdfColorBlue2, align: pw.Alignment.centerLeft),
        cell(k1, bg: pdfColorBlue2, child: txt(k1, size: 10), align: pw.Alignment.centerLeft),
        cell(v1, align: pw.Alignment.centerLeft),
        cell(k2, bg: pdfColorBlue2, child: txt(k2, size: 10), align: pw.Alignment.centerLeft),
        cell(v2, align: pw.Alignment.centerLeft),
      ],
    ),
  ],
);

// ── Photo layout helpers ──────────────────────────────────────────────────────

/// Single image with a max height cap so it never overflows the page.
pw.Widget single(pw.ImageProvider? image, {double maxHeight = 175}) => pw.ConstrainedBox(
  constraints: pw.BoxConstraints(maxHeight: maxHeight),
  child: image == null ? pw.SizedBox.shrink() : pw.Image(image, fit: pw.BoxFit.contain),
);

/// Two images side by side, equal width.
pw.Widget pair(pw.ImageProvider? a, pw.ImageProvider? b, {double ratio = 4 / 3}) => pw.Row(
  children: [
    pw.Expanded(
      child: pw.AspectRatio(
        aspectRatio: ratio,
        child: a == null ? pw.SizedBox.shrink() : pw.Image(a),
      ),
    ),
    pw.SizedBox(width: 8),
    pw.Expanded(
      child: pw.AspectRatio(
        aspectRatio: ratio,
        child: b == null ? pw.SizedBox.shrink() : pw.Image(b),
      ),
    ),
  ],
);

/// Variable number of images in a single row, each Expanded equally.
pw.Widget multi(List<pw.ImageProvider?> images, {double ratio = 1.0}) {
  final visible = images.whereType<pw.ImageProvider>().toList();
  if (visible.isEmpty) return pw.SizedBox.shrink();
  return pw.Row(
    children: [
      for (int i = 0; i < visible.length; i++) ...[
        if (i > 0) pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.AspectRatio(
            aspectRatio: ratio,
            child: pw.Image(visible[i]),
          ),
        ),
      ],
    ],
  );
}

// ── Photo table row: num col | content col ───────────────────────────────────

pw.Widget photoRow(String num, pw.Widget content) => pw.Table(
  border: pw.TableBorder.all(color: PdfColors.black),
  columnWidths: {
    0: const pw.FlexColumnWidth(1),
    1: const pw.FlexColumnWidth(10),
  },
  children: [
    pw.TableRow(
      children: [
        cell(num),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: content,
        ),
      ],
    ),
  ],
);

// ── Label + photos stacked vertically ────────────────────────────────────────

pw.Widget labeled(String label, pw.Widget photos) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    txt(label),
    pw.SizedBox(height: 6),
    photos,
  ],
);
