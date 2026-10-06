import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/models.dart';
import '../domain/queries.dart';
import 'style.dart';

Future<void> exportRegistryCsv(List<RegistryRecord> records) async {
  String q(String v) => '"${v.replaceAll('"', '""')}"';
  final lines = <String>['ID,Тури,Номи,Ҳолати,Ҳудуд,Рақам,Сана'];
  for (final r in records) { lines.add([r.id, r.kind, r.title, r.status, r.region, r.reference, dateText(r.createdAt)].map(q).join(',')); }
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/yer_prokuror_reestr.csv');
  await file.writeAsBytes([0xef, 0xbb, 0xbf, ...utf8.encode(lines.join('\r\n'))]);
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'YER PROKUROR реестри'));
}

List<int> buildComparisonCsvBytes(AppData data) {
  String q(String v) => '"${v.replaceAll('"', '""')}"';
  final lines = <String>['Назорат объекти,Кадастр рақами,Майдон,Материал мазмуни,Келиб тушган сана,Қайта расмийлаштириш,Жиноят иши,ЖПК қарори,Зарар,Қайтарилган ер,Судга юбориш,Суд натижаси'];
  for (final s in visibleSignals(data)) {
    lines.add([
      s.id, s.cadastral, s.area.toStringAsFixed(1), s.title, dateText(s.detectedAt),
      '', '', '', s.damage.toStringAsFixed(0), s.status == SignalStatus.completed ? s.area.toStringAsFixed(1) : '0',
      s.claimNumber ?? '', s.courtOutcome ?? '',
    ].map(q).join(','));
  }
  return [0xef, 0xbb, 0xbf, ...utf8.encode(lines.join('\r\n'))];
}

Future<void> exportComparisonCsv(AppData data) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/yer_prokuror_solishtirma_dalolatnoma.csv');
  await file.writeAsBytes(buildComparisonCsvBytes(data));
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: 'YER PROKUROR солиштирма далолатнома'));
}

Future<pw.Document> _newDocument() async {
  final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
  final font = pw.Font.ttf(fontData);
  return pw.Document(theme: pw.ThemeData.withFont(base: font, bold: font));
}

Future<void> exportRegistryPdf(List<RegistryRecord> records) async {
  await Printing.sharePdf(bytes: await buildRegistryPdfBytes(records), filename: 'yer_prokuror_reestr.pdf');
}

Future<Uint8List> buildRegistryPdfBytes(List<RegistryRecord> records) async {
  final doc = await _newDocument();
  doc.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, maxPages: 150, build: (_) => [
    pw.Text('YER PROKUROR — РЕЕСТР', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
    pw.SizedBox(height: 10),
    pw.Text('ДЕМО МАЪЛУМОТ · ${records.length} та ёзув'),
    pw.SizedBox(height: 10),
    pw.TableHelper.fromTextArray(headers: ['ID', 'Тури', 'Номи', 'Ҳолат', 'Ҳудуд'], data: records.map((r) => [r.id, r.kind, r.title, r.status, r.region]).toList(), cellStyle: const pw.TextStyle(fontSize: 7), headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
  ]));
  return doc.save();
}

Future<void> exportSummaryPdf(AppData data) async {
  await Printing.sharePdf(bytes: await buildSummaryPdfBytes(data), filename: 'yer_prokuror_hisobot.pdf');
}

Future<Uint8List> buildSummaryPdfBytes(AppData data) async {
  final doc = await _newDocument();
  final signals = visibleSignals(data);
  final recovered = signals.fold<double>(0, (sum, s) => sum + s.recovered);
  final damage = signals.fold<double>(0, (sum, s) => sum + s.damage);
  doc.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, build: (_) => [
    pw.Text('YER PROKUROR — ТАҲЛИЛИЙ ҲИСОБОТ', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
    pw.SizedBox(height: 10), pw.Text('ДЕМО МАЪЛУМОТ · ${dateText(data.demoDate)}'),
    pw.SizedBox(height: 15),
    pw.Text('Ҳудуд: ${data.selectedRegion}'),
    pw.Text('Жами сигналлар: ${signals.length}'),
    pw.Text('Юқори хавф: ${signals.where((s) => s.risk == Risk.high).length}'),
    pw.Text('Ўрта хавф: ${signals.where((s) => s.risk == Risk.medium).length}'),
    pw.Text('Паст хавф: ${signals.where((s) => s.risk == Risk.low).length}'),
    pw.Text('Намунали зарар: ${money(damage)} сўм'),
    pw.Text('Қайд этилган ундирув: ${money(recovered)} сўм'),
    pw.SizedBox(height: 12),
    pw.Text('Ушбу ҳужжат намунавий маълумотлар асосида тузилган; расмий ҳуқуқий ёки молиявий далолатнома эмас.', style: const pw.TextStyle(fontSize: 9)),
  ]));
  return doc.save();
}
