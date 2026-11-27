import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:material_ui/material_ui.dart' hide Card, FilledButton;

import '../clients/client_tabs.dart';
import '../reparation/fiche_reception/manager/fiche_reception_tabs.dart';
import '../reparation/reparation/manager/reparation_tabs.dart';
import '../settings_gts.dart';
import '../workshop/inventory/storage/storage_tabs.dart';
import '../workshop/parts/parts_management/parts_tabs.dart';
import '../../admin_parameters.dart';
import '../../main.dart';
import 'sidemenu.dart';

import 'package:responsive_sizer/responsive_sizer.dart';

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
import '../reparation/reparation_dashboard.dart';
import '../settings.dart';
import '../../tutorials/tutorial.dart';
import '../user_management/user_management.dart';
import '../platform/platform_companies_screen.dart';
import '../access/access_management.dart';
import '../vehicle/vehicle_dashboard.dart';
import '../workshop/inventory/fournisseurs/fournisseur_tabs.dart';
import '../workshop/parts/brands/brand_tabs.dart';
import '../workshop/parts/categories/category_tabs.dart';
import '../workshop/parts/options/option_tabs.dart';
import '../workshop/workshop_dashboard.dart';

class PaneItemsAndFooters {
  AppTheme appTheme;

  PaneItemsAndFooters(this.appTheme) {
    initPanes();
  }

  static late PaneItem dashboard;
  static late PaneItem usermanagement;
  static late PaneItem platformCompanies;
  static late PaneItem accessManagement;
  static late PaneItemExpander userAccessManagement;
  static late PaneItem vehicles;
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

  final TextStyle paneTextStyle = TextStyle(fontSize: 12.px);

