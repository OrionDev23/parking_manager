import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:parc_oto/screens/sidemenu/sidemenu.dart';

import '../../providers/client_database.dart';
import '../chauffeur/disponibilite/disponibilite_tabs.dart';
import '../chauffeur/document/chauf_document_tabs.dart';
import '../chauffeur/manager/chauffeur_tabs.dart';
import '../dashboard/dashboard.dart';
import '../entreprise.dart';
import '../login.dart';
import '../logout.dart';
import '../logs/logging/log_management.dart';
import '../logs/planning/planing_calendar.dart';
import '../prestataire/prestataire_tabs.dart';
import '../reparation/reparation_tabs.dart';
import '../settings.dart';
import '../user_management/user_management.dart';
import '../vehicle/brand/brand_list.dart';
import '../vehicle/documents/document_tabs.dart';
import '../vehicle/manager/vehicle_tabs.dart';
import '../vehicle/states/state_tabs.dart';
import '../vehicle/vehicle_dashboard.dart';

class PaneItemsAndFooters{
  SharedPreferences savedPrefs;
  PaneItemsAndFooters(this.savedPrefs){
    initPanes();
  }

  initPanes(){
    PaneItem dashboard = PaneItem(
        icon: const Icon(FluentIcons.home),
        body: const Dashboard(),
        title: const Text('home').tr());
    PaneItem usermanagement=PaneItem(
      title: const Text('usermanagement').tr(),
        icon: const Icon(FluentIcons.account_management),
        body: const UserManagement());
    PaneItem vehicles = PaneItemExpander(
        icon: const Icon(FluentIcons.car),
        title: const Text('vehicules').tr(),
        items: [
          PaneItem(
              icon: const Icon(FluentIcons.list),
              title: const Text('gestionvehicles').tr(),
              body: const VehicleTabs()),
          PaneItem(
            icon: const Icon(FluentIcons.verified_brand),
            title: const Text('brands').tr(),
            body: const BrandList(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.health),
            title: const Text('vstates').tr(),
            body: const StateTabs(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.document_set),
            title: const Text('documents').tr(),
            body: const DocumentTabs(),
          ),
        ],
        body: const VehicleDashboard());
    PaneItem reparations = PaneItemExpander(
        icon: const Icon(FluentIcons.repair),
        title: const Text('reparations').tr(),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.list),
            title: const Text('greparations').tr(),
            body: const ReparationTabs(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.service_activity),
            title: const Text('prestataires').tr(),
            body: const PrestataireTabs(),
          ),
        ],
        body: const SizedBox());
    PaneItem chauffeurs = PaneItemExpander(
        icon: const Icon(FluentIcons.people),
        title: const Text("chauffeurs").tr(),
        body: const Placeholder(),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.list),
            body: const ChauffeurTabs(),
            title: const Text('gchauffeurs').tr(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.document_set),
            title: const Text('documents').tr(),
            body: const CDocumentTabs(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.check_list_check),
            title: const Text('disponibilite').tr(),
            body: const DisponbiliteTabs(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.search_bookmark),
            title: const Text('archive').tr(),
            body: const ChauffeurTabs(
              archive: true,
            ),
          ),
        ]);
    PaneItem evenements = PaneItemExpander(
        items: [
          PaneItem(
              icon: const Icon(FluentIcons.edit),
              title: const Text("gestionevent").tr(),
              body: const LogActivityManagement()),
          PaneItem(
              icon: const Icon(FluentIcons.reservation_orders),
              title: const Text('planifier').tr(),
              body: const PlanningCalendar()),
          PaneItem(
              icon: const Icon(FluentIcons.parking_solid),
              title: const Text('parking').tr(),
              body: const Placeholder()),
        ],
        icon: const Icon(FluentIcons.event),
        title: const Text('journal').tr(),
        body: const Placeholder());
    PaneItem login = PaneItem(
        icon: const Icon(FluentIcons.signin),
        title: const Text('seconnecter').tr(),
        body: const LoginScreen());
    PaneItem logout = PaneItem(
        icon: const Icon(FluentIcons.sign_out),
        title: const Text('decon').tr(),
        body: const LogoutScreen());
    PaneItem parametres = PaneItem(
      icon: const Icon(FluentIcons.settings),
      title: const Text('parametres').tr(),
      body: Settings(savedPrefs),
    );
    PaneItem entreprise = PaneItem(
      icon: const Icon(FluentIcons.build_definition),
      title: const Text('monentreprise').tr(),
      body: const MyEntreprise(),
    );

    bool isAdmin = ClientDatabase().isAdmin();
    bool isManager = ClientDatabase().isManager();

    if (PanesListState.signedIn.value) {
      originalItems = [
        if (isAdmin || isManager) dashboard,
        if(isAdmin) usermanagement,
        if (isAdmin || isManager) vehicles,
        if (isAdmin || isManager) reparations,
        if (isAdmin || isManager) chauffeurs,
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
      if (PanesListState.signedIn.value) logout,
      parametres,
    ];
  }
  List<NavigationPaneItem> originalItems = List.empty(growable: true);
  List<NavigationPaneItem> footerItems=List.empty(growable: true);

}