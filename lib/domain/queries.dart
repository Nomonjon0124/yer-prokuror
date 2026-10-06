import 'models.dart';

List<RiskSignal> visibleSignals(AppData data) => data.signals.where((s) =>
  (data.selectedRegion == 'Барча ҳудудлар' || s.region == data.selectedRegion) &&
  !s.detectedAt.isAfter(DateTime(data.demoDate.year, data.demoDate.month, data.demoDate.day, 23, 59, 59))
).toList();

bool isOverdue(RiskSignal signal, DateTime date) =>
  signal.deadline.isBefore(date) &&
  signal.status != SignalStatus.completed &&
  signal.status != SignalStatus.rejected;

bool isDueSoon(RiskSignal signal, DateTime date) =>
  !isOverdue(signal, date) &&
  signal.status != SignalStatus.completed &&
  signal.status != SignalStatus.rejected &&
  !signal.deadline.isAfter(DateTime(date.year, date.month, date.day).add(const Duration(days: 3)));
