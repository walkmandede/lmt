import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lmt/src/models/site_detail_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:http/http.dart' as http;

class SitePdfPageController {
  late SiteDetailModel siteDetailModel;
  ValueNotifier<bool> isLoading = ValueNotifier(true);

  Future<void> initLoad(SiteDetailModel siteDetail) async {
    siteDetailModel = siteDetail;
    await Future.delayed(const Duration(milliseconds: 1200));
    isLoading.value = false;
  }

  void _buildPdf() async {
    //prepare logos
    final imgMptData = await rootBundle.load('assets/mptlogo.jpg');
    final imgKsgmData = await rootBundle.load('assets/ksgm.jpg');
  }

  Future<Uint8List?> _fetchBytes(String? url) async {
    if (url == null) return null;
    try {
      final res = await http.get(Uri.parse(url));
      return res.statusCode == 200 ? res.bodyBytes : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {}
}
