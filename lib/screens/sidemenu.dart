import 'package:parc_oto/screens/login_screen.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'dashboard.dart';
import 'settings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import '../theme.dart';


const defaultUserPic="https://upload.wikimedia.org/wikipedia/commons/7/72/Default-welcomer.png";
class PanesList extends StatefulWidget {
  final SharedPreferences prefs;
  const PanesList({
    super.key,
    required this.prefs,
  });

  @override
  State<PanesList> createState() => PanesListState();
}

class PanesListState extends State<PanesList> with WindowListener {
  static ValueNotifier<int> index = ValueNotifier(0);

  final viewKey = GlobalKey(debugLabel: 'Navigation View Key');
  static ValueNotifier<bool> signedIn = ValueNotifier(false);
  static bool listening = false;

  late PaneItem acceuil;
  PaneItemSeparator separator = PaneItemSeparator();
  late PaneItem login;
  late PaneItem logout;
  late PaneItem parametres;
  void listenToSigningChanges() {

  }

  static List<NavigationPaneItem> originalItems = List.empty(growable: true);
  late final List<NavigationPaneItem> footerItems;


  bool loading=false;
  @override
  void initState() {
    getProfil();
    initPanes();
    footerItems = [
      PaneItemSeparator(),
      parametres,
    ];

    windowManager.setPreventClose(true);
    windowManager.addListener(this);
    listenToSigningChanges();
    super.initState();
  }

  void initPanes() {
    acceuil = PaneItem(
        icon: const Icon(FluentIcons.home),
        body: const HomePage(),
        title: const Text('home').tr());
    login = PaneItem(
        icon: const Icon(FluentIcons.signin),
        title: const Text('seconnecter').tr(),
        body: const Placeholder());
    logout = PaneItem(
        icon: const Icon(FluentIcons.sign_out),
        title: const Text('decon').tr(),
        body: const Placeholder());
    parametres = PaneItem(
      icon: const Icon(FluentIcons.settings),
      title: const Text('parametres').tr(),
      body: Settings(widget.prefs),
    );
    updateOriginalItems();
  }

  void getProfil() async{

    loading=false;
    if(mounted){
      setState(() {
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    return ValueListenableBuilder(
        valueListenable: signedIn,
        builder: (BuildContext context, bool value, Widget? child) {
          updateOriginalItems();
          return ValueListenableBuilder(
              valueListenable: index,
              builder: (BuildContext context, int value, Widget? child) {
                return NavigationView(
                  key: viewKey,
                  appBar: NavigationAppBar(
                    automaticallyImplyLeading: false,
                    title: () {
                      return DragToMoveArea(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Row(children: [
                            Image.asset(
                              'assets/images/logo.webp',
                              width: 80,
                              height: 80,
                            ),
                            const Spacer(),
                            if(!loading)
                              CircleAvatar(
                                  backgroundColor:Colors.transparent,
                                  child: Image.network(
                                    defaultUserPic,
                                    fit: BoxFit.cover,
                                    width: 24,
                                    height: 24,
                                  )),
                            if(!loading)
                              const SizedBox(width: 10,),
                            if(!loading)
                              const Text('example@example.com'),
                              const SizedBox(width: 150,),
                          ],)
                        ),
                      );
                    }(),
                    actions: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          WindowButtons(),
                        ]),
                  ),
                  pane: NavigationPane(
                    selected: index.value,
                    onChanged: (i) {
                      index.value = i;
                    },
                    size: NavigationPaneSize(
                      openMaxWidth: 20.w,
                    ),
                    displayMode: appTheme.displayMode,
                    items: originalItems,
                    footerItems: footerItems,
                  ),
                  transitionBuilder: (w, a) {
                    return SuppressPageTransition(
                      child: w,
                    );
                  },
                );
              });

        });
  }

  @override
  void onWindowClose() {
    windowManager.isPreventClose().then((value) {
      if (value) {
        showDialog<String>(
          context: context,
          builder: (context) => ContentDialog(
            title: const Text('sur').tr(),
            content: const Text(
              'sauv',
            ).tr(),
            actions: [
              Button(
                child: const Text('oui').tr(),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await windowManager.destroy();
                },
              ),
              FilledButton(
                child: const Text('non').tr(),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    });
  }
  void updateOriginalItems() {
    originalItems.clear();
    acceuil=PaneItem(
        icon: const Icon(FluentIcons.home),
        body: const HomePage(),
        title: const Text('home').tr());

    login = PaneItem(
        icon: const Icon(FluentIcons.signin),
        title: const Text('seconnecter').tr(),
        body: const LoginScreen());
    logout = PaneItem(
        icon: const Icon(FluentIcons.sign_out),
        title: const Text('decon').tr(),
        body: const Placeholder());
    parametres = PaneItem(
      icon: const Icon(FluentIcons.settings),
      title: const Text('parametres').tr(),
      body: Settings(widget.prefs),
    );

    originalItems.addAll([
      acceuil,
      login,
    ]);

  }

}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);

    return SizedBox(
      width: 138,
      height: 50,
      child: WindowCaption(
        brightness: theme.brightness,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
