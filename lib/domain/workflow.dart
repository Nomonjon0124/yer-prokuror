import 'models.dart';

class WorkflowException implements Exception {
  WorkflowException(this.message);
  final String message;
  @override
  String toString() => message;
}

DateTime addBusinessDays(
  DateTime start,
  int days, {
  Set<DateTime> holidays = const {},
}) {
  var date = DateTime(start.year, start.month, start.day);
  var remaining = days;
  while (remaining > 0) {
    date = date.add(const Duration(days: 1));
    if (date.weekday < DateTime.saturday &&
        !holidays.any(
          (h) =>
              h.year == date.year && h.month == date.month && h.day == date.day,
        )) {
      remaining--;
    }
  }
  return date;
}

bool canPerform(
  RiskSignal signal,
  UserRole role,
  WorkflowAction action, {
  DateTime? asOf,
}) => switch (action) {
  WorkflowAction.accept =>
    (role == UserRole.cadastre || role == UserRole.agro) &&
        signal.stage == Stage.detection,
  WorkflowAction.chooseMethod =>
    (role == UserRole.cadastre || role == UserRole.agro) &&
        signal.stage == Stage.verification &&
        signal.status == SignalStatus.accepted,
  WorkflowAction.reject || WorkflowAction.confirm =>
    (role == UserRole.cadastre || role == UserRole.agro) &&
        signal.stage == Stage.verification &&
        signal.status == SignalStatus.verifying &&
        signal.method != null,
  WorkflowAction.recordMeasure =>
    (role == UserRole.cadastre || role == UserRole.agro) &&
        signal.stage == Stage.measures,
  WorkflowAction.requestDocuments =>
    role == UserRole.prosecutor &&
        (signal.stage == Stage.prosecutor ||
            ((signal.stage == Stage.detection ||
                    signal.stage == Stage.verification ||
                    signal.stage == Stage.measures) &&
                signal.status != SignalStatus.rejected &&
                asOf != null &&
                signal.deadline.isBefore(asOf))),
  WorkflowAction.legalAssessment =>
    role == UserRole.prosecutor && signal.stage == Stage.prosecutor,
  WorkflowAction.issueProtest ||
  WorkflowAction.issueSubmission ||
  WorkflowAction.issueWarning ||
  WorkflowAction.requestMoreInspection =>
    role == UserRole.prosecutor &&
        signal.stage == Stage.prosecutor &&
        signal.legalAnalysis != null,
  WorkflowAction.fileClaim =>
    signal.stage == Stage.prosecutor &&
        ((role == UserRole.prosecutor && signal.legalAnalysis != null) ||
            role == UserRole.cadastre ||
            role == UserRole.agro),
  WorkflowAction.courtDecision =>
    role == UserRole.prosecutor && signal.stage == Stage.court,
  WorkflowAction.appeal =>
    role == UserRole.prosecutor &&
        signal.stage == Stage.court &&
        (signal.courtOutcome == 'Рад этилди' ||
            signal.courtOutcome == 'Қисман қаноатлантирилди') &&
        !signal.appealFiled,
  WorkflowAction.startExecution =>
    role == UserRole.enforcement &&
        signal.stage == Stage.execution &&
        signal.status == SignalStatus.inCourt,
  WorkflowAction.verifyExecution =>
    (role == UserRole.enforcement || role == UserRole.prosecutor) &&
        signal.stage == Stage.execution &&
        signal.status == SignalStatus.executing,
};

