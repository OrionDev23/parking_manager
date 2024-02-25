import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/sidemenu/sidemenu.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/client_database.dart';
import '../../theme.dart';
import '../chauffeur/conducteur_dashboard.dart';
import '../chauffeur/disponibilite/disponibilite_tabs.dart';
import '../chauffeur/document/chauf_document_tabs.dart';
import '../chauffeur/manager/chauffeur_tabs.dart';
import '../dashboard/dashboard.dart';
import '../entreprise/entreprise.dart';
import '../entreprise/fililales.dart';
import '../login.dart';
import '../logout.dart';
import '../logs/logging/log_management.dart';
import '../planning/planning_manager.dart';
import '../prestataire/prestataire_tabs.dart';
import '../reparation/manager/reparation_tabs.dart';
import '../reparation/reparation_dashboard.dart';
import '../settings.dart';
import '../user_management/user_management.dart';
import '../vehicle/brand/brand_list.dart';
import '../vehicle/documents/document_tabs.dart';
import '../vehicle/manager/vehicle_tabs.dart';
import '../vehicle/states/state_tabs.dart';
import '../vehicle/vehicle_dashboard.dart';

class PaneItemsAndFooters {
  SharedPreferences savedPrefs;
  AppTheme appTheme;

  PaneItemsAndFooters(this.savedPrefs,this.appTheme) {
    initPanes();
  }

  static late PaneItem dashboard;
  static late PaneItem usermanagement;
  static late PaneItem vehicles;
  static late PaneItem reparations;
  static late PaneItem chauffeurs;
  static late PaneItem evenements;
  static late PaneItem planner;
  static late PaneItem login;
  static late PaneItem parametres;
  static late PaneItem logout;

  static late PaneItem backup;

  static late PaneItem entreprise;

  initPanes() {
    dashboard = PaneItem(
        icon: Icon(FluentIcons.home,color: appTheme.color.lightest,),
        body: const Dashboard(),
        title: const Text('home').tr());
    usermanagement = PaneItem(
        title: const Text('usermanagement').tr(),
        icon: Icon(FluentIcons.account_management,color: appTheme.color.lightest,),
        body: const UserManagement());
    vehicles = PaneItemExpander(
        icon: Icon(FluentIcons.car,color: appTheme.color.lightest,),
        title: const Text('vehicules').tr(),
        items: [
          PaneItem(
              icon: Icon(FluentIcons.list,color: appTheme.color.lightest,),
              title: const Text('gestionvehicles').tr(),
              body: const VehicleTabs()),
          PaneItem(
            icon: Icon(FluentIcons.verified_brand,color: appTheme.color.lightest,),
            title: const Text('brands').tr(),
            body: const BrandList(),
          ),
          PaneItem(
            icon: Icon(FluentIcons.health,color: appTheme.color.lightest,),
            title: const Text('vstates').tr(),
            body: const StateTabs(),
          ),
          PaneItem(
            icon: Icon(FluentIcons.document_set,color: appTheme.color.lightest,),
            title: const Text('documents').tr(),
            body: const DocumentTabs(),
          ),
        ],
        body: const VehicleDashboard());
    reparations = PaneItemExpander(
        icon: Icon(FluentIcons.repair,color: appTheme.color.lightest,),
        title: const Text('reparations').tr(),
        items: [
          PaneItem(
            icon: Icon(FluentIcons.list,color: appTheme.color.lightest,),
            title: const Text('greparations').tr(),
            body: const ReparationTabs(),
          ),
          PaneItem(
            icon: Icon(FluentIcons.service_activity,color: appTheme.color.lightest,),
            title: const Text('prestataires').tr(),
            body: const PrestataireTabs(),
          ),
        ],
        body: const ReparationDashboard());
    chauffeurs = PaneItemExpander(
        icon: Icon(FluentIcons.people,color: appTheme.color.lightest,),
        title: const Text("chauffeurs").tr(),
        body: const ConducteurDashboard(),
        items: [
          PaneItem(
            icon: Icon(FluentIcons.list,color: appTheme.color.lightest,),
            body: const ChauffeurTabs(),
            title: const Text('gchauffeurs').tr(),
          ),
          PaneItem(
            icon: Icon(FluentIcons.check_list_check,color: appTheme.color.lightest,),
            title: const Text('disponibilite').tr(),
            body: const DisponbiliteTabs(),
          ),
          PaneItem(
            icon: Icon(FluentIcons.document_set,color: appTheme.color.lightest,),
            title: const Text('documents').tr(),
            body: const CDocumentTabs(),
          ),
          PaneItem(
            icon: Icon(FluentIcons.search_bookmark,color: appTheme.color.lightest,),
            title: const Text('archive').tr(),
            body: const ChauffeurTabs(
              archive: true,
            ),
          ),
        ]);
    evenements = PaneItem(
        icon: Icon(FluentIcons.database_activity,color: appTheme.color.lightest,),
        title: const Text('journal').tr(),
        body: const LogActivityManagement());
    planner = PaneItem(
        icon: Icon(FluentIcons.event,color: appTheme.color.lightest,),
        title: const Text('planifier').tr(),
        body: const PlanningManager());
    login = PaneItem(
        icon: Icon(FluentIcons.signin,color: appTheme.color.lightest,),
        title: const Text('seconnecter').tr(),
        body: const LoginScreen());
    logout = PaneItem(
        icon: Icon(FluentIcons.sign_out,color: appTheme.color.lightest,),
        title: const Text('decon').tr(),
        body: const LogoutScreen());
    parametres = PaneItem(
      icon: Icon(FluentIcons.settings,color: appTheme.color.lightest,),
      title: const Text('parametres').tr(),
      body: Settings(savedPrefs),
    );
    entreprise = PaneItemExpander(
      icon: Icon(FluentIcons.build_definition,color: appTheme.color.lightest,),
      title: const Text('monentreprise').tr(),
      body: const MyEntreprise(),
      items:[
        PaneItem(
          icon: Icon(FluentIcons.sections,color: appTheme.color.lightest,),
          title: const Text('filiales').tr(),
          body: const MesFilliales(),
        ),
        PaneItem(
          icon: Icon(FluentIcons.company_directory,color: appTheme.color.lightest,),
          title: const Text('directions').tr(),
          body: const MesFilliales(direction:true),
        ),
      ]
    );

    backup = PaneItem(
      icon: Icon(FluentIcons.backlog,color: appTheme.color.lightest,),
      title: const Text('backup').tr(),
      body: const Center(
        child: Text(
          'DEMO',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
    bool isAdmin = ClientDatabase().isAdmin();
    bool isManager = ClientDatabase().isManager();

    if (PanesListState.signedIn.value) {
      originalItems = [
        if (isAdmin || isManager) dashboard,
        if (isAdmin) usermanagement,
        if (isAdmin || isManager) vehicles,
        if (isAdmin || isManager) reparations,
        if (isAdmin || isManager) chauffeurs,
        if (isAdmin || isManager) planner,
        if (isAdmin || isManager) evenements,
      ];
    } else {
      originalItems = [
        login,
      ];
    }

    footerItems = [
      PaneItemSeparator(),
      if (isAdmin) entreprise,
      if (isAdmin) backup,
      if (PanesListState.signedIn.value) logout,
      parametres,
    ];
  }

  static List<NavigationPaneItem> originalItems = List.empty(growable: true);
  static List<NavigationPaneItem> footerItems = List.empty(growable: true);
}
