import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../core/tenancy/company_membership_resolver.dart';
import '../../main.dart' show authService, startBackgroundInitialization;
import '../../theme.dart';
import '../entreprise/entreprise.dart' show MyEntrepriseState;
import 'pane_items.dart';

/// Displays the active tenant and lets users switch between companies for
/// which the current Appwrite account has an active membership.
class CompanyWorkspaceSwitcher extends StatefulWidget {
  static final Map<String, String> companyNamesById = {};

  final bool compact;
  final VoidCallback? onCompanyChanged;

  const CompanyWorkspaceSwitcher({
    super.key,
    this.compact = false,
    this.onCompanyChanged,
  });

  @override
  State<CompanyWorkspaceSwitcher> createState() =>
      _CompanyWorkspaceSwitcherState();
}

class _CompanyWorkspaceSwitcherState extends State<CompanyWorkspaceSwitcher> {
  final CompanyMembershipResolver _membershipResolver =
      CompanyMembershipResolver();

  bool _loading = false;
  String? _selectedCompanyName;
  String? _selectedCompanyId;

  String get _companyLabel {
    final session = authService.session;
    if (session == null) return 'Espace entreprise';

    if (session.isPlatformSuperAdmin &&
        !session.isPlatformCompanyContext) {
      return 'Administration plateforme';
    }

    final activeCompanyId = session.company.companyId;
    final profile = MyEntrepriseState.p;
    if (profile?.id == activeCompanyId &&
        profile!.nom.trim().isNotEmpty) {
      return profile.nom;
    }

    final sharedName =
        CompanyWorkspaceSwitcher.companyNamesById[activeCompanyId];
    if (sharedName != null && sharedName.trim().isNotEmpty) {
      return sharedName;
    }

    final selectedName = _selectedCompanyId == activeCompanyId
        ? _selectedCompanyName
        : null;
    if (selectedName != null && selectedName.trim().isNotEmpty) {
      return selectedName;
    }

    return activeCompanyId;
  }

  String get _subtitle {
    final session = authService.session;
    if (session?.isPlatformSuperAdmin == true &&
        session?.isPlatformCompanyContext != true) {
      return 'Espace Super Admin';
    }
    if (session?.isPlatformCompanyContext == true) {
      return 'Consultation en mode supervision';
    }
    return 'Espace entreprise';
  }

  Future<void> _openSwitcher() async {
    if (_loading) return;

    final session = authService.session;
    if (session == null) return;

    // Platform administrators choose a tenant from the secured company
    // directory, where every target is authorized server-side.
    if (session.isPlatformSuperAdmin &&
        !session.isPlatformCompanyContext) {
      PaneItemsAndFooters.selectPane('platform-companies');
      widget.onCompanyChanged?.call();
      return;
    }

    // Selecting a normal membership here would leave the Super Admin
    // supervision context. Return to the platform through its dedicated action.
    if (session.isPlatformCompanyContext) return;

    setState(() => _loading = true);
    try {
      final memberships = await _membershipResolver.resolve();
      if (!mounted) return;

      if (memberships.isEmpty) {
        await _showError(
          'Aucune entreprise active n’est associée à ce compte.',
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final theme = context.read<AppTheme>();
          final currentCompanyId = authService.session?.company.companyId;
          return ContentDialog(
            title: const Text('Changer d’entreprise'),
            content: SizedBox(
              width: 380,
              height: (memberships.length * 68.0)
                  .clamp(76.0, 408.0)
                  .toDouble(),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: memberships.length,
                separatorBuilder: (_, __) => Container(
                  height: 1,
                  color: theme.borderColor,
                ),
                itemBuilder: (itemContext, index) {
                  final membership = memberships[index];
                  final active =
                      membership.companyId == currentCompanyId;
                  return Button(
                    onPressed: active
                        ? null
                        : () async {
                            Navigator.of(dialogContext).pop();
                            await _selectCompany(membership);
                          },
                    style: ButtonStyle(
                      padding: WidgetStatePropertyAll(
                        const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          FluentIcons.company_directory,
                          color: active
                              ? theme.color
                              : theme.mutedTextColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                membership.companyName.isNotEmpty
                                    ? membership.companyName
                                    : membership.companySlug,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.textColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${membership.role} • ${membership.companySlug}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.mutedTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (active)
                          Icon(
                            FluentIcons.check_mark,
                            color: theme.color,
                            size: 16,
                          )
                        else
                          Icon(
                            FluentIcons.chevron_right,
                            color: theme.mutedTextColor,
                            size: 13,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              Button(
                child: const Text('Fermer'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (mounted) {
        await _showError(
          error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectCompany(CompanyMembership membership) async {
    final previousCompanyId = authService.session?.company.companyId;
    if (membership.companyId == previousCompanyId) return;

    setState(() => _loading = true);
    try {
      await authService.selectCompany(membership.companyId);

      // Clear tenant-specific presentation cache before initializing the new
      // company. The runtime swap invalidates all provider/data caches.
      MyEntrepriseState.p = null;
      MyEntrepriseState.downloading = false;
      _selectedCompanyName = membership.companyName;
      _selectedCompanyId = membership.companyId;
      CompanyWorkspaceSwitcher.companyNamesById[membership.companyId] =
          membership.companyName;

      await startBackgroundInitialization(membership.companyId);
      if (!mounted) return;

      PaneItemsAndFooters.selectPane('dashboard');
      widget.onCompanyChanged?.call();
      setState(() {});
      _showNotice('Espace « ${membership.companyName} » activé.');
    } catch (error) {
      if (mounted) {
        await _showError(
          error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showNotice(String message) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text(message),
        severity: InfoBarSeverity.success,
      ),
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _showError(String message) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('Impossible de changer d’entreprise'),
        content: Text(message),
        actions: [
          FilledButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final session = authService.session;
    final platformHome = session?.isPlatformSuperAdmin == true &&
        session?.isPlatformCompanyContext != true;
    final supervision = session?.isPlatformCompanyContext == true;
    final interactive = session != null && !supervision;

    return Tooltip(
      message: interactive
          ? platformHome
              ? 'Ouvrir les entreprises clientes'
              : 'Changer d’entreprise'
          : 'Entreprise consultée en mode supervision',
      child: GestureDetector(
        onTap: interactive ? _openSwitcher : null,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 12 : 10,
            vertical: widget.compact ? 12 : 8,
          ),
          decoration: BoxDecoration(
            color: theme.fillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.borderColor),
          ),
          child: Row(
            children: [
              Icon(
                platformHome
                    ? FluentIcons.shield
                    : FluentIcons.company_directory,
                color: theme.color,
                size: widget.compact ? 22 : 20,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _companyLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: widget.compact ? 13 : 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.mutedTextColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_loading)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: ProgressRing(),
                )
              else if (interactive)
                Icon(
                  FluentIcons.chevron_down,
                  color: theme.mutedTextColor,
                  size: 12,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
