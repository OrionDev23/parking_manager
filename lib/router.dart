import 'package:go_router/go_router.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:parc_oto/screens/login.dart';
import 'package:parc_oto/screens/reset_password.dart';
import 'package:parc_oto/screens/sidemenu/sidemenu.dart';

class Routes{

  SharedPreferences savedSettings;

  Routes(this.savedSettings){
    router= GoRouter(
      routes: [
        GoRoute(
          name: 'home',
          path: '/',
          builder: (context, state) => PanesList(
            prefs: savedSettings,
          ),
          routes: [
            GoRoute(
              name: 'login',
              path: 'login',
              builder: (context,state)=>const LoginScreen(),
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