RiskSignal performAction(
  RiskSignal signal,
  UserRole role,
  WorkflowAction action,
  DateTime at, {
  String? note,
  bool? restored,
}) {
  if (!canPerform(signal, role, action, asOf: at)) {
    throw WorkflowException('Бу босқичда ёки ролда амалга рухсат йўқ.');
  }
  if (action == WorkflowAction.reject &&
      !signal.evidence.any((e) => e.kind == 'document')) {
    throw WorkflowException('Рад этиш учун тасдиқловчи ҳужжат қўшинг.');
  }
  if (action == WorkflowAction.confirm &&
      !signal.evidence.any((e) => e.kind == 'document')) {
    throw WorkflowException('Тасдиқлаш учун далолатнома қўшинг.');
  }
  if (action == WorkflowAction.recordMeasure) {
    final confirmed = signal.events.lastWhere(
      (e) => e.title == 'Қонунбузилиш тасдиқланди',
    );
    if (!signal.evidence.any(
      (e) => e.kind == 'document' && !e.at.isBefore(confirmed.at),
    )) {
      throw WorkflowException(
        'Тасдиқдан кейин кўрилган чора ҳужжатини қўшинг.',
      );
    }
  }
  if (action == WorkflowAction.verifyExecution) {
    final opened = signal.events.lastWhere(
      (e) => e.title == 'Ижро иши очилди',
      orElse: () => throw WorkflowException('Ижро иши очилмаган.'),
    );
    final newEvidence = signal.evidence.where((e) => !e.at.isBefore(opened.at));
    if (!newEvidence.any((e) => e.kind == 'document') ||
        !newEvidence.any((e) => e.kind == 'image')) {
      throw WorkflowException(
        'Ижро очилгандан кейин акт ва янги сурат қўшинг.',
      );
    }
  }
  final event = TimelineEvent(
    title: _actionTitle(action),
    at: at,
    actor: role.name,
    note: note ?? 'Демо амал',
  );
  final events = [...signal.events, event];
  return switch (action) {
    WorkflowAction.accept => signal.copyWith(
      stage: Stage.verification,
      status: SignalStatus.accepted,
      events: events,
    ),
    WorkflowAction.chooseMethod => signal.copyWith(
      status: SignalStatus.verifying,
      method: note ?? 'Жойига чиқиб ўрганиш',
      events: events,
    ),
    WorkflowAction.reject => signal.copyWith(
      status: SignalStatus.rejected,
      events: events,
    ),
    WorkflowAction.confirm => signal.copyWith(
      stage: Stage.measures,
      status: SignalStatus.confirmed,
      deadline: addBusinessDays(at, 3),
      events: events,
    ),
    WorkflowAction.recordMeasure => signal.copyWith(
      stage: Stage.prosecutor,
      status: SignalStatus.underProsecutor,
      deadline: at.add(const Duration(days: 10)),
      events: events,
    ),
    WorkflowAction.requestDocuments => signal.copyWith(events: events),
    WorkflowAction.legalAssessment => signal.copyWith(
      legalAnalysis: note ?? 'Демо ҳуқуқий таҳлил: факт ва реестр ўртасида тафовут мавжуд. Якуний баҳони прокурор беради.',
      events: events,
    ),
    WorkflowAction.issueProtest ||
    WorkflowAction.issueSubmission ||
    WorkflowAction.issueWarning => signal.copyWith(
      events: events,
      deadline: action == WorkflowAction.issueSubmission
          ? at.add(const Duration(days: 30))
          : at.add(const Duration(days: 10)),
    ),
    WorkflowAction.requestMoreInspection => signal.copyWith(
      events: events,
      deadline: addBusinessDays(at, 5),
    ),
    WorkflowAction.fileClaim => signal.copyWith(
      stage: Stage.court,
      status: SignalStatus.inCourt,
      claimNumber: 'DAVO-${signal.id}',
      caseNumber: 'SUD-${signal.id}',
      deadline: at.add(const Duration(days: 30)),
      events: events,
    ),
    WorkflowAction.courtDecision =>
      note == 'Рад этилди' || note == 'Қисман қаноатлантирилди'
          ? signal.copyWith(
              courtOutcome: note,
              status: SignalStatus.inCourt,
              deadline: at.add(const Duration(days: 10)),
              events: events,
            )
          : signal.copyWith(
              stage: Stage.execution,
              courtOutcome: note ?? 'Қаноатлантирилди',
              status: SignalStatus.inCourt,
              deadline: at.add(const Duration(days: 30)),
              events: events,
            ),
    WorkflowAction.appeal => signal.copyWith(
      appealFiled: true,
      deadline: at.add(const Duration(days: 30)),
      events: events,
    ),
    WorkflowAction.startExecution => signal.copyWith(
      status: SignalStatus.executing,
      executionNumber: 'IJRO-${signal.id}',
      deadline: at.add(const Duration(days: 30)),
      events: events,
    ),
    WorkflowAction.verifyExecution =>
      restored == true
          ? signal.copyWith(
              status: SignalStatus.completed,
              recovered: signal.damage,
              events: events,
            )
          : signal.copyWith(
              stage: Stage.prosecutor,
              status: SignalStatus.formal,
              deadline: at.add(const Duration(days: 10)),
              events: events,
            ),
  };
}

String _actionTitle(WorkflowAction action) => switch (action) {
  WorkflowAction.accept => 'Сигнал қабул қилинди',
  WorkflowAction.chooseMethod => 'Текширув усули танланди',
  WorkflowAction.reject => 'Сигнал рад этилди',
  WorkflowAction.confirm => 'Қонунбузилиш тасдиқланди',
  WorkflowAction.recordMeasure => 'Назорат органи чора кўрди',
  WorkflowAction.requestDocuments => 'Ҳужжатлар талаб қилинди',
  WorkflowAction.legalAssessment => 'Ҳуқуқий баҳо шаклланди',
  WorkflowAction.issueProtest => 'Протест киритилди',
  WorkflowAction.issueSubmission => 'Тақдимнома киритилди',
  WorkflowAction.issueWarning => 'Огоҳлантириш берилди',
  WorkflowAction.requestMoreInspection => 'Қўшимча текширув сўралди',
  WorkflowAction.fileClaim => 'Даъво киритилди',
  WorkflowAction.courtDecision => 'Суд қарори чиқди',
  WorkflowAction.appeal => 'Апелляция берилди',
  WorkflowAction.startExecution => 'Ижро иши очилди',
  WorkflowAction.verifyExecution => 'Ижро қайта текширилди',
};
