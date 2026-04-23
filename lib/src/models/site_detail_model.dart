import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum EnumPoleType { epc, mpt, other }

enum EnumSiteStatus {
  newAssigned,
  cablingOngoing,
  cablingDone,
  activation,
  qcRequest,
  qcRejected,
  completed,
}

extension EnumSiteStatusX on EnumSiteStatus {
  String get label => switch (this) {
    EnumSiteStatus.newAssigned => 'New Assigned',
    EnumSiteStatus.cablingOngoing => 'Cabling Ongoing',
    EnumSiteStatus.cablingDone => 'Cabling Done',
    EnumSiteStatus.activation => 'Activation',
    EnumSiteStatus.qcRequest => 'QC Request',
    EnumSiteStatus.qcRejected => 'QC Rejected',
    EnumSiteStatus.completed => 'Completed',
  };

  String get dbValue => switch (this) {
    EnumSiteStatus.newAssigned => 'new_assigned',
    EnumSiteStatus.cablingOngoing => 'cabling_ongoing',
    EnumSiteStatus.cablingDone => 'cabling_done',
    EnumSiteStatus.activation => 'activation',
    EnumSiteStatus.qcRequest => 'qc_request',
    EnumSiteStatus.qcRejected => 'qc_rejected',
    EnumSiteStatus.completed => 'completed',
  };

  Color get badgeColor => switch (this) {
    EnumSiteStatus.newAssigned => Colors.blue,
    EnumSiteStatus.cablingOngoing => Colors.orange,
    EnumSiteStatus.cablingDone => Colors.teal,
    EnumSiteStatus.activation => Colors.purple,
    EnumSiteStatus.qcRequest => Colors.amber.shade700,
    EnumSiteStatus.qcRejected => Colors.red,
    EnumSiteStatus.completed => Colors.green,
  };

  static EnumSiteStatus? fromDb(String? value) {
    for (final s in EnumSiteStatus.values) {
      if (s.dbValue == value) return s;
    }
    return null;
  }
}

class SitePoleModel {
  String? id;
  String? circuitId;
  EnumPoleType? enumPoleType;
  double? lat;
  double? lng;
  String? image;

  SitePoleModel({
    this.id,
    this.circuitId,
    this.enumPoleType,
    this.lat,
    this.lng,
    this.image,
  });

  factory SitePoleModel.fromJson(Map<String, dynamic> json) {
    return SitePoleModel(
      id: json['id'],
      circuitId: json['circuit_id'],
      enumPoleType: json['pole_type'] != null ? EnumPoleType.values.byName(json['pole_type']) : null,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      image: json['image'],
    );
  }

  bool get hasLocations => lat != null && lng != null;

  LatLng? get location => hasLocations ? LatLng(lat!, lng!) : null;

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'circuit_id': circuitId,
    'pole_type': enumPoleType?.name,
    'lat': lat,
    'lng': lng,
    'image': image,
  };

  SitePoleModel copyWith({
    String? id,
    String? circuitId,
    EnumPoleType? enumPoleType,
    double? lat,
    double? lng,
    String? image,
  }) {
    return SitePoleModel(
      id: id ?? this.id,
      circuitId: circuitId ?? this.circuitId,
      enumPoleType: enumPoleType ?? this.enumPoleType,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      image: image ?? this.image,
    );
  }
}

class SiteGalleryModel {
  String? circuitId;
  String? anNode;

  // ── Map image ─────────────────────────────────────────────────────────────
  String? mapImage;

  String? d1_1;
  String? d1_2;
  String? d2_1;
  String? d2_2;
  String? d3_1;
  String? d3_2;
  List<String>? d4;

  String? e1;
  String? e2;
  String? e3;
  String? e4_1;
  String? e4_2;
  String? e5;
  String? e6_1;
  String? e6_2;
  String? e6_3;

  String? f1;
  String? f2;
  String? f3;
  String? f4_1;
  String? f4_2;
  String? f5;
  String? f6_1;
  String? f6_2;

  SiteGalleryModel({this.circuitId});

