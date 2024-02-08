import 'package:fluent_ui/fluent_ui.dart';
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

import 'main.dart';

class Routes {
  Routes(AppTheme appTheme) {
    final savedSettings = prefs;
    routes=
    {
     '/' : (context) =>
              PanesList(
                paneList: PaneItemsAndFooters(savedSettings),
                appTheme: appTheme,
              ),
    '/login': (context) => const LoginScreen(),
    '/dashboard' : (context) => const Dashboard(),
    '/vehicles':(context) => const VehicleDashboard(),
    '/vehicles/manager': (context ) => const VehicleTabs(),
    '/vehicles/brands': (context ) => const BrandList(),
     '/vehicles/states':(context) => const StateTabs(),
     '/vehicles/documents': (context) => const DocumentTabs(),
    '/recoverpassword': (context) => const ResetScreen(),
    '/acceptinvitation': (context) => const AcceptInvitation()
  };
  }

  late final Map<String,Widget Function(BuildContext)> routes;
}
