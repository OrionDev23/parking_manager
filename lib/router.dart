import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:parc_oto/screens/accept_invitation.dart';
import 'package:parc_oto/screens/dashboard/dashboard.dart';
import 'package:parc_oto/screens/login.dart';
import 'package:parc_oto/screens/reset_password.dart';
import 'package:parc_oto/screens/sidemenu/pane_items.dart';
import 'package:parc_oto/screens/sidemenu/sidemenu.dart';
import 'package:parc_oto/screens/vehicle/brand/brand_list.dart';
import 'package:parc_oto/screens/vehicle/documents/document_tabs.dart';
import 'package:parc_oto/screens/vehicle/manager/vehicle_tabs.dart';
import 'package:parc_oto/screens/vehicle/states/state_tabs.dart';
import 'package:parc_oto/screens/vehicle/vehicle_dashboard.dart';
import 'package:parc_oto/theme.dart';


GlobalKey sideKey=GlobalKey();
class Routes {
  Routes(AppTheme appTheme) {
    router = GoRouter(

      initialLocation: '/dashboard',
      routes: [
        ShellRoute(
            builder: (context, state,s ) =>
                PanesList(key: sideKey,
                  paneList: PaneItemsAndFooters(appTheme), appTheme:
            appTheme,
                ),
            routes: [
              GoRoute(
                name: 'login',
                path: '/login',
                builder: (context, state) => const LoginScreen(),
              ),
              GoRoute(
                name: 'dashboard',
                path: '/dashboard',
                builder: (context, state) => const Dashboard(),
              ),
              GoRoute(
                  path: '/vehicles',
                  builder: (context, state) => const VehicleDashboard(),
                  routes: [
                    GoRoute(
                        path: 'manager',
                        builder: (context, state) => const VehicleTabs()),
                    GoRoute(
                        path: 'brands',
                        builder: (context, state) => const BrandList()),
                    GoRoute(
                        path: 'states',
                        builder: (context, state) => const StateTabs()),
                    GoRoute(
                        path: 'documents',
                        builder: (context, state) => const DocumentTabs()),
                  ]),
            ]),
        GoRoute(
            name: 'recoverpassword',
            path: '/recoverpassword',
            builder: (context, state) => const ResetScreen()),
        GoRoute(
            name: 'acceptinvitation',
            path: '/acceptinvitation',
            builder: (context, state) => const AcceptInvitation()),
      ],
    );
  }

  late final GoRouter router;
}