  factory SiteGalleryModel.fromJson(Map<String, dynamic> json) {
    return SiteGalleryModel(circuitId: json['circuit_id'])
      ..anNode = json['an_node']
      ..mapImage = json['map_image']
      ..d1_1 = json['d1_1']
      ..d1_2 = json['d1_2']
      ..d2_1 = json['d2_1']
      ..d2_2 = json['d2_2']
      ..d3_1 = json['d3_1']
      ..d3_2 = json['d3_2']
      ..d4 = json['d4'] != null ? List<String>.from(json['d4']) : null
      ..e1 = json['e1']
      ..e2 = json['e2']
      ..e3 = json['e3']
      ..e4_1 = json['e4_1']
      ..e4_2 = json['e4_2']
      ..e5 = json['e5']
      ..e6_1 = json['e6_1']
      ..e6_2 = json['e6_2']
      ..e6_3 = json['e6_3']
      ..f1 = json['f1']
      ..f2 = json['f2']
      ..f3 = json['f3']
      ..f4_1 = json['f4_1']
      ..f4_2 = json['f4_2']
      ..f5 = json['f5']
      ..f6_1 = json['f6_1']
      ..f6_2 = json['f6_2'];
  }

  Map<String, dynamic> toJson() => {
    'an_node': anNode,
    'map_image': mapImage,
    'circuit_id': circuitId,
    'd1_1': d1_1,
    'd1_2': d1_2,
    'd2_1': d2_1,
    'd2_2': d2_2,
    'd3_1': d3_1,
    'd3_2': d3_2,
    'd4': d4,
    'e1': e1,
    'e2': e2,
    'e3': e3,
    'e4_1': e4_1,
    'e4_2': e4_2,
    'e5': e5,
    'e6_1': e6_1,
    'e6_2': e6_2,
    'e6_3': e6_3,
    'f1': f1,
    'f2': f2,
    'f3': f3,
    'f4_1': f4_1,
    'f4_2': f4_2,
    'f5': f5,
    'f6_1': f6_1,
    'f6_2': f6_2,
  };

  SiteGalleryModel copyWith({
    String? circuitId,
    String? anNode,
    String? mapImage,
    String? d1_1,
    String? d1_2,
    String? d2_1,
    String? d2_2,
    String? d3_1,
    String? d3_2,
    List<String>? d4,
    String? e1,
    String? e2,
    String? e3,
    String? e4_1,
    String? e4_2,
    String? e5,
    String? e6_1,
    String? e6_2,
    String? e6_3,
    String? f1,
    String? f2,
    String? f3,
    String? f4_1,
    String? f4_2,
    String? f5,
    String? f6_1,
    String? f6_2,
  }) {
    return SiteGalleryModel(circuitId: circuitId ?? this.circuitId)
      ..anNode = anNode ?? this.anNode
      ..mapImage = mapImage ?? this.mapImage
      ..d1_1 = d1_1 ?? this.d1_1
      ..d1_2 = d1_2 ?? this.d1_2
      ..d2_1 = d2_1 ?? this.d2_1
      ..d2_2 = d2_2 ?? this.d2_2
      ..d3_1 = d3_1 ?? this.d3_1
      ..d3_2 = d3_2 ?? this.d3_2
      ..d4 = d4 ?? this.d4
      ..e1 = e1 ?? this.e1
      ..e2 = e2 ?? this.e2
      ..e3 = e3 ?? this.e3
      ..e4_1 = e4_1 ?? this.e4_1
      ..e4_2 = e4_2 ?? this.e4_2
      ..e5 = e5 ?? this.e5
      ..e6_1 = e6_1 ?? this.e6_1
      ..e6_2 = e6_2 ?? this.e6_2
      ..e6_3 = e6_3 ?? this.e6_3
      ..f1 = f1 ?? this.f1
      ..f2 = f2 ?? this.f2
      ..f3 = f3 ?? this.f3
      ..f4_1 = f4_1 ?? this.f4_1
      ..f4_2 = f4_2 ?? this.f4_2
      ..f5 = f5 ?? this.f5
      ..f6_1 = f6_1 ?? this.f6_1
      ..f6_2 = f6_2 ?? this.f6_2;
  }
}

class SiteDetailModel {
  final String circuitId;
  EnumSiteStatus? siteStatus;

  double? customerLat;
  double? customerLng;
  DateTime? workOrderDateTime;
  DateTime? activationDateTime;

  String? surveyResult;
  DateTime? surveyResultDateTime;
  String? fatName;
  String? fatPortNumber;
  double? fatLat;
  double? fatLng;
  double? opticalLevelFatPort1310nm;
  double? opticalLevelFatPort1490nm;
  double? opticalLevelAtbPort1310nm;
  double? opticalLevelAtbPort1490nm;
  String? dropCableLengthInMeter;
  double? cableDrumStart;
  double? cableDrumEnd;
  String? rowIssue;

  String? customerName;
  String? lspName;
  String? ontSnNumber;
  String? splitterNo;
  String? wifiSsid;
  String? msan;
  String? linkId;
  String? poleRange;

  String? checkArea;
  String? conclusionAndComments;

