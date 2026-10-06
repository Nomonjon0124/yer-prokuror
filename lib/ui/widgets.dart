import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/models.dart';
import 'style.dart';

class SignalTile extends ConsumerWidget {
  const SignalTile(this.signal, {super.key, this.compact = false});
  final RiskSignal signal;
  final bool compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = riskColor(signal.risk);
    return Panel(
      onTap: () => context.go('/signals/${signal.id}'),
      padding: const EdgeInsets.all(12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(11)), child: Icon(riskIcon(signal.risk), color: color, size: 30)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(signal.id, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))), if (!compact) RiskPill(signal.risk)]),
          const SizedBox(height: 3),
          Text(localized(ref, signal.title), maxLines: compact ? 1 : 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 7),
          Wrap(spacing: 12, runSpacing: 3, children: [
            Text('⌖ ${localized(ref, signal.address)}', style: const TextStyle(color: muted, fontSize: 11)),
            Text('▣ ${signal.area.toStringAsFixed(1)} га', style: const TextStyle(color: muted, fontSize: 11)),
            if (!compact) Text(dateText(signal.detectedAt), style: const TextStyle(color: muted, fontSize: 11)),
          ]),
        ])),
        const SizedBox(width: 2),
        const Icon(Icons.chevron_right, color: muted, size: 18),
      ]),
    );
  }
}

class KpiCard extends ConsumerWidget {
  const KpiCard({super.key, required this.title, required this.value, required this.icon, required this.color, this.onTap, this.subtitle});
  final String title, value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Panel(
        onTap: onTap,
        borderColor: color.withValues(alpha: .55),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 21),
          const Spacer(),
          Text(localized(ref, title), maxLines: 2, style: const TextStyle(color: muted, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
          if (subtitle != null) Text(localized(ref, subtitle!), style: TextStyle(color: color, fontSize: 10)),
        ]),
      );
}

class DistributionChart extends ConsumerWidget {
  const DistributionChart(this.signals, {super.key});
  final List<RiskSignal> signals;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = [Risk.high, Risk.medium, Risk.low].map((r) => signals.where((s) => s.risk == r).length).toList();
    final total = counts.fold<int>(0, (a, b) => a + b);
    if (total == 0) return Text(localized(ref, 'Маълумот йўқ'), style: const TextStyle(color: muted));
    final chart = SizedBox(width: 125, height: 125, child: Stack(alignment: Alignment.center, children: [
        PieChart(PieChartData(centerSpaceRadius: 38, sectionsSpace: 1, sections: List.generate(3, (i) => PieChartSectionData(value: counts[i].toDouble(), color: [red, yellow, green][i], radius: 15, showTitle: false)))),
        Column(mainAxisSize: MainAxisSize.min, children: [Text('$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)), Text(localized(ref, 'жами'), style: const TextStyle(color: muted, fontSize: 10))]),
      ]));
    final legend = Column(crossAxisAlignment: CrossAxisAlignment.start, children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [CircleAvatar(radius: 5, backgroundColor: [red, yellow, green][i]), const SizedBox(width: 7), Expanded(child: Text(localized(ref, riskText(Risk.values[i])), style: const TextStyle(color: muted, fontSize: 10))), Text('${counts[i]}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))]),
      )));
    return LayoutBuilder(builder: (context, constraints) => constraints.maxWidth < 230
      ? Column(children: [chart, const SizedBox(height: 8), SizedBox(width: double.infinity, child: legend)])
      : Row(children: [chart, const SizedBox(width: 10), Expanded(child: legend)]));
  }
}

class TrendChart extends StatelessWidget {
  const TrendChart(this.signals, {super.key});
  final List<RiskSignal> signals;
  @override
  Widget build(BuildContext context) {
    final counts = List.generate(7, (i) => signals.where((s) => s.detectedAt.day == 24 + i && s.detectedAt.month == 4).length.toDouble());
    final max = counts.fold<double>(1, (a, b) => b > a ? b : a);
    return SizedBox(height: 135, child: BarChart(BarChartData(
      maxY: max * 1.2,
      alignment: BarChartAlignment.spaceAround,
      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: stroke, strokeWidth: .5)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (value, meta) => Padding(padding: const EdgeInsets.only(top: 5), child: Text('${24 + value.toInt()}', style: const TextStyle(color: muted, fontSize: 9))))),
      ),
      barGroups: List.generate(7, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: counts[i], color: [green, yellow, red, green, red, yellow, blue][i], width: 15, borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))])),
    )));
  }
}

class PagePadding extends StatelessWidget {
  const PagePadding({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 20), children: [for (final child in children) ...[child, const SizedBox(height: 12)]]);
}

class DemoLabel extends ConsumerWidget {
  const DemoLabel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: gold.withValues(alpha: .16), borderRadius: BorderRadius.circular(8), border: Border.all(color: gold.withValues(alpha: .45))),
        child: Text(localized(ref, 'ДЕМО МАЪЛУМОТ'), style: const TextStyle(color: gold, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: .5)),
      );
}
