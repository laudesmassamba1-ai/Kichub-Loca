import 'package:flutter/material.dart';
import 'package:kichub_loca/core/theme/app_theme.dart';
import 'package:kichub_loca/core/services/supabase_service.dart';
import 'package:kichub_loca/features/admin/admin_dashboard_screen.dart';
import 'package:kichub_loca/features/auth/login_screen.dart';
import 'package:kichub_loca/features/dashboard/dashboard_screen.dart';
import 'package:kichub_loca/features/field/agents_screen.dart';
import 'package:kichub_loca/features/field/field_home_screen.dart';
import 'package:kichub_loca/features/field/map_screen.dart';
import 'package:kichub_loca/features/field/nearby_businesses_screen.dart';
import 'package:kichub_loca/features/field/new_business_screen.dart';
import 'package:kichub_loca/features/field/profile_screen.dart';
import 'package:kichub_loca/features/field/prospects_screen.dart';
import 'package:kichub_loca/features/field/reminders_screen.dart';
import 'package:kichub_loca/features/field/visit_flow_screen.dart';
import 'package:kichub_loca/features/field/visit_history_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const map = '/map';
  static const nearby = '/nearby';
  static const newBusiness = '/new-business';
  static const profile = '/profile';
  static const reminders = '/reminders';
  static const history = '/history';
  static const admin = '/admin';
  static const visitFlow = '/visit-flow';
  static const agents = '/agents';
  static const prospects = '/prospects';
  static const dashboard = '/dashboard';
}

class KichubApp extends StatelessWidget {
  const KichubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kichub Loca',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      scrollBehavior: const MaterialScrollBehavior(),
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.home: (_) => const FieldHomeScreen(),
        AppRoutes.map: (_) => const MapScreen(),
        AppRoutes.nearby: (_) => const NearbyBusinessesScreen(),
        AppRoutes.newBusiness: (_) => const NewBusinessScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.reminders: (_) => const RemindersScreen(),
        AppRoutes.history: (_) => const VisitHistoryScreen(),
        AppRoutes.admin: (_) => const AdminDashboardScreen(),
        AppRoutes.agents: (_) => const AgentDirectoryScreen(),
        AppRoutes.prospects: (_) => const ProspectsScreen(),
        AppRoutes.dashboard: (_) => const DashboardScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.visitFlow) {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            return MaterialPageRoute(
              builder: (_) => VisitFlowScreen(nearbyBusiness: args),
              settings: settings,
            );
          }
        }
        return null;
      },
      home: SupabaseService.isConfigured
          ? const AuthGate()
          : const MissingConfigScreen(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.authStateChanges,
      builder: (context, snapshot) {
        final isLoggedIn = SupabaseService.currentUser != null;

        return isLoggedIn ? const FieldHomeScreen() : const LoginScreen();
      },
    );
  }
}

class MissingConfigScreen extends StatelessWidget {
  const MissingConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: AppColors.amber,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Configuration Supabase manquante',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ajoute les variables --dart-define=SUPABASE_URL et '
                    '--dart-define=SUPABASE_ANON_KEY pour lancer l\'app.',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.admin,
                        );
                      },
                      icon: const Icon(Icons.dashboard_rounded),
                      label: const Text('Ouvrir le dashboard démo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
