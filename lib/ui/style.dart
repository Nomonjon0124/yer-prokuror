import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_state.dart';
import '../domain/models.dart';
import '../domain/queries.dart';

const navy = Color(0xff06172a);
const card = Color(0xff10283f);
const cardDeep = Color(0xff0b2137);
const stroke = Color(0xff31506b);
const gold = Color(0xfff1c66f);
const muted = Color(0xffa6b8cc);
const blue = Color(0xff46a9ff);
const red = Color(0xffff6064);
const green = Color(0xff39d58b);
const yellow = Color(0xffffcb4c);

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: navy,
  colorScheme: const ColorScheme.dark(
    primary: gold,
    surface: card,
    secondary: blue,
    error: red,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 31,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      fontFamily: 'serif',
    ),
    headlineMedium: TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      fontFamily: 'serif',
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(fontSize: 14, color: muted),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: cardDeep,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: stroke),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: stroke),
    ),
  ),
);

String uz(String text, bool latin) {
  if (!latin) return text;
  const map = <String, String>{
    'А': 'A',
    'а': 'a',
    'Б': 'B',
    'б': 'b',
    'В': 'V',
    'в': 'v',
    'Г': 'G',
    'г': 'g',
    'Д': 'D',
    'д': 'd',
    'Е': 'E',
    'е': 'e',
    'Ё': 'Yo',
    'ё': 'yo',
    'Ж': 'J',
    'ж': 'j',
    'З': 'Z',
    'з': 'z',
    'И': 'I',
    'и': 'i',
    'Й': 'Y',
    'й': 'y',
    'К': 'K',
    'к': 'k',
    'Л': 'L',
    'л': 'l',
    'М': 'M',
    'м': 'm',
    'Н': 'N',
    'н': 'n',
    'О': 'O',
    'о': 'o',
    'П': 'P',
    'п': 'p',
    'Р': 'R',
    'р': 'r',
    'С': 'S',
    'с': 's',
    'Т': 'T',
    'т': 't',
    'У': 'U',
    'у': 'u',
    'Ф': 'F',
    'ф': 'f',
    'Х': 'X',
    'х': 'x',
    'Ц': 'S',
    'ц': 's',
    'Ч': 'Ch',
    'ч': 'ch',
    'Ш': 'Sh',
    'ш': 'sh',
    'Щ': 'Sh',
    'щ': 'sh',
    'Ъ': 'ʼ',
    'ъ': 'ʼ',
    'Ь': '',
    'ь': '',
    'Э': 'E',
    'э': 'e',
    'Ю': 'Yu',
    'ю': 'yu',
    'Я': 'Ya',
    'я': 'ya',
    'Ў': 'O‘',
    'ў': 'o‘',
    'Қ': 'Q',
    'қ': 'q',
    'Ғ': 'G‘',
    'ғ': 'g‘',
    'Ҳ': 'H',
    'ҳ': 'h',
  };
  return text.split('').map((c) => map[c] ?? c).join();
}

String localized(WidgetRef ref, String value) =>
    uz(value, ref.watch(appControllerProvider.select((s) => s.latin)));
String dateText(DateTime date) => DateFormat('dd.MM.yyyy').format(date);
String money(double value) =>
    NumberFormat.decimalPattern('ru').format(value.round());

Color riskColor(Risk risk) => switch (risk) {
  Risk.high => red,
  Risk.medium => yellow,
  Risk.low => green,
};
String riskText(Risk risk) => switch (risk) {
  Risk.high => 'Юқори хавф',
  Risk.medium => 'Ўрта хавф',
  Risk.low => 'Паст хавф',
};
IconData riskIcon(Risk risk) => switch (risk) {
  Risk.high => Icons.warning_rounded,
  Risk.medium => Icons.error_rounded,
  Risk.low => Icons.verified_rounded,
};

String statusText(SignalStatus status) => switch (status) {
  SignalStatus.fresh => 'Янги',
  SignalStatus.accepted => 'Қабул қилинди',
  SignalStatus.verifying => 'Текширувда',
  SignalStatus.rejected => 'Рад этилди',
  SignalStatus.confirmed => 'Тасдиқланган',
  SignalStatus.underProsecutor => 'Прокурор назоратида',
  SignalStatus.inCourt => 'Судда',
  SignalStatus.executing => 'Ижрода',
  SignalStatus.completed => 'Ижро тасдиқланган',
  SignalStatus.formal => 'Формал ижро',
  SignalStatus.overdue => 'Муддати ўтган',
};

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = card,
    this.borderColor = stroke,
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color color, borderColor;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor.withValues(alpha: .8)),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: .9), const Color(0xff0b2238)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child,
      ),
    ),
  );
}

class HeroHeader extends ConsumerWidget {
  const HeroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.height = 205,
    this.showBrand = true,
  });
  final String title, subtitle;
  final double height;
  final bool showBrand;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    final alerts = visibleSignals(data)
        .where(
          (s) => isOverdue(s, data.demoDate) || isDueSoon(s, data.demoDate),
        )
        .length;
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/civic_hero.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [navy, Color(0xee06172a), Color(0xaa06172a)],
                stops: [0, .45, 1],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, topInset + 8, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showBrand)
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/brand_shield.svg',
                        width: 44,
                        height: 48,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YER PROKUROR',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'serif',
                                color: gold,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: .5,
                              ),
                            ),
                            Text(
                              'ҚОНУН УСТУВОР — АДОЛАТ ТАЯНЧИ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: muted,
                                fontSize: 8,
                                letterSpacing: .5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/notifications'),
                        icon: Badge(
                          isLabelVisible: alerts > 0,
                          label: Text('${alerts.clamp(0, 9)}'),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/profile'),
                        icon: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                const Spacer(),
                Text(
                  localized(ref, title),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  localized(ref, subtitle),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xffd2dbe5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends ConsumerWidget {
  const SectionTitle(
    this.title, {
    super.key,
    this.icon = Icons.bar_chart_rounded,
    this.trailing,
    this.onTap,
  });
  final String title;
  final IconData icon;
  final String? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    children: [
      Icon(icon, color: gold, size: 21),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          localized(ref, title),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      if (trailing != null)
        InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Text(
                localized(ref, trailing!),
                style: const TextStyle(color: Color(0xff9db8cc), fontSize: 11),
              ),
              const Icon(Icons.chevron_right, color: muted, size: 19),
            ],
          ),
        ),
    ],
  );
}

class RiskPill extends ConsumerWidget {
  const RiskPill(this.risk, {super.key});
  final Risk risk;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: riskColor(risk).withValues(alpha: .16),
      border: Border.all(color: riskColor(risk).withValues(alpha: .7)),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      localized(ref, riskText(risk)),
      style: TextStyle(
        color: riskColor(risk),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class FilterChipButton extends ConsumerWidget {
  const FilterChipButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.selected = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected;
  @override
  Widget build(BuildContext context, WidgetRef ref) => OutlinedButton.icon(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      backgroundColor: selected ? gold.withValues(alpha: .18) : card,
      side: BorderSide(color: selected ? gold : stroke),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    icon: Icon(icon, color: selected ? gold : Colors.white, size: 17),
    label: Text(
      localized(ref, label),
      style: TextStyle(color: selected ? gold : Colors.white, fontSize: 12),
    ),
  );
}

class ActionButton extends ConsumerWidget {
  const ActionButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon = Icons.arrow_forward_ios,
    this.primary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool primary;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: primary ? gold : card,
        foregroundColor: primary ? navy : Colors.white,
        side: BorderSide(color: primary ? gold : stroke),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        localized(ref, label),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

void showMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: card));
