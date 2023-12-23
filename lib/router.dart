import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:parc_oto/screens/dashboard/dashboard.dart';
import 'package:parc_oto/screens/login.dart';
import 'package:parc_oto/screens/reset_password.dart';
import 'package:parc_oto/screens/sidemenu/pane_items.dart';
import 'package:parc_oto/screens/sidemenu/sidemenu.dart';
import 'package:parc_oto/screens/vehicle/brand/brand_list.dart';
import 'package:parc_oto/screens/vehicle/manager/vehicle_tabs.dart';
import 'package:parc_oto/screens/vehicle/vehicle_dashboard.dart';

class Routes{

  SharedPreferences savedSettings;

  Routes(this.savedSettings){
    router= GoRouter(
      routes: [
        GoRoute(
          name: 'home',
          path: '/',
          builder: (context, state) => PanesList(
            paneList: PaneItemsAndFooters(savedSettings),
          ),
          routes: [
            GoRoute(
              name: 'login',
              path: 'login',
              builder: (context,state)=>const LoginScreen(),
            ),
            GoRoute(
              name: 'dashboard',
              path: 'dashboard',
              builder: (context,state)=>const Dashboard(),
            ),
            GoRoute(
                path: 'vehicles',
              builder: (context,state)=>const VehicleDashboard(),
              routes: [
                GoRoute(path: 'manager',builder: (context,state)=>const VehicleTabs()),
                GoRoute(path: 'brands',builder: (context,state)=>const BrandList())

              ]
            ),

          ]
        ),
        GoRoute(
            name: 'recoverpassword',
            path: '/recoverpassword',
            builder: (context,state) =>const ResetScreen()
        ),
      ],
    );
  }
  late final GoRouter router;
}