  List<String>? updatedBy;
  DateTime? createdAt;
  DateTime? updatedAt;

  List<SitePoleModel>? poles;
  SiteGalleryModel? gallery;

  SiteDetailModel({
    required this.circuitId,
    this.siteStatus,
    this.activationDateTime,
    this.opticalLevelFatPort1310nm,
    this.opticalLevelFatPort1490nm,
    this.opticalLevelAtbPort1310nm,
    this.opticalLevelAtbPort1490nm,
    this.dropCableLengthInMeter,
    this.ontSnNumber,
    this.splitterNo,
    this.fatPortNumber,
    this.cableDrumStart,
    this.cableDrumEnd,
    this.fatName,
    this.customerName,
  });

  LatLng? get fatLatLng => (fatLat != null && fatLng != null) ? LatLng(fatLat!, fatLng!) : null;

  LatLng? get customerLatLng => (customerLat != null && customerLng != null) ? LatLng(customerLat!, customerLng!) : null;

  bool get hasLocations => fatLatLng != null && customerLatLng != null;

  bool get hasPole => (poles ?? []).isNotEmpty;

  bool get canDrawPolyLine {
    int count = 0;
    if (customerLatLng != null) count++;
    if (fatLatLng != null) count++;

    for (final pole in (poles ?? [])) {
      if (pole.hasLocations) count++;
    }

    return count > 1;
  }

  String? _formatCoord(double? value) {
    if (value == null) return null;
    return value.toStringAsFixed(6);
  }

  // Customer
  String? get customerLatLabel => _formatCoord(customerLat);
  String? get customerLngLabel => _formatCoord(customerLng);

  // FAT
  String? get fatLatLabel => _formatCoord(fatLat);
  String? get fatLngLabel => _formatCoord(fatLng);

  factory SiteDetailModel.fromJson(Map<String, dynamic> json) {
    return SiteDetailModel(circuitId: json['circuit_id'])
      ..siteStatus = EnumSiteStatusX.fromDb(json['site_status'])
      ..customerName = json['customer_name']
      ..lspName = json['lsp_name']
      ..surveyResult = json['survey_result']
      ..surveyResultDateTime = json['survey_result_datetime'] != null ? DateTime.tryParse(json['survey_result_datetime']) : null
      ..customerLat = (json['customer_lat'] as num?)?.toDouble()
      ..customerLng = (json['customer_lng'] as num?)?.toDouble()
      ..workOrderDateTime = json['work_order_datetime'] != null ? DateTime.tryParse(json['work_order_datetime']) : null
      ..activationDateTime = json['activation_datetime'] != null ? DateTime.tryParse(json['activation_datetime']) : null
      ..fatName = json['fat_name']
      ..fatPortNumber = json['fat_port_number']
      ..fatLat = (json['fat_lat'] as num?)?.toDouble()
      ..fatLng = (json['fat_lng'] as num?)?.toDouble()
      ..opticalLevelFatPort1310nm = (json['optical_level_fat_port_1310nm'] as num?)?.toDouble()
      ..opticalLevelFatPort1490nm = (json['optical_level_fat_port_1490nm'] as num?)?.toDouble()
      ..opticalLevelAtbPort1310nm = (json['optical_level_atb_port_1310nm'] as num?)?.toDouble()
      ..opticalLevelAtbPort1490nm = (json['optical_level_atb_port_1490nm'] as num?)?.toDouble()
      ..dropCableLengthInMeter = json['drop_cable_length']
      ..cableDrumStart = (json['cable_drum_start'] as num?)?.toDouble()
      ..cableDrumEnd = (json['cable_drum_end'] as num?)?.toDouble()
      ..rowIssue = json['row_issue']
      ..ontSnNumber = json['ont_sn_number']
      ..splitterNo = json['splitter_no']
      ..wifiSsid = json['wifi_ssid']
      ..msan = json['msan']
      ..linkId = json['link_id']
      ..poleRange = json['pole_range']
      ..checkArea = json['check_area']
      ..conclusionAndComments = json['conclusion']
      ..updatedBy = json['updated_by'] != null ? List<String>.from(json['updated_by']) : null
      ..createdAt = json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null
      ..updatedAt = json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null;
  }

