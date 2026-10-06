import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_state.dart';
import '../data/fixtures.dart';
import 'style.dart';

class RegionDateBar extends ConsumerWidget {
  const RegionDateBar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    return Wrap(spacing: 7, runSpacing: 7, children: [
      FilterChipButton(label: data.selectedRegion, icon: Icons.location_on, onTap: () async {
        final value = await showModalBottomSheet<String>(context: context, backgroundColor: card, builder: (context) => SafeArea(child: ListView(shrinkWrap: true, children: [
          for (final region in ['Барча ҳудудлар', ...regions]) ListTile(title: Text(localized(ref, region)), onTap: () => Navigator.pop(context, region)),
        ])));
        if (value != null) ref.read(appControllerProvider.notifier).setRegion(value);
      }),
      FilterChipButton(label: dateText(data.demoDate), icon: Icons.calendar_month, onTap: () async {
        final date = await showDatePicker(context: context, initialDate: data.demoDate, firstDate: DateTime(2024), lastDate: DateTime(2027));
        if (date != null) ref.read(appControllerProvider.notifier).setDate(date);
      }),
    ]);
  }
}
