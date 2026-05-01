import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lmt/app.dart';
import 'package:lmt/core/services/site_service.dart';
import 'package:lmt/src/models/site_detail_model.dart';

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
  Set<EnumSiteStatus> _statusFilter = {};

  bool get _hasActiveFilters => _activationFilter != _ActivationFilter.all || _statusFilter.isNotEmpty;
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

    final data = await _service.listSitesByFliter(
      page: _page,
      limit: _limit,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      sortField: _sort.field,
      sortAsc: _sort.ascending,
      statusFilter: _statusFilter.isEmpty ? null : _statusFilter.map((s) => s.dbValue).toList(),
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
    var tempSort = _sort;
    var tempActivation = _activationFilter;
    var tempStatus = Set<EnumSiteStatus>.from(_statusFilter);

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
                      return ChoiceChip(
                        label: Text(opt.label, style: const TextStyle(fontSize: 12)),
                        selected: tempSort == opt,
                        onSelected: (_) => setSheetState(() => tempSort = opt),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Status filter ──────────────────────────────────────
                  Text('Site Status', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: EnumSiteStatus.values.map((s) {
                      final selected = tempStatus.contains(s);
                      return FilterChip(
                        label: Text(s.label, style: const TextStyle(fontSize: 12)),
                        selected: selected,
                        selectedColor: s.badgeColor.withAlpha(50),
                        checkmarkColor: s.badgeColor,
                        side: BorderSide(
                          color: selected ? s.badgeColor : Colors.grey.shade300,
                        ),
                        onSelected: (_) => setSheetState(() {
                          if (selected) {
                            tempStatus.remove(s);
                          } else {
                            tempStatus.add(s);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Buttons ────────────────────────────────────────────
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setSheetState(() {
                            tempSort = _SortOption.newestFirst;
                            tempActivation = _ActivationFilter.all;
                            tempStatus = {};
                          });
                        },
                        child: const Text('Reset'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            final changed = tempSort != _sort || tempActivation != _activationFilter || !setEquals(tempStatus, _statusFilter);
                            _sort = tempSort;
                            _activationFilter = tempActivation;
                            _statusFilter = tempStatus;
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
  /// Returns a list of (label, isFilled) pairs for all tracked fields.
  // ── Field completion helper ───────────────────────────────────────────────

  List<({String label, bool filled})> _allFields(Map<String, dynamic> s) {
    final g = s['site_gallery'] as Map<String, dynamic>?;

    bool str(String k) {
      final v = s[k];
      return v != null && v.toString().trim().isNotEmpty;
    }

    bool num_(String k) => s[k] != null;

    bool gal(String k) {
      if (g == null) return false;
      final v = g[k];
      if (v is List) return v.isNotEmpty;
      return v != null;
    }

    bool hasFatLoc = num_('fat_lat') && num_('fat_lng');
    bool hasCustomLoc = num_('customer_lat') && num_('customer_lng');
    bool hasDrumRange = num_('cable_drum_start') && num_('cable_drum_end');
    bool hasOptFat = num_('optical_level_fat_port_1310nm') && num_('optical_level_fat_port_1490nm');
    bool hasOptAtb = num_('optical_level_atb_port_1310nm') && num_('optical_level_atb_port_1490nm');

    return [
      // ── Site info ──────────────────────────────────────────────────────
      (label: 'Customer', filled: str('customer_name')),
      (label: 'LSP', filled: str('lsp_name')),
      (label: 'Customer Loc', filled: hasCustomLoc),
      (label: 'Work Order', filled: num_('work_order_datetime')),
      (label: 'Activation', filled: num_('activation_datetime')),
      (label: 'Survey Date', filled: num_('survey_result_datetime')),
      (label: 'Survey Result', filled: str('survey_result')),
      // ── FAT ────────────────────────────────────────────────────────────
      (label: 'FAT Name', filled: str('fat_name')),
      (label: 'FAT Port', filled: str('fat_port_number')),
      (label: 'FAT Loc', filled: hasFatLoc),
      (label: 'Opt FAT', filled: hasOptFat),
      (label: 'Opt ATB', filled: hasOptAtb),
      // ── Cable ──────────────────────────────────────────────────────────
      (label: 'Drop Cable', filled: str('drop_cable_length')),
      (label: 'Drum Range', filled: hasDrumRange),
      (label: 'Pole Range', filled: str('pole_range')),
      (label: 'ROW Issue', filled: str('row_issue')),
      // ── Equipment ──────────────────────────────────────────────────────
      (label: 'ONT S/N', filled: str('ont_sn_number')),
      (label: 'Splitter', filled: str('splitter_no')),
      (label: 'WiFi SSID', filled: str('wifi_ssid')),
      (label: 'MSAN', filled: str('msan')),
      (label: 'Link ID', filled: str('link_id')),
      (label: 'Check Area', filled: str('check_area')),
      (label: 'Conclusion', filled: str('conclusion')),
      // ── Gallery ────────────────────────────────────────────────────────
      (label: 'AN Node', filled: gal('an_node')),
      (label: 'Map', filled: gal('map_image')),
      (label: 'D1-1', filled: gal('d1_1')),
      (label: 'D1-2', filled: gal('d1_2')),
      (label: 'D2-1', filled: gal('d2_1')),
      (label: 'D2-2', filled: gal('d2_2')),
      (label: 'D3-1', filled: gal('d3_1')),
      (label: 'D3-2', filled: gal('d3_2')),
      (label: 'D4', filled: gal('d4')),
      (label: 'E1', filled: gal('e1')),
      (label: 'E2', filled: gal('e2')),
      (label: 'E3', filled: gal('e3')),
      (label: 'E4-1', filled: gal('e4_1')),
      (label: 'E4-2', filled: gal('e4_2')),
      (label: 'E5', filled: gal('e5')),
      (label: 'E6-1', filled: gal('e6_1')),
      (label: 'E6-2', filled: gal('e6_2')),
      (label: 'E6-3', filled: gal('e6_3')),
      (label: 'F1', filled: gal('f1')),
      (label: 'F2', filled: gal('f2')),
      (label: 'F3', filled: gal('f3')),
      (label: 'F4-1', filled: gal('f4_1')),
      (label: 'F4-2', filled: gal('f4_2')),
      (label: 'F5', filled: gal('f5')),
      (label: 'F6-1', filled: gal('f6_1')),
      (label: 'F6-2', filled: gal('f6_2')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FTTH Sites - v(1.2.0)'),
        actions: [
          // Sort / filter button with active badge
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
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
                      color: Colors.red,
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
            child: const Text(
              'Import Excel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.overrideImportPage);
              _refresh();
            },
            child: const Text(
              'Import Overrides',
              style: TextStyle(color: Colors.white),
            ),
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
                runSpacing: 4,
                children: [
                  if (_activationFilter != _ActivationFilter.all)
                    _FilterChip(
                      label: _activationFilter.label,
                      onRemove: () {
                        setState(() => _activationFilter = _ActivationFilter.all);
                        _refresh();
                      },
                    ),
                  ..._statusFilter.map(
                    (s) => _FilterChip(
                      label: s.label,
                      color: s.badgeColor,
                      onRemove: () {
                        setState(() => _statusFilter.remove(s));
                        _refresh();
                      },
                    ),
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
                setState(() {
                  _statusFilter = {};
                  _activationFilter = _ActivationFilter.all;
                });
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
    final status = EnumSiteStatusX.fromDb(site['site_status'] as String?);
    final fields = _allFields(site);
    final doneCount = fields.where((f) => f.filled).length;
    final total = fields.length;

    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(context, '/detail', arguments: site['circuit_id']);
        _refresh();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ──────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: status?.badgeColor ?? Colors.blueGrey,
                  child: const Icon(Icons.cell_tower, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    site['circuit_id'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                SiteStatusBadge(status: status),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  tooltip: 'Update Status',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showStatusPicker(site['circuit_id'] as String, status),
                ),
              ],
            ),
            // ── Customer / LSP ─────────────────────────────────────────
            if (site['customer_name'] != null) ...[
              const SizedBox(height: 2),
              Text(site['customer_name'], style: const TextStyle(fontSize: 12)),
            ],
            if (site['lsp_name'] != null)
              Text(
                site['lsp_name'],
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            const SizedBox(height: 4),
            // ── Stats row ──────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.photo_library_outlined, size: 12, color: Colors.blueGrey.shade400),
                const SizedBox(width: 3),
                Text('${c.images} photos', style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade400)),
                const SizedBox(width: 10),
                Icon(Icons.cell_tower, size: 12, color: Colors.blueGrey.shade400),
                const SizedBox(width: 3),
                Text('${c.poles} poles (${c.polesWithImage} w/ photo)', style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade400)),
                const Spacer(),
                Text(
                  '$doneCount / $total fields',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: doneCount == total ? Colors.green.shade600 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // ── Progress bar ───────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: doneCount / total,
                minHeight: 3,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  doneCount == total ? Colors.green.shade500 : Colors.green.shade300,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // ── Field chips ────────────────────────────────────────────
            _SiteFieldChips(fields: fields),
          ],
        ),
      ),
    );
  }

  Future<void> _showStatusPicker(String circuitId, EnumSiteStatus? current) async {
    EnumSiteStatus? selected = current;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  Text('Update Status — $circuitId', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...EnumSiteStatus.values.map((s) {
                    return RadioListTile<EnumSiteStatus>(
                      dense: true,
                      value: s,
                      groupValue: selected,
                      title: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: s.badgeColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(s.label),
                        ],
                      ),
                      onChanged: (v) => setSheet(() => selected = v),
                    );
                  }),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: selected == null ? null : () => Navigator.pop(ctx, true),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed == true && selected != null) {
      try {
        await _service.updateSiteStatus(circuitId, selected!);
        _refresh();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
  }
}

class SiteStatusBadge extends StatelessWidget {
  final EnumSiteStatus? status;

  const SiteStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status;
    final color = s?.badgeColor ?? Colors.grey;
    final label = s?.label ?? 'No Status';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        border: Border.all(color: color.withAlpha(160)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Small removable filter chip ───────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final Color? color;

  const _FilterChip({required this.label, required this.onRemove, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 11, color: c)),
      deleteIcon: Icon(Icons.close, size: 14, color: c),
      side: c != null ? BorderSide(color: c.withAlpha(160)) : null,
      backgroundColor: c?.withAlpha(25),
      onDeleted: onRemove,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _SiteFieldChips extends StatelessWidget {
  final List<({String label, bool filled})> fields;
  const _SiteFieldChips({required this.fields});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: fields.map((f) => _FieldChip(label: f.label, filled: f.filled)).toList(),
    );
  }
}

class _FieldChip extends StatelessWidget {
  final String label;
  final bool filled;
  const _FieldChip({required this.label, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: filled ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: filled ? Colors.green.shade300 : Colors.grey.shade300,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filled ? Icons.check : Icons.remove,
            size: 9,
            color: filled ? Colors.green.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: filled ? Colors.green.shade800 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
