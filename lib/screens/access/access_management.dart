import 'package:fluent_ui/fluent_ui.dart';

import '../../core/permissions/permission.dart';
import '../../core/permissions/permission_catalog.dart';
import '../../domain/entities/access_team.dart';
import '../../main.dart';

class AccessManagement extends StatefulWidget {
  const AccessManagement({super.key});
  @override
  State<AccessManagement> createState() => _AccessManagementState();
}

class _AccessManagementState extends State<AccessManagement> {
  List<AccessTeam> _teams = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final companyId = authService.session?.company.companyId;
    if (companyId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final teams = await accessControlService.getTeams(companyId);
      if (!mounted) return;
      setState(() => _teams = teams);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createTeam() async {
    final companyId = authService.session?.company.companyId;
    if (companyId == null) return;
    final result = await showDialog<AccessTeam>(
      context: context, builder: (_) => const _TeamEditor(),
    );
    if (result == null) return;
    await accessControlService.createTeam(AccessTeam(
      id: '', companyId: companyId, name: result.name,
      description: result.description, permissions: result.permissions,
    ));
    await _load();
  }

  Future<void> _editTeam(AccessTeam team) async {
    final result = await showDialog<AccessTeam>(
      context: context, builder: (_) => _TeamEditor(team: team),
    );
    if (result == null) return;
    await accessControlService.updateTeam(result);
    await _load();
  }

  Future<void> _deleteTeam(AccessTeam team) async {
    if (team.isSystem) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ContentDialog(
        title: const Text('Supprimer l’équipe'),
        content: Text('Supprimer « \${team.name} » ?'),
        actions: [
          Button(child: const Text('Annuler'), onPressed: () => Navigator.pop(context, false)),
          FilledButton(child: const Text('Supprimer'), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (confirmed == true) {
      await accessControlService.deleteTeam(team.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: ProgressRing());
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Équipes et accès'),
        commandBar: CommandBar(primaryItems: [
          CommandBarButton(icon: const Icon(FluentIcons.add), label: const Text('Nouvelle équipe'), onPressed: _createTeam),
          CommandBarButton(icon: const Icon(FluentIcons.refresh), label: const Text('Actualiser'), onPressed: _load),
        ]),
      ),
      content: _error != null
          ? Center(child: Text(_error!))
          : _teams.isEmpty
              ? _EmptyState(onCreate: _createTeam)
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _teams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final team = _teams[index];
                    return Card(
                      padding: const EdgeInsets.all(18),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: FluentTheme.of(context).accentColor.withValues(alpha: .12),
                          ),
                          child: Icon(team.isSystem ? FluentIcons.shield : FluentIcons.people,
                              color: FluentTheme.of(context).accentColor),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(team.name, style: FluentTheme.of(context).typography.subtitle),
                            if (team.isSystem) ...[
                              const SizedBox(width: 8),
                              const InfoBadge(source: Text('Système')),
                            ],
                          ]),
                          const SizedBox(height: 5),
                          Text(
                            team.description?.isNotEmpty == true
                                ? team.description!
                                : '\${team.permissions.length} permission(s)',
                            style: FluentTheme.of(context).typography.caption,
                          ),
                        ])),
                        Button(onPressed: () => _editTeam(team), child: const Text('Modifier')),
                        if (!team.isSystem) ...[
                          const SizedBox(width: 8),
                          IconButton(icon: const Icon(FluentIcons.delete), onPressed: () => _deleteTeam(team)),
                        ],
                      ]),
                    );
                  },
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});
  @override
  Widget build(BuildContext context) => Center(
    child: Card(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(FluentIcons.people_add, size: 40),
        const SizedBox(height: 14),
        Text('Aucune équipe', style: FluentTheme.of(context).typography.title),
        const SizedBox(height: 8),
        const Text('Créez une équipe à partir d’un profil prédéfini ou configurez ses accès manuellement.'),
        const SizedBox(height: 18),
        FilledButton(onPressed: onCreate, child: const Text('Créer une équipe')),
      ]),
    ),
  );
}

class _TeamEditor extends StatefulWidget {
  final AccessTeam? team;
  const _TeamEditor({this.team});
  @override
  State<_TeamEditor> createState() => _TeamEditorState();
}

