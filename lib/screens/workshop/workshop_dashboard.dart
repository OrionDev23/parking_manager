import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/parts_provider.dart';
import '../../theme.dart';
import '../../widgets/module_dashboard_header.dart';
import '../sidemenu/pane_items.dart';

class WorkshopDashboard extends StatefulWidget {
  const WorkshopDashboard({super.key});

  @override
  State<WorkshopDashboard> createState() => _WorkshopDashboardState();
}

class _WorkshopDashboardState extends State<WorkshopDashboard> {
  late final PartsProvider _partsProvider;

  @override
  void initState() {
    super.initState();
    _partsProvider = PartsProvider();
    _refreshCatalog();
  }

  Future<void> _refreshCatalog() async {
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
        final hasError =
            PartsProvider.errorParts ||
            PartsProvider.errorCategories ||
            PartsProvider.errorBrands ||
            PartsProvider.errorOptions ||
            PartsProvider.errorFournisseurs;

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
                      title: const Text('Certaines données sont indisponibles'),
                      content: const Text(
                        'Les éléments déjà présents localement restent affichés. Vérifiez la connexion puis actualisez.',
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
                      _WorkshopAction(
                        label: 'Gestion des pièces',
                        detail: 'Catalogue et références',
                        icon: FluentIcons.list,
                        onPressed: () =>
                            PaneItemsAndFooters.selectPane('workshop-parts'),
                      ),
                      _WorkshopAction(
                        label: 'Stock',
                        detail: 'Quantités et emplacements',
                        icon: FluentIcons.database,
                        onPressed: () =>
                            PaneItemsAndFooters.selectPane('workshop-stock'),
                      ),
                      _WorkshopAction(
                        label: 'Fournisseurs',
                        detail: 'Partenaires et approvisionnement',
                        icon: FluentIcons.people,
                        onPressed: () => PaneItemsAndFooters.selectPane(
                          'workshop-suppliers',
                        ),
                      ),
                      _WorkshopAction(
                        label: 'Marques',
                        detail: 'Référentiels fabricants',
                        icon: FluentIcons.verified_brand,
                        onPressed: () =>
                            PaneItemsAndFooters.selectPane('workshop-brands'),
                      ),
                      _WorkshopAction(
                        label: 'Catégories',
                        detail: 'Organisation du catalogue',
                        icon: FluentIcons.category_classification,
                        onPressed: () => PaneItemsAndFooters.selectPane(
                          'workshop-categories',
                        ),
                      ),
                      _WorkshopAction(
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

class _WorkshopAction extends StatelessWidget {
  final String label;
  final String detail;
  final IconData icon;
  final VoidCallback onPressed;

  const _WorkshopAction({
    required this.label,
    required this.detail,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      width: 245,
      child: Button(
        onPressed: onPressed,
        style: ButtonStyle(
          padding: WidgetStatePropertyAll(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: TextStyle(color: Colors.grey[100], fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(FluentIcons.chevron_right, size: 12),
          ],
        ),
      ),
    );
  }
}
