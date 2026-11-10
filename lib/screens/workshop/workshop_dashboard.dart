import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../providers/parts_provider.dart';
import '../../theme.dart';
import '../../widgets/module_dashboard_header.dart';
import '../../widgets/module_dashboard_action.dart';
import '../sidemenu/pane_items.dart';

class WorkshopDashboard extends StatefulWidget {
  const WorkshopDashboard({super.key});

  @override
  State<WorkshopDashboard> createState() => _WorkshopDashboardState();
}

class _WorkshopDashboardState extends State<WorkshopDashboard> {
  late final PartsProvider _partsProvider;
  bool? _hasInternet;

  @override
  void initState() {
    super.initState();
    _partsProvider = PartsProvider();
    _refreshCatalog();
  }

  Future<void> _refreshCatalog() async {
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
              final compact = constraints.maxWidth < 760;
              final columns = constraints.maxWidth >= 1250
                  ? 4
                  : constraints.maxWidth >= 850
                  ? 3
                  : constraints.maxWidth >= 540
                  ? 2
                  : 1;
              return ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 16 : 28,
                  vertical: 24,
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
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: compact ? 2.7 : 2.5,
                    children: [
                      _WorkshopMetric(
                        label: 'Pièces référencées',
                        value: PartsProvider.parts.length,
                        icon: FluentIcons.list,
                        accent: theme.color,
                      ),
                      _WorkshopMetric(
                        label: 'Catégories',
                        value: PartsProvider.categories.length,
                        icon: FluentIcons.category_classification,
                        accent: theme.color,
                      ),
                      _WorkshopMetric(
                        label: 'Marques',
                        value: PartsProvider.brands.length,
                        icon: FluentIcons.verified_brand,
                        accent: theme.color,
                      ),
                      _WorkshopMetric(
                        label: 'Fournisseurs',
                        value: PartsProvider.fournisseurs.length,
                        icon: FluentIcons.people,
                        accent: theme.color,
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

class _WorkshopMetric extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color accent;

  const _WorkshopMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backGroundColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: theme.writingStyle.color!.withValues(alpha: .10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    color: theme.writingStyle.color,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[100], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

