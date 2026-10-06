import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_state.dart';
import '../../domain/models.dart';
import '../../domain/queries.dart';
import '../export.dart';
import '../style.dart';
import '../widgets.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    return Scaffold(appBar: AppBar(title: Text(localized(ref, 'Профил'))), body: ListView(padding: const EdgeInsets.all(16), children: [
      Panel(child: Row(children: [const CircleAvatar(radius: 28, backgroundColor: gold, child: Icon(Icons.person, color: navy, size: 28)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(localized(ref, 'Демо фойдаланувчи'), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium), Text(localized(ref, 'Рол ва тилни алмаштириш'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 11))]))])),
      const SizedBox(height: 12),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Демо роли', icon: Icons.badge_outlined), const SizedBox(height: 8),
        for (final role in UserRole.values) ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(data.role == role ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: data.role == role ? gold : muted), title: Text(localized(ref, _roleLabel(role))), onTap: () => ref.read(appControllerProvider.notifier).setRole(role)),
      ])),
      const SizedBox(height: 12),
      Panel(child: Column(children: [
        const SectionTitle('Тил', icon: Icons.language), const SizedBox(height: 8),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(localized(ref, 'Ўзбек лотинча')), subtitle: Text(localized(ref, 'Ўчирилса — ўзбек кириллча'), style: const TextStyle(color: muted)), value: data.latin, onChanged: ref.read(appControllerProvider.notifier).setLatin),
      ])),
      const SizedBox(height: 12),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Демо санаси', icon: Icons.calendar_today), const SizedBox(height: 8),
        Text(dateText(data.demoDate), style: const TextStyle(color: gold, fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), ActionButton('Санани ўзгартириш', icon: Icons.date_range, onPressed: () async {
          final selected = await showDatePicker(context: context, initialDate: data.demoDate, firstDate: DateTime(2024), lastDate: DateTime(2027));
          if (selected != null) ref.read(appControllerProvider.notifier).setDate(selected);
        }),
      ])),
      const SizedBox(height: 12),
      ActionButton('Демо маълумотларини тиклаш', icon: Icons.restart_alt, onPressed: () async {
        final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: Text(localized(ref, 'Маълумотларни тиклаш')), content: Text(localized(ref, 'Қўшилган далиллар ва ўзгарган ҳолатлар бошланғич ҳолатга қайтади.')), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(localized(ref, 'Бекор қилиш'))), FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(localized(ref, 'Тиклаш')))]));
        if (yes == true) { await ref.read(appControllerProvider.notifier).reset(); if (context.mounted) showMessage(context, localized(ref, 'Демо тикланди')); }
      }),
      const SizedBox(height: 15),
      Text(localized(ref, 'Барча ёзувлар ва ҳуқуқий хулосалар намунавий. Расмий қарор ёки давлат тизимига юбориш амалга оширилмайди.'), textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 11)),
    ]));
  }
}

String _roleLabel(UserRole role) => switch (role) { UserRole.prosecutor => 'Прокурор', UserRole.cadastre => 'Кадастр агентлиги', UserRole.agro => 'Агроинспекция', UserRole.enforcement => 'Ижрочи' };

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    final overdue = visibleSignals(data).where((s) => isOverdue(s, data.demoDate)).toList();
    final dueSoon = visibleSignals(data).where((s) => isDueSoon(s, data.demoDate)).toList();
    final high = visibleSignals(data).where((s) => s.risk == Risk.high).toList();
    return Scaffold(appBar: AppBar(title: Text(localized(ref, 'Хавф хабарлари'))), body: ListView(padding: const EdgeInsets.all(15), children: [
      const DemoLabel(), const SizedBox(height: 12),
      Panel(borderColor: red, child: Text(localized(ref, '${overdue.length} та муддати ўтган сигнал. Тўлиқ рўйхат фильтрлар орқали очилади.'), style: const TextStyle(color: Colors.white))),
      const SizedBox(height: 12),
      SectionTitle('Муддати ўтган', icon: Icons.warning, trailing: 'Сигналлар', onTap: () => context.go('/signals')),
      const SizedBox(height: 8),
      for (final signal in overdue.take(8)) ...[SignalTile(signal, compact: true), const SizedBox(height: 7)],
      const SizedBox(height: 12), const SectionTitle('3 кун ичида муддат тугайди', icon: Icons.schedule), const SizedBox(height: 8),
      for (final signal in dueSoon.take(5)) ...[SignalTile(signal, compact: true), const SizedBox(height: 7)],
      const SizedBox(height: 12), const SectionTitle('Юқори хавфли янги сигналлар', icon: Icons.notifications_active), const SizedBox(height: 8),
      for (final signal in high.take(5)) ...[SignalTile(signal, compact: true), const SizedBox(height: 7)],
    ]));
  }
}

