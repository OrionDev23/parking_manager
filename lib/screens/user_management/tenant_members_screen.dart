import 'package:fluent_ui/fluent_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/tenancy/tenant_members_repository.dart';

class TenantMembersScreen extends StatefulWidget {
  const TenantMembersScreen({super.key});

  @override
  State<TenantMembersScreen> createState() => _TenantMembersScreenState();
}

class _TenantMembersScreenState extends State<TenantMembersScreen> {
  final TenantMembersRepository repository = TenantMembersRepository();
  final TextEditingController searchController = TextEditingController();
  String? companyId;
  String? loadError;
  bool loading = true;
  List<TenantMember> members = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      loadError = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final resolvedCompanyId = prefs.getString('active_company_id') ??
          prefs.getString('project');
      if (resolvedCompanyId == null || resolvedCompanyId.isEmpty) {
        throw StateError('Aucune entreprise active n’est sélectionnée.');
      }
      final result = await repository.list(resolvedCompanyId);
      if (!mounted) return;
      setState(() {
        companyId = resolvedCompanyId;
        members = result;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loadError = error.toString().replaceFirst('Bad state: ', '');
        loading = false;
      });
    }
  }

  List<TenantMember> get visibleMembers {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) return members;
    return members.where((member) {
      return member.name.toLowerCase().contains(query) ||
          member.email.toLowerCase().contains(query) ||
          member.userId.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      header: PageHeader(
        title: const Text('Utilisateurs de l’entreprise'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('Ajouter un membre'),
              onPressed: loading || companyId == null ? null : _addMember,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Actualiser'),
              onPressed: loading ? null : _load,
            ),
          ],
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextBox(
            controller: searchController,
            placeholder: 'Rechercher par nom, email ou identifiant',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          if (loading)
            const Expanded(child: Center(child: ProgressRing()))
          else if (loadError != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(FluentIcons.error, size: 28),
                    const SizedBox(height: 10),
                    Text(loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          else if (visibleMembers.isEmpty)
            const Expanded(
              child: Center(child: Text('Aucun membre dans cette entreprise.')),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: visibleMembers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final member = visibleMembers[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(FluentIcons.contact, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name.isEmpty ? member.email : member.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  member.email,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'ID: ${member.userId} • ${member.role}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (member.role != 'owner')
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Button(
                                  child: const Text('Rôle'),
                                  onPressed: () => _changeRole(member),
                                ),
                                const SizedBox(height: 4),
                                Button(
                                  child: const Text('Retirer'),
                                  onPressed: () => _revoke(member),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addMember() async {
    final email = TextEditingController();
    String role = 'employee';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('Ajouter un membre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Le compte Parcoto doit déjà exister. Cette opération ne crée pas de compte Appwrite.',
            ),
            const SizedBox(height: 12),
            TextBox(
              controller: email,
              placeholder: 'Adresse email du compte',
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setDialogState) => ComboBox<String>(
                value: role,
                isExpanded: true,
                items: const [
                  ComboBoxItem(value: 'manager', child: Text('Manager')),
                  ComboBoxItem(value: 'employee', child: Text('Employé')),
                  ComboBoxItem(value: 'viewer', child: Text('Lecture seule')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => role = value);
                },
              ),
            ),
          ],
        ),
        actions: [
          Button(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          FilledButton(
            child: const Text('Ajouter'),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (confirmed != true || companyId == null) {
      email.dispose();
      return;
    }
    try {
      await repository.add(
        companyId: companyId!,
        email: email.text,
        role: role,
      );
      await _load();
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      email.dispose();
    }
  }

  Future<void> _changeRole(TenantMember member) async {
    String role = member.role;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: Text('Rôle de ${member.email}'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => ComboBox<String>(
            value: role,
            isExpanded: true,
            items: const [
              ComboBoxItem(value: 'admin', child: Text('Administrateur')),
              ComboBoxItem(value: 'manager', child: Text('Manager')),
              ComboBoxItem(value: 'employee', child: Text('Employé')),
              ComboBoxItem(value: 'viewer', child: Text('Lecture seule')),
            ],
            onChanged: (value) {
              if (value != null) setDialogState(() => role = value);
            },
          ),
        ),
        actions: [
          Button(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          FilledButton(
            child: const Text('Enregistrer'),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (confirmed != true || companyId == null || role == member.role) return;
    try {
      await repository.changeRole(
        companyId: companyId!,
        membershipId: member.membershipId,
        role: role,
      );
      await _load();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _revoke(TenantMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('Retirer cet utilisateur ?'),
        content: Text(
          '${member.email} perdra l’accès à cette entreprise. Son compte Parcoto ne sera pas supprimé.',
        ),
        actions: [
          Button(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          FilledButton(
            child: const Text('Retirer'),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (confirmed != true || companyId == null) return;
    try {
      await repository.revoke(
        companyId: companyId!,
        membershipId: member.membershipId,
      );
      await _load();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) {
    displayInfoBar(
      context,
      builder: (_, close) => InfoBar(
        title: Text(error.toString().replaceFirst('Bad state: ', '')),
        severity: InfoBarSeverity.error,
      ),
    );
  }
}
