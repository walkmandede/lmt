import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lmt/core/services/site_service.dart';

// ── Sort option ───────────────────────────────────────────────────────────────

enum _SortOption {
  newestFirst('created_at', false, 'Newest first'),
  oldestFirst('created_at', true, 'Oldest first'),
  circuitIdAZ('circuit_id', true, 'Circuit ID  A → Z'),
  circuitIdZA('circuit_id', false, 'Circuit ID  Z → A'),
  customerAZ('customer_name', true, 'Customer  A → Z'),
  activationNewest('activation_date_time', false, 'Activation  newest first');

  const _SortOption(this.field, this.ascending, this.label);
  final String field;
  final bool ascending;
  final String label;
}

// ── Activation filter option ──────────────────────────────────────────────────

enum _ActivationFilter {
  all('All'),
  activated('Activated'),
  notActivated('Not activated');

  const _ActivationFilter(this.label);
  final String label;
}

// ── Page ──────────────────────────────────────────────────────────────────────

class SiteListPage extends StatefulWidget {
  const SiteListPage({super.key});

  @override
  State<SiteListPage> createState() => _SiteListPageState();
}

class _SiteListPageState extends State<SiteListPage> {
  final _service = SupabaseSiteService();
  final List<Map<String, dynamic>> _sites = [];
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;
  static const _limit = 20;

  // ── Search / sort / filter state ──────────────────────────────────────────
  String _searchQuery = '';
  _SortOption _sort = _SortOption.newestFirst;
  _ActivationFilter _activationFilter = _ActivationFilter.all;
  Timer? _debounce;

  bool get _hasActiveFilters => _activationFilter != _ActivationFilter.all;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchMore();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _fetchMore();
    }
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _fetchMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);

    // final data = await _service.listSites(
    //   page: _page,
    //   limit: _limit,
    //   // search: _searchQuery.isEmpty ? null : _searchQuery,
    //   // sortField: _sort.field,
    //   // sortAsc: _sort.ascending,
    //   // filterActivated: _activationFilter == _ActivationFilter.all ? null : _activationFilter == _ActivationFilter.activated,
    // );

    final data = await _service.listSitesByFliter(
      page: _page,
      limit: _limit,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      sortField: _sort.field,
      sortAsc: _sort.ascending,
    );

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

  // ── Search debounce ───────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (value != _searchQuery) {
        _searchQuery = value;
        _refresh();
      }
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _searchQuery = '';
    _refresh();
  }

  // ── Sort / filter sheet ───────────────────────────────────────────────────

  void _openSortFilter() {
    // Snapshot current values so cancel works correctly
    var tempSort = _sort;
    var tempFilter = _activationFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Sort ───────────────────────────────────────────────
                  Text('Sort by', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _SortOption.values.map((opt) {
                      final selected = tempSort == opt;
                      return ChoiceChip(
                        label: Text(opt.label, style: const TextStyle(fontSize: 12)),
                        selected: selected,
                        onSelected: (_) => setSheetState(() => tempSort = opt),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Activation filter ──────────────────────────────────
                  Text('Activation status', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _ActivationFilter.values.map((f) {
                      final selected = tempFilter == f;
                      return ChoiceChip(
                        label: Text(f.label, style: const TextStyle(fontSize: 12)),
                        selected: selected,
                        onSelected: (_) => setSheetState(() => tempFilter = f),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Buttons ────────────────────────────────────────────
                  Row(
                    children: [
                      // Reset
                      OutlinedButton(
                        onPressed: () {
                          setSheetState(() {
                            tempSort = _SortOption.newestFirst;
                            tempFilter = _ActivationFilter.all;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                      const SizedBox(width: 12),
                      // Apply
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            final changed = tempSort != _sort || tempFilter != _activationFilter;
                            _sort = tempSort;
                            _activationFilter = tempFilter;
                            if (changed) _refresh();
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Counts helper (unchanged) ─────────────────────────────────────────────

  ({int images, int poles, int polesWithImage}) _counts(Map<String, dynamic> site) {
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
      final d4 = g['d4'];
      if (d4 is List) images += d4.length;
    }
    final poleList = (site['site_poles'] as List?) ?? [];
    final poles = poleList.length;
    final polesWithImage = poleList.where((p) => (p as Map<String, dynamic>)['image'] != null).length;
    return (images: images, poles: poles, polesWithImage: polesWithImage);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FTTH Sites - v(1.0.3)'),
        actions: [
          // Sort / filter button with active badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Sort & Filter',
                onPressed: _openSortFilter,
              ),
              if (_hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          TextButton(
            onPressed: () async {
              await Navigator.pushNamed(context, '/import');
              _refresh();
            },
            child: const Text('Import Excel', style: TextStyle(color: Colors.yellow)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search circuit ID, customer, LSP...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _clearSearch,
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/create');
          _refresh();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Active filter chips row
          if (_hasActiveFilters)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120),
              child: Wrap(
                spacing: 6,
                children: [
                  if (_activationFilter != _ActivationFilter.all)
                    _FilterChip(
                      label: _activationFilter.label,
                      onRemove: () {
                        setState(() => _activationFilter = _ActivationFilter.all);
                        _refresh();
                      },
                    ),
                ],
              ),
            ),
          // Sort indicator row
          if (_sort != _SortOption.newestFirst)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Row(
                children: [
                  Icon(Icons.sort, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    _sort.label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _sites.isEmpty && !_loading
                  ? _buildEmpty()
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
                        return _buildItem(_sites[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final hasQuery = _searchQuery.isNotEmpty || _hasActiveFilters;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasQuery ? Icons.search_off : Icons.cell_tower, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            hasQuery ? 'No results found' : 'No sites yet. Tap + to create one.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          if (hasQuery) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                _searchQuery = '';
                setState(() => _activationFilter = _ActivationFilter.all);
                _refresh();
              },
              child: const Text('Clear search & filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> site) {
    final c = _counts(site);
    final isActivated = site['activation_date_time'] != null;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.cell_tower, color: Colors.white, size: 18),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              site['circuit_id'] ?? '',
              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
            ),
          ),
          // Activation badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isActivated ? Colors.green.shade50 : Colors.orange.shade50,
              border: Border.all(
                color: isActivated ? Colors.green.shade300 : Colors.orange.shade300,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isActivated ? 'Active' : 'Pending',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActivated ? Colors.green.shade700 : Colors.orange.shade700,
              ),
            ),
          ),
        ],
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
              Text('${c.images} photos', style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400)),
              const SizedBox(width: 10),
              Icon(Icons.cell_tower, size: 13, color: Colors.blueGrey.shade400),
              const SizedBox(width: 3),
              Text('${c.poles} poles  (${c.polesWithImage} with photo)', style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400)),
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
  }
}

// ── Small removable filter chip ───────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onRemove,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
