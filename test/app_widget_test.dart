import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yer_prokuror/app_state.dart';
import 'package:yer_prokuror/data/fixtures.dart';
import 'package:yer_prokuror/data/repository.dart';
import 'package:yer_prokuror/domain/models.dart';
import 'package:yer_prokuror/main.dart';
import 'package:yer_prokuror/ui/pages/analytics_page.dart';
import 'package:yer_prokuror/ui/pages/registry_page.dart';
import 'package:yer_prokuror/ui/pages/map_page.dart';
import 'package:yer_prokuror/ui/pages/more_pages.dart';

class _FakeRepository implements SignalRepository {
  _FakeRepository() {
    final signals = buildSignals().take(26).toList();
    initial = AppData(signals: signals, registry: buildRegistry(signals).take(26).toList(), role: UserRole.prosecutor, latin: false, demoDate: DateTime(2026, 4, 30));
  }
  @override
  late final AppData initial;
  @override
  Future<void> addRecord(RegistryRecord record) async {}
  @override
  Future<void> savePreferences(AppData data) async {}
  @override
  Future<void> saveSignal(RiskSignal signal) async {}
  @override
  Future<AppData> reset() async => initial;
}

void main() {
  testWidgets('main sections and detail open on a phone viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
    await tester.pumpWidget(ProviderScope(overrides: [repositoryProvider.overrideWithValue(_FakeRepository())], child: const YerProkurorApp()));
    await tester.pumpAndSettle();
    expect(find.text('YER PROKUROR'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.warning_amber_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('RSK-ASOS-01'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('RSK-ASOS-01').first);
    await tester.pumpAndSettle();
    expect(find.text('Ер участкаси маълумотлари'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Таҳлиллар')).first);
    await tester.pumpAndSettle();
    expect(find.byType(AnalyticsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Реестр')).first);
    await tester.pumpAndSettle();
    expect(find.byType(RegistryPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Харита')).first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(RiskMapPage), findsOneWidget);
    await tester.tap(find.byIcon(Icons.person_outline).first);
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