  void initPanes() {
    dashboard = PaneItem(
      key: Key("dashboard"),
      icon: Icon(FluentIcons.home, color: appTheme.color.lightest),
      body: const Dashboard(),
      title: Text('home', style: paneTextStyle).tr(),
    );
    accessManagement = PaneItem(
      key: const Key("access"),
      title: const Text('Équipes et accès'),
      icon: Icon(FluentIcons.security_group, color: appTheme.color.lightest),
      body: const AccessManagement(),
    );
    platformCompanies = PaneItem(
      key: const Key('platform-companies'),
      title: const Text('Entreprises clientes'),
      icon: Icon(FluentIcons.cloud, color: appTheme.color.lightest),
      body: const PlatformCompaniesScreen(),
    );
    usermanagement = PaneItem(
      key: Key("usermngmt"),
      title: Text('usermanagement', style: paneTextStyle).tr(),
      icon: Icon(
        FluentIcons.account_management,
        color: appTheme.color.lightest,
      ),
      body: const UserManagement(),
    );
    vehicles = PaneItem(
      key: const ValueKey('vehicles'),
      icon: Icon(
        gts ? Icons.local_shipping_outlined : Icons.directions_car,
        color: appTheme.color.lightest,
      ),
      title: Text('thevehicles', style: paneTextStyle).tr(),
      body: const VehicleDashboard(),
    );
    chauffeurs = PaneItemExpander(
      key: Key("chauffeurs"),

      icon: Icon(FluentIcons.people, color: appTheme.color.lightest),
      title: Text("thechauffeurs", style: paneTextStyle).tr(),
      body: const ConducteurDashboard(),
      items: [
        PaneItem(
          key: const Key('driver-manager'),
          icon: Icon(FluentIcons.list, color: appTheme.color.lightest),
          body: const ChauffeurTabs(),
          title: Text('gchauffeurs', style: paneTextStyle).tr(),
        ),
        PaneItem(
          key: const Key('driver-availability'),
          icon: Icon(
            FluentIcons.check_list_check,
            color: appTheme.color.lightest,
          ),
          title: Text('disponibilite', style: paneTextStyle).tr(),
          body: const DisponbiliteTabs(),
        ),
        PaneItem(
          key: const Key('driver-documents'),
          icon: Icon(FluentIcons.document_set, color: appTheme.color.lightest),
          title: Text('documents', style: paneTextStyle).tr(),
          body: const CDocumentTabs(),
        ),
        PaneItem(
          key: const Key('driver-archive'),
          icon: Icon(
            FluentIcons.search_bookmark,
            color: appTheme.color.lightest,
          ),
          title: Text('archive', style: paneTextStyle).tr(),
          body: const ChauffeurTabs(archive: true),
        ),
      ],
    );
    atelier = PaneItemExpander(
      key: const ValueKey('atelier'),
      icon: Icon(
        Icons.home_repair_service_outlined,
        color: appTheme.color.lightest,
      ),
      body: const WorkshopDashboard(),
      title: Text("workshop", style: paneTextStyle).tr(),
      items: [
        PaneItemHeader(header: Text('inventaire', style: paneTextStyle).tr()),
        PaneItem(
          key: const ValueKey('workshop-stock'),
          icon: Icon(
            Icons.inventory_2_outlined,
            color: appTheme.color.lightest,
          ),
          title: Text('stock', style: paneTextStyle).tr(),
          body: const StorageTabs(),
        ),
        PaneItem(
          key: const ValueKey('workshop-suppliers'),
          icon: Icon(
            FluentIcons.service_activity,
            color: appTheme.color.lightest,
          ),
          title: Text('fournisseurs', style: paneTextStyle).tr(),
          body: const FournisseurTabs(),
        ),
        PaneItemHeader(header: Text('pieces', style: paneTextStyle).tr()),
        PaneItem(
          key: const ValueKey('workshop-parts'),
          icon: Icon(Icons.plumbing, color: appTheme.color.lightest),
          body: const PartsTabs(),
          title: Text("gpieces", style: paneTextStyle).tr(),
        ),
        PaneItem(
          key: const ValueKey('workshop-brands'),
          icon: Icon(
            FluentIcons.verified_brand,
            color: appTheme.color.lightest,
          ),
          body: const BrandTabs(),
          title: Text("brands", style: paneTextStyle).tr(),
        ),
        PaneItem(
          key: const ValueKey('workshop-categories'),
          icon: Icon(
            FluentIcons.category_classification,
            color: appTheme.color.lightest,
          ),
          body: const CategoryTabs(),
          title: Text("categories", style: paneTextStyle).tr(),
        ),
        PaneItem(
          key: const ValueKey('workshop-options'),
          icon: Icon(
            FluentIcons.text_paragraph_option,
            color: appTheme.color.lightest,
          ),
          body: const OptionTabs(),
          title: Text("options", style: paneTextStyle).tr(),
        ),
      ],
    );
    evenements = PaneItem(
      key: Key("events"),

      icon: Icon(FluentIcons.database_activity, color: appTheme.color.lightest),
      title: Text('journal', style: paneTextStyle).tr(),
      body: const LogActivityManagement(),
    );
    planner = PaneItem(
      key: Key("planner"),

      icon: Icon(FluentIcons.event, color: appTheme.color.lightest),
      title: Text('planifier', style: paneTextStyle).tr(),
      body: const PlanningManager(),
    );
    login = PaneItem(
      key: Key("login"),

      icon: Icon(FluentIcons.signin, color: appTheme.color.lightest),
      title: Text('seconnecter', style: paneTextStyle).tr(),
      body: const LoginScreen(),
    );
    logout = PaneItem(
      key: Key("logout"),
      icon: Icon(FluentIcons.sign_out, color: appTheme.color.lightest),
      title: Text('decon', style: paneTextStyle).tr(),
      body: const LogoutScreen(),
    );
    parametres = PaneItem(
      key: Key("settings"),

      icon: Icon(FluentIcons.settings, color: appTheme.color.lightest),
      title: Text('parametres', style: paneTextStyle).tr(),
      body: gts ? SettingsGTS(prefs) : Settings(prefs),
    );
    entreprise = PaneItemExpander(
      key: Key("company"),

      icon: Icon(FluentIcons.build_definition, color: appTheme.color.lightest),
      title: Text('monentreprise', style: paneTextStyle).tr(),
      body: const MyEntreprise(),
      items: [
        PaneItem(
          key: const ValueKey('company-filiales'),
          icon: Icon(FluentIcons.sections, color: appTheme.color.lightest),
          title: Text('filiales', style: paneTextStyle).tr(),
          body: const MesFilliales(),
        ),
        PaneItem(
          key: const ValueKey('company-directions'),
          icon: Icon(
            FluentIcons.company_directory,
            color: appTheme.color.lightest,
          ),
          title: Text('directions', style: paneTextStyle).tr(),
          body: const MesFilliales(type: 1),
        ),
        PaneItem(
          key: const ValueKey('company-departments'),
          icon: Icon(
            FluentIcons.company_directory_mirrored,
            color: appTheme.color.lightest,
          ),
          title: Text('departements', style: paneTextStyle).tr(),
          body: const MesFilliales(type: 2),
        ),
      ],
    );
    reparations = PaneItemExpander(
      key: Key("repairs"),

      icon: Icon(FluentIcons.repair, color: appTheme.color.lightest),
      title: Text('thereparations', style: paneTextStyle).tr(),
      items: [
        PaneItem(
          key: const Key('repair-reception'),
          icon: Icon(
            Icons.receipt_long_outlined,
            color: appTheme.color.lightest,
          ),
          title: Text('fichesreception', style: paneTextStyle).tr(),
          body: const FicheReceptionTabs(),
        ),
        PaneItem(
          key: const Key('repair-orders'),
          icon: Icon(Icons.car_repair_outlined, color: appTheme.color.lightest),
          title: Text('orderreparations', style: paneTextStyle).tr(),
          body: const ReparationTabs(),
        ),
        PaneItem(
          key: const Key('repair-providers'),
          icon: Icon(
            FluentIcons.service_activity,
            color: appTheme.color.lightest,
          ),
          title: Text('prestataires', style: paneTextStyle).tr(),
          body: const PrestataireTabs(),
        ),
        PaneItem(
          key: const Key('repair-clients'),
          icon: Icon(Icons.people_alt_outlined, color: appTheme.color.lightest),
          title: Text('clients', style: paneTextStyle).tr(),
          body: const ClientTabs(),
        ),
      ],
      body: const ReparationDashboard(),
    );
    backup = PaneItem(
      key: Key("backup"),

      icon: Icon(FluentIcons.save, color: appTheme.color.lightest),
      title: Text('backup', style: paneTextStyle).tr(),
      body: const BackupManager(),
    );
    tutorial = PaneItem(
      key: Key("tutorials"),

      icon: Icon(FluentIcons.guid, color: appTheme.color.lightest),
      title: Text('tutorial', style: paneTextStyle).tr(),
      body: const Tutorial(),
    );
    final canManageUsers =
        authService.session?.hasPermission('users.manage') ?? false;
    final canManageAccess =
        authService.session?.hasPermission('permissions.manage') ?? false;

    userAccessManagement = PaneItemExpander(
      key: const Key("user-access-management"),
      icon: Icon(FluentIcons.people, color: appTheme.color.lightest),
      title: const Text('Utilisateurs & accès'),
      body: canManageUsers ? const UserManagement() : const AccessManagement(),
      items: [
        if (canManageUsers) usermanagement,
        if (canManageAccess) accessManagement,
      ],
    );

    final isPlatformCompanyContext =
        authService.session?.isPlatformCompanyContext == true;
    final isPlatformSession =
        authService.session?.isPlatformSuperAdmin == true &&
        !isPlatformCompanyContext;
    if (PanesListState.signedIn.value) {
      if (isPlatformSession) {
        originalItems = [
          PaneItemHeader(header: const Text('ADMINISTRATION CENTRALE')),
          platformCompanies,
          PaneItemHeader(header: const Text('ORGANISATION')),
          parametres,
        ];
      } else {
        originalItems = [
          dashboard,
          PaneItemHeader(header: const Text('EXPLOITATION')),
          vehicles,
          chauffeurs,
          if (authService.session?.hasPermission('planning.manage') == true)
            planner,
          PaneItemHeader(header: const Text('MAINTENANCE')),
          reparations,
          if (showAtelier) atelier,
          if (authService.session?.hasPermission('activity.view') == true)
            PaneItemHeader(header: const Text('GESTION & SUIVI')),
          if (authService.session?.hasPermission('activity.view') == true)
            evenements,
          PaneItemHeader(header: const Text('ORGANISATION')),
          if (canManageUsers || canManageAccess) userAccessManagement,
          if (authService.session?.hasPermission('company.manage') == true)
            entreprise,
          parametres,
        ];
      }
    } else {
      originalItems = [
        PaneItemHeader(header: const Text('BIENVENUE SUR PARCOTO')),
        login,
      ];
    }

    footerItems = [
      PaneItemSeparator(),
      PaneItemHeader(header: const Text('COMPTE & SYSTÈME')),
      if (!isPlatformSession &&
          authService.session?.hasPermission('backup.manage') == true &&
          PanesListState.signedIn.value)
        backup,
      if (isPlatformCompanyContext)
        PaneItem(
          key: const ValueKey('platform-return'),
          icon: Icon(FluentIcons.back, color: appTheme.color.lightest),
          title: const Text('Retour administration plateforme'),
          body: const _PlatformContextReturnScreen(),
        ),
      if (PanesListState.signedIn.value) logout,
      if (!PanesListState.signedIn.value) parametres,
      if (PanesListState.signedIn.value && !isPlatformSession) tutorial,
    ];
  }

