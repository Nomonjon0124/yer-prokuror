import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_state.dart';
import 'data/repository.dart';
import 'ui/pages/analytics_page.dart';
import 'ui/pages/detail_page.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/map_page.dart';
import 'ui/pages/more_pages.dart';
import 'ui/pages/registry_page.dart';
import 'ui/pages/signals_page.dart';
import 'ui/style.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await DemoRepository.open();
  runApp(
    ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(repository)],
      child: const YerProkurorApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/signals',
              builder: (context, state) =>
                  SignalsPage(key: ValueKey(state.uri.queryParameters['risk'])),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      SignalDetailPage(id: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const RiskMapPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/registry',
              builder: (context, state) => const RegistryPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(path: '/court', builder: (context, state) => const CourtPage()),
    GoRoute(
      path: '/executions',
      builder: (context, state) => const ExecutionsPage(),
    ),
    GoRoute(path: '/damage', builder: (context, state) => const DamagePage()),
    GoRoute(path: '/reports', builder: (context, state) => const ReportsPage()),
  ],
);

class YerProkurorApp extends StatelessWidget {
  const YerProkurorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'YER PROKUROR',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    routerConfig: _router,
  );
}

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const labels = [
      'Бош саҳифа',
      'Хавф сигналлари',
      'Таҳлиллар',
      'Харита',
      'Реестр',
    ];
    const icons = [
      Icons.home_rounded,
      Icons.warning_amber_rounded,
      Icons.bar_chart_rounded,
      Icons.map_outlined,
      Icons.storage_rounded,
    ];
    return Scaffold(
      body: shell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xff071a2e),
            border: Border(top: BorderSide(color: stroke)),
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 12,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: NavigationBar(
            height: 82,
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (index) => shell.goBranch(
              index,
              initialLocation: index == shell.currentIndex,
            ),
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: gold.withValues(alpha: .14),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                color: states.contains(WidgetState.selected)
                    ? gold
                    : const Color(0xffd4deea),
                fontSize: 10.5,
                height: 1.05,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
            destinations: List.generate(
              labels.length,
              (i) => NavigationDestination(
                icon: Icon(icons[i], size: 23, color: muted),
                selectedIcon: Icon(icons[i], size: 25, color: gold),
                label: localized(ref, labels[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
