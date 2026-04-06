import 'package:flutter/material.dart';
import 'package:lmt/core/services/site_service.dart';

class SiteListPage extends StatefulWidget {
  const SiteListPage({super.key});

  @override
  State<SiteListPage> createState() => _SiteListPageState();
}

class _SiteListPageState extends State<SiteListPage> {
  final _service = SupabaseSiteService();
  final List<Map<String, dynamic>> _sites = [];
  final _scrollCtrl = ScrollController();

  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchMore();
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
        _fetchMore();
      }
    });
  }

  ({int images, int poles, int polesWithImage}) _counts(Map<String, dynamic> site) {
    // Gallery — single-slot fields
    final g = site['site_gallery'] as Map<String, dynamic>?;
    int images = 0;
    if (g != null) {
      const singleKeys = [
        'an_node',
        'd1_1',
        'd1_2',
        'd2_1',
        'd2_2',
        'd3_1',
        'd3_2',
        'e1',
        'e2',
        'e3',
        'e4_1',
        'e4_2',
        'e5',
        'e6_1',
        'e6_2',
        'e6_3',
        'f1',
        'f2',
        'f3',
        'f4_1',
        'f4_2',
        'f5',
        'f6_1',
        'f6_2',
      ];
      for (final k in singleKeys) {
        if (g[k] != null) images++;
      }
      // d4 is a JSON array of URLs
      final d4 = g['d4'];
      if (d4 is List) images += d4.length;
    }

    // Poles
    final poleList = (site['site_poles'] as List?) ?? [];
    final poles = poleList.length;
    final polesWithImage = poleList.where((p) => (p as Map<String, dynamic>)['image'] != null).length;

    return (images: images, poles: poles, polesWithImage: polesWithImage);
  }

  Future<void> _fetchMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);

    final data = await _service.listSites(page: _page, limit: _limit);

    setState(() {
      _sites.addAll(data);
      _page++;
      _loading = false;
      if (data.length < _limit) _hasMore = false;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _sites.clear();
      _page = 0;
      _hasMore = true;
    });
    await _fetchMore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FTTH Sites - v(1.0.2)'),
        actions: [
          TextButton(
            onPressed: () async {
              await Navigator.pushNamed(context, '/import');
              _refresh();
            },
            child: Text(
              'Import Excel',
              style: TextStyle(color: Colors.yellow),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/create');
          _refresh();
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _sites.isEmpty && !_loading
            ? const Center(child: Text('No sites yet. Tap + to create one.'))
            : ListView.separated(
                controller: _scrollCtrl,
                itemCount: _sites.length + (_loading ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == _sites.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final site = _sites[index];
                  final c = _counts(site);
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF1565C0),
                      child: Icon(Icons.cell_tower, color: Colors.white, size: 18),
                    ),
                    title: Text(
                      site['circuit_id'] ?? '',
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (site['customer_name'] != null) Text(site['customer_name']),
                        if (site['lsp_name'] != null) Text(site['lsp_name'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.photo_library_outlined, size: 13, color: Colors.blueGrey.shade400),
                            const SizedBox(width: 3),
                            Text(
                              '${c.images} photos',
                              style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.cell_tower, size: 13, color: Colors.blueGrey.shade400),
                            const SizedBox(width: 3),
                            Text(
                              '${c.poles} poles  (${c.polesWithImage} with photo)',
                              style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.pushNamed(context, '/detail', arguments: site['circuit_id']);
                      _refresh();
                    },
                  );
                },
              ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }
}
