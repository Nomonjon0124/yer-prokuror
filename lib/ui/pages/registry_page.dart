import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_state.dart';
import '../../domain/models.dart';
import '../export.dart';
import '../filter_bar.dart';
import '../style.dart';
import '../widgets.dart';

class RegistryPage extends ConsumerStatefulWidget {
  const RegistryPage({super.key});
  @override
  ConsumerState<RegistryPage> createState() => _RegistryPageState();
}

class _RegistryPageState extends ConsumerState<RegistryPage> {
  String query = '';
  String kind = 'Барчаси';
  String status = 'Барчаси';
  bool comparing = false;
  final chosen = <String>{};

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider);
    final records = data.registry.where((r) =>
      (data.selectedRegion == 'Барча ҳудудлар' || r.region == data.selectedRegion) &&
      r.createdAt.isBefore(DateTime(data.demoDate.year, data.demoDate.month, data.demoDate.day + 1)) &&
      (kind == 'Барчаси' || r.kind == kind) && (status == 'Барчаси' || r.status == status) &&
      (query.isEmpty || '${r.id} ${r.reference} ${r.title}'.toLowerCase().contains(query.toLowerCase()))
    ).toList();
    return Scaffold(backgroundColor: navy, body: CustomScrollView(slivers: [
      const SliverToBoxAdapter(child: HeroHeader(title: 'Реестрлар', subtitle: 'Ягона электрон реестр ва материаллар рўйхати', height: 205)),
      SliverPadding(padding: const EdgeInsets.fromLTRB(15, 0, 15, 12), sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const DemoLabel(), const Spacer(), Text(localized(ref, '${records.length} ёзув'), style: const TextStyle(color: muted, fontSize: 11))]),
        const SizedBox(height: 10),
        TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: localized(ref, 'Сигнал коди, кадастр рақами ёки ҳужжат'))),
        const SizedBox(height: 10),
        SizedBox(height: 105, child: Row(children: [
          Expanded(child: KpiCard(title: 'Жами реестр', value: '${records.length}', icon: Icons.storage, color: blue)), const SizedBox(width: 7),
          Expanded(child: KpiCard(title: 'Фаол', value: '${records.where((r) => r.status == 'Фаол').length}', icon: Icons.timelapse, color: green)), const SizedBox(width: 7),
          Expanded(child: KpiCard(title: 'Ёпилган', value: '${records.where((r) => r.status == 'Ёпилган').length}', icon: Icons.check_circle, color: muted)),
        ])),
        const SizedBox(height: 10),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          for (final item in ['Барчаси', 'Сигнал', 'Материал', 'Ҳужжат']) ...[
            FilterChipButton(label: item, icon: item == 'Барчаси' ? Icons.apps : item == 'Сигнал' ? Icons.warning_amber : item == 'Материал' ? Icons.folder : Icons.description, selected: kind == item, onTap: () => setState(() => kind = item)),
            const SizedBox(width: 6),
          ],
        ])),
        const SizedBox(height: 10),
        Row(children: [const Expanded(child: RegionDateBar()), FilterChipButton(label: status == 'Барчаси' ? 'Ҳолат' : status, icon: Icons.filter_list, onTap: () async {
          final result = await showModalBottomSheet<String>(context: context, backgroundColor: card, builder: (c) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [for (final item in ['Барчаси', 'Фаол', 'Текширувда', 'Ёпилган', 'Кўриб чиқилмоқда']) ListTile(title: Text(localized(ref, item)), onTap: () => Navigator.pop(c, item))])));
          if (result != null) setState(() => status = result);
        })]),
        const SizedBox(height: 8),
        if (comparing) Text(localized(ref, 'Солиштириш учун 2 та ёзув танланг (${chosen.length}/2)'), style: const TextStyle(color: gold, fontSize: 11)),
      ]))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(15, 0, 15, 10), sliver: SliverList.builder(itemCount: records.length, itemBuilder: (context, i) {
        final record = records[i];
        final color = record.kind == 'Сигнал' ? red : record.kind == 'Материал' ? blue : green;
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Panel(onTap: () {
          if (comparing) { setState(() { if (!chosen.remove(record.id) && chosen.length < 2) chosen.add(record.id); }); }
          else if (record.signalId != null) { context.go('/signals/${record.signalId}'); }
          else { _showRecord(record); }
        }, child: Row(children: [
          if (comparing) Checkbox(value: chosen.contains(record.id), onChanged: (_) => setState(() { if (!chosen.remove(record.id) && chosen.length < 2) chosen.add(record.id); })),
          Container(width: 38, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(9)), child: Icon(record.kind == 'Сигнал' ? Icons.warning : record.kind == 'Материал' ? Icons.folder : Icons.description, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(record.id, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))), Text(localized(ref, record.status), style: TextStyle(color: color, fontSize: 10))]),
            const SizedBox(height: 3), Text(localized(ref, record.title), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 11)),
            const SizedBox(height: 4), Text('${record.reference}  ·  ${dateText(record.createdAt)}', style: const TextStyle(color: muted, fontSize: 10)),
          ])), const Icon(Icons.chevron_right, size: 17, color: muted),
        ])));
      })),
    ]), bottomNavigationBar: SafeArea(top: false, child: Container(padding: const EdgeInsets.fromLTRB(14, 7, 14, 8), decoration: const BoxDecoration(color: navy, border: Border(top: BorderSide(color: stroke))), child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (comparing && chosen.length == 2) ...[ActionButton('Танланганларни солиштириш', primary: true, icon: Icons.compare_arrows, onPressed: () => _compare(data.registry)), const SizedBox(height: 6)],
      Row(children: [
        Expanded(child: _RegistryAction('Қўшиш', Icons.add_circle, _add, active: true)),
        Expanded(child: _RegistryAction('Экспорт', Icons.ios_share, () => _export(records))),
        Expanded(child: _RegistryAction(comparing ? 'Бекор' : 'Солиштириш', Icons.compare, () => setState(() { comparing = !comparing; chosen.clear(); }))),
      ]),
    ]))));
  }

  void _showRecord(RegistryRecord record) => showDialog<void>(context: context, builder: (c) => AlertDialog(title: Text(record.id), content: Text('${record.title}\n${record.kind}\n${record.status}\n${record.reference}'), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))]));

  Future<void> _add() async {
    final titleCtrl = TextEditingController();
    final referenceCtrl = TextEditingController();
    String selectedKind = 'Материал';
    final done = await showDialog<bool>(context: context, builder: (c) => StatefulBuilder(builder: (c, update) => AlertDialog(title: Text(localized(ref, 'Реестрга қўшиш')), content: Column(mainAxisSize: MainAxisSize.min, children: [
      DropdownButtonFormField<String>(initialValue: selectedKind, items: ['Сигнал', 'Материал', 'Ҳужжат'].map((v) => DropdownMenuItem(value: v, child: Text(localized(ref, v)))).toList(), onChanged: (v) => update(() => selectedKind = v!)),
      const SizedBox(height: 9), TextField(controller: titleCtrl, decoration: InputDecoration(labelText: localized(ref, 'Номи'))),
      const SizedBox(height: 9), TextField(controller: referenceCtrl, decoration: InputDecoration(labelText: localized(ref, 'Рақам'))),
    ]), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(localized(ref, 'Бекор қилиш'))), FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(localized(ref, 'Қўшиш')))])));
    if (done == true && titleCtrl.text.trim().isNotEmpty && referenceCtrl.text.trim().isNotEmpty) {
      final data = ref.read(appControllerProvider);
      await ref.read(appControllerProvider.notifier).addRegistry(RegistryRecord(id: 'REG-${DateTime.now().millisecondsSinceEpoch}', title: titleCtrl.text.trim(), kind: selectedKind, status: 'Фаол', region: data.selectedRegion == 'Барча ҳудудлар' ? 'Тошкент вилояти' : data.selectedRegion, reference: referenceCtrl.text.trim(), createdAt: data.demoDate));
      if (mounted) showMessage(context, localized(ref, 'Ёзув қўшилди'));
    }
    titleCtrl.dispose(); referenceCtrl.dispose();
  }

  void _compare(List<RegistryRecord> all) {
    final items = chosen.map((id) => all.firstWhere((r) => r.id == id)).toList();
    showDialog<void>(context: context, builder: (c) => AlertDialog(title: Text(localized(ref, 'Ёзувларни солиштириш')), content: SingleChildScrollView(child: Table(border: TableBorder.all(color: stroke), children: [
      for (final row in <List<String>>[
        ['Майдон', items[0].id, items[1].id],
        ['Тури', items[0].kind, items[1].kind],
        ['Ҳолати', items[0].status, items[1].status],
        ['Ҳудуд', items[0].region, items[1].region],
        ['Рақам', items[0].reference, items[1].reference],
        ['Сана', dateText(items[0].createdAt), dateText(items[1].createdAt)],
      ]) TableRow(children: [for (final cell in row) Padding(padding: const EdgeInsets.all(6), child: Text(localized(ref, cell), style: const TextStyle(fontSize: 10)))])
    ])), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))]));
  }

  Future<void> _export(List<RegistryRecord> records) async {
    final format = await showModalBottomSheet<String>(context: context, backgroundColor: card, builder: (c) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.picture_as_pdf), title: const Text('PDF'), onTap: () => Navigator.pop(c, 'pdf')),
      ListTile(leading: const Icon(Icons.table_view), title: const Text('CSV'), onTap: () => Navigator.pop(c, 'csv')),
    ])));
    if (format == null) return;
    try { if (format == 'pdf') { await exportRegistryPdf(records); } else { await exportRegistryCsv(records); } }
    catch (_) { if (mounted) showMessage(context, localized(ref, 'Экспорт амалга ошмади')); }
  }
}

class _RegistryAction extends ConsumerWidget {
  const _RegistryAction(this.label, this.icon, this.onTap, {this.active = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  @override
  Widget build(BuildContext context, WidgetRef ref) => InkWell(onTap: onTap, child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 3), padding: const EdgeInsets.symmetric(vertical: 7),
    decoration: BoxDecoration(color: active ? gold : card, borderRadius: BorderRadius.circular(10), border: Border.all(color: active ? gold : stroke)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: active ? navy : Colors.white, size: 20), const SizedBox(height: 2), Text(localized(ref, label), style: TextStyle(color: active ? navy : Colors.white, fontSize: 10, fontWeight: FontWeight.bold))]),
  ));
}
