import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:parc_oto/admin_parameters.dart';
import 'package:parc_oto/main.dart';
import 'package:parc_oto/screens/sidemenu/sidemenu.dart';
import 'package:parc_oto/screens/workshop/inventory/inventory.dart';
import 'package:parc_oto/screens/workshop/inventory/suppliers.dart';
import 'package:parc_oto/screens/workshop/my_repair.dart';
import 'package:parc_oto/screens/workshop/parts/brands.dart';
import 'package:parc_oto/screens/workshop/parts/categories.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/client_database.dart';
import '../../theme.dart';
import '../backup/backup_manager.dart';
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
import '../../tutorials/tutorial.dart';
import '../user_management/user_management.dart';
import '../vehicle/brand/brand_list.dart';
import '../vehicle/documents/document_tabs.dart';
import '../vehicle/manager/vehicle_tabs.dart';
import '../vehicle/states/state_tabs.dart';
import '../vehicle/vehicle_dashboard.dart';
import '../workshop/parts/options.dart';
import '../workshop/parts/parts_management.dart';
import '../workshop/workshop_dashboard.dart';

class PaneItemsAndFooters {
  AppTheme appTheme;

  PaneItemsAndFooters(this.appTheme) {
    initPanes();
  }

  static late PaneItem dashboard;
  static late PaneItem usermanagement;
  static late PaneItemExpander vehicles;
  static late PaneItemExpander reparations;
  static late PaneItemExpander chauffeurs;
  static late PaneItem evenements;
  static late PaneItem planner;
  static late PaneItemExpander atelier;
  static late PaneItem login;
  static late PaneItem parametres;
  static late PaneItem logout;

  static late PaneItem backup;

  static late PaneItem entreprise;

  static late PaneItem tutorial;

  final TextStyle paneTextStyle = TextStyle(
    fontSize: 12.px,
  );

