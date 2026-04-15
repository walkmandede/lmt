import 'dart:typed_data';

import 'package:lmt/core/constants/app_functions.dart';
import 'package:lmt/src/models/site_detail_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:js_interop';
import 'dart:convert';

@JS('listenForPaste')
external JSPromise<JSAny?> _listenForPaste();

/// Call this, then tell the user to press Ctrl+V / Cmd+V
Future<Uint8List?> waitForPaste() async {
  try {
    final result = await _listenForPaste().toDart;
    if (result == null) return null;

    final dataUrl = (result as JSString).toDart;
    // dataUrl = "data:image/jpeg;base64,/9j/4AAQ..."
    final comma = dataUrl.indexOf(',');
    if (comma == -1) return null;

    return base64Decode(dataUrl.substring(comma + 1));
  } catch (e) {
    superPrint('Paste error: $e');
    return null;
  }
}

class SupabaseSiteService {
  final client = Supabase.instance.client;

  // ─── SITE ────────────────────────────────────────────────────────────────

  Future<void> upsertSite(SiteDetailModel site) async {
    await client.from('site_details').upsert(site.toJson());
  }

  Future<SiteDetailModel?> getSite(String circuitId) async {
    final data = await client.from('site_details').select().eq('circuit_id', circuitId).maybeSingle();

    if (data == null) return null;

    final model = SiteDetailModel.fromJson(data);
    model.poles = await getPoles(circuitId);
    model.gallery = await getGallery(circuitId);
    return model;
  }

  Future<List<Map<String, dynamic>>> listSites({
    int page = 0,
    int limit = 20,
  }) async {
    final from = page * limit;
    final to = from + limit - 1;
    return List<Map<String, dynamic>>.from(
      await client
          .from('site_details')
          .select(
            'circuit_id, customer_name, lsp_name, created_at, survey_result, site_status, '
            'site_gallery(an_node,d1_1,d1_2,d2_1,d2_2,d3_1,d3_2,d4,'
            'e1,e2,e3,e4_1,e4_2,e5,e6_1,e6_2,e6_3,'
            'f1,f2,f3,f4_1,f4_2,f5,f6_1,f6_2), '
            'site_poles(id,image)',
          )
          .range(from, to)
          .order('created_at', ascending: false),
    );
  }

  Future<List<Map<String, dynamic>>> listSitesByFliter({
    int page = 0,
    int limit = 20,
    String? search,
    String sortField = 'created_at',
    bool sortAsc = false,
    List<String>? statusFilter, // <-- new
  }) async {
    final from = page * limit;
    final to = from + limit - 1;

    var query = client
        .from('site_details')
        .select(
          'circuit_id, customer_name, lsp_name, created_at, survey_result, site_status, '
          'site_gallery(an_node,d1_1,d1_2,d2_1,d2_2,d3_1,d3_2,d4,'
          'e1,e2,e3,e4_1,e4_2,e5,e6_1,e6_2,e6_3,'
          'f1,f2,f3,f4_1,f4_2,f5,f6_1,f6_2), '
          'site_poles(id,image)',
        );

    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim();
      query = query.or(
        'circuit_id.ilike.%$q%,customer_name.ilike.%$q%,lsp_name.ilike.%$q%',
      );
    }

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.inFilter('site_status', statusFilter);
    }

    return List<Map<String, dynamic>>.from(
      await query.range(from, to).order(sortField, ascending: sortAsc),
    );
  }

  Future<void> deleteSite(String circuitId) async {
    await client.from('site_poles').delete().eq('circuit_id', circuitId);
    await client.from('site_gallery').delete().eq('circuit_id', circuitId);
    await client.from('site_details').delete().eq('circuit_id', circuitId);
  }

  Future<void> updateSiteStatus(String circuitId, EnumSiteStatus status) async {
    await client.from('site_details').update({'site_status': status.dbValue}).eq('circuit_id', circuitId);
  }

  // ─── POLES ───────────────────────────────────────────────────────────────

  Future<void> savePoles(String circuitId, List<SitePoleModel> poles) async {
    // Delete existing then re-insert so order is preserved
    await client.from('site_poles').delete().eq('circuit_id', circuitId);

    if (poles.isEmpty) return;

    final rows = poles.map((p) {
      final j = p.toJson();
      j['circuit_id'] = circuitId;
      j.remove('id'); // let Supabase generate id on insert
      return j;
    }).toList();

    await client.from('site_poles').insert(rows);
  }

  Future<List<SitePoleModel>> getPoles(String circuitId) async {
    final data = await client.from('site_poles').select().eq('circuit_id', circuitId).order('created_at');
    return (data as List).map((e) => SitePoleModel.fromJson(e)).toList();
  }

  // ─── GALLERY ─────────────────────────────────────────────────────────────

  Future<void> saveGallery(SiteGalleryModel gallery) async {
    await client.from('site_gallery').upsert(gallery.toJson());
  }

  Future<SiteGalleryModel?> getGallery(String circuitId) async {
    final data = await client.from('site_gallery').select().eq('circuit_id', circuitId).maybeSingle();
    if (data == null) return null;
    return SiteGalleryModel.fromJson(data);
  }
}