  /// Resolves a destination using the same selectable-item ordering as
  /// NavigationPane. Headers and separators are structural and do not occupy
  /// a selected index.
  /// Returns the selected destination key using the exact same flattened
  /// ordering as ParcotoNavigationShell. This is used by the global shell to
  /// choose a search adapter for the currently visible screen.
  static String? paneKeyForIndex(int selectedIndex) {
    final selectableItems = <NavigationPaneItem>[];

    void flatten(List<NavigationPaneItem> items) {
      for (final item in items) {
        if (item is PaneItemHeader || item is PaneItemSeparator) continue;
        if (item is PaneItem || item is PaneItemExpander) {
          selectableItems.add(item);
          if (item is PaneItemExpander) flatten(item.items);
        }
      }
    }

    flatten(originalItems);
    flatten(footerItems);
    if (selectedIndex < 0 || selectedIndex >= selectableItems.length) {
      return null;
    }

    final selected = selectableItems[selectedIndex];
    final rawKey = selected.key;
    final key = rawKey is ValueKey ? rawKey.value.toString() : null;
    if (key == null || key.isEmpty) return null;

    if (key == 'user-access-management' &&
        authService.session?.hasPermission('users.manage') == true) {
      return 'usermngmt';
    }

    // The vehicle dashboard is a nested workspace. Its selected legacy
    // section is more specific than the parent NavigationPane destination.
    if (key == 'vehicles') {
      switch (VehicleDashboard.selectedSection.value) {
        case 1:
          return 'vehicle-documents';
        case 2:
          return VehicleDashboard.selectedReference.value == 1
              ? 'vehicle-states'
              : 'vehicle-brands';
        default:
          return 'vehicle-manager';
      }
    }

    return key;
  }

