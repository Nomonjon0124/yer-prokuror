import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_state.dart';
import '../../domain/models.dart';
import '../../domain/queries.dart';
import '../filter_bar.dart';
import '../style.dart';
import '../widgets.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    final signals = visibleSignals(data);
    int count(Risk risk) => signals.where((s) => s.risk == risk).length;
    final recent = [...signals]..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return CustomScrollView(slivers: [
      const SliverToBoxAdapter(child: HeroHeader(title: 'Бош саҳифа', subtitle: 'Ер қонунчилиги ижроси устидан прокурор назорати')),
      SliverPadding(padding: const EdgeInsets.fromLTRB(15, 0, 15, 22), sliver: SliverList(delegate: SliverChildListDelegate([
        const Row(children: [DemoLabel(), Spacer()]),
        const SizedBox(height: 12),
        const RegionDateBar(),
        const SizedBox(height: 14),
        SizedBox(height: 115, child: Row(children: [
          Expanded(child: KpiCard(title: 'Юқори хавф', value: '${count(Risk.high)}', icon: Icons.warning_rounded, color: red, onTap: () => context.go('/signals?risk=high'))),
          const SizedBox(width: 8),
          Expanded(child: KpiCard(title: 'Ўрта хавф', value: '${count(Risk.medium)}', icon: Icons.error_rounded, color: yellow, onTap: () => context.go('/signals?risk=medium'))),
        ])),
        const SizedBox(height: 8),
        SizedBox(height: 115, child: Row(children: [
          Expanded(child: KpiCard(title: 'Паст хавф', value: '${count(Risk.low)}', icon: Icons.verified_rounded, color: green, onTap: () => context.go('/signals?risk=low'))),
          const SizedBox(width: 8),
          Expanded(child: KpiCard(title: 'Жами сигналлар', value: '${signals.length}', icon: Icons.bar_chart_rounded, color: blue, onTap: () => context.go('/signals'))),
        ])),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Panel(onTap: () => context.go('/analytics'), child: Column(children: [const SectionTitle('Сигналлар динамикаси', icon: Icons.bar_chart), const SizedBox(height: 10), TrendChart(signals)]))),
          const SizedBox(width: 8),
          Expanded(child: Panel(onTap: () => context.go('/analytics'), child: Column(children: [const SectionTitle('Хавф даражалари', icon: Icons.pie_chart), const SizedBox(height: 12), DistributionChart(signals)]))),
        ]),
        const SizedBox(height: 12),
        Panel(child: Column(children: [
          SectionTitle('Сўнгги хавф сигналлари', icon: Icons.notifications_active, trailing: 'Ҳаммасини кўриш', onTap: () => context.go('/signals')),
          const SizedBox(height: 10),
          for (final signal in recent.take(3)) ...[SignalTile(signal, compact: true), const SizedBox(height: 7)],
        ])),
        const SizedBox(height: 12),
        Panel(child: Column(children: [
          const SectionTitle('Тезкор ҳаракатлар', icon: Icons.bolt_rounded), const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _QuickAction('Харитани кўриш', Icons.map_outlined, () => context.go('/map'))),
            const SizedBox(width: 7),
            Expanded(child: _QuickAction('Ҳисобот', Icons.description_outlined, () => context.push('/reports'))),
            const SizedBox(width: 7),
            Expanded(child: _QuickAction('Ижро', Icons.fact_check_outlined, () => context.push('/executions'))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _QuickAction('Даъво ва суд', Icons.gavel, () => context.push('/court'))),
            const SizedBox(width: 7),
            Expanded(child: _QuickAction('Зарар/тўлов', Icons.payments_outlined, () => context.push('/damage'))),
          ]),
        ])),
      ]))),
    ]);
  }
}

class _QuickAction extends ConsumerWidget {
  const _QuickAction(this.title, this.icon, this.onTap);
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Panel(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
        child: Column(children: [Icon(icon, color: gold, size: 25), const SizedBox(height: 5), Text(localized(ref, title), maxLines: 2, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10))]),
      );
}
