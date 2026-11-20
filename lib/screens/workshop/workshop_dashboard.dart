import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';

import '../../providers/client_database.dart';
import '../../providers/counters.dart';
import '../../providers/parts_provider.dart';
import '../../theme.dart';
import '../../ui/design_system/parcoto_tokens.dart';
import '../../widgets/module_dashboard_action.dart';
import '../../widgets/module_dashboard_header.dart';
import '../../widgets/module_dashboard_metric.dart';
import '../sidemenu/pane_items.dart';

class WorkshopDashboard extends StatefulWidget {
  const WorkshopDashboard({super.key});

  @override
  State<WorkshopDashboard> createState() => _WorkshopDashboardState();
}

class _WorkshopDashboardState extends State<WorkshopDashboard> {
  late final PartsProvider _partsProvider;
  late final VoidCallback _companyRevisionListener;
  Future<int> _loadStockCount() =>
      DatabaseCounters().countStockEntries();
  int _stockMetricRevision = 0;
  bool? _hasInternet;

  @override
  void initState() {
    super.initState();
    _partsProvider = PartsProvider();
    _companyRevisionListener = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_refreshCatalog());
      });
    };
    DatabaseGetter.companyRevisionListenable.addListener(
      _companyRevisionListener,
    );
    _refreshCatalog();
  }

  Future<void> _refreshCatalog() async {
    // Recreate all asynchronous KPIs after explicit refreshes.
    if (_stockMetricRevision == 0) {
      _stockMetricRevision = 1;
    } else if (mounted) {
      setState(() => _stockMetricRevision++);
    } else {
      _stockMetricRevision++;
    }
    DatabaseCounters.invalidateCache();
    try {
      final hasInternet = await InternetConnection().hasInternetAccess;
      if (mounted) setState(() => _hasInternet = hasInternet);
    } catch (_) {
      if (mounted) setState(() => _hasInternet = null);
    }
    await Future.wait([
      _partsProvider.downloadAllParts(),
      _partsProvider.downloadAllCategories(),
      _partsProvider.downloadAllBrands(),
      _partsProvider.downloadAllOptions(),
      _partsProvider.downloadAllFournisseurs(),
    ]);
  }

  @override
  void dispose() {
    DatabaseGetter.companyRevisionListenable.removeListener(
      _companyRevisionListener,
    );
    _partsProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return AnimatedBuilder(
      animation: _partsProvider,
      builder: (context, _) {
        final isLoading =
            PartsProvider.downloadingParts ||
            PartsProvider.downloadingCategories ||
            PartsProvider.downloadingBrands ||
            PartsProvider.downloadingOptions ||
            PartsProvider.downloadingFournisseurs;
        final hasError = PartsProvider.refreshErrors.isNotEmpty;

        return ScaffoldPage(
          padding: EdgeInsets.zero,
          content: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < ParcotoTokens.tabletBreakpoint;
              final columns = constraints.maxWidth >= 1250
                  ? 4
                  : constraints.maxWidth >= 850
                  ? 3
                  : constraints.maxWidth >= 540
                  ? 2
                  : 1;
              final metricWidth =
                  (constraints.maxWidth - 12.0 * (columns - 1)) / columns;
              return ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? ParcotoTokens.space4 : ParcotoTokens.space8,
                  vertical: ParcotoTokens.space6,
                ),
                children: [
                  ModuleDashboardHeader(
                    title: 'Atelier',
                    subtitle: 'Vue opérationnelle du catalogue et de l’inventaire',
                    eyebrow: 'ParcOto / Workshop',
                    heroTitle: 'Centre de contrôle de l’atelier',
                    heroDescription:
                        'Accédez aux pièces, aux références et aux partenaires de votre chaîne d’approvisionnement.',
                    icon: FluentIcons.repair,
                    trailing: Tooltip(
                      message: 'Actualiser les données',
                      child: IconButton(
                        icon: const Icon(FluentIcons.refresh),
                        onPressed: isLoading ? null : _refreshCatalog,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'État du catalogue',
                    style: TextStyle(
                      color: theme.writingStyle.color,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: ParcotoTokens.space3,
                    crossAxisSpacing: ParcotoTokens.space3,
                    childAspectRatio: compact ? 2.7 : 2.5,
                    children: [
                      ModuleDashboardMetric(
                        key: ValueKey('workshop-parts-$_stockMetricRevision'),
                        width: metricWidth,
                        label: 'Pièces référencées',
                        detail: 'Catalogue de l’entreprise',
                        icon: FluentIcons.list,
                        loadValue: () => DatabaseCounters().countParts(),
                      ),
                      ModuleDashboardMetric(
                        key: ValueKey('workshop-categories-$_stockMetricRevision'),
                        width: metricWidth,
                        label: 'Catégories',
                        detail: 'Catégories de pièces',
                        icon: FluentIcons.category_classification,
                        loadValue: () => DatabaseCounters().countCategories(),
                      ),
                      ModuleDashboardMetric(
                        key: ValueKey('workshop-brands-$_stockMetricRevision'),
                        width: metricWidth,
                        label: 'Marques',
                        detail: 'Marques référencées',
                        icon: FluentIcons.verified_brand,
                        loadValue: () => DatabaseCounters().countBrands(),
                      ),
                      ModuleDashboardMetric(
                        key: ValueKey('workshop-suppliers-$_stockMetricRevision'),
                        width: metricWidth,
                        label: 'Fournisseurs',
                        detail: 'Partenaires d’approvisionnement',
                        icon: FluentIcons.people,
                        loadValue: () => DatabaseCounters().countSuppliers(),
                      ),
                      ModuleDashboardMetric(
                        key: ValueKey('workshop-stock-$_stockMetricRevision'),
                        width: metricWidth,
                        label: 'Entrées de stock',
                        detail: 'Enregistrements de stock de l’entreprise',
                        icon: FluentIcons.database,
                        loadValue: _loadStockCount,
                      ),
                    ],
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 14),
                    const ProgressBar(),
                    const SizedBox(height: 6),
                    Text(
                      'Synchronisation du catalogue…',
                      style: TextStyle(color: Colors.grey[100], fontSize: 12),
                    ),
                  ] else if (hasError) ...[
                    const SizedBox(height: 14),
                    InfoBar(
                      title: Text(
                        _hasInternet == false
                            ? 'Connexion Internet indisponible'
                            : 'Échec de synchronisation avec Appwrite',
                      ),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Les données locales sont conservées. Le détail des chargements en échec :',
                          ),
                          const SizedBox(height: 6),
                          ...PartsProvider.refreshErrors.entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                '${entry.key} : ${entry.value}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      severity: InfoBarSeverity.warning,
                    ),
                  ],
                  const SizedBox(height: 26),
                  Text(
                    'Accès rapides',
                    style: TextStyle(
                      color: theme.writingStyle.color,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ModuleDashboardAction(
                        label: 'Gestion des pièces',
                        detail: 'Catalogue et références',
                        icon: FluentIcons.list,
                        onPressed: () =>
                            PaneItemsAndFooters.selectPane('workshop-parts'),
                      ),
                      ModuleDashboardAction(
                        label: 'Stock',
                        detail: 'Quantités et emplacements',
                        icon: FluentIcons.database,
                        onPressed: () =>
                            PaneItemsAndFooters.selectPane('workshop-stock'),
                      ),
                      ModuleDashboardAction(
                        label: 'Fournisseurs',
                        detail: 'Partenaires et approvisionnement',
                        icon: FluentIcons.people,
                        onPressed: () => PaneItemsAndFooters.selectPane(
                          'workshop-suppliers',
                        ),
                      ),
                      ModuleDashboardAction(
                        label: 'Marques',
                        detail: 'Référentiels fabricants',
                        icon: FluentIcons.verified_brand,
                        onPressed: () =>
                            PaneItemsAndFooters.selectPane('workshop-brands'),
                      ),
                      ModuleDashboardAction(
                        label: 'Catégories',
                        detail: 'Organisation du catalogue',
                        icon: FluentIcons.category_classification,
                        onPressed: () => PaneItemsAndFooters.selectPane(
                          'workshop-categories',
                        ),
                      ),
                      ModuleDashboardAction(
                        label: 'Options',
                        detail: 'Variantes et caractéristiques',
                        icon: FluentIcons.settings,
                        onPressed: () =>
                            PaneItemsAndFooters.selectPane('workshop-options'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

