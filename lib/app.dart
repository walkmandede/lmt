import 'package:flutter/material.dart';
import 'package:lmt/src/views/maps/map_test.dart';
import 'package:lmt/src/views/sites/create/site_create_page.dart';
import 'package:lmt/src/views/sites/detail/site_detail_page.dart';
import 'package:lmt/src/views/sites/import/site_import_page.dart';
import 'package:lmt/src/views/sites/list/site_list_page.dart';
import 'package:lmt/src/views/sites/override_import/override_import_page.dart';
import 'package:lmt/src/views/sites/update/site_update_page.dart';

class AppRoutes {
  static const root = '/';
  static const create = '/create';
  static const mapPage = '/map_page';
  static const overrideImportPage = '/override_import_page';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const SiteListPage(),
        '/create': (_) => const SiteCreatePage(),
        '/map_page': (_) => const MapPage(),
      },
      theme: ThemeData(
        useMaterial3: false,
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/detail') {
          final id = settings.arguments as String;
          return MaterialPageRoute(builder: (_) => SiteDetailPage(circuitId: id));
        }

        if (settings.name == '/update') {
          final id = settings.arguments as String;
          return MaterialPageRoute(builder: (_) => SiteUpdatePage(circuitId: id));
        }

        if (settings.name == '/update') {
          final id = settings.arguments as String;
          return MaterialPageRoute(builder: (_) => SiteUpdatePage(circuitId: id));
        }

        if (settings.name == '/import') {
          return MaterialPageRoute(builder: (_) => SiteImportPage());
        }
        if (settings.name == AppRoutes.overrideImportPage) {
          return MaterialPageRoute(builder: (_) => OverrideImportPage());
        }
        // '/import': (_) => const SiteImportPage(),

        return null;
      },
    );
  }
}
