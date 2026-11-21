import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../core/services/vehicle_make_service.dart';
import '../../../providers/client_database.dart';
import '../../../theme.dart';
import '../../../widgets/forms/parcoto_form_field.dart';
import '../../../widgets/page_header.dart';
import 'brand_container.dart';

class BrandList extends StatefulWidget {
  const BrandList({super.key});

  @override
  State<BrandList> createState() => _BrandListState();
}

class _BrandListState extends State<BrandList> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _loading = true;
  bool _adding = false;
  String? _error;

  bool get _canAddMake =>
      DatabaseGetter().isAdmin() || DatabaseGetter.user?.$id == '999';

  @override
  void initState() {
    super.initState();
    _loadMakes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMakes({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await VehicleMakeService.load(forceRefresh: forceRefresh);
    } catch (error) {
      _error = error.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addMake() async {
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _AddVehicleMakeDialog(),
    );
    if (values == null || !mounted) return;

    final isPlatformSuperAdmin = DatabaseGetter.user?.$id == '999';
    final companyId = DatabaseGetter.activeCompanyId ?? '';
    if (!isPlatformSuperAdmin && companyId.isEmpty) {
      displayInfoBar(
        context,
        builder: (context, close) => const InfoBar(
          title: Text('Aucune entreprise active.'),
          severity: InfoBarSeverity.error,
        ),
        duration: const Duration(seconds: 4),
      );
      return;
    }

    setState(() => _adding = true);
    try {
      await VehicleMakeService.create(
        companyId: companyId,
        name: values['name']!,
        category: values['category']!,
      );
      await _loadMakes(forceRefresh: true);
      if (!mounted) return;
      displayInfoBar(
        context,
        builder: (context, close) => const InfoBar(
          title: Text('Marque ajoutée au catalogue partagé.'),
          content: Text('Elle est maintenant disponible pour toutes les entreprises Parcoto.'),
          severity: InfoBarSeverity.success,
        ),
        duration: const Duration(seconds: 4),
      );
    } catch (error) {
      if (!mounted) return;
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Impossible d’ajouter cette marque.'),
          content: Text(error.toString()),
          severity: InfoBarSeverity.error,
        ),
        duration: const Duration(seconds: 5),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final makes = VehicleMakeService.search(_query);

    return ScaffoldPage(
      header: PageTitle(text: 'brandlist'.tr()),
      content: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final search = SizedBox(
                  width: compact ? constraints.maxWidth : 360,
                  height: 44,
                  child: ParcotoTextBox(
                    controller: _searchController,
                    placeholder: 'Rechercher une marque ou un alias…',
                    style: theme.writingStyle,
                    placeholderStyle: placeStyle,
                    cursorColor: theme.color,
                    onChanged: (value) => setState(() => _query = value),
                    suffix: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(FluentIcons.cancel, size: 13),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                );
                final actions = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Button(
                      onPressed: _loading ? null : () => _loadMakes(forceRefresh: true),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.refresh, size: 13),
                          SizedBox(width: 7),
                          Text('Actualiser'),
                        ],
                      ),
                    ),
                    if (_canAddMake)
                      FilledButton(
                        onPressed: _adding ? null : _addMake,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_adding)
                              const ProgressRing(strokeWidth: 2)
                            else
                              const Icon(FluentIcons.add, size: 13),
                            const SizedBox(width: 7),
                            const Text('Ajouter une marque'),
                          ],
                        ),
                      ),
                  ],
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      search,
                      const SizedBox(height: 10),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: actions,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    search,
                    const Spacer(),
                    actions,
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  _loading ? 'Chargement du catalogue…' : '${makes.length} marque(s)',
                  style: TextStyle(
                    color: theme.mutedTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Catalogue mondial partagé',
                  style: TextStyle(
                    color: theme.mutedTextColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading && VehicleMakeService.cached.isEmpty
                  ? const Center(child: ProgressRing())
                  : _error != null && VehicleMakeService.cached.isEmpty
                      ? Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(FluentIcons.warning, size: 28),
                                const SizedBox(height: 10),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Button(
                                  onPressed: () => _loadMakes(forceRefresh: true),
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : makes.isEmpty
                          ? const Center(child: Text('Aucune marque ne correspond à la recherche.'))
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final crossAxisCount = constraints.maxWidth < 540
                                    ? 2
                                    : constraints.maxWidth < 900
                                        ? 3
                                        : constraints.maxWidth < 1250
                                            ? 4
                                            : 5;
                                return GridView.builder(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 1.2,
                                  ),
                                  itemCount: makes.length,
                                  itemBuilder: (context, index) =>
                                      BrandContainer(
                                    key: ValueKey(makes[index].id),
                                    make: makes[index],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddVehicleMakeDialog extends StatefulWidget {
  const _AddVehicleMakeDialog();

  @override
  State<_AddVehicleMakeDialog> createState() => _AddVehicleMakeDialogState();
}

class _AddVehicleMakeDialogState extends State<_AddVehicleMakeDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _category = 'passenger';

  static const categories = <String, String>{
    'passenger': 'Voiture particulière',
    'commercial': 'Utilitaire / poids lourd',
    'bus': 'Autobus / autocar',
    'motorcycle': 'Moto / scooter',
    'agricultural': 'Matériel agricole',
    'construction': 'Engin de chantier',
    'industrial': 'Matériel industriel',
    'other': 'Autre',
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('Ajouter une marque au catalogue mondial'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cette marque deviendra visible dans toutes les entreprises Parcoto.',
            ),
            const SizedBox(height: 14),
            TextBox(
              controller: _nameController,
              placeholder: 'Nom officiel de la marque',
              maxLength: 100,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            ComboBox<String>(
              isExpanded: true,
              value: _category,
              items: categories.entries
                  .map(
                    (entry) => ComboBoxItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _nameController.text.trim().length < 2
              ? null
              : () => Navigator.of(context).pop({
                    'name': _nameController.text.trim(),
                    'category': _category,
                  }),
          child: const Text('Ajouter au catalogue'),
        ),
      ],
    );
  }
}
