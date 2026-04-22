import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lmt/core/constants/app_functions.dart';
import 'package:lmt/core/repositories/site_repository.dart';
import 'package:lmt/core/services/site_service.dart';
import 'package:lmt/core/services/storage_service.dart';
import 'package:lmt/src/models/site_detail_model.dart';
import 'package:lmt/src/views/_widgets/image_viewer_page.dart';
import 'package:lmt/src/views/_widgets/section_card.dart';

class SiteUpdatePage extends StatefulWidget {
  final String circuitId;
  const SiteUpdatePage({super.key, required this.circuitId});

  @override
  State<SiteUpdatePage> createState() => _SiteUpdatePageState();
}

class _SiteUpdatePageState extends State<SiteUpdatePage> {
  final _picker = ImagePicker();
  final _storage = StorageService();
  final _service = SupabaseSiteService();
  late final _repo = SiteRepository(_service);

  bool _loading = true;
  bool _saving = false;

  // ── A ────────────────────────────────────────────────────────────────────
  final _circuitIdCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();
  final _startMeterController = TextEditingController();
  final _endMeterController = TextEditingController();
  final _lspNameCtrl = TextEditingController();
  final _customerLatCtrl = TextEditingController();
  final _customerLngCtrl = TextEditingController();
  DateTime? _workOrderDate;
  DateTime? _activationDate;

  // ── B ────────────────────────────────────────────────────────────────────
  DateTime? _surveyDate;
  final _fatNameCtrl = TextEditingController();
  final _fatPortCtrl = TextEditingController();
  final _fatLatCtrl = TextEditingController();
  final _fatLngCtrl = TextEditingController();
  final _optFat1310Ctrl = TextEditingController();
  final _optFat1490Ctrl = TextEditingController();
  final _optAtb1310Ctrl = TextEditingController();
  final _optAtb1490Ctrl = TextEditingController();
  final _dropCableCtrl = TextEditingController();
  final _rowIssueCtrl = TextEditingController();

  // ── Additional ───────────────────────────────────────────────────────────
  final _ontSnCtrl = TextEditingController();
  final _splitterCtrl = TextEditingController();
  final _wifiSsidCtrl = TextEditingController();
  final _msanCtrl = TextEditingController();
  final _linkIdCtrl = TextEditingController();
  final _poleRangeCtrl = TextEditingController();

  // ── G ────────────────────────────────────────────────────────────────────
  final _checkAreaCtrl = TextEditingController();
  final _conclusionCtrl = TextEditingController();

  // ── Poles ─────────────────────────────────────────────────────────────────
  final List<_PoleEntry> _poles = [];

  // ── Gallery ──────────────────────────────────────────────────────────────
  final Map<String, String?> _existingUrls = {};
  final Map<String, XFile?> _newFiles = {};
  final List<XFile> _d4NewImages = [];
  final List<String> _d4ExistingUrls = [];
  EnumSiteStatus? _siteStatus;

  // ── Load ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final model = await _service.getSite(widget.circuitId);
    if (model == null || !mounted) return;

    _circuitIdCtrl.text = model.circuitId;
    _startMeterController.text = model.cableDrumStart?.toString() ?? '';

