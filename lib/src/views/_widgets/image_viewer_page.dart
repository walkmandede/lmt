import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageViewerPage extends StatelessWidget {
  final Uint8List? bytes;
  final String? imageUrl;
  final String title;

  const ImageViewerPage({
    super.key,
    this.bytes,
    this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (bytes != null) {
      image = Image.memory(bytes!, fit: BoxFit.contain);
    } else if (imageUrl != null) {
      image = Image.network(imageUrl!, fit: BoxFit.contain);
    } else {
      image = const SizedBox();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: image,
        ),
      ),
    );
  }
}

void openImageViewer({
  required BuildContext context,
  Uint8List? bytes,
  String? url,
  String title = "Image",
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ImageViewerPage(
        bytes: bytes,
        imageUrl: url,
        title: title,
      ),
    ),
  );
}
