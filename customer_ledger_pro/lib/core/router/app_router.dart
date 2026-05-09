import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Screens
import 'package:customer_ledger_pro/features/auth/presentation/screens/splash_screen.dart';
import 'package:customer_ledger_pro/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:customer_ledger_pro/features/auth/presentation/screens/login_screen.dart';
import 'package:customer_ledger_pro/features/auth/presentation/screens/register_screen.dart';
import 'package:customer_ledger_pro/features/auth/presentation/screens/otp_screen.dart';
import 'package:customer_ledger_pro/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:customer_ledger_pro/features/customers/presentation/screens/customers_list_screen.dart';
import 'package:customer_ledger_pro/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:customer_ledger_pro/features/customers/presentation/screens/add_customer_screen.dart';
import 'package:customer_ledger_pro/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:customer_ledger_pro/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:customer_ledger_pro/features/reports/presentation/screens/reports_screen.dart';
import 'package:customer_ledger_pro/features/settings/presentation/screens/settings_screen.dart';
import 'package:customer_ledger_pro/features/admin/presentation/screens/admin_screen.dart';
import 'package:customer_ledger_pro/shared/widgets/main_shell.dart';
import 'package:customer_ledger_pro/features/auth/presentation/providers/auth_provider.dart';

/// Route name constants
class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const otpVerify = '/otp';
  static const home = '/home';
  static const dashboard = '/home/dashboard';
  static const customers = '/home/customers';
  static const customerDetail = '/home/customers/:id';
  static const addCustomer = '/home/customers/add';
  static const editCustomer = '/home/customers/:id/edit';
  static const transactions = '/home/transactions';
  static const addTransaction = '/home/transactions/add';
  static const reports = '/home/reports';
  static const settings = '/home/settings';
  static const admin = '/admin';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isOnAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/otp') ||
          state.matchedLocation.startsWith('/onboarding') ||
          state.matchedLocation == '/';

      if (!isLoggedIn && !isOnAuthRoute) {
        return AppRoutes.login;
      }
      if (isLoggedIn && isOnAuthRoute && state.matchedLocation != '/') {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerify,
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpScreen(phoneNumber: phone);
        },
      ),
      // ── Main Shell with Bottom Nav ──────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            redirect: (_, __) => AppRoutes.dashboard,
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.customers,
            builder: (context, state) => const CustomersListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddCustomerScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return CustomerDetailScreen(customerId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.transactions,
            builder: (context, state) => const TransactionsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) {
                  final customerId = state.uri.queryParameters['customer_id'];
                  return AddTransactionScreen(customerId: customerId);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.error}'),
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
