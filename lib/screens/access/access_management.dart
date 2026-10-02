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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final companyId = authService.session?.company.companyId;
    if (companyId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
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
      context: context,
      builder: (_) => const _TeamEditor(),
    );
    if (result == null) return;

    await accessControlService.createTeam(
      AccessTeam(
        id: '',
        companyId: companyId,
        name: result.name,
        description: result.description,
        permissions: result.permissions,
      ),
    );
    await _load();
  }

  Future<void> _editTeam(AccessTeam team) async {
    final result = await showDialog<AccessTeam>(
      context: context,
      builder: (_) => _TeamEditor(team: team),
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
        content: Text('Supprimer « ${team.name} » ?'),
        actions: [
          Button(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            child: const Text('Supprimer'),
            onPressed: () => Navigator.pop(context, true),
          ),
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
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('Nouvelle équipe'),
              onPressed: _createTeam,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Actualiser'),
              onPressed: _load,
            ),
          ],
        ),
      ),
      content: _error != null
          ? Center(child: Text(_error!))
          : _teams.isEmpty
              ? const Center(child: Text('Aucune équipe personnalisée.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _teams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final team = _teams[index];
                    return ListTile(
                      title: Text(team.name),
                      subtitle: Text(
                        '${team.permissions.length} permission(s)'
                        '${team.description == null ? '' : ' • ${team.description}'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Button(
                            onPressed: () => _editTeam(team),
                            child: const Text('Modifier'),
                          ),
                          const SizedBox(width: 8),
                          if (!team.isSystem)
                            Button(
                              onPressed: () => _deleteTeam(team),
                              child: const Text('Supprimer'),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
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

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.team?.name ?? '');
    _description = TextEditingController(text: widget.team?.description ?? '');
    _selected = {...?widget.team?.permissions};
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Map<String, List<Permission>> _groupedPermissions() {
    final result = <String, List<Permission>>{};
    for (final permission in PermissionCatalog.all) {
      result.putIfAbsent(permission.module, () => []).add(permission);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedPermissions();
    return ContentDialog(
      title: Text(widget.team == null ? 'Nouvelle équipe' : 'Modifier l’équipe'),
      content: SizedBox(
        width: 700,
        height: 600,
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nom'),
                const SizedBox(height: 6),
                TextBox(
                  controller: _name,
                  enabled: !(widget.team?.isSystem ?? false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Description'),
                const SizedBox(height: 6),
                TextBox(
                  controller: _description,
                  maxLines: 2,
                  enabled: !(widget.team?.isSystem ?? false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: grouped.entries.map((entry) {
                  return Expander(
                    header: Text(entry.key),
                    content: Column(
                      children: entry.value.map((permission) {
                        return Checkbox(
                          content: Text(permission.label),
                          checked: _selected.contains(permission.id),
                          onChanged: widget.team?.isSystem == true
                              ? null
                              : (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selected.add(permission.id);
                                    } else {
                                      _selected.remove(permission.id);
                                    }
                                  });
                                },
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Button(
          child: const Text('Annuler'),
          onPressed: () => Navigator.pop(context),
        ),
        FilledButton(
          child: const Text('Enregistrer'),
          onPressed: widget.team?.isSystem == true || _name.text.trim().isEmpty
              ? null
              : () {
                  Navigator.pop(
                    context,
                    AccessTeam(
                      id: widget.team?.id ?? '',
                      companyId: widget.team?.companyId ?? '',
                      name: _name.text.trim(),
                      description: _description.text.trim().isEmpty
                          ? null
                          : _description.text.trim(),
                      permissions: _selected,
                      isSystem: widget.team?.isSystem ?? false,
                    ),
                  );
                },
        ),
      ],
    );
  }
}
