import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_state.dart';
import '../../domain/models.dart';
import '../../domain/queries.dart';
import '../filter_bar.dart';
import '../style.dart';
import '../widgets.dart';

class SignalsPage extends ConsumerStatefulWidget {
  const SignalsPage({super.key});
  @override
  ConsumerState<SignalsPage> createState() => _SignalsPageState();
}

class _SignalsPageState extends ConsumerState<SignalsPage> {
  String query = '';
  Risk? selectedRisk;
  SignalStatus? selectedStatus;
  String category = 'Барчаси';
  String agency = 'Барчаси';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider);
    final riskParam = GoRouterState.of(context).uri.queryParameters['risk'];
    final activeRisk = selectedRisk ?? Risk.values.where((r) => r.name == riskParam).firstOrNull;
    final source = visibleSignals(data);
    final signals = source.where((s) =>
      (activeRisk == null || s.risk == activeRisk) &&
      (selectedStatus == null || s.status == selectedStatus) &&
      (category == 'Барчаси' || s.category == category) &&
      (agency == 'Барчаси' || s.assignedAgency == agency) &&
      (query.isEmpty || '${s.id} ${s.title} ${s.address} ${s.cadastral}'.toLowerCase().contains(query.toLowerCase()))
    ).toList();
    return CustomScrollView(slivers: [
      const SliverToBoxAdapter(child: HeroHeader(title: 'Хавф сигналлари', subtitle: 'Ер участкалари бўйича аниқланган хавфлар', height: 205)),
      SliverPadding(padding: const EdgeInsets.fromLTRB(15, 0, 15, 12), sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(onChanged: (value) => setState(() => query = value), decoration: InputDecoration(hintText: localized(ref, 'Сигнал коди ёки манзил бўйича қидириш'), prefixIcon: const Icon(Icons.search))),
        const SizedBox(height: 10),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          FilterChipButton(label: 'Барчаси', icon: Icons.apps, selected: activeRisk == null, onTap: () => setState(() { selectedRisk = null; context.go('/signals'); })),
          for (final risk in Risk.values) ...[const SizedBox(width: 7), FilterChipButton(label: riskText(risk), icon: riskIcon(risk), selected: activeRisk == risk, onTap: () => setState(() => selectedRisk = risk))],
        ])),
        const SizedBox(height: 10),
        Row(children: [const Expanded(child: RegionDateBar()), FilterChipButton(label: 'Фильтр', icon: Icons.tune, onTap: _openFilters)]),
        const SizedBox(height: 11),
        SizedBox(height: 112, child: Row(children: [
          for (final risk in Risk.values) ...[if (risk != Risk.high) const SizedBox(width: 8), Expanded(child: KpiCard(title: riskText(risk), value: '${signals.where((s) => s.risk == risk).length}', icon: riskIcon(risk), color: riskColor(risk), onTap: () => setState(() => selectedRisk = risk)))],
        ])),
        const SizedBox(height: 10),
        Text(localized(ref, '${signals.length} та сигнал'), style: const TextStyle(color: muted, fontSize: 12)),
      ]))),
      SliverPadding(padding: const EdgeInsets.fromLTRB(15, 0, 15, 20), sliver: SliverList.builder(itemCount: signals.length, itemBuilder: (context, i) => Padding(padding: const EdgeInsets.only(bottom: 8), child: SignalTile(signals[i])))),
    ]);
  }

  void _openFilters() => showModalBottomSheet<void>(context: context, backgroundColor: navy, isScrollControlled: true, builder: (sheetContext) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(localized(ref, 'Қўшимча фильтрлар'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<SignalStatus?>(initialValue: selectedStatus, decoration: InputDecoration(labelText: localized(ref, 'Ҳолат')), items: [
            DropdownMenuItem(value: null, child: Text(localized(ref, 'Барчаси'))),
            for (final status in SignalStatus.values) DropdownMenuItem(value: status, child: Text(localized(ref, statusText(status)))),
          ], onChanged: (v) => setState(() => selectedStatus = v)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(initialValue: category, decoration: InputDecoration(labelText: localized(ref, 'Ер тоифаси')), items: ['Барчаси', 'Суғориладиган ер', 'Қишлоқ хўжалиги ери'].map((v) => DropdownMenuItem(value: v, child: Text(localized(ref, v)))).toList(), onChanged: (v) => setState(() => category = v!)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(initialValue: agency, decoration: InputDecoration(labelText: localized(ref, 'Масъул орган')), items: ['Барчаси', 'Кадастр агентлиги', 'Агроинспекция'].map((v) => DropdownMenuItem(value: v, child: Text(localized(ref, v)))).toList(), onChanged: (v) => setState(() => agency = v!)),
          const SizedBox(height: 16),
          ActionButton('Қўллаш', primary: true, icon: Icons.check, onPressed: () => Navigator.pop(sheetContext)),
        ]),
      )));
}
