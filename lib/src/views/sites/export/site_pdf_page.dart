import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lmt/src/models/site_detail_model.dart';
import 'package:lmt/src/views/sites/export/site_pdf_controller.dart';

class SitePdfPage extends StatefulWidget {
  final SiteDetailModel siteDetailModel;
  final Uint8List mapImage;

  const SitePdfPage({
    super.key,
    required this.siteDetailModel,
    required this.mapImage,
  });

  @override
  State<SitePdfPage> createState() => _SitePdfPageState();
}

class _SitePdfPageState extends State<SitePdfPage> {
  SitePdfPageController _pageController = SitePdfPageController();

  @override
  void initState() {
    _pageController.initLoad(widget.siteDetailModel);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
    );
  }
}
