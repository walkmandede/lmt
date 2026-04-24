import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lmt/src/models/site_detail_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper: parse a TSV row into SiteDetailModel
// ─────────────────────────────────────────────────────────────────────────────

class _ImportRow {
  final SiteDetailModel model;
  bool isInDb;
  bool selected;

  _ImportRow({
    required this.model,
    required this.isInDb,
    this.selected = true,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class OverrideImportPage extends StatefulWidget {
  const OverrideImportPage({super.key});

  @override
  State<OverrideImportPage> createState() => _OverrideImportPageState();
}

class _OverrideImportPageState extends State<OverrideImportPage> {
  // ── State ──────────────────────────────────────────────────────────────────
  List<_ImportRow> _rows = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // ── Constants ──────────────────────────────────────────────────────────────
  static const _colCircuitId = 'Circuit ID';
  static const _colCustomerName = 'Customer Name';
  static const _colCusLat = 'Cus Lat';
  static const _colCusLong = 'Cus Long';
  static const _colWorkOrderDate = 'Work Order Date';
  static const _colActivationDate = 'Activation Date';
  static const _colSurveyResultDate = 'Suvery Result Date'; // sic — matches TSV header
  static const _colFatName = 'FAT Name';
  static const _colFatPortNumber = 'FAT Port Number';
  static const _colFatLat = 'FAT Lat';
  static const _colFatLong = 'FAT Long';
  static const _colFat1310 = 'FAT 1310';
  static const _colFat1490 = 'FAT 1490';
  static const _colAtb1310 = 'ATB 1310';
  static const _colAtb1490 = 'ATB 1490';
  static const _colStart = 'Start';
  static const _colEnd = 'End';
  static const _colCableLength = 'Actual Cable Length- KissFlow';

  // ── Supabase ───────────────────────────────────────────────────────────────
  final _client = Supabase.instance.client;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void dispose() {
    super.dispose();
  }

  // ── TSV parsing ────────────────────────────────────────────────────────────
  List<SiteDetailModel> _parseTsv(String content) {
    final lines = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

    if (lines.isEmpty) return [];

    final headers = lines.first.split('\t').map((h) => h.trim()).toList();

    int _col(String name) {
      final idx = headers.indexOf(name);
      return idx; // returns -1 if not found — safe via _get
    }

    String? _get(List<String> cells, int idx) {
      if (idx < 0 || idx >= cells.length) return null;
      final v = cells[idx].trim();
      return v.isEmpty ? null : v;
    }

    double? _dbl(String? s) => s == null ? null : double.tryParse(s);

    DateTime? _date(String? s) {
      if (s == null) return null;
      // Try ISO-like formats: "2026/02/19 13:43" or "03/06/2026"
      // First try DateTime.tryParse (handles yyyy-mm-dd and ISO)
      final replaced = s.replaceAll('/', '-');
      return DateTime.tryParse(replaced);
    }

    final idxCircuitId = _col(_colCircuitId);
    final idxCustomerName = _col(_colCustomerName);
    final idxCusLat = _col(_colCusLat);
    final idxCusLong = _col(_colCusLong);
    final idxWorkOrderDate = _col(_colWorkOrderDate);
    final idxActivationDate = _col(_colActivationDate);
    final idxSurveyResultDate = _col(_colSurveyResultDate);
    final idxFatName = _col(_colFatName);
    final idxFatPortNumber = _col(_colFatPortNumber);
    final idxFatLat = _col(_colFatLat);
    final idxFatLong = _col(_colFatLong);
    final idxFat1310 = _col(_colFat1310);
    final idxFat1490 = _col(_colFat1490);
    final idxAtb1310 = _col(_colAtb1310);
    final idxAtb1490 = _col(_colAtb1490);
    final idxStart = _col(_colStart);
    final idxEnd = _col(_colEnd);
    final idxCableLength = _col(_colCableLength);

    final result = <SiteDetailModel>[];

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cells = line.split('\t');

      final circuitId = _get(cells, idxCircuitId);
      if (circuitId == null || circuitId.isEmpty) continue;

      final model =
          SiteDetailModel(
              circuitId: circuitId,
              customerName: _get(cells, idxCustomerName),
              fatName: _get(cells, idxFatName),
              fatPortNumber: _get(cells, idxFatPortNumber),
              opticalLevelFatPort1310nm: _dbl(_get(cells, idxFat1310)),
              opticalLevelFatPort1490nm: _dbl(_get(cells, idxFat1490)),
              opticalLevelAtbPort1310nm: _dbl(_get(cells, idxAtb1310)),
              opticalLevelAtbPort1490nm: _dbl(_get(cells, idxAtb1490)),
              cableDrumStart: _dbl(_get(cells, idxStart)),
              cableDrumEnd: _dbl(_get(cells, idxEnd)),
              dropCableLengthInMeter: _get(cells, idxCableLength),
              activationDateTime: _date(_get(cells, idxActivationDate)),
            )
            ..customerLat = _dbl(_get(cells, idxCusLat))
            ..customerLng = _dbl(_get(cells, idxCusLong))
            ..fatLat = _dbl(_get(cells, idxFatLat))
            ..fatLng = _dbl(_get(cells, idxFatLong))
            ..workOrderDateTime = _date(_get(cells, idxWorkOrderDate))
            ..surveyResultDateTime = _date(_get(cells, idxSurveyResultDate));

      result.add(model);
    }

    return result;
  }

  // ── Upload & DB check ──────────────────────────────────────────────────────
  Future<void> _uploadTsv() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _rows = [];
    });

    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['tsv', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final bytes = result.files.first.bytes;
      if (bytes == null) throw Exception('Could not read file bytes.');

      final content = String.fromCharCodes(bytes);
      final models = _parseTsv(content);

      if (models.isEmpty) {
        setState(() {
          _errorMessage = 'No valid rows found in the TSV file.';
          _isLoading = false;
        });
        return;
      }

      // Check which circuitIds already exist in DB
      final ids = models.map((m) => m.circuitId).toList();
      final existing = await _client.from('site_details').select('circuit_id').inFilter('circuit_id', ids);

      final existingIds = (existing as List).map((e) => e['circuit_id'] as String).toSet();

      setState(() {
        _rows = models
            .map(
              (m) => _ImportRow(
                model: m,
                isInDb: existingIds.contains(m.circuitId),
                selected: true,
              ),
            )
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _addSitesNow() async {
    final selected = _rows.where((r) => r.selected).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sites selected.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    int successCount = 0;
    final errors = <String>[];

    for (final row in selected) {
      try {
        await _client.from('site_details').upsert(row.model.toJson(), onConflict: 'circuit_id');
        successCount++;
      } catch (e) {
        errors.add('${row.model.circuitId}: $e');
      }
    }

    // Refresh DB status for updated rows
    final updatedIds = selected.map((r) => r.model.circuitId).toList();
    final existing = await _client.from('site_details').select('circuit_id').inFilter('circuit_id', updatedIds);
    final nowInDb = (existing as List).map((e) => e['circuit_id'] as String).toSet();

    setState(() {
      for (final row in _rows) {
        if (nowInDb.contains(row.model.circuitId)) row.isInDb = true;
      }
      _isSaving = false;
      _successMessage = errors.isEmpty ? '$successCount site(s) saved successfully.' : '$successCount saved. ${errors.length} failed: ${errors.join(', ')}';
    });
  }

  // ── Selection helpers ──────────────────────────────────────────────────────
  void _selectAll() => setState(() {
    for (final r in _rows) r.selected = true;
  });

  void _unselectAll() => setState(() {
    for (final r in _rows) r.selected = false;
  });

  int get _selectedCount => _rows.where((r) => r.selected).length;

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Override Import'),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top action row ──────────────────────────────────────────────
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _isLoading ? null : _uploadTsv,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: const Text('Import TSV'),
                ),
                if (_rows.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _selectAll,
                    child: const Text('Select All'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _unselectAll,
                    child: const Text('Unselect All'),
                  ),
                  const Spacer(),
                  // Summary chips
                  _StatusChip(
                    label: '${_rows.where((r) => !r.isInDb).length} new',
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: '${_rows.where((r) => r.isInDb).length} update',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: (_isSaving || _selectedCount == 0) ? null : _addSitesNow,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_alt),
                    label: Text('Add Sites Now ($_selectedCount)'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // ── Messages ───────────────────────────────────────────────────
            if (_errorMessage != null) _Banner(message: _errorMessage!, color: colorScheme.errorContainer),
            if (_successMessage != null) _Banner(message: _successMessage!, color: Colors.green.withOpacity(0.15)),

            const SizedBox(height: 8),

            // ── Table ──────────────────────────────────────────────────────
            if (_rows.isEmpty && !_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.table_chart_outlined, size: 64, color: colorScheme.onSurface.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      Text(
                        'Press "Import TSV" to load sites',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_rows.isNotEmpty)
              Expanded(
                child: _SiteList(
                  rows: _rows,
                  onToggle: (idx, val) => setState(() => _rows[idx].selected = val),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List Widget
// ─────────────────────────────────────────────────────────────────────────────

class _SiteList extends StatelessWidget {
  final List<_ImportRow> rows;
  final void Function(int index, bool value) onToggle;

  const _SiteList({required this.rows, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: rows.length,
      itemExtent: 148, // fixed height — eliminates layout recalc on scroll
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (context, i) => _SiteTile(
        row: rows[i],
        index: i,
        onToggle: onToggle,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single Tile
// ─────────────────────────────────────────────────────────────────────────────

class _SiteTile extends StatelessWidget {
  final _ImportRow row;
  final int index;
  final void Function(int index, bool value) onToggle;

  const _SiteTile({
    required this.row,
    required this.index,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final m = row.model;

    final accentColor = row.isInDb ? Colors.orange : Colors.green;
    final bgColor = row.selected ? cs.primaryContainer.withOpacity(0.18) : cs.surfaceContainer;

    return GestureDetector(
      onTap: () => onToggle(index, !row.selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: row.selected ? cs.primary.withOpacity(0.4) : cs.outline.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Colored left accent bar ──────────────────────────────────
            Container(
              width: 5,
              height: double.infinity,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),

            // ── Checkbox ────────────────────────────────────────────────
            Checkbox(
              value: row.selected,
              onChanged: (v) => onToggle(index, v ?? false),
              activeColor: cs.primary,
            ),

            // ── Content ─────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Row 1: Circuit ID + status chip
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            m.circuitId,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: row.isInDb ? 'UPDATE' : 'NEW',
                          color: accentColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Row 2: Customer name + FAT name
                    Row(
                      children: [
                        _InfoChunk(
                          icon: Icons.person_outline,
                          label: 'Customer',
                          value: m.customerName,
                        ),
                        const SizedBox(width: 16),
                        _InfoChunk(
                          icon: Icons.hub_outlined,
                          label: 'FAT',
                          value: m.fatName != null && m.fatPortNumber != null ? '${m.fatName}  ·  ${m.fatPortNumber}' : m.fatName ?? m.fatPortNumber,
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Row 3: Optical levels + cable
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(
                        children: [
                          _MiniTag(label: 'FAT 1310', value: m.opticalLevelFatPort1310nm),
                          _MiniTag(label: 'FAT 1490', value: m.opticalLevelFatPort1490nm),
                          _MiniTag(label: 'ATB 1310', value: m.opticalLevelAtbPort1310nm),
                          _MiniTag(label: 'ATB 1490', value: m.opticalLevelAtbPort1490nm),
                          _MiniTag(
                            label: 'Cable',
                            rawValue: m.dropCableLengthInMeter != null ? '${m.dropCableLengthInMeter} m' : null,
                          ),
                          _MiniTag(
                            label: 'Drum',
                            rawValue: (m.cableDrumStart != null && m.cableDrumEnd != null)
                                ? '${m.cableDrumStart!.toStringAsFixed(0)}→${m.cableDrumEnd!.toStringAsFixed(0)}'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small Reusable Widgets
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Tile Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Icon + label + value — used for customer / FAT name
class _InfoChunk extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _InfoChunk({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          value ?? '—',
          style: theme.textTheme.bodySmall?.copyWith(
            color: value != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Small pill showing a numeric measurement label + value
class _MiniTag extends StatelessWidget {
  final String label;
  final double? value;
  final String? rawValue; // override for non-numeric display

  const _MiniTag({required this.label, this.value, this.rawValue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = rawValue ?? (value != null ? value!.toString() : null);
    final hasValue = displayValue != null;

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: hasValue ? theme.colorScheme.secondaryContainer.withOpacity(0.6) : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: displayValue ?? '—',
              style: TextStyle(
                fontSize: 11,
                color: hasValue ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String message;
  final Color color;
  const _Banner({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: const TextStyle(fontSize: 13)),
    );
  }
}
