import 'package:latlong2/latlong.dart';

import '../domain/models.dart';
import '../domain/workflow.dart';

const riskStories = <String>[
  'Ер участкасидаги ўзгаришга ҳуқуқий асос топилмади',
  'Кадастр контури ва амалдаги фойдаланиш ўртасида тафовут',
  'Унумдор тупроқ қатлами олиб ташланган',
  'Ер тоифаси ваколатсиз орган қарори билан ўзгартирилган',
  'Қурилишга рухсатнома бор, ер тоифаси ўзгартирилмаган',
  'Сигнал бир иш куни ичида очилмаган',
  'Масъул орган белгиланмаган ва ҳаракат қилинмаган',
  'Тасдиқловчи текширув усули танланмаган',
  'Юқори аниқликдаги сурат муддатда берилмаган',
  'Юқори хавфли сигнал икки кунда текширилмаган',
  'Ўрта хавфли сигнал беш кунда текширилмаган',
  'Сигнал ҳужжатсиз рад этилган',
  'Хавф даражасини асоссиз қайта таснифлаш сўралган',
  'Қонунбузилиш тасдиқланган, чора кўрилмаган',
  'Янги ер ўзлаштириш мажбурияти бажарилмаган',
  'Бартараф этилган участкада ўзгариш қайта аниқланган',
  'Жиноят аломатли материал прокуратурага юборилмаган',
  'Материал камчиликлари беш кунда бартараф этилмаган',
  'Якуний қарор ҳақида уч кунда хабар берилмаган',
  'Ўн кун ичида даъво киритилмаган',
  'Даъво ёки ижро ҳужжати асоссиз қайтариб олинган',
  'Ер қайтариш далолатномаси юкланмаган',
  'Далолатнома уч иш кунида юкланмаган',
  'Прокурор ҳужжати муддатида кўриб чиқилмаган',
  'Жавоб хати бор, ерда объектив ўзгариш йўқ',
  'Суд қарори ижро этилмаган',
];

const districts = <String>[
  'Зангиота т.',
  'Қибрай т.',
  'Паркент т.',
  'Чирчиқ ш.',
  'Оҳангарон т.',
  'Бўстонлиқ т.',
];
const regions = <String>[
  'Тошкент вилояти',
  'Самарқанд вилояти',
  'Фарғона вилояти',
];
const mediumStoryIndexes = <int>{1, 5, 8, 10, 12, 17, 18, 22};