  /// Resolves the localized title for the currently active page.
  /// Vehicle sub-sections are nested inside a single legacy workspace.
  static String? pageTitleForKey(String? key) {
    if (key == null || key.isEmpty) return null;

    switch (key) {
      case 'vehicle-manager':
        return 'Parc automobile';
      case 'vehicle-documents':
        return 'gestiondocument'.tr();
      case 'vehicle-brands':
        return 'brands'.tr();
      case 'vehicle-states':
        return 'vstates'.tr();
    }

    String? textFromTitle(Widget? title) {
      if (title is Text) {
        return title.data ?? title.textSpan?.toPlainText();
      }
      if (title is RichText) return title.text.toPlainText();
      return null;
    }

    String? findTitle(List<NavigationPaneItem> items) {
      for (final item in items) {
        if (item.key is ValueKey &&
            (item.key as ValueKey).value.toString() == key) {
          if (item is PaneItem) return textFromTitle(item.title);
          if (item is PaneItemExpander) {
            return textFromTitle(item.title);
          }
        }
        if (item is PaneItemExpander) {
          final nested = findTitle(item.items);
          if (nested != null) return nested;
        }
      }
      return null;
    }

    return findTitle(originalItems) ?? findTitle(footerItems);
  }

  static int? indexForPaneKey(String value) {
    if (_isLegacyVehiclePaneKey(value)) value = 'vehicles';
    final mainIndex = _findPaneIndex(originalItems, value, 0);
    if (mainIndex != null) return mainIndex;

    // Footer items are rendered after the primary navigation destinations in
    // ParcotoNavigationShell, so their indices begin after the main menu.
    return _findPaneIndex(
      footerItems,
      value,
      _selectablePaneCount(originalItems),
    );
  }