class CourtPage extends ConsumerStatefulWidget {
  const CourtPage({super.key});
  @override
  ConsumerState<CourtPage> createState() => _CourtPageState();
}
class _CourtPageState extends ConsumerState<CourtPage> {
  String selected = 'Барча ишлар';
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider);
    final cases = visibleSignals(data).where((s) => s.stage == Stage.court || s.stage == Stage.execution).toList();
    final shown = cases.where((s) => selected == 'Барча ишлар' || (selected == 'Судда' && s.stage == Stage.court) || (selected == 'Якунланган' && s.stage == Stage.execution) || (selected == 'Апелляция' && s.appealFiled)).toList();
    return Scaffold(appBar: AppBar(title: Text(localized(ref, 'Даъво ва суд'))), body: ListView(padding: const EdgeInsets.all(15), children: [
      const DemoLabel(), const SizedBox(height: 9),
      Text(localized(ref, 'Даъво материаллари ва суд иши ҳаракати'), style: const TextStyle(color: muted)), const SizedBox(height: 11),
      SizedBox(height: 104, child: Row(children: [
        Expanded(child: KpiCard(title: 'Жами ишлар', value: '${cases.length}', icon: Icons.description_outlined, color: blue)), const SizedBox(width: 7),
        Expanded(child: KpiCard(title: 'Судда', value: '${cases.where((s) => s.stage == Stage.court).length}', icon: Icons.balance, color: gold)), const SizedBox(width: 7),
        Expanded(child: KpiCard(title: 'Якунланган', value: '${cases.where((s) => s.stage == Stage.execution).length}', icon: Icons.check_circle, color: green)),
      ])), const SizedBox(height: 10),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final item in ['Барча ишлар', 'Судда', 'Апелляция', 'Якунланган']) ...[FilterChipButton(label: item, icon: Icons.gavel, selected: selected == item, onTap: () => setState(() => selected = item)), const SizedBox(width: 7)]])),
      const SizedBox(height: 10),
      for (final signal in shown) ...[Panel(onTap: () => context.go('/signals/${signal.id}'), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.description, color: blue), const SizedBox(width: 8), Expanded(child: Text(signal.claimNumber ?? 'DAVO-${signal.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), Text(localized(ref, signal.stage == Stage.court ? 'Судда' : 'Қарор чиқди'), style: const TextStyle(color: gold, fontSize: 11)), const Icon(Icons.chevron_right, color: muted)]),
        const SizedBox(height: 6), Text(localized(ref, signal.title), style: const TextStyle(color: muted, fontSize: 12)),
        if (signal.courtOutcome != null) Text(localized(ref, signal.courtOutcome!), style: const TextStyle(color: gold, fontSize: 11)),
        const Divider(color: stroke), Text('${localized(ref, 'Суд')}: ${localized(ref, signal.region)}  ·  ${localized(ref, 'Сумма')}: ${money(signal.damage)} сўм', style: const TextStyle(color: muted, fontSize: 10)),
      ])), const SizedBox(height: 8)],
      if (shown.isNotEmpty) Panel(child: Column(children: [const SectionTitle('Иш ҳаракати', icon: Icons.timeline), const SizedBox(height: 12), for (final event in shown.first.events) ListTile(dense: true, leading: const Icon(Icons.circle, size: 11, color: gold), title: Text(localized(ref, event.title)), subtitle: Text(dateText(event.at)))])),
    ]));
  }
}