  initPanes() {
    dashboard = PaneItem(
        icon: Icon(
          FluentIcons.home,
          color: appTheme.color.lightest,
        ),
        body: const Dashboard(),
        title: Text(
          'home',
          style: paneTextStyle,
        ).tr());
    usermanagement = PaneItem(
        title: Text(
          'usermanagement',
          style: paneTextStyle,
        ).tr(),
        icon: Icon(
          FluentIcons.account_management,
          color: appTheme.color.lightest,
        ),
        body: const UserManagement());
    vehicles = PaneItemExpander(
        icon: Icon(
          FluentIcons.car,
          color: appTheme.color.lightest,
        ),
        title: Text(
          'thevehicles',
          style: paneTextStyle,
        ).tr(),
        items: [
          PaneItem(
              icon: Icon(
                FluentIcons.list,
                color: appTheme.color.lightest,
              ),
              title: Text(
                'gestionvehicles',
                style: paneTextStyle,
              ).tr(),
              body: const VehicleTabs()),
          PaneItem(
            icon: Icon(
              FluentIcons.verified_brand,
              color: appTheme.color.lightest,
            ),
            title: Text(
              'brands',
              style: paneTextStyle,
            ).tr(),
            body: const BrandList(),
          ),
          PaneItem(
            icon: Icon(
              FluentIcons.health,
              color: appTheme.color.lightest,
            ),
            title: Text(
              'vstates',
              style: paneTextStyle,
            ).tr(),
            body: const StateTabs(),
          ),
          PaneItem(
            icon: Icon(
              FluentIcons.document_set,
              color: appTheme.color.lightest,
            ),
            title: Text(
              'documents',
              style: paneTextStyle,
            ).tr(),
            body: const DocumentTabs(),
          ),
        ],
        body: const VehicleDashboard());

    chauffeurs = PaneItemExpander(
        icon: Icon(
          FluentIcons.people,
          color: appTheme.color.lightest,
        ),
        title: Text(
          "thechauffeurs",
          style: paneTextStyle,
        ).tr(),
        body: const ConducteurDashboard(),
        items: [
          PaneItem(
            icon: Icon(
              FluentIcons.list,
              color: appTheme.color.lightest,
            ),
            body: const ChauffeurTabs(),
            title: Text(
              'gchauffeurs',
              style: paneTextStyle,
            ).tr(),
          ),
          PaneItem(
            icon: Icon(
              FluentIcons.check_list_check,
              color: appTheme.color.lightest,
            ),
            title: Text(
              'disponibilite',
              style: paneTextStyle,
            ).tr(),
            body: const DisponbiliteTabs(),
          ),
          PaneItem(
            icon: Icon(
              FluentIcons.document_set,
              color: appTheme.color.lightest,
            ),
            title: Text(
              'documents',
              style: paneTextStyle,
            ).tr(),
            body: const CDocumentTabs(),
          ),
          PaneItem(
            icon: Icon(
              FluentIcons.search_bookmark,
              color: appTheme.color.lightest,
            ),
            title: Text(
              'archive',
              style: paneTextStyle,
            ).tr(),
            body: const ChauffeurTabs(
              archive: true,
            ),
          ),
        ]);
    atelier = PaneItemExpander(
      icon: Icon(
        Icons.home_repair_service_outlined,
        color: appTheme.color.lightest,
      ),
      body: const WorkshopDashboard(),
      title: Text(
        "workshop",
        style: paneTextStyle,
      ).tr(),
      items: [
        PaneItem(
          icon: Icon(
            FluentIcons.repair,
            color: appTheme.color.lightest,
          ),
          title: Text(
            'localrepair',
            style: paneTextStyle,
          ).tr(),
          body: const SelfRepair(),
        ),
        PaneItemHeader(
            header: Text('inventaire',style: paneTextStyle,).tr()
        ),
        PaneItem(
          icon: Icon(
            Icons.inventory_2_outlined,
            color: appTheme.color.lightest,
          ),
          title: Text(
            'stock',
            style: paneTextStyle,
          ).tr(),
          body: const PartsInventory(),
        ),
        PaneItem(
          icon: Icon(
            FluentIcons.service_activity,
            color: appTheme.color.lightest,
          ),
          title: Text(
            'fournisseurs',
            style: paneTextStyle,
          ).tr(),
          body: const SuppliersManagement(),
        ),
        PaneItemHeader(
            header: Text('pieces',style: paneTextStyle,).tr()
        ),
        PaneItem(
          icon: Icon(
            Icons.plumbing,
            color: appTheme.color.lightest,
          ),
          body: const PartsManagement(),
          title: Text(
            "gpieces",
            style: paneTextStyle,
          ).tr(),
        ),
        PaneItem(
          icon: Icon(
            FluentIcons.verified_brand,
            color: appTheme.color.lightest,
          ),
          body: const PartsBrands(),
          title: Text(
            "brands",
            style: paneTextStyle,
          ).tr(),
        ),
        PaneItem(
          icon: Icon(
            FluentIcons.category_classification,
            color: appTheme.color.lightest,
          ),
          body: const PartsCategories(),
          title: Text(
            "categories",
            style: paneTextStyle,
          ).tr(),
        ),
        PaneItem(
          icon: Icon(
            FluentIcons.text_paragraph_option,
            color: appTheme.color.lightest,
          ),
          body: const PartsOptions(),
          title: Text(
            "options",
            style: paneTextStyle,
          ).tr(),
        ),
      ],
    );
    evenements = PaneItem(
        icon: Icon(
          FluentIcons.database_activity,
          color: appTheme.color.lightest,
        ),
        title: Text(
          'journal',
          style: paneTextStyle,
        ).tr(),
        body: const LogActivityManagement());
    planner = PaneItem(
        icon: Icon(
          FluentIcons.event,
          color: appTheme.color.lightest,
        ),
        title: Text(
          'planifier',
          style: paneTextStyle,
        ).tr(),
        body: const PlanningManager());
    login = PaneItem(
        icon: Icon(
          FluentIcons.signin,
          color: appTheme.color.lightest,
        ),
        title: Text(
          'seconnecter',
          style: paneTextStyle,
        ).tr(),
        body: const LoginScreen());
    logout = PaneItem(
        icon: Icon(
          FluentIcons.sign_out,
          color: appTheme.color.lightest,
        ),
        title: Text(
          'decon',
          style: paneTextStyle,
        ).tr(),
        body: const LogoutScreen());
    parametres = PaneItem(
      icon: Icon(
        FluentIcons.settings,
        color: appTheme.color.lightest,
      ),
      title: Text(
        'parametres',
        style: paneTextStyle,
      ).tr(),
      body: Settings(prefs),
    );
    entreprise = PaneItemExpander(
        icon: Icon(
          FluentIcons.build_definition,
          color: appTheme.color.lightest,
        ),
        title: Text(
          'monentreprise',
          style: paneTextStyle,
        ).tr(),
        body: const MyEntreprise(),
        items: [
          PaneItem(
            icon: Icon(
              FluentIcons.sections,
              color: appTheme.color.lightest,
            ),
            title: Text(
              'filiales',
              style: paneTextStyle,
            ).tr(),
            body: const MesFilliales(),
          ),
          PaneItem(
            icon: Icon(
              FluentIcons.company_directory,
              color: appTheme.color.lightest,
            ),
            title: Text(
              'directions',
              style: paneTextStyle,
            ).tr(),
            body: const MesFilliales(
              type: 1,
            ),
          ),
          PaneItem(
            icon: Icon(
              FluentIcons.company_directory_mirrored,
              color: appTheme.color.lightest,
            ),
            title: Text(
              'departements',
              style: paneTextStyle,
            ).tr(),
            body: const MesFilliales(
              type: 2,
            ),
          ),
        ]);
    reparations = PaneItemExpander(
        icon: Icon(
          FluentIcons.repair,
          color: appTheme.color.lightest,
        ),
        title: Text(
          'thereparations',
          style: paneTextStyle,
        ).tr(),
        items: [
          PaneItem(
            icon: Icon(
              FluentIcons.list,
              color: appTheme.color.lightest,
            ),
            title: Text(
              'greparations',
              style: paneTextStyle,
            ).tr(),
            body: const ReparationTabs(),
          ),
          PaneItem(
            icon: Icon(
              FluentIcons.service_activity,
              color: appTheme.color.lightest,
            ),
            title: Text(
              'prestataires',
              style: paneTextStyle,
            ).tr(),
            body: const PrestataireTabs(),
          ),
        ],
        body: const ReparationDashboard());
    backup = PaneItem(
      icon: Icon(
        FluentIcons.save,
        color: appTheme.color.lightest,
      ),
      title: Text(
        'backup',
        style: paneTextStyle,
      ).tr(),
      body: const BackupManager(),
    );
    tutorial = PaneItem(
        icon: Icon(
          FluentIcons.guid,
          color: appTheme.color.lightest,
        ),
        title: Text(
          'tutorial',
          style: paneTextStyle,
        ).tr(),
        body: const Tutorial());
    bool isAdmin = ClientDatabase().isAdmin();
    bool isManager = ClientDatabase().isManager();

    if (PanesListState.signedIn.value) {
      originalItems = [
        if (PanesListState.signedIn.value)dashboard,
        if (isAdmin) usermanagement,
        if (PanesListState.signedIn.value)vehicles,
        if (PanesListState.signedIn.value)reparations,
        if (showAtelier) atelier,
        if (PanesListState.signedIn.value)chauffeurs,
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
      if (isAdmin && PanesListState.signedIn.value) entreprise,
      if (isAdmin && PanesListState.signedIn.value) backup,
      if (PanesListState.signedIn.value) logout,
      parametres,
      if (PanesListState.signedIn.value) tutorial,
    ];
  }

  static List<NavigationPaneItem> originalItems = List.empty(growable: true);
  static List<NavigationPaneItem> footerItems = List.empty(growable: true);
}