  static int? _findPaneIndex(
    List<NavigationPaneItem> items,
    String value,
    int startIndex,
  ) {
    var currentIndex = startIndex;
    for (final item in items) {
      if (item is PaneItemHeader || item is PaneItemSeparator) {
        continue;
      }

      if (item.key is ValueKey && (item.key as ValueKey).value == value) {
        return currentIndex;
      }

      currentIndex++;
      if (item is PaneItemExpander) {
        final childIndex = _findPaneIndex(
          item.items,
          value,
          currentIndex,
        );
        if (childIndex != null) return childIndex;
        currentIndex += _selectablePaneCount(item.items);
      }
    }
    return null;
  }

  static int _selectablePaneCount(List<NavigationPaneItem> items) {
    var count = 0;
    for (final item in items) {
      if (item is PaneItemHeader || item is PaneItemSeparator) {
        continue;
      }
      count++;
      if (item is PaneItemExpander) {
        count += _selectablePaneCount(item.items);
      }
    }
    return count;
  }

  static bool selectPane(String value) {
    if (_isLegacyVehiclePaneKey(value)) {
      VehicleDashboard.selectLegacySection(value);
      value = 'vehicles';
    }
    final targetIndex = indexForPaneKey(value);
    if (targetIndex == null) {
      debugPrint('[ParcOto Navigation] Pane not found: $value');
      return false;
    }
    PanesListState.index.value = targetIndex;
    return true;
  }

  static bool _isLegacyVehiclePaneKey(String value) => const {
    'vehicle-manager',
    'vehicle-documents',
    'vehicle-brands',
    'vehicle-states',
  }.contains(value);

  static List<NavigationPaneItem> originalItems = List.empty(growable: true);
  static List<NavigationPaneItem> footerItems = List.empty(growable: true);
}


class _PlatformContextReturnScreen extends StatelessWidget {
  const _PlatformContextReturnScreen();

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(FluentIcons.cloud, size: 36),
                const SizedBox(height: 16),
                const Text(
                  'Contexte entreprise',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vous consultez Parcoto avec vos privilèges Super Admin. '
                  'Vous pouvez revenir à tout moment à la gestion globale des entreprises.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    try {
                      await authService.returnToPlatformContext();
                    } catch (error) {
                      if (!context.mounted) return;
                      displayMessage(
                        context,
                        error.toString().replaceFirst('Bad state: ', ''),
                        InfoBarSeverity.error,
                      );
                    }
                  },
                  child: const Text('Retour à l’administration plateforme'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
