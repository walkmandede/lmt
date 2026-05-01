import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:lmt/src/models/site_detail_model.dart';
import 'package:lmt/src/views/sites/detail/pdf_helper.dart';

class SiteAnPdfViewPage extends StatefulWidget {
  final SiteDetailModel siteDetailModel;

  const SiteAnPdfViewPage({
    super.key,
    required this.siteDetailModel,
  });

  @override
  State<SiteAnPdfViewPage> createState() => _SiteAnPdfViewPageState();
}

class _SiteAnPdfViewPageState extends State<SiteAnPdfViewPage> {
  late Future<Uint8List> _pdfFuture;

  @override
  void initState() {
    super.initState();
    _pdfFuture = _generatePdf();
  }

  Future<Uint8List> _generatePdf() async {
    final doc = pw.Document(title: 'Advice Note', author: 'Galaxia Net');
    final site = widget.siteDetailModel;

    Uint8List? anNodeBytes;
    if (site.gallery?.anNode != null) {
      anNodeBytes = await fetchBytes(site.gallery!.anNode!);
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (_) => pw.SizedBox.expand(
          child: pw.Center(
            child: anNodeBytes == null
                ? pw.Text('No image available')
                : pw.Image(
                    pw.MemoryImage(anNodeBytes),
                    fit: pw.BoxFit.contain,
                  ),
          ),
        ),
      ),
    );

    return await doc.save();
  }

  Future<void> _onPdfPressed(BuildContext context, Uint8List pdfBytes) async {
    final fileName = '${widget.siteDetailModel.circuitId}.CSRA.pdf';
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advice Note'),
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No PDF data'));
          }

          return SizedBox(
            height: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: min(500, ((MediaQuery.of(context).size.width) * 0.9))),
                  child: PdfPreview(
                    initialPageFormat: PdfPageFormat.a4,
                    pdfFileName: '${widget.siteDetailModel.circuitId}.CSRA.pdf',
                    onPrinted: (context) => _onPdfPressed(context, snapshot.data!),
                    build: (_) => snapshot.data!,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