  Map<String, dynamic> toJson() => {
    'circuit_id': circuitId,
    'site_status': siteStatus?.dbValue,
    'customer_name': customerName,
    'lsp_name': lspName,
    'survey_result': surveyResult,
    'survey_result_datetime': surveyResultDateTime?.toIso8601String(),
    'customer_lat': customerLat,
    'customer_lng': customerLng,
    'work_order_datetime': workOrderDateTime?.toIso8601String(),
    'activation_datetime': activationDateTime?.toIso8601String(),
    'fat_name': fatName,
    'fat_port_number': fatPortNumber,
    'fat_lat': fatLat,
    'fat_lng': fatLng,
    'optical_level_fat_port_1310nm': opticalLevelFatPort1310nm,
    'optical_level_fat_port_1490nm': opticalLevelFatPort1490nm,
    'optical_level_atb_port_1310nm': opticalLevelAtbPort1310nm,
    'optical_level_atb_port_1490nm': opticalLevelAtbPort1490nm,
    'drop_cable_length': dropCableLengthInMeter,
    'cable_drum_start': cableDrumStart,
    'cable_drum_end': cableDrumEnd,
    'row_issue': rowIssue,
    'ont_sn_number': ontSnNumber,
    'splitter_no': splitterNo,
    'wifi_ssid': wifiSsid,
    'msan': msan,
    'link_id': linkId,
    'pole_range': poleRange,
    'check_area': checkArea,
    'conclusion': conclusionAndComments,
    'updated_by': updatedBy,
    'updated_at': DateTime.now().toIso8601String(),
  };

  SiteDetailModel copyWith({
    String? circuitId,
    EnumSiteStatus? siteStatus,
    double? customerLat,
    double? customerLng,
    DateTime? workOrderDateTime,
    DateTime? activationDateTime,
    String? surveyResult,
    DateTime? surveyResultDateTime,
    String? fatName,
    String? fatPortNumber,
    double? fatLat,
    double? fatLng,
    double? opticalLevelFatPort1310nm,
    double? opticalLevelFatPort1490nm,
    double? opticalLevelAtbPort1310nm,
    double? opticalLevelAtbPort1490nm,
    String? dropCableLengthInMeter,
    double? cableDrumStart,
    double? cableDrumEnd,
    String? rowIssue,
    String? customerName,
    String? lspName,
    String? ontSnNumber,
    String? splitterNo,
    String? wifiSsid,
    String? msan,
    String? linkId,
    String? poleRange,
    String? checkArea,
    String? conclusionAndComments,
    List<String>? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SitePoleModel>? poles,
    SiteGalleryModel? gallery,
  }) {
    return SiteDetailModel(
        circuitId: circuitId ?? this.circuitId,
        activationDateTime: activationDateTime ?? this.activationDateTime,
        opticalLevelFatPort1310nm: opticalLevelFatPort1310nm ?? this.opticalLevelFatPort1310nm,
        opticalLevelFatPort1490nm: opticalLevelFatPort1490nm ?? this.opticalLevelFatPort1490nm,
        opticalLevelAtbPort1310nm: opticalLevelAtbPort1310nm ?? this.opticalLevelAtbPort1310nm,
        opticalLevelAtbPort1490nm: opticalLevelAtbPort1490nm ?? this.opticalLevelAtbPort1490nm,
        dropCableLengthInMeter: dropCableLengthInMeter ?? this.dropCableLengthInMeter,
        ontSnNumber: ontSnNumber ?? this.ontSnNumber,
        splitterNo: splitterNo ?? this.splitterNo,
        fatPortNumber: fatPortNumber ?? this.fatPortNumber,
        cableDrumStart: cableDrumStart ?? this.cableDrumStart,
        cableDrumEnd: cableDrumEnd ?? this.cableDrumEnd,
        fatName: fatName ?? this.fatName,
        customerName: customerName ?? this.customerName,
      )
      ..siteStatus = siteStatus ?? this.siteStatus
      ..customerLat = customerLat ?? this.customerLat
      ..customerLng = customerLng ?? this.customerLng
      ..workOrderDateTime = workOrderDateTime ?? this.workOrderDateTime
      ..surveyResult = surveyResult ?? this.surveyResult
      ..surveyResultDateTime = surveyResultDateTime ?? this.surveyResultDateTime
      ..fatLat = fatLat ?? this.fatLat
      ..fatLng = fatLng ?? this.fatLng
      ..rowIssue = rowIssue ?? this.rowIssue
      ..lspName = lspName ?? this.lspName
      ..wifiSsid = wifiSsid ?? this.wifiSsid
      ..msan = msan ?? this.msan
      ..linkId = linkId ?? this.linkId
      ..poleRange = poleRange ?? this.poleRange
      ..checkArea = checkArea ?? this.checkArea
      ..conclusionAndComments = conclusionAndComments ?? this.conclusionAndComments
      ..updatedBy = updatedBy ?? this.updatedBy
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt
      ..poles = poles ?? this.poles
      ..gallery = gallery ?? this.gallery;
  }
}