class _TeamEditorState extends State<_TeamEditor> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late Set<String> _selected;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.team?.name ?? '');
    _description = TextEditingController(text: widget.team?.description ?? '');
    _selected = {...?widget.team?.permissions};
  }

  @override
  void dispose() { _name.dispose(); _description.dispose(); super.dispose(); }

  Map<String, List<Permission>> _groupedPermissions() {
    final result = <String, List<Permission>>{};
    final query = _search.trim().toLowerCase();
    for (final permission in PermissionCatalog.all) {
      if (query.isNotEmpty &&
          !permission.label.toLowerCase().contains(query) &&
          !permission.id.toLowerCase().contains(query)) continue;
      result.putIfAbsent(permission.module, () => []).add(permission);
    }
    return result;
  }

  void _applyPreset(String name) => setState(() => _selected = PermissionCatalog.preset(name));

  void _setAll(bool value) => setState(() {
    _selected = value ? PermissionCatalog.all.map((p) => p.id).toSet() : <String>{};
  });

  void _setCategory(List<Permission> permissions, bool value) => setState(() {
    final ids = permissions.map((p) => p.id);
    if (value) { _selected.addAll(ids); } else { _selected.removeAll(ids); }
  });

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedPermissions();
    final total = PermissionCatalog.all.length;
    final isLocked = widget.team?.isSystem == true;

    return ContentDialog(
      constraints: const BoxConstraints(
        minWidth: 680,
        maxWidth: 900,
        maxHeight: 820,
      ),
      title: Row(children: [
        Icon(FluentIcons.people, color: FluentTheme.of(context).accentColor),
        const SizedBox(width: 10),
        Text(widget.team == null ? 'Nouvelle équipe' : 'Modifier l’équipe'),
      ]),
      content: SizedBox(
        width: 760, height: 650,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: TextBox(controller: _name, placeholder: 'Nom de l’équipe', enabled: !isLocked)),
            const SizedBox(width: 10),
            Expanded(child: TextBox(controller: _description, placeholder: 'Description (optionnelle)', enabled: !isLocked)),
          ]),
          const SizedBox(height: 16),
          Text('Profil de départ', style: FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              for (final preset in PermissionCatalog.presets.keys)
                Button(onPressed: isLocked ? null : () => _applyPreset(preset), child: Text(preset)),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TextBox(
              placeholder: 'Rechercher une permission…',
              onChanged: (value) => setState(() => _search = value),
            )),
            const SizedBox(width: 10),
            Button(onPressed: isLocked ? null : () => _setAll(true), child: const Text('Tout sélectionner')),
            const SizedBox(width: 6),
            Button(onPressed: isLocked ? null : () => _setAll(false), child: const Text('Tout retirer')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Icon(FluentIcons.permissions, size: 14,
                color: FluentTheme.of(context).accentColor),
            const SizedBox(width: 6),
            Text('\${_selected.length} / \${total} permissions sélectionnées',
                style: FluentTheme.of(context).typography.caption),
          ]),
          const SizedBox(height: 8),
          Expanded(child: ListView.separated(
            itemCount: grouped.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final entry = grouped.entries.elementAt(index);
              final permissions = entry.value;
              final selectedCount = permissions.where((p) => _selected.contains(p.id)).length;
              final allSelected = selectedCount == permissions.length;
              return Card(
                padding: EdgeInsets.zero,
                child: Expander(
                  header: Row(children: [
                    Expanded(child: Text(_moduleLabel(entry.key),
                        style: FluentTheme.of(context).typography.subtitle)),
                    Text('\${selectedCount}/\${permissions.length}',
                        style: FluentTheme.of(context).typography.caption),
                  ]),
                  content: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Button(
                            onPressed: isLocked
                                ? null
                                : () => _setCategory(permissions, !allSelected),
                            child: Text(allSelected
                                ? 'Tout retirer de cette catégorie'
                                : 'Tout sélectionner dans cette catégorie'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        for (final permission in permissions)
                          Checkbox(
                            content: Text(permission.label),
                            checked: _selected.contains(permission.id),
                            onChanged: isLocked ? null : (value) => setState(() {
                              if (value == true) { _selected.add(permission.id); }
                              else { _selected.remove(permission.id); }
                            }),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          )),
        ]),
      ),
      actions: [
        Button(child: const Text('Annuler'), onPressed: () => Navigator.pop(context)),
        FilledButton(
          child: const Text('Enregistrer'),
          onPressed: isLocked || _name.text.trim().isEmpty ? null : () => Navigator.pop(context, AccessTeam(
            id: widget.team?.id ?? '',
            companyId: widget.team?.companyId ?? '',
            name: _name.text.trim(),
            description: _description.text.trim().isEmpty ? null : _description.text.trim(),
            permissions: _selected,
            isSystem: widget.team?.isSystem ?? false,
          )),
        ),
      ],
    );
  }

  String _moduleLabel(String module) {
    const labels = {
      'dashboard': 'Tableau de bord', 'vehicles': 'Véhicules', 'drivers': 'Conducteurs',
      'stock': 'Stock', 'repairs': 'Réparations', 'planning': 'Planning',
      'reception': 'Réception', 'clients': 'Clients', 'company': 'Entreprise',
      'users': 'Utilisateurs', 'teams': 'Équipes', 'permissions': 'Accès',
      'activity': 'Activité', 'backup': 'Sauvegardes',
    };
    return labels[module] ?? module;
  }
}