    _endMeterController.text = model.cableDrumEnd?.toString() ?? '';
    _siteStatus = model.siteStatus;
    _customerNameCtrl.text = model.customerName ?? '';
    _lspNameCtrl.text = model.lspName ?? '';
    _customerLatCtrl.text = model.customerLat?.toString() ?? '';
    _customerLngCtrl.text = model.customerLng?.toString() ?? '';
    _workOrderDate = model.workOrderDateTime;
    _activationDate = model.activationDateTime;
    _surveyDate = model.surveyResultDateTime;
    _fatNameCtrl.text = model.fatName ?? '';
    _fatPortCtrl.text = model.fatPortNumber ?? '';
    _fatLatCtrl.text = model.fatLat?.toString() ?? '';
    _fatLngCtrl.text = model.fatLng?.toString() ?? '';
    _optFat1310Ctrl.text = model.opticalLevelFatPort1310nm?.toString() ?? '';
    _optFat1490Ctrl.text = model.opticalLevelFatPort1490nm?.toString() ?? '';
    _optAtb1310Ctrl.text = model.opticalLevelAtbPort1310nm?.toString() ?? '';
    _optAtb1490Ctrl.text = model.opticalLevelAtbPort1490nm?.toString() ?? '';
    _dropCableCtrl.text = model.dropCableLengthInMeter ?? '';
    _rowIssueCtrl.text = model.rowIssue ?? '';
    _ontSnCtrl.text = model.ontSnNumber ?? '';
    _splitterCtrl.text = model.splitterNo ?? '';
    _wifiSsidCtrl.text = model.wifiSsid ?? '';
    _msanCtrl.text = model.msan ?? '';
    _linkIdCtrl.text = model.linkId ?? '';
    _poleRangeCtrl.text = model.poleRange ?? '';
    _checkAreaCtrl.text = model.checkArea ?? '';
    _conclusionCtrl.text = model.conclusionAndComments ?? '';

    for (final p in model.poles ?? []) {
      _poles.add(_PoleEntry.fromModel(p));
    }

    final g = model.gallery;
    if (g != null) {
      _existingUrls.addAll({
        'an_node': g.anNode,
        'map_image': g.mapImage,
        'd1_1': g.d1_1,
        'd1_2': g.d1_2,
        'd2_1': g.d2_1,
        'd2_2': g.d2_2,
        'd3_1': g.d3_1,
        'd3_2': g.d3_2,
        'e1': g.e1,
        'e2': g.e2,
        'e3': g.e3,
        'e4_1': g.e4_1,
        'e4_2': g.e4_2,
        'e5': g.e5,
        'e6_1': g.e6_1,
        'e6_2': g.e6_2,
        'e6_3': g.e6_3,
        'f1': g.f1,
        'f2': g.f2,
        'f3': g.f3,
        'f4_1': g.f4_1,
        'f4_2': g.f4_2,
        'f5': g.f5,
        'f6_1': g.f6_1,
        'f6_2': g.f6_2,
      });
    }

    final d4 = model.gallery?.d4;
    if (d4 != null) {
      _d4ExistingUrls.addAll(d4);
    }

