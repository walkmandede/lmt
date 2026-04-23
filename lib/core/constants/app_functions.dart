import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'dart:js_interop';

@JS('getPastedImageData')
external JSPromise<JSAny?> _getPastedImageData();

Future<Uint8List?> readClipboardImage() async {
  try {
    final result = await _getPastedImageData().toDart;
    if (result == null) return null;

    final base64String = (result as JSString).toDart;
    // base64String = "data:image/png;base64,xxxx..."
    final comma = base64String.indexOf(',');
    if (comma == -1) return null;

    return base64Decode(base64String.substring(comma + 1));
  } catch (e) {
    debugPrint('Paste error: $e');
    return null;
  }
}

void superPrint(var content, {var title = 'Super Print'}) {
  String callerFrame = '';

  log(content.toString(), name: title);
  return;

  if (kDebugMode) {
    try {
      final stackTrace = StackTrace.current;
      final frames = stackTrace.toString().split("\n");
      callerFrame = frames[1];
    } catch (e1) {
      debugPrint(e1.toString(), wrapWidth: 1024);
    }

    DateTime dateTime = DateTime.now();
    String dateTimeString = '${dateTime.hour} : ${dateTime.minute} : ${dateTime.second}.${dateTime.millisecond}';
    debugPrint('', wrapWidth: 1024);
    debugPrint('- ${title.toString()} - ${callerFrame.split('(').last.replaceAll(')', '')}', wrapWidth: 1024);
    debugPrint('____________________________');
    try {
      debugPrint(const JsonEncoder.withIndent('  ').convert(const JsonDecoder().convert(content)), wrapWidth: 1024);
    } catch (e1) {
      try {
        debugPrint(const JsonEncoder.withIndent('  ').convert(const JsonDecoder().convert(jsonEncode(content))), wrapWidth: 1024);
      } catch (e1) {
        debugPrint(content.toString());
        // saveLogFromException(e1,e2);;
      }
      // saveLogFromException(e1,e2);;
    }
    debugPrint('____________________________ $dateTimeString');
  }
}

void dismissKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
}

void vibrateNow() {
  try {
    HapticFeedback.selectionClick();
  } catch (_) {}
}

class AppFunctions {
  static LatLng getMidPointSimple(LatLng a, LatLng b) {
    return LatLng(
      (a.latitude + b.latitude) / 2,
      (a.longitude + b.longitude) / 2,
    );
  }
}
