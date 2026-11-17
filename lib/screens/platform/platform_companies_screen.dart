import 'package:fluent_ui/fluent_ui.dart';

import '../../main.dart';

import '../../core/tenancy/platform_companies_repository.dart';
import '../../widgets/module_dashboard_header.dart';

class PlatformCompaniesScreen extends StatefulWidget {
  const PlatformCompaniesScreen({super.key});

  @override
  State<PlatformCompaniesScreen> createState() =>
      _PlatformCompaniesScreenState();
}

class _PlatformCompaniesScreenState extends State<PlatformCompaniesScreen> {
  final _repository = PlatformCompaniesRepository();
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<PlatformCompany> _companies = [];
  String? _preparingCompanyId;
  String? _openingCompanyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repository.list();
      if (!mounted) return;
      setState(() {
        _companies = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Bad state: ', '');
        _loading = false;
      });
    }
  }

  List<PlatformCompany> get _visibleCompanies {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _companies;
    return _companies.where((company) =>
      company.name.toLowerCase().contains(query) ||
      company.slug.toLowerCase().contains(query) ||
      company.companyId.toLowerCase().contains(query)
    ).toList(growable: false);
  }

  Future<void> _openCompany(PlatformCompany company) async {
    setState(() => _openingCompanyId = company.companyId);
    try {
      await authService.enterPlatformCompany(company.companyId);
      await startBackgroundInitialization(company.companyId);
    } catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('Impossible d’ouvrir l’entreprise'),
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _openingCompanyId = null);
    }
  }

  Future<void> _editCompany(PlatformCompany company) async {
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EditCompanyDialog(
        company: company,
        repository: _repository,
      ),
    );
    if (updated == true) await _load();
  }

  Future<void> _manageAdministrators(PlatformCompany company) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _CompanyAdministratorsDialog(
        company: company,
        repository: _repository,
      ),
    );
  }

  Future<void> _prepareCompanyPermissions(PlatformCompany company) async {
    setState(() => _preparingCompanyId = company.companyId);
    try {
      final result = await _repository.preparePermissions(company.companyId);
      if (!mounted) return;
      final count = (result['totalUpdated'] as num?)?.toInt() ?? 0;
      await showDialog<void>(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('Permissions de lignes préparées'),
          content: Text(
            '$count lignes de ' + company.name + ' disposent maintenant de permissions liées à son équipe Appwrite. '
            'Les permissions globales des tables restent actives : aucune isolation complète n’a encore été appliquée.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('Échec de la préparation'),
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _preparingCompanyId = null);
    }
  }

  Future<void> _openCreateDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CreateCompanyDialog(repository: _repository),
    );
    if (result == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final active = _companies.where((item) => item.status == 'active').length;
    final expired = _companies.where((item) {
      final date = item.expiresAt;
      return date != null && date.isBefore(DateTime.now());
    }).length;

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final horizontalPadding = compact ? 16.0 : 28.0;
          final visibleCompanies = _visibleCompanies;

          final header = Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              compact ? 16 : 22,
              horizontalPadding,
              12,
            ),
            child: ModuleDashboardHeader(
              title: 'Plateforme Parcoto',
              subtitle: 'Provisionnement et suivi commercial des entreprises clientes.',
              eyebrow: 'Parcoto / Platform administration',
              heroTitle: 'Gestion des entreprises',
              heroDescription:
                  'Créez les entreprises, provisionnez leur premier administrateur et définissez les limites contractuelles de chaque licence.',
              icon: FluentIcons.cloud,
            ),
          );

          final metrics = Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: compact
                ? Column(
                    children: [
                      _MetricCard(
                        label: 'Entreprises',
                        value: _companies.length.toString(),
                        icon: FluentIcons.company_directory,
                        compact: true,
                      ),
                      const SizedBox(height: 8),
                      _MetricCard(
                        label: 'Actives',
                        value: active.toString(),
                        icon: FluentIcons.check_mark,
                        compact: true,
                      ),
                      const SizedBox(height: 8),
                      _MetricCard(
                        label: 'Licences expirées',
                        value: expired.toString(),
                        icon: FluentIcons.warning,
                        compact: true,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _MetricCard(label: 'Entreprises', value: _companies.length.toString(), icon: FluentIcons.company_directory)),
                      const SizedBox(width: 10),
                      Expanded(child: _MetricCard(label: 'Actives', value: active.toString(), icon: FluentIcons.check_mark)),
                      const SizedBox(width: 10),
                      Expanded(child: _MetricCard(label: 'Licences expirées', value: expired.toString(), icon: FluentIcons.warning)),
                    ],
                  ),
          );

          final search = TextBox(
            controller: _search,
            placeholder: 'Rechercher une entreprise...',
            onChanged: (_) => setState(() {}),
          );
          final actions = Row(
            children: [
              Expanded(
                child: Button(
                  onPressed: _loading ? null : _load,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.refresh),
                      SizedBox(width: 8),
                      Text('Actualiser'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _openCreateDialog,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.add),
                      SizedBox(width: 8),
                      Flexible(child: Text('Nouvelle entreprise', overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),
            ],
          );

          final controls = Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 10),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      search,
                      const SizedBox(height: 10),
                      actions,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: search),
                      const SizedBox(width: 10),
                      Button(
                        onPressed: _loading ? null : _load,
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(FluentIcons.refresh), SizedBox(width: 8), Text('Actualiser'),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _openCreateDialog,
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(FluentIcons.add), SizedBox(width: 8), Text('Nouvelle entreprise'),
                        ]),
                      ),
                    ],
                  ),
          );

          Widget companyResults({bool shrinkWrap = false}) {
            if (_loading) {
              return const Center(child: Padding(
              padding: EdgeInsets.all(28),
              child: ProgressRing(),
            ));
            }
            if (_error != null) return _ErrorPanel(message: _error!, onRetry: _load);
            if (visibleCompanies.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Aucune entreprise trouvée.')),
              );
            }
            if (shrinkWrap) {
              return Column(
                children: [
                  for (var index = 0; index < visibleCompanies.length; index++) ...[
                    if (index > 0) const SizedBox(height: 8),
                    _CompanyCard(
                      company: visibleCompanies[index],
                      onPrepare: _preparingCompanyId == visibleCompanies[index].companyId
                          ? null
                          : () => _prepareCompanyPermissions(visibleCompanies[index]),
                      onOpen: _openingCompanyId == visibleCompanies[index].companyId
                          ? null
                          : () => _openCompany(visibleCompanies[index]),
                      onManageAdministrators: () => _manageAdministrators(visibleCompanies[index]),
                      onEdit: () => _editCompany(visibleCompanies[index]),
                      opening: _openingCompanyId == visibleCompanies[index].companyId,
                    ),
                  ],
                ],
              );
            }
            return ListView.separated(
              itemCount: visibleCompanies.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _CompanyCard(
                company: visibleCompanies[index],
                onOpen: _openingCompanyId == visibleCompanies[index].companyId
                    ? null
                    : () => _openCompany(visibleCompanies[index]),
                onManageAdministrators: () => _manageAdministrators(visibleCompanies[index]),
                onEdit: () => _editCompany(visibleCompanies[index]),
                opening: _openingCompanyId == visibleCompanies[index].companyId,
                onPrepare: _preparingCompanyId == visibleCompanies[index].companyId
                    ? null
                    : () => _prepareCompanyPermissions(visibleCompanies[index]),
              ),
            );
          }

          if (compact) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  metrics,
                  controls,
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 0),
                    child: companyResults(shrinkWrap: true),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              header,
              metrics,
              controls,
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 20),
                  child: companyResults(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool compact;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: EdgeInsets.all(compact ? 13 : 14),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Text(value, style: FluentTheme.of(context).typography.titleLarge),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              softWrap: true,
              style: FluentTheme.of(context).typography.caption,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CompanyCard extends StatelessWidget {
  final PlatformCompany company;
  final VoidCallback? onPrepare;
  final VoidCallback? onOpen;
  final VoidCallback onManageAdministrators;
  final VoidCallback onEdit;
  final bool opening;
  const _CompanyCard({
    required this.company,
    required this.onPrepare,
    required this.onOpen,
    required this.onManageAdministrators,
    required this.onEdit,
    this.opening = false,
  });

  @override
  Widget build(BuildContext context) {
    final expiry = company.expiresAt;
    final expired = expiry != null && expiry.isBefore(DateTime.now());
    final suspended = company.status == 'suspended';
    final entitlement = company.entitlement;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(FluentIcons.company_directory, size: 24),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(company.name, style: FluentTheme.of(context).typography.subtitle),
              Text('${company.slug} • ${company.companyId}', style: FluentTheme.of(context).typography.caption),
            ])),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                expired || suspended
                    ? FluentIcons.warning
                    : FluentIcons.check_mark,
                size: 14,
                color: expired || suspended ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 6),
              Text(
                expired
                    ? 'Licence expirée'
                    : suspended
                        ? 'Suspendue'
                        : 'Active',
              ),
            ]),
          ]),
          const SizedBox(height: 14),
          Wrap(spacing: 18, runSpacing: 8, children: [
            _QuotaText(label: 'Utilisateurs', value: '${company.activeUsers}/${company.quota('maxUsers')}'),
            _QuotaText(label: 'Véhicules', value: company.quota('maxVehicles').toString()),
            _QuotaText(label: 'Employés', value: company.quota('maxEmployees').toString()),
            _QuotaText(label: 'Chauffeurs', value: company.quota('maxDrivers').toString()),
            _QuotaText(label: 'Sites', value: company.quota('maxSites').toString()),
            _QuotaText(label: 'Échéance', value: expiry == null ? 'Non configurée' : '${expiry.day.toString().padLeft(2, '0')}/${expiry.month.toString().padLeft(2, '0')}/${expiry.year}'),
            _QuotaText(label: 'Tarif', value: '${company.priceAmount} ${company.currency} / ${entitlement['billingCycle'] ?? '—'}'),
          ]),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                Button(
                  onPressed: onEdit,
                  child: const Text('Modifier'),
                ),
                Button(
                  onPressed: onManageAdministrators,
                  child: const Text('Administrateurs'),
                ),
                Button(
                  onPressed: onPrepare,
                  child: const Text('Préparer les droits de ligne'),
                ),
                FilledButton(
                  onPressed: onOpen,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (opening) const SizedBox(
                        width: 14,
                        height: 14,
                        child: ProgressRing(),
                      ) else const Icon(FluentIcons.open_in_new_window, size: 14),
                      const SizedBox(width: 8),
                      const Text('Ouvrir Parcoto'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if ((entitlement['notes']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(entitlement['notes'].toString()),
          ],
        ]),
      ),
    );
  }
}

