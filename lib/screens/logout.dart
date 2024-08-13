import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/sidemenu/sidemenu.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../widgets/page_header.dart';

class LogoutScreen extends StatefulWidget {
  const LogoutScreen({super.key});

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  bool loginOut = false;

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
      header: PageTitle(
        text: 'deconnexion'.tr(),
      ),
      content: Center(
        child: Column(
          children: [
            SizedBox(
              height: 20.h,
            ),
            Container(
              padding: const EdgeInsets.all(10),
              alignment: Alignment.center,
              width: 25.w,
              height: 25.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: appTheme.mode == ThemeMode.dark
                    ? Colors.grey
                    : appTheme.mode == ThemeMode.light
                        ? Colors.white
                        : ThemeMode.system == ThemeMode.light
                            ? Colors.white
                            : Colors.grey,
                boxShadow: kElevationToShadow[2],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'disconnectconfirm',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                  ).tr(),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Button(
                            onPressed: loginOut ? null : logout,
                            child: loginOut
                                ? const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8.0),
                                    child: ProgressRing(),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: const Text('oui').tr(),
                                  )),
                        FilledButton(
                          onPressed: loginOut ? null : cancel,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: const Text('non').tr(),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void logout() async {
    setState(() {
      loginOut = true;
    });
    await DatabaseGetter.account!.deleteSession(sessionId: 'current');

    DatabaseGetter.user = null;
    PanesListState.signedIn.value = false;
    PanesListState.index.value = 0;
  }

  void cancel() {
    PanesListState.index.value = PanesListState.previousValue;
  }
}
