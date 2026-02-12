import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/site_manager_management_screen.dart';
import '../../features/dashboard/screens/add_site_manager_screen.dart';
import '../../features/dashboard/screens/staff_directory_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/dashboard/screens/super_admin_dashboard.dart';
import '../../features/dashboard/screens/admin_dashboard_shell.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/projects/screens/project_list_screen.dart';
import '../../features/projects/screens/create_project_screen.dart';
import '../../features/projects/screens/project_detail_screen.dart';
import '../../features/blueprints/screens/blueprint_files_screen.dart';
import '../../features/blueprints/screens/blueprint_viewer_screen.dart';
import '../../features/blueprints/data/models/blueprint_model.dart';
import '../../features/inventory/screens/stock_list_screen.dart';
import '../../features/vendors/screens/vendors_list_screen.dart';
import '../../features/inventory/screens/daily_material_log_screen.dart';
import '../../features/labour/screens/labour_roster_screen.dart';
import '../../features/labour/screens/attendance_screen.dart';
import '../../features/projects/screens/project_operations_screen.dart';
import '../../features/inventory/screens/supplier_list_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/bills/screens/bills_screen.dart';
import '../../features/bills/screens/create_bill_screen.dart';
import '../../features/bills/screens/admin_approval_queue_screen.dart';
import '../../features/materials/screens/materials_tab_screen.dart';
import '../../features/machinery/screens/machinery_tab_screen.dart';
import '../../features/machinery/screens/machinery_log_screen.dart';
import '../../features/machinery/screens/machinery_master_screen.dart';
import '../../features/labour/screens/labour_master_screen.dart';
import '../../features/labour/screens/labour_tab_screen.dart';

