import 'package:latlong2/latlong.dart';

enum Risk { high, medium, low }

enum Stage { detection, verification, measures, prosecutor, court, execution }

enum UserRole { prosecutor, cadastre, agro, enforcement }

enum SignalStatus {
  fresh,
  accepted,
  verifying,
  rejected,
  confirmed,
  underProsecutor,
  inCourt,
  executing,
  completed,
  formal,
  overdue,
}

enum WorkflowAction {
  accept,
  chooseMethod,
  reject,
  confirm,
  recordMeasure,
  requestDocuments,
  legalAssessment,
  issueProtest,
  issueSubmission,
  issueWarning,
  requestMoreInspection,
  fileClaim,
  courtDecision,
  appeal,
  startExecution,
  verifyExecution,
}

class Evidence {
  const Evidence({
    required this.name,
    required this.kind,
    required this.path,
    required this.at,
    required this.by,
  });
  final String name;
  final String kind;
  final String path;
  final DateTime at;
  final UserRole by;
  Map<String, Object?> toJson() => {
    'name': name,
    'kind': kind,
    'path': path,
    'at': at.toIso8601String(),
    'by': by.name,
  };
  factory Evidence.fromJson(Map<String, dynamic> json) => Evidence(
    name: json['name'] as String,
    kind: json['kind'] as String,
    path: json['path'] as String,
    at: DateTime.parse(json['at'] as String),
    by: UserRole.values.byName(json['by'] as String),
  );
}

class TimelineEvent {
  const TimelineEvent({
    required this.title,
    required this.at,
    required this.actor,
    this.note = '',
  });
  final String title;
  final DateTime at;
  final String actor;
  final String note;
  Map<String, Object?> toJson() => {
    'title': title,
    'at': at.toIso8601String(),
    'actor': actor,
    'note': note,
  };
  factory TimelineEvent.fromJson(Map<String, dynamic> json) => TimelineEvent(
    title: json['title'] as String,
    at: DateTime.parse(json['at'] as String),
    actor: json['actor'] as String,
    note: (json['note'] as String?) ?? '',
  );
}

class RiskSignal {
  const RiskSignal({
    required this.id,
    required this.title,
    required this.address,
    required this.region,
    required this.cadastral,
    required this.area,
    required this.location,
    required this.risk,
    required this.score,
    required this.status,
    required this.stage,
    required this.detectedAt,
    required this.deadline,
    required this.description,
    required this.category,
    required this.owner,
    required this.permittedUse,
    required this.assignedAgency,
    this.method,
    this.legalAnalysis,
    this.claimNumber,
    this.caseNumber,
    this.executionNumber,
    this.courtOutcome,
    this.appealFiled = false,
    this.damage = 0,
    this.recovered = 0,
    this.detailed = false,
    this.scenarioNumber,
    this.events = const [],
    this.evidence = const [],
  });
  final String id,
      title,
      address,
      region,
      cadastral,
      description,
      category,
      owner,
      permittedUse,
      assignedAgency;
  final LatLng location;
  final double area, damage, recovered;
  final int score;
  final Risk risk;
  final SignalStatus status;
  final Stage stage;
  final DateTime detectedAt, deadline;
  final String? method, legalAnalysis, claimNumber, caseNumber, executionNumber;
  final String? courtOutcome;
  final bool appealFiled;
  final bool detailed;
  final int? scenarioNumber;
  final List<TimelineEvent> events;
  final List<Evidence> evidence;