class _EditCompanyDialog extends StatefulWidget {
  final PlatformCompany company;
  final PlatformCompaniesRepository repository;

  const _EditCompanyDialog({
    required this.company,
    required this.repository,
  });

  @override
  State<_EditCompanyDialog> createState() => _EditCompanyDialogState();
}

class _EditCompanyDialogState extends State<_EditCompanyDialog> {
  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _startsAt;
  late final TextEditingController _expiresAt;
  late final TextEditingController _maxUsers;
  late final TextEditingController _maxVehicles;
  late final TextEditingController _maxEmployees;
  late final TextEditingController _maxDrivers;
  late final TextEditingController _maxSites;
  late final TextEditingController _priceAmount;
  late final TextEditingController _notes;
  late String _status;
  late String _billingCycle;
  late String _currency;
  bool _saving = false;
  String? _error;

  String _dateValue(String? raw, DateTime fallback) {
    final parsed = DateTime.tryParse(raw ?? '');
    final value = parsed ?? fallback;
    return value.toIso8601String().substring(0, 10);
  }

  @override
  void initState() {
    super.initState();
    final company = widget.company;
    final entitlement = company.entitlement;
    final now = DateTime.now();
    _name = TextEditingController(text: company.name);
    _slug = TextEditingController(text: company.slug);
    _startsAt = TextEditingController(
      text: _dateValue(entitlement['startsAt']?.toString(), now),
    );
    _expiresAt = TextEditingController(
      text: _dateValue(
        entitlement['expiresAt']?.toString(),
        now.add(const Duration(days: 365)),
      ),
    );
    _maxUsers = TextEditingController(
      text: (company.quota('maxUsers') == 0 ? 5 : company.quota('maxUsers')).toString(),
    );
    _maxVehicles = TextEditingController(
      text: (company.quota('maxVehicles') == 0 ? 50 : company.quota('maxVehicles')).toString(),
    );
    _maxEmployees = TextEditingController(
      text: (company.quota('maxEmployees') == 0 ? 20 : company.quota('maxEmployees')).toString(),
    );
    _maxDrivers = TextEditingController(
      text: (company.quota('maxDrivers') == 0 ? 20 : company.quota('maxDrivers')).toString(),
    );
    _maxSites = TextEditingController(
      text: (company.quota('maxSites') == 0 ? 1 : company.quota('maxSites')).toString(),
    );
    _priceAmount = TextEditingController(text: company.priceAmount.toString());
    _notes = TextEditingController(text: entitlement['notes']?.toString() ?? '');
    _status = company.status == 'suspended' ? 'suspended' : 'active';
    final cycle = entitlement['billingCycle']?.toString() ?? 'monthly';
    _billingCycle = const ['monthly', 'quarterly', 'yearly', 'custom'].contains(cycle)
        ? cycle
        : 'monthly';
    _currency = company.currency;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _slug,
      _startsAt,
      _expiresAt,
      _maxUsers,
      _maxVehicles,
      _maxEmployees,
      _maxDrivers,
      _maxSites,
      _priceAmount,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  int? _integer(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  Widget _field(
    String label,
    TextEditingController controller, {
    bool numeric = false,
    String? placeholder,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          TextBox(
            controller: controller,
            placeholder: placeholder,
            keyboardType: numeric ? TextInputType.number : TextInputType.text,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final startsAt = DateTime.tryParse(_startsAt.text.trim());
    final expiresAt = DateTime.tryParse(_expiresAt.text.trim());
    final maxUsers = _integer(_maxUsers);
    final maxVehicles = _integer(_maxVehicles);
    final maxEmployees = _integer(_maxEmployees);
    final maxDrivers = _integer(_maxDrivers);
    final maxSites = _integer(_maxSites);
    final priceAmount = _integer(_priceAmount);
    if (startsAt == null || expiresAt == null || maxUsers == null ||
        maxVehicles == null || maxEmployees == null || maxDrivers == null ||
        maxSites == null || priceAmount == null) {
      setState(() => _error = 'Vérifiez les dates et les valeurs numériques.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.updateCompany(
        companyId: widget.company.companyId,
        name: _name.text.trim(),
        slug: _slug.text.trim(),
        status: _status,
        startsAt: startsAt,
        expiresAt: expiresAt,
        maxUsers: maxUsers,
        maxVehicles: maxVehicles,
        maxEmployees: maxEmployees,
        maxDrivers: maxDrivers,
        maxSites: maxSites,
        priceAmount: priceAmount,
        billingCycle: _billingCycle,
        currency: _currency,
        notes: _notes.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Bad state: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencies = <String>{'DZD', 'EUR', 'USD', _currency}.toList();
    return ContentDialog(
      title: const Text('Modifier l’entreprise et sa licence'),
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 820),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width < 760
            ? MediaQuery.sizeOf(context).width * 0.82
            : 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Identité de l’entreprise',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const SizedBox(height: 10),
              _field('Nom commercial', _name),
              _field('Identifiant unique', _slug),
              const Text('État du compte'),
              const SizedBox(height: 4),
              ComboBox<String>(
                value: _status,
                isExpanded: true,
                items: const [
                  ComboBoxItem(value: 'active', child: Text('Active')),
                  ComboBoxItem(value: 'suspended', child: Text('Suspendue')),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _status = value);
                      },
              ),
              const SizedBox(height: 18),
              Text(
                'Licence et quotas',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const SizedBox(height: 10),
              _field('Début de licence (AAAA-MM-JJ)', _startsAt),
              _field('Fin de licence (AAAA-MM-JJ)', _expiresAt),
              _field('Nombre maximal d’utilisateurs', _maxUsers, numeric: true),
              _field('Nombre maximal de véhicules', _maxVehicles, numeric: true),
              _field('Nombre maximal d’employés', _maxEmployees, numeric: true),
              _field('Nombre maximal de chauffeurs', _maxDrivers, numeric: true),
              _field('Nombre maximal de sites', _maxSites, numeric: true),
              _field('Tarif', _priceAmount, numeric: true),
              const Text('Périodicité'),
              const SizedBox(height: 4),
              ComboBox<String>(
                value: _billingCycle,
                isExpanded: true,
                items: const [
                  ComboBoxItem(value: 'monthly', child: Text('Mensuelle')),
                  ComboBoxItem(value: 'quarterly', child: Text('Trimestrielle')),
                  ComboBoxItem(value: 'yearly', child: Text('Annuelle')),
                  ComboBoxItem(value: 'custom', child: Text('Personnalisée')),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _billingCycle = value);
                      },
              ),
              const SizedBox(height: 10),
              const Text('Devise'),
              const SizedBox(height: 4),
              ComboBox<String>(
                value: _currency,
                isExpanded: true,
                items: currencies
                    .map((currency) => ComboBoxItem(
                          value: currency,
                          child: Text(currency),
                        ))
                    .toList(growable: false),
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _currency = value);
                      },
              ),
              const SizedBox(height: 10),
              const Text('Notes internes'),
              const SizedBox(height: 4),
              TextBox(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                placeholder: 'Informations contractuelles...',
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                InfoBar(
                  title: Text(_error!),
                  severity: InfoBarSeverity.error,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        Button(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving ? const ProgressRing() : const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _CompanyAdministratorsDialog extends StatefulWidget {
  final PlatformCompany company;
  final PlatformCompaniesRepository repository;

  const _CompanyAdministratorsDialog({
    required this.company,
    required this.repository,
  });

  @override
  State<_CompanyAdministratorsDialog> createState() =>
      _CompanyAdministratorsDialogState();
}

class _CompanyAdministratorsDialogState
    extends State<_CompanyAdministratorsDialog> {
  List<PlatformCompanyAdministrator> _administrators = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.listAdministrators(
        widget.company.companyId,
      );
      if (!mounted) return;
      setState(() {
        _administrators = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Bad state: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final added = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddCompanyAdministratorDialog(
        company: widget.company,
        repository: widget.repository,
      ),
    );
    if (added == true) await _load();
  }

  Future<void> _edit(PlatformCompanyAdministrator administrator) async {
    final controller = TextEditingController(text: administrator.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Modifier le nom de l’administrateur'),
        content: TextBox(
          controller: controller,
          placeholder: 'Nom complet',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.length < 2) return;
    try {
      await widget.repository.updateAdministratorName(
        companyId: widget.company.companyId,
        membershipId: administrator.membershipId,
        name: name,
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _revoke(PlatformCompanyAdministrator administrator) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Révoquer cet administrateur ?'),
        content: Text(
          'Le compte ${administrator.email} perdra son accès à ${widget.company.name}. '
          'Son compte Appwrite ne sera pas supprimé.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.revokeAdministrator(
        companyId: widget.company.companyId,
        membershipId: administrator.membershipId,
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _restore(PlatformCompanyAdministrator administrator) async {
    try {
      await widget.repository.addAdministrator(
        companyId: widget.company.companyId,
        name: administrator.name.isNotEmpty
            ? administrator.name
            : 'Administrateur',
        email: administrator.email,
        password: '',
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Widget _administratorTile(PlatformCompanyAdministrator administrator) {
    final active = administrator.status == 'active';
    final protected =
        administrator.isPlatformSuperAdmin || administrator.role == 'owner';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FluentTheme.of(context).accentColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                administrator.name.isNotEmpty
                    ? administrator.name.substring(0, 1).toUpperCase()
                    : '?',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    administrator.name.isEmpty
                        ? administrator.email
                        : administrator.name,
                    style: FluentTheme.of(context).typography.bodyStrong,
                  ),
                  Text(
                    administrator.email,
                    style: FluentTheme.of(context).typography.caption,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    children: [
                      Text(
                        active ? 'Actif' : 'Révoqué',
                        style: TextStyle(
                          color: active ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        administrator.isPlatformSuperAdmin
                            ? 'Super Admin plateforme'
                            : administrator.role,
                        style: FluentTheme.of(context).typography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (active)
              IconButton(
                icon: const Icon(FluentIcons.edit),
                onPressed: () => _edit(administrator),
              ),
            if (!active && !administrator.isPlatformSuperAdmin)
              IconButton(
                icon: const Icon(FluentIcons.refresh),
                onPressed: () => _restore(administrator),
              ),
            if (active && !protected)
              IconButton(
                icon: const Icon(FluentIcons.delete, color: Colors.red),
                onPressed: () => _revoke(administrator),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text('Administrateurs — ${widget.company.name}'),
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width < 800
            ? MediaQuery.sizeOf(context).width * 0.82
            : 660,
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_administrators.where((item) => item.status == 'active').length} administrateur(s) actif(s)',
                    style: FluentTheme.of(context).typography.caption,
                  ),
                ),
                Button(
                  onPressed: _loading ? null : _load,
                  child: const Icon(FluentIcons.refresh),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _add,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.add),
                      SizedBox(width: 6),
                      Text('Ajouter'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              InfoBar(
                title: Text(_error!),
                severity: InfoBarSeverity.error,
              ),
            Expanded(
              child: _loading
                  ? const Center(child: ProgressRing())
                  : _administrators.isEmpty
                      ? const Center(
                          child: Text('Aucun administrateur enregistré.'),
                        )
                      : ListView.separated(
                          itemCount: _administrators.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              _administratorTile(_administrators[index]),
                        ),
            ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

class _AddCompanyAdministratorDialog extends StatefulWidget {
  final PlatformCompany company;
  final PlatformCompaniesRepository repository;

  const _AddCompanyAdministratorDialog({
    required this.company,
    required this.repository,
  });

  @override
  State<_AddCompanyAdministratorDialog> createState() =>
      _AddCompanyAdministratorDialogState();
}

class _AddCompanyAdministratorDialogState
    extends State<_AddCompanyAdministratorDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.addAdministrator(
        companyId: widget.company.companyId,
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Bad state: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text('Ajouter un administrateur — ${widget.company.name}'),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width < 600
            ? MediaQuery.sizeOf(context).width * 0.82
            : 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nom complet'),
            const SizedBox(height: 4),
            TextBox(controller: _name, placeholder: 'Nom et prénom'),
            const SizedBox(height: 12),
            const Text('Adresse e-mail'),
            const SizedBox(height: 4),
            TextBox(
              controller: _email,
              placeholder: 'administrateur@entreprise.dz',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            const Text('Mot de passe initial'),
            const SizedBox(height: 4),
            TextBox(
              controller: _password,
              placeholder: 'Requis uniquement pour un nouveau compte',
              obscureText: true,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              InfoBar(
                title: Text(_error!),
                severity: InfoBarSeverity.error,
              ),
            ],
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const ProgressRing()
              : const Text('Créer / associer'),
        ),
      ],
    );
  }
}

class _QuotaText extends StatelessWidget {
  final String label;
  final String value;
  const _QuotaText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text('$label : ', style: FluentTheme.of(context).typography.caption),
    Text(value, style: FluentTheme.of(context).typography.bodyStrong),
  ]);
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(FluentIcons.error, size: 28),
      const SizedBox(height: 10),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
    ],
  ));
}

class _CreateCompanyDialog extends StatefulWidget {
  final PlatformCompaniesRepository repository;
  const _CreateCompanyDialog({required this.repository});

  @override
  State<_CreateCompanyDialog> createState() => _CreateCompanyDialogState();
}

class _CreateCompanyDialogState extends State<_CreateCompanyDialog> {
  final _name = TextEditingController();
  final _slug = TextEditingController();
  final _adminName = TextEditingController();
  final _adminEmail = TextEditingController();
  final _adminPassword = TextEditingController();
  final _startsAt = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  final _expiresAt = TextEditingController(
    text: DateTime.now().add(const Duration(days: 365)).toIso8601String().substring(0, 10),
  );
  final _maxUsers = TextEditingController(text: '5');
  final _maxVehicles = TextEditingController(text: '50');
  final _maxEmployees = TextEditingController(text: '20');
  final _maxDrivers = TextEditingController(text: '20');
  final _maxSites = TextEditingController(text: '1');
  final _priceAmount = TextEditingController(text: '0');
  final _notes = TextEditingController();
  String _billingCycle = 'monthly';
  String _currency = 'DZD';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _slug,
      _adminName,
      _adminEmail,
      _adminPassword,
      _startsAt,
      _expiresAt,
      _maxUsers,
      _maxVehicles,
      _maxEmployees,
      _maxDrivers,
      _maxSites,
      _priceAmount,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  int? _number(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  Widget _field(
    String label,
    TextEditingController controller, {
    bool password = false,
    bool numeric = false,
    String? placeholder,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 5),
          TextBox(
            controller: controller,
            obscureText: password,
            keyboardType: numeric ? TextInputType.number : TextInputType.text,
            placeholder: placeholder,
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String description, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: FluentTheme.of(context).typography.subtitle),
            const SizedBox(height: 4),
            Text(
              description,
              style: FluentTheme.of(context).typography.caption,
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final starts = DateTime.tryParse(_startsAt.text.trim());
    final expires = DateTime.tryParse(_expiresAt.text.trim());
    final maxUsers = _number(_maxUsers);
    final maxVehicles = _number(_maxVehicles);
    final maxEmployees = _number(_maxEmployees);
    final maxDrivers = _number(_maxDrivers);
    final maxSites = _number(_maxSites);
    final priceAmount = _number(_priceAmount);

    if (_name.text.trim().length < 2 ||
        _adminName.text.trim().length < 2 ||
        !_adminEmail.text.trim().contains('@') ||
        starts == null ||
        expires == null ||
        maxUsers == null ||
        maxVehicles == null ||
        maxEmployees == null ||
        maxDrivers == null ||
        maxSites == null ||
        priceAmount == null) {
      setState(() {
        _error = 'Complétez les informations obligatoires et vérifiez les dates et quotas.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.create(
        name: _name.text.trim(),
        slug: _slug.text.trim(),
        adminName: _adminName.text.trim(),
        adminEmail: _adminEmail.text.trim(),
        adminPassword: _adminPassword.text,
        startsAt: starts,
        expiresAt: expires,
        maxUsers: maxUsers,
        maxVehicles: maxVehicles,
        maxEmployees: maxEmployees,
        maxDrivers: maxDrivers,
        maxSites: maxSites,
        priceAmount: priceAmount,
        billingCycle: _billingCycle,
        currency: _currency,
        notes: _notes.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Bad state: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    return ContentDialog(
      title: const Text('Créer une entreprise cliente'),
      constraints: const BoxConstraints(maxWidth: 820, maxHeight: 860),
      content: SizedBox(
        width: compact ? MediaQuery.sizeOf(context).width * 0.84 : 740,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _section(
                'Identité de l’entreprise',
                'Informations qui identifieront l’espace client dans Parcoto.',
                [
                  _field(
                    'Raison sociale / nom commercial',
                    _name,
                    placeholder: 'Ex. GTS Guelma Truck Service',
                  ),
                  _field(
                    'Identifiant de l’entreprise',
                    _slug,
                    placeholder: 'Laisser vide pour le générer automatiquement',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _section(
                'Administrateur principal',
                'Un véritable compte Appwrite Auth sera créé si cette adresse n’existe pas déjà. Sinon, le compte existant sera associé.',
                [
                  _field('Nom complet', _adminName),
                  _field(
                    'Adresse e-mail',
                    _adminEmail,
                    placeholder: 'admin@entreprise.dz',
                  ),
                  _field(
                    'Mot de passe initial',
                    _adminPassword,
                    password: true,
                    placeholder: 'Obligatoire uniquement pour un nouveau compte',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _section(
                'Licence et facturation',
                'La période et les limites sont enregistrées dans les droits contractuels de l’entreprise.',
                [
                  _field(
                    'Début de licence (AAAA-MM-JJ)',
                    _startsAt,
                    placeholder: '2026-11-17',
                  ),
                  _field(
                    'Expiration (AAAA-MM-JJ)',
                    _expiresAt,
                    placeholder: '2027-11-17',
                  ),
                  const Text('Périodicité'),
                  const SizedBox(height: 5),
                  ComboBox<String>(
                    value: _billingCycle,
                    isExpanded: true,
                    items: const [
                      ComboBoxItem(value: 'monthly', child: Text('Mensuelle')),
                      ComboBoxItem(value: 'quarterly', child: Text('Trimestrielle')),
                      ComboBoxItem(value: 'yearly', child: Text('Annuelle')),
                      ComboBoxItem(value: 'custom', child: Text('Personnalisée')),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _billingCycle = value);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  const Text('Devise'),
                  const SizedBox(height: 5),
                  ComboBox<String>(
                    value: _currency,
                    isExpanded: true,
                    items: const [
                      ComboBoxItem(value: 'DZD', child: Text('DZD — Dinar algérien')),
                      ComboBoxItem(value: 'EUR', child: Text('EUR — Euro')),
                      ComboBoxItem(value: 'USD', child: Text('USD — Dollar américain')),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null) setState(() => _currency = value);
                          },
                  ),
                  const SizedBox(height: 12),
                  _field('Tarif par période', _priceAmount, numeric: true),
                ],
              ),
              const SizedBox(height: 12),
              _section(
                'Quotas contractuels',
                'Les limites sont appliquées par l’API métier lorsqu’elles sont prises en charge.',
                [
                  _field('Utilisateurs maximum', _maxUsers, numeric: true),
                  _field('Véhicules maximum', _maxVehicles, numeric: true),
                  _field('Employés maximum', _maxEmployees, numeric: true),
                  _field('Chauffeurs maximum', _maxDrivers, numeric: true),
                  _field('Sites maximum', _maxSites, numeric: true),
                ],
              ),
              const SizedBox(height: 12),
              _section(
                'Notes internes',
                'Informations commerciales ou conditions particulières.',
                [
                  TextBox(
                    controller: _notes,
                    minLines: 2,
                    maxLines: 4,
                    placeholder: 'Notes...',
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                InfoBar(
                  title: Text(_error!),
                  severity: InfoBarSeverity.error,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        Button(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving ? const ProgressRing() : const Text('Créer l’entreprise'),
        ),
      ],
    );
  }
}
