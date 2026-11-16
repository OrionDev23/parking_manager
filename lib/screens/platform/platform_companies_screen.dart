import 'package:fluent_ui/fluent_ui.dart';

import '../../core/tenancy/platform_companies_repository.dart';
import '../../main.dart';
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
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 12),
            child: ModuleDashboardHeader(
              title: 'Plateforme Parcoto',
              subtitle: 'Provisionnement et suivi commercial des entreprises clientes.',
              eyebrow: 'Parcoto / Platform administration',
              heroTitle: 'Gestion des entreprises',
              heroDescription:
                  'Créez les entreprises, provisionnez leur premier administrateur et définissez les limites contractuelles de chaque licence.',
              icon: FluentIcons.cloud,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                Expanded(child: _MetricCard(label: 'Entreprises', value: _companies.length.toString(), icon: FluentIcons.company_directory)),
                const SizedBox(width: 10),
                Expanded(child: _MetricCard(label: 'Actives', value: active.toString(), icon: FluentIcons.check_mark)),
                const SizedBox(width: 10),
                Expanded(child: _MetricCard(label: 'Licences expirées', value: expired.toString(), icon: FluentIcons.warning)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextBox(
                    controller: _search,
                    placeholder: 'Rechercher une entreprise...',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
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
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 4, 28, 20),
              child: _loading
                  ? const Center(child: ProgressRing())
                  : _error != null
                      ? _ErrorPanel(message: _error!, onRetry: _load)
                      : _visibleCompanies.isEmpty
                          ? const Center(child: Text('Aucune entreprise trouvée.'))
                          : ListView.separated(
                              itemCount: _visibleCompanies.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) => _CompanyCard(company: _visibleCompanies[index]),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Icon(icon, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: FluentTheme.of(context).typography.titleLarge),
          Text(label, style: FluentTheme.of(context).typography.caption),
        ])),
      ]),
    ),
  );
}

class _CompanyCard extends StatelessWidget {
  final PlatformCompany company;
  const _CompanyCard({required this.company});

  @override
  Widget build(BuildContext context) {
    final expiry = company.expiresAt;
    final expired = expiry != null && expiry.isBefore(DateTime.now());
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
                expired ? FluentIcons.warning : FluentIcons.check_mark,
                size: 14,
                color: expired ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 6),
              Text(expired ? 'Licence expirée' : company.status),
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
            _QuotaText(label: 'Tarif', value: '${company.monthlyPrice} ${company.currency} / ${entitlement['billingCycle'] ?? '—'}'),
          ]),
          if ((entitlement['notes']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(entitlement['notes'].toString()),
          ],
        ]),
      ),
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
  final _startsAt = TextEditingController(text: DateTime.now().toUtc().toIso8601String());
  final _expiresAt = TextEditingController(text: DateTime.now().toUtc().add(const Duration(days: 365)).toIso8601String());
  final _maxUsers = TextEditingController(text: '5');
  final _maxVehicles = TextEditingController(text: '50');
  final _maxEmployees = TextEditingController(text: '20');
  final _maxDrivers = TextEditingController(text: '20');
  final _maxSites = TextEditingController(text: '1');
  final _monthlyPrice = TextEditingController(text: '0');
  final _notes = TextEditingController();
  final _billingCycle = TextEditingController(text: 'monthly');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, _slug, _adminName, _adminEmail, _adminPassword, _startsAt, _expiresAt, _maxUsers, _maxVehicles, _maxEmployees, _maxDrivers, _maxSites, _monthlyPrice, _notes, _billingCycle]) {
      controller.dispose();
    }
    super.dispose();
  }

  int _number(TextEditingController controller) => int.tryParse(controller.text.trim()) ?? -1;

  Future<void> _submit() async {
    setState(() { _saving = true; _error = null; });
    try {
      final starts = DateTime.parse(_startsAt.text.trim());
      final expires = DateTime.parse(_expiresAt.text.trim());
      await widget.repository.create(
        name: _name.text.trim(),
        slug: _slug.text.trim(),
        adminName: _adminName.text.trim(),
        adminEmail: _adminEmail.text.trim(),
        adminPassword: _adminPassword.text,
        startsAt: starts,
        expiresAt: expires,
        maxUsers: _number(_maxUsers),
        maxVehicles: _number(_maxVehicles),
        maxEmployees: _number(_maxEmployees),
        maxDrivers: _number(_maxDrivers),
        maxSites: _number(_maxSites),
        monthlyPrice: _number(_monthlyPrice),
        billingCycle: _billingCycle.text.trim(),
        currency: 'DZD',
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

  Widget _field(String label, TextEditingController controller, {bool password = false, bool numeric = false, String? placeholder}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label),
        const SizedBox(height: 4),
        TextBox(controller: controller, obscureText: password, keyboardType: numeric ? TextInputType.number : TextInputType.text, placeholder: placeholder),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => ContentDialog(
    title: const Text('Créer une entreprise cliente'),
    constraints: const BoxConstraints(maxWidth: 760, maxHeight: 820),
    content: SizedBox(
      width: 700,
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Identité de l’entreprise', style: FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 8),
          _field('Nom commercial / raison sociale', _name),
          _field('Identifiant (slug)', _slug, placeholder: 'Ex. societe-annaba'),
          const Divider(),
          Text('Premier administrateur de l’entreprise', style: FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 8),
          _field('Nom complet', _adminName),
          _field('Adresse email', _adminEmail),
          _field('Mot de passe initial (8 caractères minimum)', _adminPassword, password: true),
          const Divider(),
          Text('Licence et contrat', style: FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 8),
          _field('Début (ISO 8601)', _startsAt, placeholder: '2026-11-16T00:00:00Z'),
          _field('Expiration (ISO 8601)', _expiresAt, placeholder: '2027-11-16T00:00:00Z'),
          Row(children: [
            Expanded(child: _field('Cycle de facturation (monthly / quarterly / yearly / custom)', _billingCycle)),
            const SizedBox(width: 10),
            Expanded(child: _field('Tarif par période (DA)', _monthlyPrice, numeric: true)),
          ]),
          const Divider(),
          Text('Quotas contractuels', style: FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _field('Utilisateurs', _maxUsers, numeric: true)),
            const SizedBox(width: 10),
            Expanded(child: _field('Véhicules', _maxVehicles, numeric: true)),
          ]),
          Row(children: [
            Expanded(child: _field('Employés', _maxEmployees, numeric: true)),
            const SizedBox(width: 10),
            Expanded(child: _field('Chauffeurs', _maxDrivers, numeric: true)),
            const SizedBox(width: 10),
            Expanded(child: _field('Sites', _maxSites, numeric: true)),
          ]),
          _field('Notes commerciales / conditions', _notes),
          if (_error != null) InfoBar(title: Text(_error!), severity: InfoBarSeverity.error),
        ]),
      ),
    ),
    actions: [
      Button(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Annuler')),
      FilledButton(onPressed: _saving ? null : _submit, child: _saving ? const ProgressRing() : const Text('Créer l’entreprise')),
    ],
  );
}