class ExecutionsPage extends ConsumerStatefulWidget {
  const ExecutionsPage({super.key});
  @override
  ConsumerState<ExecutionsPage> createState() => _ExecutionsPageState();
}
class _ExecutionsPageState extends ConsumerState<ExecutionsPage> {
  String filter = 'Барчаси';
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider);
    final items = visibleSignals(data).where((s) => s.stage == Stage.execution || s.status == SignalStatus.formal).toList();
    final shown = items.where((s) => filter == 'Барчаси' || (filter == 'Муддати ўтган' && isOverdue(s, data.demoDate)) || (filter == 'Ижрода' && s.status == SignalStatus.executing) || (filter == 'Тасдиқланган' && s.status == SignalStatus.completed)).toList();
    return Scaffold(appBar: AppBar(title: Text(localized(ref, 'Ижро назорати'))), body: ListView(padding: const EdgeInsets.all(15), children: [
      const DemoLabel(), const SizedBox(height: 8), Text(localized(ref, 'Прокурор ҳужжатлари ва суд қарорлари ижроси'), style: const TextStyle(color: muted)), const SizedBox(height: 10),
      SizedBox(height: 105, child: Row(children: [
        Expanded(child: KpiCard(title: 'Жами ижро', value: '${items.length}', icon: Icons.description, color: blue)), const SizedBox(width: 7),
        Expanded(child: KpiCard(title: 'Муддати ўтган', value: '${items.where((s) => isOverdue(s, data.demoDate)).length}', icon: Icons.schedule, color: red)), const SizedBox(width: 7),
        Expanded(child: KpiCard(title: 'Тасдиқланган', value: '${items.where((s) => s.status == SignalStatus.completed).length}', icon: Icons.check_circle, color: green)),
      ])), const SizedBox(height: 10),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final item in ['Барчаси', 'Муддати ўтган', 'Ижрода', 'Тасдиқланган']) ...[FilterChipButton(label: item, icon: Icons.fact_check, selected: filter == item, onTap: () => setState(() => filter = item)), const SizedBox(width: 6)]])),
      const SizedBox(height: 10),
      for (final signal in shown) ...[Panel(onTap: () => context.go('/signals/${signal.id}'), borderColor: isOverdue(signal, data.demoDate) ? red : stroke, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.description, color: blue), const SizedBox(width: 8), Expanded(child: Text(signal.executionNumber ?? 'IJRO-${signal.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), Text(localized(ref, statusText(signal.status)), style: TextStyle(color: signal.status == SignalStatus.completed ? green : isOverdue(signal, data.demoDate) ? red : blue, fontSize: 10)), const Icon(Icons.chevron_right, color: muted)]),
        const SizedBox(height: 5), Text(localized(ref, signal.title), style: const TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 7), Text('${localized(ref, 'Муддат')}: ${dateText(signal.deadline)}  ·  ${localized(ref, 'Зарар')}: ${money(signal.damage)} сўм', style: const TextStyle(color: muted, fontSize: 10)),
      ])), const SizedBox(height: 8)],
    ]));
  }
}