List<RiskSignal> buildSignals() {
  final result = <RiskSignal>[];
  var highCount = 0;
  var mediumCount = 0;
  for (var i = 0; i < 833; i++) {
    final detailed = i < riskStories.length;
    late final Risk risk;
    if (detailed) {
      risk = mediumStoryIndexes.contains(i) ? Risk.medium : Risk.high;
    } else if (highCount < 152) {
      risk = Risk.high;
    } else if (mediumCount < 263) {
      risk = Risk.medium;
    } else {
      risk = Risk.low;
    }
    if (risk == Risk.high) highCount++;
    if (risk == Risk.medium) mediumCount++;
    final region = regions[(i ~/ 130) % regions.length];
    final districtNames = switch (region) {
      'Самарқанд вилояти' => const [
        'Самарқанд ш.',
        'Ургут т.',
        'Пастдарғом т.',
        'Жомбой т.',
        'Каттақўрғон т.',
      ],
      'Фарғона вилояти' => const [
        'Фарғона ш.',
        'Қўқон ш.',
        'Марғилон ш.',
        'Қува т.',
        'Олтиариқ т.',
      ],
      _ => districts,
    };
    final district = districtNames[i % districtNames.length];
    final base = switch (region) {
      'Самарқанд вилояти' => const LatLng(39.65, 66.96),
      'Фарғона вилояти' => const LatLng(40.38, 71.78),
      _ => const LatLng(41.29, 69.14),
    };
    final detected = DateTime(2026, 4, 30 - (i % 7), 9 + (i % 8), (i * 7) % 60);
    final id = i == 0
        ? 'RSK-ASOS-01'
        : i == 1
        ? 'RSK-QAROR-01'
        : i == 2
        ? 'RSK-TUPR-01'
        : 'RSK-${(i + 1).toString().padLeft(4, '0')}';
    final stage = i < 26
        ? Stage.detection
        : Stage.values[(i ~/ 47) % Stage.values.length];
    final status = i < 26
        ? SignalStatus.fresh
        : switch (stage) {
            Stage.detection => SignalStatus.fresh,
            Stage.verification => SignalStatus.verifying,
            Stage.measures => SignalStatus.confirmed,
            Stage.prosecutor => SignalStatus.underProsecutor,
            Stage.court => SignalStatus.inCourt,
            Stage.execution => SignalStatus.executing,
          };
    final events = <TimelineEvent>[
      TimelineEvent(
        title: 'Сигнал шаклланди',
        at: detected,
        actor: 'Платформа',
        note: 'Демо маълумот',
      ),
    ];
    if (!detailed && stage.index >= Stage.verification.index) {
      events.add(
        TimelineEvent(
          title: 'Сигнал қабул қилинди',
          at: detected.add(const Duration(minutes: 10)),
          actor: 'Назорат органи',
        ),
      );
    }
    if (!detailed && stage.index >= Stage.measures.index) {
      events.add(
        TimelineEvent(
          title: 'Текширув усули танланди',
          at: detected.add(const Duration(minutes: 20)),
          actor: 'Назорат органи',
        ),
      );
      events.add(
        TimelineEvent(
          title: 'Қонунбузилиш тасдиқланди',
          at: detected.add(const Duration(minutes: 30)),
          actor: 'Назорат органи',
        ),
      );
    }
    if (!detailed && stage.index >= Stage.prosecutor.index) {
      events.add(
        TimelineEvent(
          title: 'Назорат органи чора кўрди',
          at: detected.add(const Duration(minutes: 40)),
          actor: 'Назорат органи',
        ),
      );
    }
    if (!detailed && stage.index >= Stage.court.index) {
      events.add(
        TimelineEvent(
          title: 'Даъво киритилди',
          at: detected.add(const Duration(minutes: 50)),
          actor: 'Назорат органи',
        ),
      );
    }
    if (!detailed && stage == Stage.court && i % 7 == 0) {
      events.add(
        TimelineEvent(
          title: 'Суд қарори чиқди',
          at: detected.add(const Duration(minutes: 55)),
          actor: 'Суд',
          note: 'Қисман қаноатлантирилди',
        ),
      );
      events.add(
        TimelineEvent(
          title: 'Апелляция берилди',
          at: detected.add(const Duration(minutes: 58)),
          actor: 'Прокурор',
        ),
      );
    }
    if (!detailed && stage.index >= Stage.execution.index) {
      events.add(
        TimelineEvent(
          title: 'Суд қарори чиқди',
          at: detected.add(const Duration(minutes: 55)),
          actor: 'Суд',
        ),
      );
      events.add(
        TimelineEvent(
          title: 'Ижро иши очилди',
          at: detected.add(const Duration(minutes: 59)),
          actor: 'Ижрочи',
        ),
      );
    }
    final evidence = <Evidence>[];
    if (!detailed && stage.index >= Stage.measures.index) {
      evidence.add(
        Evidence(
          name: 'Кўздан кечириш далолатномаси',
          kind: 'document',
          path: '',
          at: detected.add(const Duration(minutes: 25)),
          by: UserRole.cadastre,
        ),
      );
    }
    if (!detailed && stage.index >= Stage.prosecutor.index) {
      evidence.add(
        Evidence(
          name: 'Чора ҳужжати',
          kind: 'document',
          path: '',
          at: detected.add(const Duration(minutes: 35)),
          by: UserRole.cadastre,
        ),
      );
    }
    result.add(
      RiskSignal(
        id: id,
        title: detailed
            ? riskStories[i]
            : [
                'Ҳуқуқий асос топилмади',
                'Ваколатсиз орган қарори',
                'Унумдор тупроқ олиб ташланган',
                'Кадастр контуридан ташқари фойдаланиш',
              ][i % 4],
        address: district,
        region: region,
        cadastral:
            '10:${(11 + i % 15).toString().padLeft(2, '0')}:${(23 + i % 45).toString().padLeft(2, '0')}:01:${(1234 + i).toString()}',
        area: ((i % 71) + 10) / 10,
        location: LatLng(
          base.latitude + ((i * 37) % 90) / 1000,
          base.longitude + ((i * 53) % 150) / 1000,
        ),
        risk: risk,
        score: risk == Risk.high
            ? 70 + i % 31
            : risk == Risk.medium
            ? 40 + i % 30
            : i % 40,
        status: status,
        stage: stage,
        method: !detailed && stage.index >= Stage.measures.index
            ? 'Жойига чиқиб ўрганиш'
            : null,
        legalAnalysis: !detailed && stage.index >= Stage.court.index
            ? 'Демо ҳуқуқий баҳо: назорат органи ҳужжатлари кўриб чиқилди.'
            : null,
        claimNumber: !detailed && stage.index >= Stage.court.index
            ? 'DAVO-$id'
            : null,
        caseNumber: !detailed && stage.index >= Stage.court.index
            ? 'SUD-$id'
            : null,
        executionNumber: !detailed && stage.index >= Stage.execution.index
            ? 'IJRO-$id'
            : null,
        courtOutcome: !detailed && stage == Stage.court && i % 7 == 0
            ? 'Қисман қаноатлантирилди'
            : !detailed && stage == Stage.execution
            ? 'Қаноатлантирилди'
            : null,
        appealFiled: !detailed && stage == Stage.court && i % 7 == 0,
        detectedAt: detected,
        deadline: switch (stage) {
          Stage.detection || Stage.verification => addBusinessDays(
            detected,
            risk == Risk.high ? 2 : 5,
          ),
          Stage.measures => addBusinessDays(detected, 3),
          Stage.prosecutor => detected.add(const Duration(days: 10)),
          Stage.court ||
          Stage.execution => detected.add(const Duration(days: 30)),
        },
        description: detailed
            ? '${riskStories[i]}. Намуна ҳолат: реестр маълумоти ва кузатув натижаси ўртасида тафовут бор. Сигнал қонунбузилишнинг тасдиғи эмас.'
            : 'Реестр ва кузатув маълумотлари ўртасида текширилиши лозим бўлган тафовут аниқланди.',
        category: i % 4 == 0 ? 'Суғориладиган ер' : 'Қишлоқ хўжалиги ери',
        owner: i % 2 == 0 ? 'Фермер хўжалиги' : 'Юридик шахс',
        permittedUse: 'Қишлоқ хўжалиги',
        assignedAgency: i % 2 == 0 ? 'Кадастр агентлиги' : 'Агроинспекция',
        damage: (i % 17 + 1) * 12500000.0,
        recovered: i % 6 == 0 ? (i % 17 + 1) * 2500000.0 : 0,
        detailed: detailed,
        scenarioNumber: detailed ? i + 1 : null,
        events: events,
        evidence: evidence,
      ),
    );
  }
  return result;
}

List<RegistryRecord> buildRegistry(List<RiskSignal> signals) =>
    List.generate(1248, (i) {
      final signal = signals[i % signals.length];
      final kind = ['Сигнал', 'Материал', 'Ҳужжат'][i % 3];
      return RegistryRecord(
        id: i < 4
            ? ['RSK-ASOS-01', 'MAT-036', 'DOC-114', 'RSK-IJRO-02'][i]
            : 'REG-${(i + 1).toString().padLeft(4, '0')}',
        title: i < 4
            ? [
                'Ҳуқуқий асос топилмади',
                'Жиноят аломати аниқланган материал',
                'Протест лойиҳаси',
                'Формал ижро',
              ][i]
            : signal.title,
        kind: kind,
        status: ['Фаол', 'Текширувда', 'Ёпилган', 'Кўриб чиқилмоқда'][i % 4],
        region: signal.region,
        reference: kind == 'Сигнал'
            ? signal.cadastral
            : '2026/${(i + 36).toString().padLeft(3, '0')}',
        createdAt: DateTime(2026, 4, 30 - i % 25),
        signalId: signal.id,
      );
    });
