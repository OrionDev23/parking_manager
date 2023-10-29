import 'package:parc_oto/providers/client_database.dart';
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

  late PaneItem vehicles;

  late PaneItem chauffeurs;

  late PaneItem evenements;
  void listenToSigningChanges() {

  }

  static List<NavigationPaneItem> originalItems = List.empty(growable: true);
  late List<NavigationPaneItem> footerItems;


  bool loading=false;
  @override
  void initState() {

    windowManager.setPreventClose(true);
    windowManager.addListener(this);
    getProfil();

    super.initState();
  }


  void getProfil() async{
    loading=true;
    if(mounted){
      setState(() {

      });
    }
    await ClientDatabase().getUser();
    updateOriginalItems();
    listenToSigningChanges();
    loading=false;
    if(mounted){
      setState(() {
      });
    }

  }


  String getFirstLetters(){
    String result="";
    if(ClientDatabase.user!=null){
      var s=ClientDatabase.user!.name.split(' ');
      if(s.length>1){
        result=s[0][0]+s[1][0];
      }
      else{
        result=ClientDatabase.user!.email[0]+ClientDatabase.user!.email[1];
      }
    }
    return result;
  }
  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();

    if(loading){
      return const Center(child: ProgressRing());
    }
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
                            if(!loading && ClientDatabase.user!=null)
                              CircleAvatar(
                                  backgroundColor:Colors.transparent,
                                  child:
                                  Container(
                                    decoration: BoxDecoration(
                                      color: appTheme.color,
                                      shape: BoxShape.circle,
                                    ),
                                    width: 4.w,
                                    height: 4.w,
                                    alignment: Alignment.center,
                                    child: Text(getFirstLetters().toUpperCase(),style: const TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
                                  ),
                              ),
                            if(!loading && ClientDatabase.user!=null)
                              const SizedBox(width: 10,),
                            if(!loading && ClientDatabase.user!=null)
                              Text(ClientDatabase.user!.email),
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
    vehicles=PaneItemExpander(icon: const Icon(FluentIcons.car),
        title: const Text('vehicules').tr(),
        items: [
          PaneItem(icon: const Icon(FluentIcons.edit),title: const Text('gestionvehicles').tr(), body: const Placeholder()),
          PaneItem(icon: const Icon(FluentIcons.verified_brand), title:const Text('brands').tr(),body: const Placeholder(),),
        ], body: const Text(''));
    chauffeurs=PaneItem(icon: const Icon(FluentIcons.people),title: const Text("chauffeurs").tr(), body: const Placeholder());
    evenements=PaneItemExpander(items:[
      PaneItem(icon: const Icon(FluentIcons.edit),title: const Text("gestionevent").tr(), body: const Placeholder()),
      PaneItem(icon: const Icon(FluentIcons.reservation_orders),title: const Text('planifier').tr(),body: const Placeholder()),
      PaneItem(icon: const Icon(FluentIcons.parking_solid),title: const Text('parking').tr(),body: const Placeholder()),
    ],icon: const Icon(FluentIcons.event),title: const Text('journal').tr(), body: const Placeholder());
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

    if(ClientDatabase.user!=null){
      originalItems=[
        acceuil,
        vehicles,
        evenements,
        chauffeurs,
      ];
    }
    else{
      originalItems=[
        login,
      ];
    }


    footerItems = [
      PaneItemSeparator(),
      if(ClientDatabase.user!=null)
      logout,
      parametres,
    ];
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