  RiskSignal copyWith({
    SignalStatus? status,
    Stage? stage,
    DateTime? deadline,
    String? method,
    String? legalAnalysis,
    String? claimNumber,
    String? caseNumber,
    String? executionNumber,
    String? courtOutcome,
    bool? appealFiled,
    double? recovered,
    List<TimelineEvent>? events,
    List<Evidence>? evidence,
  }) => RiskSignal(
    id: id,
    title: title,
    address: address,
    region: region,
    cadastral: cadastral,
    area: area,
    location: location,
    risk: risk,
    score: score,
    status: status ?? this.status,
    stage: stage ?? this.stage,
    detectedAt: detectedAt,
    deadline: deadline ?? this.deadline,
    description: description,
    category: category,
    owner: owner,
    permittedUse: permittedUse,
    assignedAgency: assignedAgency,
    method: method ?? this.method,
    legalAnalysis: legalAnalysis ?? this.legalAnalysis,
    claimNumber: claimNumber ?? this.claimNumber,
    caseNumber: caseNumber ?? this.caseNumber,
    executionNumber: executionNumber ?? this.executionNumber,
    courtOutcome: courtOutcome ?? this.courtOutcome,
    appealFiled: appealFiled ?? this.appealFiled,
    damage: damage,
    recovered: recovered ?? this.recovered,
    detailed: detailed,
    scenarioNumber: scenarioNumber,
    events: events ?? this.events,
    evidence: evidence ?? this.evidence,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'address': address,
    'region': region,
    'cadastral': cadastral,
    'area': area,
    'lat': location.latitude,
    'lng': location.longitude,
    'risk': risk.name,
    'score': score,
    'status': status.name,
    'stage': stage.name,
    'detectedAt': detectedAt.toIso8601String(),
    'deadline': deadline.toIso8601String(),
    'description': description,
    'category': category,
    'owner': owner,
    'permittedUse': permittedUse,
    'assignedAgency': assignedAgency,
    'method': method,
    'legalAnalysis': legalAnalysis,
    'claimNumber': claimNumber,
    'caseNumber': caseNumber,
    'executionNumber': executionNumber,
    'courtOutcome': courtOutcome,
    'appealFiled': appealFiled,
    'damage': damage,
    'recovered': recovered,
    'detailed': detailed,
    'scenarioNumber': scenarioNumber,
    'events': events.map((e) => e.toJson()).toList(),
    'evidence': evidence.map((e) => e.toJson()).toList(),
  };
  factory RiskSignal.fromJson(Map<String, dynamic> json) => RiskSignal(
    id: json['id'] as String,
    title: json['title'] as String,
    address: json['address'] as String,
    region: json['region'] as String,
    cadastral: json['cadastral'] as String,
    area: (json['area'] as num).toDouble(),
    location: LatLng(
      (json['lat'] as num).toDouble(),
      (json['lng'] as num).toDouble(),
    ),
    risk: Risk.values.byName(json['risk'] as String),
    score: json['score'] as int,
    status: SignalStatus.values.byName(json['status'] as String),
    stage: Stage.values.byName(json['stage'] as String),
    detectedAt: DateTime.parse(json['detectedAt'] as String),
    deadline: DateTime.parse(json['deadline'] as String),
    description: json['description'] as String,
    category: json['category'] as String,
    owner: json['owner'] as String,
    permittedUse: json['permittedUse'] as String,
    assignedAgency: json['assignedAgency'] as String,
    method: json['method'] as String?,
    legalAnalysis: json['legalAnalysis'] as String?,
    claimNumber: json['claimNumber'] as String?,
    caseNumber: json['caseNumber'] as String?,
    executionNumber: json['executionNumber'] as String?,
    courtOutcome: json['courtOutcome'] as String?,
    appealFiled: json['appealFiled'] as bool? ?? false,
    damage: (json['damage'] as num).toDouble(),
    recovered: (json['recovered'] as num).toDouble(),
    detailed: json['detailed'] as bool? ?? false,
    scenarioNumber:
        (json['scenarioNumber'] as int?) ??
        ((json['detailed'] == true)
            ? switch (json['id'] as String) {
                'RSK-ASOS-01' => 1,
                'RSK-QAROR-01' => 2,
                'RSK-TUPR-01' => 3,
                final id when id.startsWith('RSK-') => int.tryParse(
                  id.substring(4),
                ),
                _ => null,
              }
            : null),
    events: ((json['events'] as List?) ?? [])
        .map((e) => TimelineEvent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    evidence: ((json['evidence'] as List?) ?? [])
        .map((e) => Evidence.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}

class RiskScenario {
  const RiskScenario({
    required this.number,
    required this.title,
    required this.fact,
    required this.basis,
    required this.narrative,
    required this.timeline,
    required this.analysis,
  });
  final int number;
  final String title, fact, basis, narrative, timeline, analysis;
  factory RiskScenario.fromJson(Map<String, dynamic> json) => RiskScenario(
    number: json['number'] as int,
    title: json['title'] as String,
    fact: json['fact'] as String,
    basis: json['basis'] as String,
    narrative: json['narrative'] as String,
    timeline: json['timeline'] as String,
    analysis: json['analysis'] as String,
  );
}

class RegistryRecord {
  const RegistryRecord({
    required this.id,
    required this.title,
    required this.kind,
    required this.status,
    required this.region,
    required this.reference,
    required this.createdAt,
    this.signalId,
  });
  final String id, title, kind, status, region, reference;
  final DateTime createdAt;
  final String? signalId;
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'kind': kind,
    'status': status,
    'region': region,
    'reference': reference,
    'createdAt': createdAt.toIso8601String(),
    'signalId': signalId,
  };
  factory RegistryRecord.fromJson(Map<String, dynamic> j) => RegistryRecord(
    id: j['id'] as String,
    title: j['title'] as String,
    kind: j['kind'] as String,
    status: j['status'] as String,
    region: j['region'] as String,
    reference: j['reference'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    signalId: j['signalId'] as String?,
  );
}

class AppData {
  const AppData({
    required this.signals,
    required this.registry,
    required this.role,
    required this.latin,
    required this.demoDate,
    this.selectedRegion = 'Барча ҳудудлар',
    this.scenarios = const {},
  });
  final List<RiskSignal> signals;
  final List<RegistryRecord> registry;
  final UserRole role;
  final bool latin;
  final DateTime demoDate;
  final String selectedRegion;
  final Map<int, RiskScenario> scenarios;
  AppData copyWith({
    List<RiskSignal>? signals,
    List<RegistryRecord>? registry,
    UserRole? role,
    bool? latin,
    DateTime? demoDate,
    String? selectedRegion,
  }) => AppData(
    signals: signals ?? this.signals,
    registry: registry ?? this.registry,
    role: role ?? this.role,
    latin: latin ?? this.latin,
    demoDate: demoDate ?? this.demoDate,
    selectedRegion: selectedRegion ?? this.selectedRegion,
    scenarios: scenarios,
  );
}
