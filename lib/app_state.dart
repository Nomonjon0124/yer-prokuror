import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repository.dart';
import 'domain/models.dart';
import 'domain/workflow.dart';

final repositoryProvider = Provider<SignalRepository>(
  (ref) => throw StateError('Repository not provided'),
);
final appControllerProvider = NotifierProvider<AppController, AppData>(
  AppController.new,
);

class AppController extends Notifier<AppData> {
  @override
  AppData build() => ref.read(repositoryProvider).initial;

  void setRole(UserRole role) => _set(state.copyWith(role: role));
  void setLatin(bool latin) => _set(state.copyWith(latin: latin));
  void setDate(DateTime date) => _set(state.copyWith(demoDate: date));
  void setRegion(String region) => _set(state.copyWith(selectedRegion: region));
  void _set(AppData next) {
    state = next;
    ref.read(repositoryProvider).savePreferences(next);
  }

  Future<void> reset() async =>
      state = await ref.read(repositoryProvider).reset();

  Future<void> addEvidence(String signalId, Evidence item) async {
    final signal = state.signals.firstWhere((s) => s.id == signalId);
    final at = _nextEventTime(signal);
    final saved = Evidence(
      name: item.name,
      kind: item.kind,
      path: item.path,
      at: at,
      by: item.by,
    );
    await _updateSignal(
      signal.copyWith(
        evidence: [...signal.evidence, saved],
        events: [
          ...signal.events,
          TimelineEvent(
            title: 'Далил қўшилди',
            at: at,
            actor: state.role.name,
            note: item.name,
          ),
        ],
      ),
    );
  }

  Future<void> act(
    String signalId,
    WorkflowAction action, {
    String? note,
    bool? restored,
  }) async {
    final signal = state.signals.firstWhere((s) => s.id == signalId);
    final at = _nextEventTime(signal);
    final updated = performAction(
      signal,
      state.role,
      action,
      at,
      note: note,
      restored: restored,
    );
    await _updateSignal(updated);
    final documentTitle = switch (action) {
      WorkflowAction.issueProtest => 'Протест',
      WorkflowAction.issueSubmission => 'Тақдимнома',
      WorkflowAction.issueWarning => 'Огоҳлантириш',
      WorkflowAction.requestMoreInspection => 'Қўшимча текширув сўрови',
      _ => null,
    };
    if (documentTitle != null) {
      await addRegistry(
        RegistryRecord(
          id: 'DOC-${signal.id}-${updated.events.length}',
          title: '$documentTitle · ${signal.id}',
          kind: 'Ҳужжат',
          status: 'Кўриб чиқилмоқда',
          region: signal.region,
          reference: '${at.year}/${updated.events.length}',
          createdAt: at,
          signalId: signal.id,
        ),
      );
    }
  }

  DateTime _nextEventTime(RiskSignal signal) {
    final proposed = DateTime(
      state.demoDate.year,
      state.demoDate.month,
      state.demoDate.day,
      12,
    );
    if (signal.events.isEmpty) return proposed;
    final last = signal.events.last.at.add(const Duration(minutes: 1));
    return last.isAfter(proposed) ? last : proposed;
  }

  Future<void> _updateSignal(RiskSignal signal) async {
    final signals = [...state.signals];
    final index = signals.indexWhere((s) => s.id == signal.id);
    signals[index] = signal;
    state = state.copyWith(signals: signals);
    await ref.read(repositoryProvider).saveSignal(signal);
  }

  Future<void> addRegistry(RegistryRecord record) async {
    state = state.copyWith(registry: [record, ...state.registry]);
    await ref.read(repositoryProvider).addRecord(record);
  }
}
