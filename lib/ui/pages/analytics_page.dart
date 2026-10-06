import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_state.dart';
import '../../domain/models.dart';
import '../../domain/queries.dart';
import '../filter_bar.dart';
import '../style.dart';
import '../widgets.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});
  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  String category = 'Барча турлар';
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider);
    final signals = visibleSignals(data).where((s) => category == 'Барча турлар' || s.category == category).toList();
    final high = signals.where((s) => s.risk == Risk.high).length;
    final medium = signals.where((s) => s.risk == Risk.medium).length;
    final low = signals.where((s) => s.risk == Risk.low).length;
    final districtCounts = <String, int>{};
    for (final signal in signals) { districtCounts[signal.address] = (districtCounts[signal.address] ?? 0) + 1; }
    final ranking = districtCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final categories = <String, int>{};
    for (final s in signals) { categories[s.title] = (categories[s.title] ?? 0) + 1; }
    final topType = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return CustomScrollView(slivers: [
      const SliverToBoxAdapter(child: HeroHeader(title: 'Таҳлиллар', subtitle: 'Ер қонунчилиги ижроси бўйича таҳлилий кўрсаткичлар')),
      SliverPadding(padding: const EdgeInsets.fromLTRB(15, 0, 15, 18), sliver: SliverList(delegate: SliverChildListDelegate([
        const Row(children: [DemoLabel(), Spacer()]), const SizedBox(height: 10),
        Row(children: [const Expanded(child: RegionDateBar()), FilterChipButton(label: category, icon: Icons.filter_list, onTap: () async {
          final picked = await showModalBottomSheet<String>(context: context, backgroundColor: card, builder: (context) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [for (final value in ['Барча турлар', 'Суғориладиган ер', 'Қишлоқ хўжалиги ери']) ListTile(title: Text(localized(ref, value)), onTap: () => Navigator.pop(context, value))])));
          if (picked != null) setState(() => category = picked);
        })]),
        const SizedBox(height: 12),
        SizedBox(height: 112, child: Row(children: [
          Expanded(child: KpiCard(title: 'Жами сигналлар', value: '${signals.length}', icon: Icons.article_outlined, color: blue)), const SizedBox(width: 7),
          Expanded(child: KpiCard(title: 'Юқори хавф', value: '$high', icon: Icons.warning_rounded, color: red)), const SizedBox(width: 7),
          Expanded(child: KpiCard(title: 'Ўрта хавф', value: '$medium', icon: Icons.error, color: yellow)), const SizedBox(width: 7),
          Expanded(child: KpiCard(title: 'Паст хавф', value: '$low', icon: Icons.verified, color: green)),
        ])),
        const SizedBox(height: 12),
        Panel(child: Column(children: [const SectionTitle('Сигналлар динамикаси'), const SizedBox(height: 14), TrendChart(signals)])),
        const SizedBox(height: 12),
        Panel(child: Column(children: [const SectionTitle('Хавф даражалари бўйича тақсимот', icon: Icons.pie_chart), const SizedBox(height: 14), DistributionChart(signals)])),
        const SizedBox(height: 12),
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Ҳудудлар кесимида (топ 5)', icon: Icons.bar_chart), const SizedBox(height: 12),
          for (final item in ranking.take(5)) ...[
            Row(children: [SizedBox(width: 103, child: Text(localized(ref, item.key), style: const TextStyle(color: muted, fontSize: 11))), Expanded(child: LinearProgressIndicator(value: ranking.first.value == 0 ? 0 : item.value / ranking.first.value, minHeight: 10, borderRadius: BorderRadius.circular(4), color: gold, backgroundColor: stroke)), const SizedBox(width: 10), Text('${item.value}', style: const TextStyle(color: Colors.white, fontSize: 11))]),
            const SizedBox(height: 10),
          ],
        ])),
        const SizedBox(height: 12),
        Panel(onTap: () => context.push('/reports'), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Асосий хулосалар', icon: Icons.lightbulb_outline, trailing: 'Ҳисобот'), const SizedBox(height: 12),
          Text(localized(ref, '1. Энг кўп сигнал: ${ranking.isEmpty ? '—' : ranking.first.key} — ${ranking.isEmpty ? 0 : ranking.first.value} та.'), style: const TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 8),
          Text(localized(ref, '2. Асосий тур: ${topType.isEmpty ? '—' : topType.first.key}.'), style: const TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 8),
          Text(localized(ref, '3. Юқори хавф улуши: ${signals.isEmpty ? 0 : (high * 100 / signals.length).round()}%.'), style: const TextStyle(color: muted, fontSize: 12)),
        ])),
      ]))),
    ]);
  }
}
