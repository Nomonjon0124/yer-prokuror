import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_state.dart';
import '../../data/repository.dart';
import '../../domain/models.dart';
import '../../domain/queries.dart';
import '../../domain/workflow.dart';
import '../style.dart';
import '../widgets.dart';

class SignalDetailPage extends ConsumerWidget {
  const SignalDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    final matches = data.signals.where((s) => s.id == id);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Сигнал')),
        body: const Center(child: Text('Сигнал топилмади')),
      );
    }
    final signal = matches.first;
    final scenario = data.scenarios[signal.scenarioNumber];
    final overdue = isOverdue(signal, data.demoDate);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        title: Text(signal.id),
        actions: [
          const DemoLabel(),
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(15, 10, 15, 24),
        children: [
          Panel(
            borderColor: riskColor(signal.risk),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      riskIcon(signal.risk),
                      color: riskColor(signal.risk),
                      size: 34,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        localized(ref, signal.title),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    RiskPill(signal.risk),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  localized(ref, scenario?.fact ?? signal.description),
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  children: [
                    Chip(
                      label: Text(
                        localized(ref, statusText(signal.status)),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    if (overdue)
                      Chip(
                        label: Text(
                          localized(ref, 'Муддати ўтган'),
                          style: const TextStyle(color: red, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              children: [
                const SectionTitle(
                  'Ер участкаси маълумотлари',
                  icon: Icons.landscape,
                ),
                const SizedBox(height: 12),
                _Info('Манзил', '${signal.region}, ${signal.address}'),
                _Info('Кадастр рақами', signal.cadastral),
                _Info('Майдон', '${signal.area.toStringAsFixed(1)} га'),
                _Info('Ер тоифаси', signal.category),
                _Info('Рухсат этилган фойдаланиш', signal.permittedUse),
                _Info('Ҳуқуқ эгаси', signal.owner),
                _Info('Масъул орган', signal.assignedAgency),
                _Info(
                  'Координаталар',
                  '${signal.location.latitude.toStringAsFixed(5)}, ${signal.location.longitude.toStringAsFixed(5)}',
                ),
                _Info('Тасвир санаси', dateText(signal.detectedAt)),
                _Info('Хавф кўрсаткичи', '${signal.score} / 100'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (scenario != null) ...[
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    'ТЗдаги намунавий кейс',
                    icon: Icons.menu_book,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    localized(ref, scenario.narrative),
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      localized(ref, 'Ҳуқуқий асос ва вақт чизиғи'),
                      style: const TextStyle(fontSize: 12, color: gold),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          localized(ref, scenario.basis),
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          localized(ref, scenario.timeline),
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  'Босқичлар ва вақт чизиғи',
                  icon: Icons.timeline,
                ),
                const SizedBox(height: 12),
                _StageTrack(signal.stage),
                const SizedBox(height: 12),
                for (final event in signal.events.reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle, color: gold, size: 10),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localized(ref, event.title),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${dateText(event.at)} · ${event.actor} · ${localized(ref, event.note)}',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  '${localized(ref, 'Босқич муддати')}: ${dateText(signal.deadline)}',
                  style: TextStyle(color: overdue ? red : gold, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              children: [
                const SectionTitle('Олдин — кейин', icon: Icons.compare),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ParcelImage(label: 'Олдин', changed: false),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ParcelImage(label: 'Кейин', changed: true),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  localized(
                    ref,
                    'Намунали визуал таққослаш. Расмий далил учун юқори аниқликдаги сурат керак.',
                  ),
                  style: const TextStyle(color: muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  'Далиллар (${signal.evidence.length})',
                  icon: Icons.attach_file,
                  trailing: 'Қўшиш',
                  onTap: () => _pickEvidence(context, ref, signal),
                ),
                const SizedBox(height: 10),
                if (signal.evidence.isEmpty)
                  Text(
                    localized(ref, 'Ҳали далил юкланмаган'),
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                for (final item in signal.evidence)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      item.kind == 'image' ? Icons.image : Icons.description,
                      color: blue,
                    ),
                    title: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('${dateText(item.at)} · ${item.by.name}'),
                    onTap: () => _previewEvidence(context, item),
                  ),
                const SizedBox(height: 5),
                ActionButton(
                  'Файл ёки сурат қўшиш',
                  icon: Icons.add,
                  onPressed: () => _pickEvidence(context, ref, signal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  'Ҳуқуқий таҳлил · демо',
                  icon: Icons.balance,
                ),
                const SizedBox(height: 8),
                Text(
                  localized(
                    ref,
                    signal.legalAnalysis ?? scenario?.analysis ?? 'Факт: реестр ва кузатув ўртасида тафовут. Етишмайдиган далиллар: кўздан кечириш далолатномаси ва геобелгили сурат. Сигналнинг ўзи қонунбузилиш факти эмас; якуний баҳони прокурор беради.',
                  ),
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (signal.claimNumber != null || signal.executionNumber != null)
            Panel(
              child: Column(
                children: [
                  const SectionTitle('Суд ва ижро', icon: Icons.gavel),
                  const SizedBox(height: 8),
                  if (signal.claimNumber != null)
                    _Info('Даъво', signal.claimNumber!),
                  if (signal.caseNumber != null)
                    _Info('Суд иши', signal.caseNumber!),
                  if (signal.courtOutcome != null)
                    _Info('Суд натижаси', signal.courtOutcome!),
                  if (signal.appealFiled) const _Info('Апелляция', 'Берилган'),
                  if (signal.executionNumber != null)
                    _Info('Ижро иши', signal.executionNumber!),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              children: [
                const SectionTitle('Навбатдаги ҳаракат', icon: Icons.bolt),
                const SizedBox(height: 10),
                _ActionArea(signal),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ActionButton(
            'Зарар ва тўловни кўриш',
            icon: Icons.payments_outlined,
            onPressed: () => context.push('/damage'),
          ),
        ],
      ),
    );
  }
}

class _Info extends ConsumerWidget {
  const _Info(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            localized(ref, label),
            style: const TextStyle(color: muted, fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            localized(ref, value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StageTrack extends ConsumerWidget {
  const _StageTrack(this.current);
  final Stage current;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var i = 0; i < Stage.values.length; i++) ...[
          if (i > 0)
            Container(
              width: 16,
              height: 1,
              color: i <= current.index ? gold : stroke,
            ),
          Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: i <= current.index ? gold : stroke,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: i <= current.index ? navy : Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                localized(
                  ref,
                  ['Аниқлаш', 'Тасдиқ', 'Чора', 'Прокурор', 'Суд', 'Ижро'][i],
                ),
                style: const TextStyle(color: muted, fontSize: 9),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _ParcelImage extends ConsumerWidget {
  const _ParcelImage({required this.label, required this.changed});
  final String label;
  final bool changed;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      Container(
        height: 105,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xff27432a),
          border: Border.all(color: changed ? red : green, width: 2),
        ),
        child: CustomPaint(
          painter: _ParcelPainter(changed),
          child: Center(
            child: Icon(
              changed ? Icons.home_work : Icons.grass,
              color: Colors.white70,
              size: 33,
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        localized(ref, label),
        style: const TextStyle(color: muted, fontSize: 11),
      ),
    ],
  );
}

class _ParcelPainter extends CustomPainter {
  _ParcelPainter(this.changed);
  final bool changed;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .13)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x + 30, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 6), grid);
    }
    if (changed) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * .27,
          size.height * .25,
          size.width * .46,
          size.height * .5,
        ),
        Paint()..color = red.withValues(alpha: .43),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParcelPainter oldDelegate) =>
      changed != oldDelegate.changed;
}

class _ActionArea extends ConsumerWidget {
  const _ActionArea(this.signal);
  final RiskSignal signal;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    final actions = WorkflowAction.values
        .where((a) => canPerform(signal, data.role, a, asOf: data.demoDate))
        .toList();
    if (actions.isEmpty) {
      return Text(
        localized(
          ref,
          'Бу рол учун ҳозир амал мавжуд эмас. Профилда ролни алмаштиринг.',
        ),
        style: const TextStyle(color: muted, fontSize: 12),
      );
    }
    return Column(
      children: [
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: ActionButton(
              _label(action),
              icon: _icon(action),
              primary: action == actions.first,
              onPressed: () => _run(context, ref, action),
            ),
          ),
      ],
    );
  }

  String _label(WorkflowAction action) => switch (action) {
    WorkflowAction.accept => 'Сигнални қабул қилиш',
    WorkflowAction.chooseMethod => 'Текширув усулини танлаш',
    WorkflowAction.reject => 'Ҳужжат билан рад этиш',
    WorkflowAction.confirm => 'Қонунбузилишни тасдиқлаш',
    WorkflowAction.recordMeasure => 'Кўрилган чорани қайд этиш',
    WorkflowAction.requestDocuments => 'Ҳужжатларни талаб қилиш',
    WorkflowAction.legalAssessment => 'Ҳуқуқий баҳо бериш',
    WorkflowAction.issueProtest => 'Протест киритиш',
    WorkflowAction.issueSubmission => 'Тақдимнома киритиш',
    WorkflowAction.issueWarning => 'Огоҳлантириш бериш',
    WorkflowAction.requestMoreInspection => 'Қўшимча текширув сўраш',
    WorkflowAction.fileClaim => 'Даъво киритиш',
    WorkflowAction.courtDecision => 'Суд қарорини қайд этиш',
    WorkflowAction.appeal => 'Апелляция бериш',
    WorkflowAction.startExecution => 'Ижро ишини очиш',
    WorkflowAction.verifyExecution => 'Ижрони қайта текшириш',
  };
  IconData _icon(WorkflowAction action) => switch (action) {
    WorkflowAction.reject => Icons.close,
    WorkflowAction.confirm ||
    WorkflowAction.verifyExecution => Icons.check_circle_outline,
    WorkflowAction.fileClaim ||
    WorkflowAction.courtDecision ||
    WorkflowAction.appeal => Icons.gavel,
    WorkflowAction.startExecution => Icons.play_arrow,
    WorkflowAction.issueProtest ||
    WorkflowAction.issueSubmission ||
    WorkflowAction.issueWarning ||
    WorkflowAction.requestMoreInspection => Icons.description_outlined,
    _ => Icons.arrow_forward,
  };
  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    WorkflowAction action,
  ) async {
    String? note;
    bool? restored;
    if (action == WorkflowAction.chooseMethod) {
      note = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: card,
        builder: (c) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final value in [
                'Юқори аниқликдаги сурат',
                'УЧА кузатуви',
                'Жойига чиқиб ўрганиш',
              ])
                ListTile(
                  title: Text(localized(ref, value)),
                  onTap: () => Navigator.pop(c, value),
                ),
            ],
          ),
        ),
      );
      if (note == null) return;
    }
    if (!context.mounted) return;
    if (action == WorkflowAction.verifyExecution) {
      restored = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(localized(ref, 'Объектив қайта текшириш')),
          content: Text(
            localized(ref, 'Янги суратда ўзгариш бартараф этилганми?'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(localized(ref, 'Йўқ — формал ижро')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(localized(ref, 'Ҳа, тикланган')),
            ),
          ],
        ),
      );
      if (restored == null) return;
    }
    if (!context.mounted) return;
    if (action == WorkflowAction.courtDecision) {
      note = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: card,
        builder: (c) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final outcome in [
                'Қаноатлантирилди',
                'Қисман қаноатлантирилди',
                'Рад этилди',
              ])
                ListTile(
                  title: Text(localized(ref, outcome)),
                  onTap: () => Navigator.pop(c, outcome),
                ),
            ],
          ),
        ),
      );
      if (note == null) return;
    }
    if (!context.mounted) return;
    if (action == WorkflowAction.legalAssessment ||
        action == WorkflowAction.recordMeasure ||
        action == WorkflowAction.requestDocuments ||
        action == WorkflowAction.issueProtest ||
        action == WorkflowAction.issueSubmission ||
        action == WorkflowAction.issueWarning ||
        action == WorkflowAction.requestMoreInspection) {
      final ctrl = TextEditingController();
      note = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(localized(ref, _label(action))),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: localized(ref, 'Изоҳ киритинг'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(localized(ref, 'Бекор қилиш')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                c,
                ctrl.text.trim().isEmpty ? 'Демо амал' : ctrl.text.trim(),
              ),
              child: Text(localized(ref, 'Сақлаш')),
            ),
          ],
        ),
      );
      ctrl.dispose();
      if (note == null) return;
    }
    try {
      await ref
          .read(appControllerProvider.notifier)
          .act(signal.id, action, note: note, restored: restored);
      if (context.mounted) {
        showMessage(context, localized(ref, 'Амал сақланди'));
      }
    } on WorkflowException catch (e) {
      if (context.mounted) showMessage(context, localized(ref, e.message));
    }
  }
}

