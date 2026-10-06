import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:yer_prokuror/data/fixtures.dart';
import 'package:yer_prokuror/domain/models.dart';
import 'package:yer_prokuror/domain/workflow.dart';
import 'package:yer_prokuror/ui/export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all 26 source scenarios have readable detailed fields', () async {
    final cases = (jsonDecode(await rootBundle.loadString('assets/data/risk_scenarios.json')) as List).cast<Map<String, dynamic>>();
    expect(cases.length, 26);
    expect(cases.first['fact'], contains('Зарафшон'));
    expect(cases.last['analysis'], contains('суд қарори'));
    for (final item in cases) {
      for (final field in ['title', 'fact', 'basis', 'narrative', 'timeline', 'analysis']) {
        expect((item[field] as String).isNotEmpty, true);
      }
    }
  });
  test('demo fixtures keep the dashboard distribution and all risk stories', () {
    final signals = buildSignals();
    expect(signals.length, 833);
    expect(signals.where((s) => s.risk == Risk.high).length, 152);
    expect(signals.where((s) => s.risk == Risk.medium).length, 263);
    expect(signals.where((s) => s.risk == Risk.low).length, 418);
    expect(signals.where((s) => s.detailed).length, 26);
    expect(buildRegistry(signals).length, 1248);
  });

  test('business day deadline skips weekends and configured holidays', () {
    expect(addBusinessDays(DateTime(2026, 4, 17), 2), DateTime(2026, 4, 21));
    expect(addBusinessDays(DateTime(2026, 4, 17), 2, holidays: {DateTime(2026, 4, 20)}), DateTime(2026, 4, 22));
  });

  test('roles, evidence and sequence protect the six stage flow', () {
    var s = buildSignals().first;
    final at = DateTime(2026, 4, 30, 12);
    expect(() => performAction(s, UserRole.prosecutor, WorkflowAction.accept, at), throwsA(isA<WorkflowException>()));
    s = performAction(s, UserRole.cadastre, WorkflowAction.accept, at);
    expect(s.stage, Stage.verification);
    expect(() => performAction(s, UserRole.cadastre, WorkflowAction.confirm, at), throwsA(isA<WorkflowException>()));
    s = performAction(s, UserRole.cadastre, WorkflowAction.chooseMethod, at, note: 'Жойига чиқиб ўрганиш');
    expect(() => performAction(s, UserRole.cadastre, WorkflowAction.reject, at), throwsA(isA<WorkflowException>()));
    s = s.copyWith(evidence: [Evidence(name: 'Далолатнома', kind: 'document', path: 'demo', at: at, by: UserRole.cadastre)]);
    s = performAction(s, UserRole.cadastre, WorkflowAction.confirm, at);
    s = s.copyWith(evidence: [...s.evidence, Evidence(name: 'Чора ҳужжати', kind: 'document', path: 'demo', at: at.add(const Duration(minutes: 1)), by: UserRole.cadastre)]);
    s = performAction(s, UserRole.cadastre, WorkflowAction.recordMeasure, at);
    expect(s.stage, Stage.prosecutor);
    s = performAction(s, UserRole.prosecutor, WorkflowAction.legalAssessment, at);
    s = performAction(s, UserRole.prosecutor, WorkflowAction.fileClaim, at);
    expect(s.stage, Stage.court);
    s = performAction(s, UserRole.prosecutor, WorkflowAction.courtDecision, at);
    s = performAction(s, UserRole.enforcement, WorkflowAction.startExecution, at);
    expect(() => performAction(s, UserRole.enforcement, WorkflowAction.verifyExecution, at), throwsA(isA<WorkflowException>()));
    s = s.copyWith(evidence: [...s.evidence, Evidence(name: 'Ижро акти', kind: 'document', path: 'demo', at: at.add(const Duration(minutes: 1)), by: UserRole.enforcement), Evidence(name: 'Янги сурат', kind: 'image', path: 'demo', at: at.add(const Duration(minutes: 1)), by: UserRole.enforcement)]);
    s = performAction(s, UserRole.enforcement, WorkflowAction.verifyExecution, at, restored: false);
    expect(s.status, SignalStatus.formal);
    expect(s.stage, Stage.prosecutor);
  });

  test('documented rejection ends verification', () {
    var s = buildSignals().first;
    final at = DateTime(2026, 4, 30);
    s = performAction(s, UserRole.agro, WorkflowAction.accept, at);
    s = performAction(s, UserRole.agro, WorkflowAction.chooseMethod, at);
    s = s.copyWith(evidence: [Evidence(name: 'Қарор', kind: 'document', path: 'demo', at: at, by: UserRole.agro)]);
    s = performAction(s, UserRole.agro, WorkflowAction.reject, at);
    expect(canPerform(s, UserRole.agro, WorkflowAction.confirm), false);
  });

  test('rejected court result can be appealed before execution', () {
    var signal = buildSignals().first.copyWith(stage: Stage.court, status: SignalStatus.inCourt);
    final at = DateTime(2026, 5, 5);
    signal = performAction(signal, UserRole.prosecutor, WorkflowAction.courtDecision, at, note: 'Рад этилди');
    expect(signal.stage, Stage.court);
    expect(canPerform(signal, UserRole.prosecutor, WorkflowAction.appeal), true);
    signal = performAction(signal, UserRole.prosecutor, WorkflowAction.appeal, at);
    expect(signal.appealFiled, true);
    expect(canPerform(signal, UserRole.prosecutor, WorkflowAction.appeal), false);
    signal = performAction(signal, UserRole.prosecutor, WorkflowAction.courtDecision, at, note: 'Қаноатлантирилди');
    expect(signal.stage, Stage.execution);
  });

  test('prosecutor documents require assessment and refresh the stage deadline', () {
    var signal = buildSignals().first.copyWith(stage: Stage.prosecutor, status: SignalStatus.underProsecutor);
    final at = DateTime(2026, 4, 30, 12);
    expect(canPerform(signal, UserRole.prosecutor, WorkflowAction.issueProtest), false);
    signal = performAction(signal, UserRole.prosecutor, WorkflowAction.legalAssessment, at);
    expect(canPerform(signal, UserRole.cadastre, WorkflowAction.issueProtest), false);
    signal = performAction(signal, UserRole.prosecutor, WorkflowAction.issueProtest, at);
    expect(signal.events.last.title, 'Протест киритилди');
    expect(signal.deadline, at.add(const Duration(days: 10)));
    signal = performAction(signal, UserRole.prosecutor, WorkflowAction.issueSubmission, at);
    expect(signal.deadline, at.add(const Duration(days: 30)));
  });

  test('workflow data survives serialization', () {
    final source = buildSignals().first.copyWith(evidence: [Evidence(name: 'Акт', kind: 'document', path: '/demo/act.pdf', at: DateTime(2026, 4, 30), by: UserRole.cadastre)]);
    final saved = RiskSignal.fromJson(Map<String, dynamic>.from(source.toJson()));
    expect(saved.id, source.id);
    expect(saved.evidence.single.name, 'Акт');
    expect(saved.events.single.title, 'Сигнал шаклланди');
    expect(saved.scenarioNumber, 1);
  });

  test('registry and summary PDFs are generated from demo records', () async {
    final signals = buildSignals();
    final registry = buildRegistry(signals);
    final data = AppData(signals: signals, registry: registry, role: UserRole.prosecutor, latin: false, demoDate: DateTime(2026, 4, 30));
    final registryBytes = await buildRegistryPdfBytes(registry);
    final summaryBytes = await buildSummaryPdfBytes(data);
    final comparison = buildComparisonCsvBytes(data);
    expect(String.fromCharCodes(registryBytes.take(4)), '%PDF');
    expect(String.fromCharCodes(summaryBytes.take(4)), '%PDF');
    expect(String.fromCharCodes(comparison.take(3)), '\u00ef\u00bb\u00bf');
    expect(comparison.length, greaterThan(1000));
  });
}
