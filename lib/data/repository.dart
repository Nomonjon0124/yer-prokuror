import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';
import 'fixtures.dart';

abstract class SignalRepository {
  AppData get initial;
  Future<void> saveSignal(RiskSignal signal);
  Future<void> addRecord(RegistryRecord record);
  Future<void> savePreferences(AppData data);
  Future<AppData> reset();
}

class DemoRepository implements SignalRepository {
  DemoRepository._(this._db, this._prefs, this.initial);
  final Database _db;
  final SharedPreferencesAsync _prefs;
  @override
  final AppData initial;
  static final _signals = stringMapStoreFactory.store('signals');
  static final _registry = stringMapStoreFactory.store('registry');

  static Future<DemoRepository> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final db = await databaseFactoryIo.openDatabase('${dir.path}/yer_prokuror_demo.db');
    final prefs = SharedPreferencesAsync();
    if (await _signals.count(db) == 0) {
      final signals = buildSignals();
      final registry = buildRegistry(signals);
      await db.transaction((txn) async {
        for (final item in signals) { await _signals.record(item.id).put(txn, item.toJson()); }
        for (final item in registry) { await _registry.record(item.id).put(txn, item.toJson()); }
      });
    }
    final signals = (await _signals.find(db)).map((e) => RiskSignal.fromJson(Map<String, dynamic>.from(e.value))).toList();
    final registry = (await _registry.find(db)).map((e) => RegistryRecord.fromJson(Map<String, dynamic>.from(e.value))).toList();
    final scenarioJson = jsonDecode(await rootBundle.loadString('assets/data/risk_scenarios.json')) as List<dynamic>;
    final scenarios = {for (final item in scenarioJson) (item as Map<String, dynamic>)['number'] as int: RiskScenario.fromJson(item)};
    signals.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    final roleName = await prefs.getString('role') ?? UserRole.prosecutor.name;
    final dateText = await prefs.getString('demoDate');
    final data = AppData(
      signals: signals,
      registry: registry,
      role: UserRole.values.firstWhere((r) => r.name == roleName, orElse: () => UserRole.prosecutor),
      latin: await prefs.getBool('latin') ?? false,
      demoDate: dateText == null ? DateTime(2026, 4, 30) : DateTime.tryParse(dateText) ?? DateTime(2026, 4, 30),
      selectedRegion: await prefs.getString('region') ?? 'Барча ҳудудлар',
      scenarios: scenarios,
    );
    return DemoRepository._(db, prefs, data);
  }

  @override
  Future<void> saveSignal(RiskSignal signal) => _signals.record(signal.id).put(_db, signal.toJson()).then((_) {});
  @override
  Future<void> addRecord(RegistryRecord record) => _registry.record(record.id).put(_db, record.toJson()).then((_) {});
  @override
  Future<void> savePreferences(AppData data) async {
    await _prefs.setString('role', data.role.name);
    await _prefs.setBool('latin', data.latin);
    await _prefs.setString('demoDate', data.demoDate.toIso8601String());
    await _prefs.setString('region', data.selectedRegion);
  }
  @override
  Future<AppData> reset() async {
    final root = await getApplicationDocumentsDirectory();
    final evidenceFolder = Directory('${root.path}/evidence');
    if (await evidenceFolder.exists()) await evidenceFolder.delete(recursive: true);
    await _db.transaction((txn) async {
      await _signals.delete(txn);
      await _registry.delete(txn);
      final signals = buildSignals();
      for (final item in signals) { await _signals.record(item.id).put(txn, item.toJson()); }
      for (final item in buildRegistry(signals)) { await _registry.record(item.id).put(txn, item.toJson()); }
    });
    final signals = buildSignals();
    final data = AppData(signals: signals, registry: buildRegistry(signals), role: UserRole.prosecutor, latin: false, demoDate: DateTime(2026, 4, 30), scenarios: initial.scenarios);
    await savePreferences(data);
    return data;
  }
}

/// API boundary for a future approved integration. The demo never sends data here.
class ApiGateway {
  ApiGateway(String baseUrl) : client = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 20)));
  final Dio client;
  Future<Map<String, dynamic>> getJson(String path) async => Map<String, dynamic>.from((await client.get<Object?>(path)).data as Map);
  Future<Map<String, dynamic>> postJson(String path, Map<String, Object?> body) async => Map<String, dynamic>.from((await client.post<Object?>(path, data: body)).data as Map);
}

Future<File> saveEvidenceFile(String sourcePath, String name) async {
  final root = await getApplicationDocumentsDirectory();
  final folder = Directory('${root.path}/evidence');
  if (!await folder.exists()) await folder.create(recursive: true);
  final safe = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  return File(sourcePath).copy('${folder.path}/${DateTime.now().microsecondsSinceEpoch}_$safe');
}

Future<File> saveEvidenceBytes(Uint8List bytes, String name) async {
  final root = await getApplicationDocumentsDirectory();
  final folder = Directory('${root.path}/evidence');
  if (!await folder.exists()) await folder.create(recursive: true);
  final safe = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  final file = File('${folder.path}/${DateTime.now().microsecondsSinceEpoch}_$safe');
  await file.writeAsBytes(bytes);
  return file;
}
