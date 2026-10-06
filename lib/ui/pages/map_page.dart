import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import '../../app_state.dart';
import '../../domain/models.dart';
import '../../domain/queries.dart';
import '../filter_bar.dart';
import '../style.dart';

class RiskMapPage extends ConsumerStatefulWidget {
  const RiskMapPage({super.key});
  @override
  ConsumerState<RiskMapPage> createState() => _RiskMapPageState();
}

class _RiskMapPageState extends ConsumerState<RiskMapPage> {
  final controller = MapController();
  final search = TextEditingController();
  Risk? selectedRisk;
  RiskSignal? selected;
  bool contours = true;
  bool tileError = false;
  @override
  void dispose() { search.dispose(); controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(appControllerProvider.select((s) => s.selectedRegion), (previous, next) {
      final center = switch (next) { 'Самарқанд вилояти' => const LatLng(39.68, 67.01), 'Фарғона вилояти' => const LatLng(40.42, 71.83), _ => const LatLng(41.32, 69.23) };
      controller.move(center, 11);
      setState(() => selected = null);
    });
    final data = ref.watch(appControllerProvider);
    final signals = visibleSignals(data).where((s) => selectedRisk == null || s.risk == selectedRisk).toList();
    final polygons = signals.where((s) => s.detailed).map((s) {
      final lat = s.location.latitude, lng = s.location.longitude;
      return Polygon(points: [LatLng(lat - .002, lng - .002), LatLng(lat - .0016, lng + .002), LatLng(lat + .0015, lng + .0022), LatLng(lat + .0017, lng - .0018)], color: riskColor(s.risk).withValues(alpha: .25), borderColor: riskColor(s.risk), borderStrokeWidth: 2);
    }).toList();
    return Column(children: [
      const HeroHeader(title: 'Харита', subtitle: 'Хавф сигналларининг жойлашуви', height: 200),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: TextField(controller: search, onSubmitted: (value) {
        final matches = signals.where((s) => '${s.id} ${s.cadastral} ${s.address}'.toLowerCase().contains(value.toLowerCase())).toList();
        if (matches.isEmpty) { showMessage(context, localized(ref, 'Манзил ёки кадастр рақами топилмади')); return; }
        setState(() => selected = matches.first);
        controller.move(matches.first.location, 14);
      }, decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: localized(ref, 'Манзил ёки кадастр рақами'), suffixIcon: IconButton(onPressed: () { search.clear(); setState(() => selected = null); }, icon: const Icon(Icons.clear))))),
      const SizedBox(height: 8),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 15), child: RegionDateBar()),
      const SizedBox(height: 8),
      SizedBox(height: 41, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 15), children: [
        FilterChipButton(label: 'Барча сигналлар', icon: Icons.apps, selected: selectedRisk == null, onTap: () => setState(() => selectedRisk = null)),
        for (final risk in Risk.values) ...[const SizedBox(width: 7), FilterChipButton(label: riskText(risk), icon: riskIcon(risk), selected: selectedRisk == risk, onTap: () => setState(() => selectedRisk = risk))],
      ])),
      const SizedBox(height: 8),
      Expanded(child: Stack(children: [
        FlutterMap(mapController: controller, options: MapOptions(initialCenter: switch (data.selectedRegion) { 'Самарқанд вилояти' => const LatLng(39.68, 67.01), 'Фарғона вилояти' => const LatLng(40.42, 71.83), _ => const LatLng(41.32, 69.23) }, initialZoom: 11), children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'uz.yerprokuror.demo',
            errorTileCallback: (_, _, _) { if (!tileError) WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => tileError = true); }); },
          ),
          if (contours) PolygonLayer(polygons: polygons),
          MarkerLayer(markers: signals.map((s) => Marker(point: s.location, width: 32, height: 32, child: GestureDetector(onTap: () => setState(() => selected = s), child: Container(decoration: BoxDecoration(color: riskColor(s.risk), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)]), child: const Icon(Icons.location_on, size: 19, color: navy))))).toList()),
        ]),
        Positioned(top: 12, left: 12, child: Panel(color: navy.withValues(alpha: .92), padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(localized(ref, 'Хавф даражаси'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
          for (final risk in Risk.values) Padding(padding: const EdgeInsets.only(top: 5), child: Row(children: [CircleAvatar(radius: 5, backgroundColor: riskColor(risk)), const SizedBox(width: 5), Text(localized(ref, riskText(risk)), style: const TextStyle(color: muted, fontSize: 10))])),
        ]))),
        Positioned(top: 12, right: 12, child: Column(children: [
          _MapButton(Icons.layers, () => setState(() => contours = !contours)),
          const SizedBox(height: 7),
          _MapButton(Icons.add, () => controller.move(controller.camera.center, controller.camera.zoom + 1)),
          _MapButton(Icons.remove, () => controller.move(controller.camera.center, controller.camera.zoom - 1)),
          const SizedBox(height: 7),
          _MapButton(Icons.my_location, _goToLocation),
        ])),
        if (tileError) Positioned(top: 140, left: 35, right: 35, child: Panel(color: navy.withValues(alpha: .9), child: Text(localized(ref, 'Харита фони юкланмади. Контур ва сигналлар ишлашда давом этади.'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.white)))),
        if (selected != null) Positioned(left: 10, right: 10, bottom: 28, child: Panel(color: navy.withValues(alpha: .96), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(selected!.id, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold))), RiskPill(selected!.risk), IconButton(onPressed: () => setState(() => selected = null), icon: const Icon(Icons.close, size: 18))]),
          Text(localized(ref, selected!.address), style: const TextStyle(color: muted)),
          const SizedBox(height: 7),
          Text('${localized(ref, 'Кадастр рақами')}: ${selected!.cadastral}', style: const TextStyle(color: muted, fontSize: 12)),
          Text('${localized(ref, 'Майдон')}: ${selected!.area.toStringAsFixed(1)} га · ${localized(ref, 'Хавф балли')}: ${selected!.score}', style: const TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 9),
          ActionButton('Батафсил кўриш', primary: true, icon: Icons.description_outlined, onPressed: () => context.go('/signals/${selected!.id}')),
        ]))),
        Positioned(bottom: 0, right: 4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), color: Colors.white70, child: const Text('© OpenStreetMap contributors', style: TextStyle(color: Colors.black87, fontSize: 9)))),
      ])),
    ]);
  }

  Future<void> _goToLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.whileInUse || permission == LocationPermission.always ? permission : await Geolocator.requestPermission();
      if (granted == LocationPermission.denied || granted == LocationPermission.deniedForever) { if (mounted) showMessage(context, localized(ref, 'Жойлашув рухсати берилмади')); return; }
      final pos = await Geolocator.getCurrentPosition();
      controller.move(LatLng(pos.latitude, pos.longitude), 13);
    } catch (_) { if (mounted) showMessage(context, localized(ref, 'Жойлашувни аниқлаб бўлмади')); }
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton(this.icon, this.onTap);
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 1), child: SizedBox(width: 43, height: 43, child: Panel(onTap: onTap, padding: EdgeInsets.zero, color: navy, child: Icon(icon, color: Colors.white))));
}
