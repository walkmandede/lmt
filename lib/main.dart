import 'package:flutter/material.dart';
import 'package:lmt/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zbqpdaedcztawcmwxqkh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpicXBkYWVkY3p0YXdjbXd4cWtoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxMjcwNDAsImV4cCI6MjA5MDcwMzA0MH0.IC0cb1Pwa9upTDHFuF_11bb4gcIyuo5Ed4psArkvyGQ',
  );
  runApp(MyApp());
}