class DamagePage extends ConsumerWidget {
  const DamagePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    final signals = visibleSignals(data);
    final claimed = signals.fold<double>(0, (sum, s) => sum + s.damage);
    final recovered = signals.fold<double>(0, (sum, s) => sum + s.recovered);
    final inconsistent = signals.where((s) => s.recovered > 0 && s.recovered < s.damage).toList();
    return Scaffold(appBar: AppBar(title: Text(localized(ref, 'Зарар ва ундирув'))), body: ListView(padding: const EdgeInsets.all(15), children: [
      const DemoLabel(), const SizedBox(height: 10),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionTitle('Зарар ва тўлов назорати', icon: Icons.payments_outlined), const SizedBox(height: 12), _DamageLine('Ҳисобланган зарар', claimed), _DamageLine('Қайд этилган ундирув', recovered), _DamageLine('Фарқ', claimed - recovered)])),
      const SizedBox(height: 10),
      Panel(borderColor: gold, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionTitle('95/5 таклифий тақсимот', icon: Icons.account_balance), const SizedBox(height: 8), Text(localized(ref, '“Жадвал (6)”даги рақамлаштириш таклифи. Расмий ҳисоб-китоб ёки тўлов йўриқномаси эмас.'), style: const TextStyle(color: muted, fontSize: 11)), const SizedBox(height: 8), _DamageLine('Бюджет 95%', recovered * .95), _DamageLine('Жамғарма 5%', recovered * .05)])),
      const SizedBox(height: 10),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionTitle('Тафовутлар журнали', icon: Icons.rule), const SizedBox(height: 9), Text(localized(ref, '${inconsistent.length} та ёзувда зарар ва ундирув ўртасида фарқ бор.'), style: const TextStyle(color: muted, fontSize: 11)), const SizedBox(height: 10), for (final signal in inconsistent.take(12)) Padding(padding: const EdgeInsets.only(bottom: 8), child: Panel(onTap: () => context.go('/signals/${signal.id}'), child: Row(children: [Expanded(child: Text(signal.id, style: const TextStyle(color: Colors.white))), Text('${money(signal.damage - signal.recovered)} сўм', style: const TextStyle(color: yellow, fontSize: 11)), const Icon(Icons.chevron_right, color: muted)])))])),
    ]));
  }
}
class _DamageLine extends ConsumerWidget {
  const _DamageLine(this.label, this.value);
  final String label;
  final double value;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(children: [Expanded(child: Text(localized(ref, label), style: const TextStyle(color: muted, fontSize: 12))), Text('${money(value)} сўм', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]));
}

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    final signals = visibleSignals(data);
    final returned = signals.where((s) => s.status == SignalStatus.completed).fold<double>(0, (sum, s) => sum + s.area);
    final recovered = signals.fold<double>(0, (sum, s) => sum + s.recovered);
    final columns = ['Объект', 'Кадастр', 'Майдон', 'Материал', 'Келган сана', 'Қайта расмийлаш', 'Жиноят иши', 'ЖПК қарори', 'Зарар', 'Қайтарилган ер', 'Судга юбориш', 'Суд натижаси'];
    return Scaffold(appBar: AppBar(title: Text(localized(ref, 'Ҳисоботлар'))), body: ListView(padding: const EdgeInsets.all(15), children: [
      const DemoLabel(), const SizedBox(height: 10),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Якуний натижалар', icon: Icons.assessment), const SizedBox(height: 10),
        Text('${localized(ref, 'Қайтарилган ер')}: ${returned.toStringAsFixed(1)} га', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 5), Text('${localized(ref, 'Ундирилган зарар')}: ${money(recovered)} сўм', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 5), Text('${localized(ref, 'Объектив тасдиқланган ижро')}: ${signals.where((s) => s.status == SignalStatus.completed).length}', style: const TextStyle(color: Colors.white)),
      ])), const SizedBox(height: 10),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Ярим йиллик солиштирма далолатнома', icon: Icons.table_chart), const SizedBox(height: 8),
        Text(localized(ref, '12 устунли намунавий кўриниш. Электрон имзо ва идоралараро солиштириш интеграциядан кейин ишлайди.'), style: const TextStyle(color: muted, fontSize: 11)), const SizedBox(height: 8),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columnSpacing: 16, headingRowHeight: 34, dataRowMinHeight: 35, dataRowMaxHeight: 43, columns: [for (final c in columns) DataColumn(label: Text(localized(ref, c), style: const TextStyle(color: gold, fontSize: 10)))], rows: [for (final s in signals.take(8)) DataRow(cells: [
          DataCell(Text(s.id)), DataCell(Text(s.cadastral)), DataCell(Text('${s.area} га')), DataCell(Text(s.title, overflow: TextOverflow.ellipsis)), DataCell(Text(dateText(s.detectedAt))), const DataCell(Text('—')), const DataCell(Text('—')), const DataCell(Text('—')), DataCell(Text(money(s.damage))), DataCell(Text(s.status == SignalStatus.completed ? '${s.area}' : '0')), DataCell(Text(s.claimNumber ?? '—')), DataCell(Text(s.caseNumber ?? '—')),
        ])])),
      ])), const SizedBox(height: 10),
      ActionButton('PDF ҳисоботни экспорт қилиш', primary: true, icon: Icons.picture_as_pdf, onPressed: () async {
        try { await exportSummaryPdf(data); } catch (_) { if (context.mounted) showMessage(context, localized(ref, 'Экспорт амалга ошмади')); }
      }),
      const SizedBox(height: 8),
      ActionButton('12 устунли CSV далолатнома', icon: Icons.table_view, onPressed: () async {
        try { await exportComparisonCsv(data); } catch (_) { if (context.mounted) showMessage(context, localized(ref, 'Экспорт амалга ошмади')); }
      }),
    ]));
  }
}
