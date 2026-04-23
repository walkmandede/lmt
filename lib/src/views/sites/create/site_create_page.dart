import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lmt/core/repositories/site_repository.dart';
import 'package:lmt/core/services/site_service.dart';
import 'package:lmt/core/services/storage_service.dart';
import 'package:lmt/src/models/site_detail_model.dart';
import 'package:lmt/src/views/_widgets/image_viewer_page.dart';
import 'package:lmt/src/views/_widgets/section_card.dart';

class SiteCreatePage extends StatefulWidget {
  const SiteCreatePage({super.key});

  @override
  State<SiteCreatePage> createState() => _SiteCreatePageState();
}

class _SiteCreatePageState extends State<SiteCreatePage> {
  final _picker = ImagePicker();
  final _storage = StorageService();
  final _repo = SiteRepository(SupabaseSiteService());

  bool _saving = false;

  // ── A: Circuit Info ──────────────────────────────────────────────────────
  final _circuitIdCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();
  final _lspNameCtrl = TextEditingController(text: 'Galaxia @ Net CO.,LTD');
  final _customerLatCtrl = TextEditingController();
  final _customerLngCtrl = TextEditingController();
  DateTime? _workOrderDate;
  DateTime? _activationDate;

  // ── B: Site / FAT Info ───────────────────────────────────────────────────
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

  // ── G: Pole check-list ───────────────────────────────────────────────────
  final _checkAreaCtrl = TextEditingController();
  final _conclusionCtrl = TextEditingController();

  // ── Poles (C) ────────────────────────────────────────────────────────────
  final List<_PoleEntry> _poles = [];

  // ── Gallery ──────────────────────────────────────────────────────────────
  final Map<String, XFile?> _gallery = {};
  final List<XFile> _d4Images = [];

  // ── Image picker ─────────────────────────────────────────────────────────

  Future<XFile?> _pickImageFromSource() async {
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
    if (choice == 'paste') return null; // clipboard not implemented in create
    final src = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
    return _picker.pickImage(source: src, imageQuality: 80);
  }

  Future<void> _pickGalleryImage(String key) async {
    final picked = await _pickImageFromSource();
    if (picked != null) setState(() => _gallery[key] = picked);
  }

  Future<void> _pickD4Image() async {
    final picked = await _pickImageFromSource();
    if (picked != null) setState(() => _d4Images.add(picked));
  }

  Future<void> _pickPoleImage(int index) async {
    final picked = await _pickImageFromSource();
    if (picked != null) setState(() => _poles[index].image = picked);
  }

  // ── Shared photo slot widget ──────────────────────────────────────────────

  Widget _photoSlot({
    required BuildContext context,
    required XFile? file,
    required String label,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: () async {
        if (file == null) {
          onTap();
          return;
        }
        final bytes = await file.readAsBytes();
        if (context.mounted) {
          openImageViewer(context: context, bytes: bytes, title: label);
        }
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 100, maxHeight: 200),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade100,
        ),
        child: file != null
            ? FutureBuilder<Uint8List>(
                future: file.readAsBytes(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(snap.data!, fit: BoxFit.contain),
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
                  );
                },
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
      file: _gallery[key],
      label: label,
      onTap: () => _pickGalleryImage(key),
      onRemove: () => setState(() => _gallery[key] = null),
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

  // ── SAVE ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final circuitId = _circuitIdCtrl.text.trim();
    if (circuitId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Circuit ID is required')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final model = SiteDetailModel(circuitId: circuitId)
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

      // All keyed gallery images (includes map_image, an_node, d*, e*, f*)
      for (final key in _gallery.keys) {
        final file = _gallery[key];
        if (file == null) continue;
        final url = await _storage.uploadImage(
          circuitId: circuitId,
          bytes: await file.readAsBytes(),
          folder: key,
        );
        _setGalleryUrl(gallery, key, url);
      }

      // D4 dynamic list
      final d4Urls = <String>[];
      for (int i = 0; i < _d4Images.length; i++) {
        final url = await _storage.uploadImage(
          circuitId: circuitId,
          bytes: await _d4Images[i].readAsBytes(),
          folder: 'd4_${(i + 1).toString().padLeft(3, '0')}',
        );
        d4Urls.add(url);
      }
      gallery.d4 = d4Urls.isEmpty ? null : d4Urls;

      model.gallery = gallery;

      // Poles
      model.poles = await Future.wait(
        _poles.asMap().entries.map((e) async {
          final index = e.key;
          final p = e.value;
          String? imageUrl;
          if (p.image != null) {
            imageUrl = await _storage.uploadImage(
              circuitId: circuitId,
              bytes: await p.image!.readAsBytes(),
              folder: 'pole_${(index + 1).toString().padLeft(3, '0')}',
            );
          }
          return SitePoleModel(
            circuitId: circuitId,
            enumPoleType: p.type,
            lat: double.tryParse(p.latCtrl.text),
            lng: double.tryParse(p.lngCtrl.text),
            image: imageUrl,
          );
        }),
      );

      // ── FAT → 1st pole sync (Create) ─────────────────────────────────────
      final fatLat = model.fatLat;
      final fatLng = model.fatLng;
      if (fatLat != null && fatLng != null) {
        // Case 1: FAT location provided — prepend MPT pole at index 0
        final fatPole = SitePoleModel(
          circuitId: circuitId,
          enumPoleType: EnumPoleType.mpt,
          lat: fatLat,
          lng: fatLng,
        );
        model.poles = [fatPole, ...?model.poles];
      }
      // ─────────────────────────────────────────────────────────────────────

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
      case 'map_image':
        g.mapImage = url;
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
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Site'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
          _labeledField(_circuitIdCtrl, 'Circuit ID *', hint: 'e.g. FTTH-323412-TKI-BC'),
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
          _labeledField(_dropCableCtrl, 'Drop Cable Length (m)', type: TextInputType.number),
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
            decoration: const InputDecoration(labelText: 'Pole Type', isDense: true, border: OutlineInputBorder()),
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
            file: entry.image,
            label: 'Tap to add $poleLabel photo',
            onTap: () => _pickPoleImage(index),
            onRemove: () => setState(() => _poles[index].image = null),
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
          // ── Map Image ──────────────────────────────────────────────────────
          const _SubLabel('Map Image'),
          _keyedPhotoSlot('map_image', 'Map / Route screenshot'),
          const SizedBox(height: 12),
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
          ..._d4Images.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _photoSlot(
                context: context,
                file: e.value,
                label: 'Accessories photo ${e.key + 1}',
                onTap: () {},
                onRemove: () => setState(() => _d4Images.removeAt(e.key)),
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
  EnumPoleType? type = EnumPoleType.other;
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();
  XFile? image;
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