    setState(() => _loading = false);
  }

  // ── Image picker ──────────────────────────────────────────────────────────

  Future<XFile?> _pickImageFromSource(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.content_paste),
              title: const Text('Paste from clipboard'),
              onTap: () => Navigator.pop(context, 'paste'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return null;
    if (context.mounted) {
      if (choice == 'paste') return _readClipboardImage(context);
    }
    final src = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
    return _picker.pickImage(source: src, imageQuality: 80);
  }

  /// Reads an image from the system clipboard using super_clipboard.
  Future<XFile?> _readClipboardImage(BuildContext context) async {
    superPrint('start');
    final bytes = await waitForPaste();
    superPrint(bytes);

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    if (bytes != null) {
      return XFile.fromData(bytes);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image found. Try copying again.')),
        );
      }

      return null;
    }
  }

  Future<void> _pickGalleryImage(String key) async {
    final picked = await _pickImageFromSource(context);
    if (picked != null) setState(() => _newFiles[key] = picked);
  }

  Future<void> _pickPoleImage(int index) async {
    final picked = await _pickImageFromSource(context);
    if (picked != null) setState(() => _poles[index].newImage = picked);
  }

  Future<void> _pickD4Image() async {
    final picked = await _pickImageFromSource(context);
    if (picked != null) setState(() => _d4NewImages.add(picked));
  }

  // ── Photo slot ────────────────────────────────────────────────────────────

  Widget _photoSlot({
    required BuildContext context,
    required XFile? newFile,
    required String? existingUrl,
    required String label,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final hasNew = newFile != null;
    final hasExisting = existingUrl != null && existingUrl.isNotEmpty;

    Future<void> handleTap() async {
      if (!hasNew && !hasExisting) {
        onTap();
        return;
      }
      if (hasNew) {
        final bytes = await newFile.readAsBytes();
        if (context.mounted) openImageViewer(context: context, bytes: bytes, title: label);
        return;
      }
      if (hasExisting) openImageViewer(context: context, url: existingUrl, title: label);
    }

    return GestureDetector(
      onTap: handleTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 100, maxHeight: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasNew
                ? Colors.blue.shade300
                : hasExisting
                ? Colors.green.shade300
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: (hasNew || hasExisting)
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: hasNew
                        ? FutureBuilder<Uint8List>(
                            future: newFile.readAsBytes(),
                            builder: (context, snap) {
                              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                              return Image.memory(snap.data!, fit: BoxFit.contain);
                            },
                          )
                        : Image.network(existingUrl!, fit: BoxFit.contain),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasNew ? Colors.blue : Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        hasNew ? 'NEW' : 'SAVED',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo, color: Colors.grey),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _keyedPhotoSlot(String key, String label) {
    return _photoSlot(
      context: context,
      newFile: _newFiles[key],
      existingUrl: _existingUrls[key],
      label: label,
      onTap: () => _pickGalleryImage(key),
      onRemove: () => setState(() {
        _newFiles[key] = null;
        _existingUrls[key] = null;
      }),
    );
  }

  Widget _twoPhotoRow(String key1, String label1, String key2, String label2) {
    return Row(
      children: [
        Expanded(child: _keyedPhotoSlot(key1, label1)),
        const SizedBox(width: 8),
        Expanded(child: _keyedPhotoSlot(key2, label2)),
      ],
    );
  }

  // ── Form helpers ──────────────────────────────────────────────────────────

  Widget _labeledField(
    TextEditingController ctrl,
    String label, {
    TextInputType type = TextInputType.text,
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, void Function(DateTime) onPicked) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d == null) return;
    if (context.mounted) {
      final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (t == null) return;
      onPicked(DateTime(d.year, d.month, d.day, t.hour, t.minute));
    }
  }

  Widget _dateTile(String label, DateTime? value, void Function(DateTime) onPicked) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        value != null ? '${value.year}/${_pad(value.month)}/${_pad(value.day)}  ${_pad(value.hour)}:${_pad(value.minute)}' : 'Tap to set',
        style: TextStyle(color: value != null ? Colors.black87 : Colors.grey),
      ),
      trailing: const Icon(Icons.calendar_today, size: 18),
      onTap: () => _pickDate(context, onPicked),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final circuitId = widget.circuitId;

      final model = SiteDetailModel(circuitId: circuitId)
        ..siteStatus = _siteStatus
        ..customerName = _customerNameCtrl.text.trim().nullIfEmpty
        ..lspName = _lspNameCtrl.text.trim().nullIfEmpty
        ..customerLat = double.tryParse(_customerLatCtrl.text)
        ..customerLng = double.tryParse(_customerLngCtrl.text)
        ..workOrderDateTime = _workOrderDate
        ..activationDateTime = _activationDate
        ..surveyResultDateTime = _surveyDate
        ..fatName = _fatNameCtrl.text.trim().nullIfEmpty
        ..fatPortNumber = _fatPortCtrl.text.trim().nullIfEmpty
        ..fatLat = double.tryParse(_fatLatCtrl.text)
        ..fatLng = double.tryParse(_fatLngCtrl.text)
        ..opticalLevelFatPort1310nm = double.tryParse(_optFat1310Ctrl.text)
        ..opticalLevelFatPort1490nm = double.tryParse(_optFat1490Ctrl.text)
        ..opticalLevelAtbPort1310nm = double.tryParse(_optAtb1310Ctrl.text)
        ..opticalLevelAtbPort1490nm = double.tryParse(_optAtb1490Ctrl.text)
        ..dropCableLengthInMeter = _dropCableCtrl.text.trim().nullIfEmpty
        ..cableDrumStart = double.tryParse(_startMeterController.text.trim())
        ..cableDrumEnd = double.tryParse(_endMeterController.text.trim())
        ..rowIssue = _rowIssueCtrl.text.trim().nullIfEmpty
        ..ontSnNumber = _ontSnCtrl.text.trim().nullIfEmpty
        ..splitterNo = _splitterCtrl.text.trim().nullIfEmpty
        ..wifiSsid = _wifiSsidCtrl.text.trim().nullIfEmpty
        ..msan = _msanCtrl.text.trim().nullIfEmpty
        ..linkId = _linkIdCtrl.text.trim().nullIfEmpty
        ..poleRange = _poleRangeCtrl.text.trim().nullIfEmpty
        ..checkArea = _checkAreaCtrl.text.trim().nullIfEmpty
        ..conclusionAndComments = _conclusionCtrl.text.trim().nullIfEmpty;

      final gallery = SiteGalleryModel(circuitId: circuitId);
      const allKeys = {
        'an_node',
        'map_image',
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
      };

      for (final key in allKeys) {
        final newFile = _newFiles[key];
        final existingUrl = _existingUrls[key];
        String? finalUrl;
        if (newFile != null) {
          finalUrl = await _storage.uploadImage(
            circuitId: circuitId,
            bytes: await newFile.readAsBytes(),
            folder: key,
          );
        } else {
          finalUrl = existingUrl;
        }
        _setGalleryUrl(gallery, key, finalUrl);
      }

      final d4Urls = List<String>.from(_d4ExistingUrls);
      for (int i = 0; i < _d4NewImages.length; i++) {
        final url = await _storage.uploadImage(
          circuitId: circuitId,
          bytes: await _d4NewImages[i].readAsBytes(),
          folder: 'd4_${(d4Urls.length + i + 1).toString().padLeft(3, '0')}',
        );
        d4Urls.add(url);
      }
      gallery.d4 = d4Urls.isEmpty ? null : d4Urls;
      model.gallery = gallery;

      model.poles = await Future.wait(
        _poles.asMap().entries.map((e) async {
          final index = e.key;
          final p = e.value;
          String? imageUrl;
          if (p.newImage != null) {
            imageUrl = await _storage.uploadImage(
              circuitId: circuitId,
              bytes: await p.newImage!.readAsBytes(),
              folder: 'pole_${(index + 1).toString().padLeft(3, '0')}',
            );
          } else {
            imageUrl = p.existingImageUrl;
          }
          return SitePoleModel(
            id: p.existingId,
            circuitId: circuitId,
            enumPoleType: p.type,
            lat: double.tryParse(p.latCtrl.text),
            lng: double.tryParse(p.lngCtrl.text),
            image: imageUrl,
          );
        }),
      );

      await _repo.saveSite(model);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setGalleryUrl(SiteGalleryModel g, String key, String? url) {
    switch (key) {
      case 'an_node':
        g.anNode = url;
        break;
      case 'd1_1':
        g.d1_1 = url;
        break;
      case 'd1_2':
        g.d1_2 = url;
        break;
      case 'd2_1':
        g.d2_1 = url;
        break;
      case 'd2_2':
        g.d2_2 = url;
        break;
      case 'd3_1':
        g.d3_1 = url;
        break;
      case 'd3_2':
        g.d3_2 = url;
        break;
      case 'e1':
        g.e1 = url;
        break;
      case 'e2':
        g.e2 = url;
        break;
      case 'e3':
        g.e3 = url;
        break;
      case 'e4_1':
        g.e4_1 = url;
        break;
      case 'e4_2':
        g.e4_2 = url;
        break;
      case 'e5':
        g.e5 = url;
        break;
      case 'e6_1':
        g.e6_1 = url;
        break;
      case 'e6_2':
        g.e6_2 = url;
        break;
      case 'e6_3':
        g.e6_3 = url;
        break;
      case 'f1':
        g.f1 = url;
        break;
      case 'f2':
        g.f2 = url;
        break;
      case 'f3':
        g.f3 = url;
        break;
      case 'f4_1':
        g.f4_1 = url;
        break;
      case 'f4_2':
        g.f4_2 = url;
        break;
      case 'f5':
        g.f5 = url;
        break;
      case 'f6_1':
        g.f6_1 = url;
        break;
      case 'f6_2':
        g.f6_2 = url;
        break;
      case 'map_image':
        g.mapImage = url;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.grey)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.circuitId, style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              ),
            )
          else
            IconButton(onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _sectionA(),
          _sectionB(),
          _sectionC(),
          _sectionD(),
          _sectionE(),
          _sectionF(),
          _sectionG(),
        ],
      ),
    );
  }

  // ── A ─────────────────────────────────────────────────────────────────────

  Widget _sectionA() {
    return SectionCard(
      title: 'A  Circuit ID Information',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _circuitIdCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Circuit ID',
                border: const OutlineInputBorder(),
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade100,
                suffixIcon: const Icon(Icons.lock, size: 16, color: Colors.grey),
              ),
            ),
          ),
          _labeledField(_customerNameCtrl, 'Customer Name'),
          _labeledField(_lspNameCtrl, 'LSP Name'),
          Row(
            children: [
              Expanded(child: _labeledField(_customerLatCtrl, 'Cust. Lat', type: const TextInputType.numberWithOptions(decimal: true, signed: true))),
              const SizedBox(width: 8),
              Expanded(child: _labeledField(_customerLngCtrl, 'Cust. Long', type: const TextInputType.numberWithOptions(decimal: true, signed: true))),
            ],
          ),
          _dateTile('Work Order Date/Time', _workOrderDate, (d) => setState(() => _workOrderDate = d)),
          _dateTile('Activation Date', _activationDate, (d) => setState(() => _activationDate = d)),
          const SizedBox(height: 4),
          DropdownButtonFormField<EnumSiteStatus>(
            initialValue: _siteStatus,
            decoration: const InputDecoration(
              labelText: 'Site Status',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: EnumSiteStatus.values
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Row(
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
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _siteStatus = v),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── B ─────────────────────────────────────────────────────────────────────

  Widget _sectionB() {
    return SectionCard(
      title: 'B  Site / FAT Information',
      child: Column(
        children: [
          _dateTile('Survey Result Date', _surveyDate, (d) => setState(() => _surveyDate = d)),
          _labeledField(_fatNameCtrl, 'FAT Name', hint: 'e.g. YGN-TKI1302-8'),
          _labeledField(_fatPortCtrl, 'FAT Port Number', hint: 'e.g. Port-5'),
          Row(
            children: [
              Expanded(child: _labeledField(_fatLatCtrl, 'FAT Lat', type: const TextInputType.numberWithOptions(decimal: true, signed: true))),
              const SizedBox(width: 8),
              Expanded(child: _labeledField(_fatLngCtrl, 'FAT Long', type: const TextInputType.numberWithOptions(decimal: true, signed: true))),
            ],
          ),
          const Text('Optical Level at FAT Port', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _labeledField(_optFat1310Ctrl, '1310nm (dBm)', type: const TextInputType.numberWithOptions(decimal: true, signed: true))),
              const SizedBox(width: 8),
              Expanded(child: _labeledField(_optFat1490Ctrl, '1490nm (dBm)', type: const TextInputType.numberWithOptions(decimal: true, signed: true))),
            ],
          ),
          const Text('Optical Level at ATB Port', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _labeledField(_optAtb1310Ctrl, '1310nm (dBm)', type: const TextInputType.numberWithOptions(decimal: true, signed: true))),
              const SizedBox(width: 8),
              Expanded(child: _labeledField(_optAtb1490Ctrl, '1490nm (dBm)', type: const TextInputType.numberWithOptions(decimal: true, signed: true))),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _labeledField(_startMeterController, 'Start Meter', hint: ''),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: _labeledField(_endMeterController, 'End Meter', hint: ''),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: _labeledField(_dropCableCtrl, 'Drop Cable Length (m)', type: TextInputType.number),
              ),
            ],
          ),
          _labeledField(_rowIssueCtrl, 'ROW Issue', hint: 'No Issue'),
        ],
      ),
    );
  }

  // ── C: Poles ──────────────────────────────────────────────────────────────

  Widget _sectionC() {
    return SectionCard(
      title: 'C  Cable Route / Poles',
      child: Column(
        children: [
          ..._poles.asMap().entries.map((e) => _poleRow(e.key, e.value)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => setState(() => _poles.add(_PoleEntry())),
            icon: const Icon(Icons.add),
            label: const Text('Add Pole'),
          ),
        ],
      ),
    );
  }

  Widget _poleRow(int index, _PoleEntry entry) {
    final poleLabel = 'P_${(index + 1).toString().padLeft(3, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(poleLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => setState(() => _poles.removeAt(index)),
              ),
            ],
          ),
          DropdownButtonFormField<EnumPoleType>(
            initialValue: entry.type,
            decoration: const InputDecoration(
              labelText: 'Pole Type',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: EnumPoleType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => entry.type = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: entry.latCtrl,
                  decoration: const InputDecoration(labelText: 'Latitude', isDense: true, border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: entry.lngCtrl,
                  decoration: const InputDecoration(labelText: 'Longitude', isDense: true, border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Pole Photo',
            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          _photoSlot(
            context: context,
            newFile: entry.newImage,
            existingUrl: entry.existingImageUrl,
            label: 'Tap to add $poleLabel photo',
            onTap: () => _pickPoleImage(index),
            onRemove: () => setState(() {
              _poles[index].newImage = null;
              _poles[index].existingImageUrl = null;
            }),
          ),
        ],
      ),
    );
  }

  // ── D ─────────────────────────────────────────────────────────────────────

  Widget _sectionD() {
    return SectionCard(
      title: 'D  Onsite Installation – FAT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SubLabel('AN  Node photo'),
          _keyedPhotoSlot('an_node', 'AN Node'),
          const SizedBox(height: 12),
          const _SubLabel('Map Image'),
          _keyedPhotoSlot('map_image', 'Map Image'),
          const _SubLabel('D1  FAT before installation'),
          _twoPhotoRow('d1_1', 'FAT Closed', 'd1_2', 'FAT Open'),
          const SizedBox(height: 12),
          const _SubLabel('D2  FAT after installation'),
          _twoPhotoRow('d2_1', 'View 1', 'd2_2', 'View 2'),
          const SizedBox(height: 12),
          const _SubLabel('D3  Cable label inside FAT'),
          _twoPhotoRow('d3_1', 'Label 1', 'd3_2', 'Label 2'),
          const SizedBox(height: 12),
          const _SubLabel('D4  Accessories (clamp / hook / buckle)'),
          ..._d4ExistingUrls.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _photoSlot(
                context: context,
                newFile: null,
                existingUrl: e.value,
                label: 'Accessories photo ${e.key + 1}',
                onTap: () {},
                onRemove: () => setState(() => _d4ExistingUrls.removeAt(e.key)),
              ),
            ),
          ),
          ..._d4NewImages.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _photoSlot(
                context: context,
                newFile: e.value,
                existingUrl: null,
                label: 'New accessories photo ${e.key + 1}',
                onTap: () {},
                onRemove: () => setState(() => _d4NewImages.removeAt(e.key)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _pickD4Image,
            icon: const Icon(Icons.add_a_photo, size: 16),
            label: const Text('Add D4 Photo'),
          ),
        ],
      ),
    );
  }

  // ── E ─────────────────────────────────────────────────────────────────────

  Widget _sectionE() {
    return SectionCard(
      title: 'E  Onsite Installation – Customer Site',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SubLabel('E1  Outdoor cable (include FAT in frame)'),
          _keyedPhotoSlot('e1', 'Outdoor cable route'),
          const SizedBox(height: 12),
          const _SubLabel('E2  Customer home entrance cable'),
          _keyedPhotoSlot('e2', 'Home entrance'),
          const SizedBox(height: 12),
          const _SubLabel('E3  Indoor cable (entrance → ATB)'),
          _keyedPhotoSlot('e3', 'Indoor cable'),
          const SizedBox(height: 12),
          const _SubLabel('E4  Cable coils'),
          _twoPhotoRow('e4_1', 'At customer side', 'e4_2', 'At FAT side'),
          const SizedBox(height: 12),
          const _SubLabel('E5  ATB'),
          _keyedPhotoSlot('e5', 'ATB photo'),
          const SizedBox(height: 12),
          const _SubLabel('E6  Other remarks'),
          Row(
            children: [
              Expanded(child: _keyedPhotoSlot('e6_1', 'Photo 1')),
              const SizedBox(width: 8),
              Expanded(child: _keyedPhotoSlot('e6_2', 'Photo 2')),
              const SizedBox(width: 8),
              Expanded(child: _keyedPhotoSlot('e6_3', 'Photo 3')),
            ],
          ),
        ],
      ),
    );
  }

  // ── F ─────────────────────────────────────────────────────────────────────

  Widget _sectionF() {
    return SectionCard(
      title: 'F  ONT Test & Service Test',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labeledField(_ontSnCtrl, 'ONT S/N Number', hint: 'e.g. 4857544307DD03AE'),
          _labeledField(_splitterCtrl, 'Splitter No'),
          _labeledField(_wifiSsidCtrl, 'WiFi SSID'),
          _labeledField(_msanCtrl, 'MSAN No'),
          const SizedBox(height: 4),
          const _SubLabel('F1  ONT device photo'),
          _keyedPhotoSlot('f1', 'ONT device'),
          const SizedBox(height: 12),
          const _SubLabel('F2  ONT S/N label'),
          _keyedPhotoSlot('f2', 'S/N sticker'),
          const SizedBox(height: 12),
          const _SubLabel('F3  ONT install environment'),
          _keyedPhotoSlot('f3', 'Install environment'),
          const SizedBox(height: 12),
          const _SubLabel('F4  Ping test'),
          _twoPhotoRow('f4_1', 'Ping screen 1', 'f4_2', 'Ping screen 2'),
          const SizedBox(height: 12),
          const _SubLabel('F5  Speed test'),
          _keyedPhotoSlot('f5', 'Speed test result'),
          const SizedBox(height: 12),
          const _SubLabel('F6  Call / IPTV test'),
          _twoPhotoRow('f6_1', 'Call test 1', 'f6_2', 'Call test 2'),
        ],
      ),
    );
  }

  // ── G ─────────────────────────────────────────────────────────────────────

  Widget _sectionG() {
    return SectionCard(
      title: 'G  Cable Laying Check-list',
      child: Column(
        children: [
          _labeledField(_linkIdCtrl, 'Link ID'),
          _labeledField(_poleRangeCtrl, 'Check Area (Pole Range)', hint: 'e.g. P_001 to P_003'),
          _labeledField(_checkAreaCtrl, 'Check Area Note', maxLines: 2),
          _labeledField(_conclusionCtrl, 'Conclusion & Comments', maxLines: 4),
        ],
      ),
    );
  }
}

// ── Pole entry ────────────────────────────────────────────────────────────────

class _PoleEntry {
  String? existingId;
  EnumPoleType? type;
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();
  String? existingImageUrl;
  XFile? newImage;

  _PoleEntry();

  factory _PoleEntry.fromModel(SitePoleModel p) {
    return _PoleEntry()
      ..existingId = p.id
      ..type = p.enumPoleType ?? EnumPoleType.other
      ..latCtrl.text = p.lat?.toString() ?? ''
      ..lngCtrl.text = p.lng?.toString() ?? ''
      ..existingImageUrl = p.image;
  }
}

// ── Sub-section label ─────────────────────────────────────────────────────────

class _SubLabel extends StatelessWidget {
  final String text;
  const _SubLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
      ),
    );
  }
}

extension _StringExt on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
