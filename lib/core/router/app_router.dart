import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:afric_eg_admin_panel/features/agenda/presentation/pages/agenda_page.dart';
import 'package:afric_eg_admin_panel/features/announcements/presentation/pages/announcements_page.dart';
import 'package:afric_eg_admin_panel/features/auth/domain/repositories/auth_repository.dart';
import 'package:afric_eg_admin_panel/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:afric_eg_admin_panel/features/auth/presentation/bloc/auth_event.dart';
import 'package:afric_eg_admin_panel/features/auth/presentation/bloc/auth_state.dart';
import 'package:afric_eg_admin_panel/features/auth/presentation/pages/login_page.dart';
import 'package:afric_eg_admin_panel/features/congress/presentation/pages/congress_page.dart';
import 'package:afric_eg_admin_panel/features/live_room/presentation/pages/live_room_admin_page.dart';
import 'package:afric_eg_admin_panel/features/live_room/presentation/pages/live_rooms_page.dart';
import 'package:afric_eg_admin_panel/features/overview/presentation/pages/overview_page.dart';
import 'package:afric_eg_admin_panel/features/push/presentation/pages/notifications_page.dart';
import 'package:afric_eg_admin_panel/features/users/presentation/pages/users_page.dart';
import 'package:afric_eg_admin_panel/features/workshops/presentation/pages/workshops_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  final ValueNotifier<bool> _isAuthenticated = ValueNotifier(false);

  late final GoRouter router;

  AppRouter(AuthRepository authRepository) {
    authRepository.isSignedIn.listen((signedIn) {
      _isAuthenticated.value = signedIn;
    });

    router = GoRouter(
      initialLocation: '/login',
      refreshListenable: _isAuthenticated,
      redirect: (context, state) {
        final loggedIn = _isAuthenticated.value;
        final loggingIn = state.matchedLocation == '/login';
        if (!loggedIn) return loggingIn ? null : '/login';
        if (loggingIn) return '/overview';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        ShellRoute(
          builder: (context, state, child) => AdminShell(child: child),
          routes: [
            GoRoute(
              path: '/overview',
              builder: (context, state) => const OverviewPage(),
            ),
            GoRoute(
              path: '/congress',
              builder: (context, state) => const CongressPage(),
            ),
            GoRoute(
              path: '/announcements',
              builder: (context, state) => const AnnouncementsPage(),
            ),
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsPage(),
            ),
            GoRoute(
              path: '/agenda',
              builder: (context, state) => const AgendaPage(),
            ),
            GoRoute(
              path: '/live-room',
              builder: (context, state) => const LiveRoomsPage(),
              routes: [
                GoRoute(
                  path: ':sessionId/:talkId',
                  builder: (context, state) => LiveRoomAdminPage(
                    sessionId: state.pathParameters['sessionId']!,
                    talkId: state.pathParameters['talkId'],
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/workshops',
              builder: (context, state) => const WorkshopsPage(),
            ),
            GoRoute(
              path: '/users',
              builder: (context, state) => const UsersPage(),
            ),
          ],
        ),
      ],
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(this.path, this.icon, this.activeIcon, this.label);
}

const _navItems = <_NavItem>[
  _NavItem('/overview', Icons.dashboard_outlined, Icons.dashboard, 'Overview'),
  _NavItem('/congress', Icons.tune_outlined, Icons.tune, 'Congress Config'),
  _NavItem(
    '/announcements',
    Icons.campaign_outlined,
    Icons.campaign,
    'Announcements',
  ),
  _NavItem(
    '/notifications',
    Icons.notifications_outlined,
    Icons.notifications,
    'Send Notification',
  ),
  _NavItem(
    '/agenda',
    Icons.calendar_month_outlined,
    Icons.calendar_month,
    'Agenda',
  ),
  _NavItem('/live-room', Icons.sensors_outlined, Icons.sensors, 'Live Room'),
  _NavItem('/workshops', Icons.school_outlined, Icons.school, 'Workshops'),
  _NavItem('/users', Icons.people_outline, Icons.people, 'Users'),
];

class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _navItems.indexWhere(
        (n) => location == n.path || location.startsWith('${n.path}/'));

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: Stack(
        children: [
          const Positioned.fill(child: _Background()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final collapsed = constraints.maxWidth < 760;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Sidebar(
                      selectedIndex: index == -1 ? 0 : index,
                      collapsed: collapsed,
                      onSelect: (i) => context.go(_navItems[i].path),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          border: Border(
                            left: BorderSide(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        child: child,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: ColoredBox(
        color: AppColors.deepBlack,
        child: CustomPaint(painter: _CongressPainter()),
      ),
    );
  }
}

class _CongressPainter extends CustomPainter {
  const _CongressPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2a0f10), Color(0xFF1a0a0b), Color(0xFF1a0a0b)],
        stops: [0.0, 0.4, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, base);

    _ellipse(
      canvas,
      rect,
      const Offset(0.5, 0.85),
      1.2,
      0.4,
      const Color(0x993B1514),
      const Color(0x003B1514),
    );
    _ellipse(
      canvas,
      rect,
      const Offset(0.25, 0.15),
      1.0,
      0.5,
      const Color(0x33C68C98),
      const Color(0x00C68C98),
    );
  }

  void _ellipse(
    Canvas canvas,
    Rect rect,
    Offset center,
    double rx,
    double ry,
    Color c0,
    Color c1,
  ) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [c0, c1],
        stops: const [0.0, 0.6],
      ).createShader(Rect.fromCircle(center: center, radius: 1.0));
    canvas.drawCircle(
      Offset(center.dx * rect.width, center.dy * rect.height),
      rect.width * rx,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final bool collapsed;
  final void Function(int) onSelect;

  const _Sidebar({
    required this.selectedIndex,
    required this.collapsed,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: collapsed ? 76 : 230,
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 10 : 16,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!collapsed)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'AFRIC',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.08,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '.',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.highlight,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'ADMIN',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.22,
                      color: AppColors.goldLight,
                    ),
                  ),
                ],
              ),
            )
          else
            const Center(
              child: Text(
                'AF',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.highlight,
                ),
              ),
            ),
          const SizedBox(height: 24),
          ...List.generate(_navItems.length, (i) {
            final item = _navItems[i];
            final active = i == selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => onSelect(i),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: collapsed ? 0 : 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active
                          ? AppColors.gold.withValues(alpha: 0.25)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: collapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      Icon(
                        active ? item.activeIcon : item.icon,
                        size: 17,
                        color: active
                            ? AppColors.highlight
                            : AppColors.navInactive,
                      ),
                      if (!collapsed) ...[
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? AppColors.textWhite
                                : AppColors.navInactive,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          if (!collapsed)
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return InkWell(
                  onTap: () =>
                      context.read<AuthBloc>().add(const SignOutRequested()),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.glassBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.logout,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Sign out',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            IconButton(
              onPressed: () =>
                  context.read<AuthBloc>().add(const SignOutRequested()),
              icon: const Icon(
                Icons.logout,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
