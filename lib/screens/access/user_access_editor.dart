import 'package:fluent_ui/fluent_ui.dart';

import '../../core/permissions/permission.dart';
import '../../core/permissions/permission_catalog.dart';
import '../../domain/entities/access_team.dart';
import '../../domain/entities/user_access.dart';
import '../../main.dart';

class UserAccessEditor extends StatefulWidget {
  final String userId;
  final String userName;

  const UserAccessEditor({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserAccessEditor> createState() => _UserAccessEditorState();
}

class _UserAccessEditorState extends State<UserAccessEditor> {
  UserAccess? _access;
  List<AccessTeam> _teams = const [];
  bool _loading = true;
  String? _error;

  final Set<String> _teamIds = {};
  final Set<String> _granted = {};
  final Set<String> _denied = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final companyId = authService.session?.company.companyId;
    if (companyId == null) return;

    try {
      final access = await accessControlService.getUserAccess(
        companyId,
        widget.userId,
      );
      final teams = await accessControlService.getTeams(companyId);

      if (!mounted) return;
      _access = access;
      _teamIds
        ..clear()
        ..addAll(access.teamIds);
      _granted
        ..clear()
        ..addAll(access.grantedPermissions);
      _denied
        ..clear()
        ..addAll(access.deniedPermissions);

      setState(() => _teams = teams);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final companyId = authService.session?.company.companyId;
    if (companyId == null) return;

    await accessControlService.updateUserAccess(
      UserAccess(
        userId: widget.userId,
        companyId: companyId,
        teamIds: _teamIds,
        grantedPermissions: _granted,
        deniedPermissions: _denied,
      ),
    );

    if (mounted) Navigator.pop(context, true);
  }

  Map<String, List<Permission>> get _grouped {
    final result = <String, List<Permission>>{};
    for (final permission in PermissionCatalog.all) {
      result.putIfAbsent(permission.module, () => []).add(permission);
    }
    return result;
  }

  bool _teamProvides(String permission) {
    return _teams
        .where((team) => _teamIds.contains(team.id))
        .any((team) => team.permissions.contains(permission));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ContentDialog(content: Center(child: ProgressRing()));
    }

    return ContentDialog(
      title: Text('Accès — ${widget.userName}'),
      content: SizedBox(
        width: 850,
        height: 650,
        child: _error != null
            ? Text(_error!)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Équipes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _teams.map((team) {
                      final selected = _teamIds.contains(team.id);
                      return ToggleButton(
                        checked: selected,
                        onChanged: (value) {
                          setState(() {
                            if (value) {
                              _teamIds.add(team.id);
                            } else {
                              _teamIds.remove(team.id);
                            }
                          });
                        },
                        child: Text(team.name),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Permissions individuelles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Une autorisation individuelle s’ajoute aux équipes. '
                    'Une restriction individuelle prend priorité.',
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: _grouped.entries.map((entry) {
                        return Expander(
                          header: Text(entry.key),
                          content: Column(
                            children: entry.value.map((permission) {
                              final fromTeam = _teamProvides(permission.id);
                              final granted = _granted.contains(permission.id);
                              final denied = _denied.contains(permission.id);

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(permission.label),
                                          if (fromTeam)
                                            const Text(
                                              'Accordé par une équipe',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                        ],
                                      ),
                                    ),
                                    ToggleSwitch(
                                      checked: granted,
                                      onChanged: denied
                                          ? null
                                          : (value) {
                                              setState(() {
                                                if (value) {
                                                  _granted.add(permission.id);
                                                } else {
                                                  _granted.remove(permission.id);
                                                }
                                              });
                                            },
                                      content: const Text('Autoriser'),
                                    ),
                                    const SizedBox(width: 8),
                                    ToggleSwitch(
                                      checked: denied,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value) {
                                            _denied.add(permission.id);
                                            _granted.remove(permission.id);
                                          } else {
                                            _denied.remove(permission.id);
                                          }
                                        });
                                      },
                                      content: const Text('Refuser'),
                                    ),
                                  ],
                                ),
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
          onPressed: _save,
        ),
      ],
    );
  }
}