/// Global router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: _AuthStateNotifier(ref),
    redirect: (context, state) {
      // 1. Check if Auth is fully initialized
      // If not initialized, DO NOT redirect yet. Let the Splash screen show.
      if (!authState.isInitialized) {
        return null;
      }

      final isAuthenticated = authState.isAuthenticated;
      final userRole = authState.role;
      final isSplashRoute = state.matchedLocation == '/splash';

      // 2. Public Routes Logic
      final publicRoutes = ['/login', '/forgot-password'];
      final isPublicRoute = publicRoutes.contains(state.matchedLocation);

      // 3. Handle Unauthenticated Users
      // If not authenticated and not on a public route, go to Login
      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }

      // 4. Handle Authenticated Users
      // If authenticated...
      if (isAuthenticated) {
        // ...and trying to access Splash or Login, send to Dashboard
        if (isSplashRoute || isPublicRoute) {
          return _getRoleBasedRoute(userRole ?? UserRole.siteManager);
        }
      }

      // 5. Default: No redirect needed
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Admin Site Manager Routes
      GoRoute(
        path: '/admin/site-managers',
        name: 'admin-site-managers',
        builder: (context, state) => const SiteManagerManagementScreen(),
      ),
      GoRoute(
        path: '/admin/site-managers/add',
        name: 'admin-add-site-manager',
        builder: (context, state) => const AddSiteManagerScreen(),
      ),
      GoRoute(
        path: '/admin/staff-directory',
        name: 'admin-staff-directory',
        builder: (context, state) => const StaffDirectoryScreen(),
      ),
      GoRoute(
        path: '/suppliers',
        name: 'suppliers',
        builder: (context, state) => const SupplierListScreen(),
      ),
      GoRoute(
        path: '/master/vendors',
        name: 'master-vendors',
        builder: (context, state) => const SupplierListScreen(),
      ),
      GoRoute(
        path: '/machinery',
        name: 'machinery',
        builder: (context, state) => const MachineryMasterScreen(),
      ),
      GoRoute(
        path: '/master/machinery',
        name: 'master-machinery',
        builder: (context, state) => const MachineryMasterScreen(),
      ),
      GoRoute(
        path: '/master/labour',
        name: 'master-labour',
        builder: (context, state) => const LabourMasterScreen(),
      ),
      GoRoute(
        path: '/vendors',
        name: 'vendors',
        builder: (context, state) => const VendorsListScreen(),
      ),

      // Super Admin Routes
      GoRoute(
        path: '/super-admin/dashboard',
        name: 'super-admin-dashboard',
        builder: (context, state) => const SuperAdminDashboard(),
      ),

      // Admin Routes
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const DashboardShell(),
      ),

      // Site Manager Routes
      GoRoute(
        path: '/site-manager/dashboard',
        name: 'site-manager-dashboard',
        builder: (context, state) => const DashboardShell(),
      ),
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/bills',
        name: 'bills',
        builder: (context, state) => const BillsScreen(),
        routes: [
           GoRoute(
            path: 'create',
            name: 'create-bill',
            builder: (context, state) => const CreateBillScreen(),
          ),
          GoRoute(
            path: 'approval-queue',
            name: 'admin-approval-queue',
            builder: (context, state) => const AdminApprovalQueueScreen(),
          ),
        ],
      ),

      // Project Routes
      GoRoute(
        path: '/projects',
        name: 'projects',
        builder: (context, state) => const ProjectListScreen(),
      ),
      GoRoute(
        path: '/projects/create',
        name: 'create-project',
        builder: (context, state) => const CreateProjectScreen(),
      ),
      GoRoute(
        path: '/projects/:id',
        name: 'project-detail',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return ProjectDetailScreen(projectId: projectId);
        },
        routes: [
          // Blueprint Routes
          GoRoute(
            path: 'blueprints',
            name: 'project-blueprints',
            builder: (context, state) {
              final projectId = state.pathParameters['id']!;
              return BlueprintFilesScreen(projectId: projectId);
            },
            routes: [
              GoRoute(
                path: 'view/:fileId',
                name: 'project-blueprint-viewer',
                builder: (context, state) {
                  final blueprint = state.extra as Blueprint?;
                  if (blueprint == null) {
                    return const Scaffold(
                      body: Center(
                        child: Text(
                          'Error: Blueprint data not provided. Please navigate from the files list.',
                        ),
                      ),
                    );
                  }
                  return BlueprintViewerScreen(blueprint: blueprint);
                },
              ),
            ],
          ),
          // Inventory Routes
          GoRoute(
            path: 'stock',
            name: 'project-stock',
            builder: (context, state) {
              final projectId = state.pathParameters['id']!;
              final projectName = (state.extra as String?) ?? 'Project';
              return StockListScreen(
                projectId: projectId,
                projectName: projectName,
              );
            },
          ),
          GoRoute(
            path: 'material-log',
            name: 'project-material-log',
            builder: (context, state) {
              final projectId = state.pathParameters['id']!;
              final projectName = (state.extra as String?) ?? 'Project';
              return DailyMaterialLogScreen(
                projectId: projectId,
                projectName: projectName,
              );
            },
          ),
          // Labour Routes
          GoRoute(
            path: 'labour',
            name: 'project-labour',
            builder: (context, state) {
              final projectId = state.pathParameters['id']!;
              final projectName = (state.extra as String?) ?? 'Project';
              return LabourRosterScreen(
                projectId: projectId,
                projectName: projectName,
              );
            },
          ),
          GoRoute(
            path: 'attendance',
            name: 'project-attendance',
            builder: (context, state) {
              final projectId = state.pathParameters['id']!;
              final projectName = (state.extra as String?) ?? 'Project';
              return AttendanceScreen(
                projectId: projectId,
                projectName: projectName,
              );
            },
          ),
          // Operations Route
          GoRoute(
            path: 'operations',
            name: 'project-operations',
            builder: (context, state) {
              final projectId = state.pathParameters['id']!;
              return ProjectOperationsScreen(projectId: projectId);
            },
            routes: [
              GoRoute(
                path: 'materials',
                name: 'project-materials',
                builder: (context, state) {
                  final projectId = state.pathParameters['id']!;
                  return MaterialsTabScreen(projectId: projectId);
                },
              ),
              GoRoute(
                path: 'machinery',
                name: 'project-machinery',
                builder: (context, state) {
                  final projectId = state.pathParameters['id']!;
                  return MachineryTabScreen(projectId: projectId);
                },
              ),
              GoRoute(
                path: 'labour',
                name: 'project-labour-tab',
                builder: (context, state) {
                  final projectId = state.pathParameters['id']!;
                  return LabourTabScreen(projectId: projectId);
                },
              ),
            ],
          ),
          // Materials Routes
          GoRoute(
            path: 'materials/receive',
            name: 'material-receive',
            builder: (context, state) => const Placeholder(), // MaterialReceiveScreen
          ),
          GoRoute(
            path: 'materials/consume',
            name: 'material-consume',
            builder: (context, state) => const Placeholder(), // MaterialConsumeScreen
          ),
          GoRoute(
             path: 'materials/stock',
             name: 'material-stock',
             builder: (context, state) => const Placeholder(), // StockLedgerScreen
          ),
          GoRoute(
             path: 'materials/receipt/:receiptId',
             name: 'receipt-detail',
             builder: (context, state) => const Placeholder(), // ReceiptDetailScreen
          ),
          // Machinery & Labour Specifics (Logs)
          GoRoute(
             path: 'machinery/log',
             name: 'machinery-log',
             builder: (context, state) {
               final projectId = state.pathParameters['id']!;
               return MachineryLogScreen(projectId: projectId);
             },
          ),
          GoRoute(
             path: 'labour/attendance',
             name: 'labour-attendance', // Duplicate check with existing?
             builder: (context, state) => const Placeholder(), // AttendanceLogScreen
          ),
          // Reports Route
          GoRoute(
            path: 'reports',
            name: 'project-reports',
            builder: (context, state) {
              final projectId = state.pathParameters['id'];
              return ReportsScreen(projectId: projectId);
            },
            routes: [
               GoRoute(
                 path: 'stock',
                 name: 'report-stock',
                 builder: (context, state) => const Placeholder(),
               ),
               GoRoute(
                 path: 'machinery',
                 name: 'report-machinery',
                 builder: (context, state) => const Placeholder(),
               ),
               GoRoute(
                 path: 'labour',
                 name: 'report-labour',
                 builder: (context, state) => const Placeholder(),
               ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/projects/:id/edit',
        name: 'edit-project',
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return CreateProjectScreen(projectId: projectId);
        },
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '404 - Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Get dashboard route based on user role
String _getRoleBasedRoute(UserRole role) {
  switch (role) {
    case UserRole.superAdmin:
      return '/super-admin/dashboard';
    case UserRole.admin:
      return '/admin/dashboard';
    case UserRole.siteManager:
      return '/site-manager/dashboard';
  }
}

/// Auth state listener for router refresh
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(this._ref) {
    _ref.listen(authProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

/// Router key for navigation without context
final rootNavigatorKey = GlobalKey<NavigatorState>();