Future<void> _pickEvidence(
  BuildContext context,
  WidgetRef ref,
  RiskSignal signal,
) async {
  final kind = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: card,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.attach_file),
            title: Text(localized(ref, 'Ҳужжатни танлаш')),
            onTap: () => Navigator.pop(c, 'file'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(localized(ref, 'Галереядан сурат')),
            onTap: () => Navigator.pop(c, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(localized(ref, 'Камерадан сурат')),
            onTap: () => Navigator.pop(c, 'camera'),
          ),
        ],
      ),
    ),
  );
  if (kind == null) return;
  try {
    late final File saved;
    late final String name;
    if (kind == 'file') {
      final picked = await FilePicker.pickFile();
      if (picked == null) return;
      name = picked.name;
      saved = await saveEvidenceBytes(await picked.readAsBytes(), name);
    } else {
      final picked = await ImagePicker().pickImage(
        source: kind == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 75,
      );
      if (picked == null) return;
      name = picked.name;
      saved = await saveEvidenceFile(picked.path, name);
    }
    await ref
        .read(appControllerProvider.notifier)
        .addEvidence(
          signal.id,
          Evidence(
            name: name,
            kind: kind == 'file' ? 'document' : 'image',
            path: saved.path,
            at: DateTime.now(),
            by: ref.read(appControllerProvider).role,
          ),
        );
    if (context.mounted) showMessage(context, localized(ref, 'Далил сақланди'));
  } catch (_) {
    if (context.mounted) {
      showMessage(context, localized(ref, 'Файлни сақлаб бўлмади'));
    }
  }
}

void _previewEvidence(BuildContext context, Evidence item) => showDialog<void>(
  context: context,
  builder: (c) => AlertDialog(
    title: Text(item.name),
    content: item.kind == 'image' && File(item.path).existsSync()
        ? Image.file(File(item.path), fit: BoxFit.contain)
        : Text(item.path),
    actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK')),
    ],
  ),
);
