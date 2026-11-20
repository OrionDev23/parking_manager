import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../core/tenancy/company_membership_resolver.dart';
import '../../core/tenancy/platform_companies_repository.dart';
import '../../main.dart' show authService, companyService, startBackgroundInitialization;
import '../../theme.dart';
import '../../ui/design_system/parcoto_surface.dart';
import '../../ui/design_system/parcoto_tokens.dart';
import '../entreprise/entreprise.dart' show MyEntrepriseState;
import 'pane_items.dart';

/// Displays the active workspace and lets users switch to authorized
/// tenants. Standard users are limited to memberships; platform Super Admins
/// use the server-authorized company directory.
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
  final PlatformCompaniesRepository _platformCompaniesRepository =
      PlatformCompaniesRepository();

  StreamSubscription<dynamic>? _authStateSubscription;

  bool _loading = false;
  String? _selectedCompanyName;
  String? _selectedCompanyId;
  String? _observedSessionMarker;

  String? _sessionMarker() {
    final session = authService.session;
    if (session == null) return null;
    return [
      session.userId,
      session.company.companyId,
      session.isPlatformSuperAdmin,
      session.isPlatformCompanyContext,
    ].join('|');
  }

  @override
  void initState() {
    super.initState();
    _observedSessionMarker = _sessionMarker();
    _loadCurrentCompanyName();
    // The parent navigation shell is kept alive and the switcher is often
    // passed as a const child. Listen directly so session/company changes
    // update this widget without requiring a resize or theme rebuild.
    _authStateSubscription = authService.stateStream.listen((_) {
      if (!mounted) return;
      final marker = _sessionMarker();
      if (marker != _observedSessionMarker) {
        _observedSessionMarker = marker;
        _selectedCompanyId = null;
        _selectedCompanyName = null;
        _loadCurrentCompanyName();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentCompanyName() async {
    final session = authService.session;
    if (session == null ||
        (session.isPlatformSuperAdmin &&
            !session.isPlatformCompanyContext)) {
      return;
    }

    final companyId = session.company.companyId;
    try {
      final company = await companyService.getCurrent();
      if (!mounted ||
          company == null ||
          authService.session?.company.companyId != companyId) {
        return;
      }
      CompanyWorkspaceSwitcher.companyNamesById[companyId] = company.name;
      setState(() {});
    } catch (_) {
      // The company ID remains a valid fallback when the profile API is
      // temporarily unavailable.
    }
  }

  String get _companyLabel {
    final session = authService.session;
    if (session == null) return 'Espace entreprise';

    if (session.isPlatformSuperAdmin &&
        !session.isPlatformCompanyContext) {
      return 'Administration plateforme';
    }

    final activeCompanyId = session.company.companyId;
    final profile = MyEntrepriseState.p;
    if (profile != null &&
        profile.id == activeCompanyId &&
        profile.nom.trim().isNotEmpty) {
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

    setState(() => _loading = true);
    try {
      if (session.isPlatformSuperAdmin) {
        await _openPlatformCompanyPicker();
      } else {
        await _openMembershipCompanyPicker();
      }
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

  Future<void> _openPlatformCompanyPicker() async {
    final companies = await _platformCompaniesRepository.list();
    if (!mounted) return;

    for (final company in companies) {
      if (company.companyId.isNotEmpty && company.name.trim().isNotEmpty) {
        CompanyWorkspaceSwitcher.companyNamesById[company.companyId] =
            company.name;
      }
    }
    setState(() {});

    final selected = await showDialog<PlatformCompany>(
      context: context,
      builder: (dialogContext) => _PlatformCompanyPickerDialog(
        companies: companies,
        currentCompanyId: authService.session?.company.companyId,
      ),
    );
    if (selected == null || !mounted) return;

    await _enterPlatformCompany(selected);
  }

  Future<void> _openMembershipCompanyPicker() async {
    final session = authService.session;
    if (session == null || session.isPlatformCompanyContext) return;

    final memberships = await _membershipResolver.resolve();
    if (!mounted) return;

    if (memberships.isEmpty) {
      await _showError(
        'Aucune entreprise active n’est associée à ce compte.',
      );
      return;
    }

    final selected = await showDialog<CompanyMembership>(
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
              separatorBuilder: (_, _) => Container(
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
                      : () => Navigator.of(dialogContext).pop(membership),
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
                            const SizedBox(height: ParcotoTokens.space2),
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
                      const SizedBox(width: ParcotoTokens.space2),
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

    if (selected == null || !mounted) return;
    await _selectCompany(selected);
  }

  Future<void> _enterPlatformCompany(PlatformCompany company) async {
    final currentSession = authService.session;
    if (currentSession?.isPlatformSuperAdmin != true) {
      throw StateError('Accès réservé au Super Admin plateforme.');
    }
    if (currentSession?.isPlatformCompanyContext == true &&
        currentSession?.company.companyId == company.companyId) {
      return;
    }

    // The server function validates the Super Admin and resolves the target
    // tenant's team/profile context. Never use ordinary membership selection
    // for a platform administrator: they may not be a member of that tenant.
    await authService.enterPlatformCompany(company.companyId);
    CompanyWorkspaceSwitcher.companyNamesById[company.companyId] =
        company.name;
    _selectedCompanyId = company.companyId;
    _selectedCompanyName = company.name;

    await startBackgroundInitialization(company.companyId);
    if (!mounted) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    PaneItemsAndFooters.selectPane('dashboard');
    widget.onCompanyChanged?.call();
    setState(() {});
    _showNotice('Espace « ${company.name} » ouvert en supervision.');
  }

  Future<void> _selectCompany(CompanyMembership membership) async {
    final previousCompanyId = authService.session?.company.companyId;
    if (membership.companyId == previousCompanyId) return;

    await authService.selectCompany(membership.companyId);

    // setActiveCompanyId already reloads the selected company profile. Do not
    // clear it here: doing so used to leave the switcher showing the raw ID
    // until a later unrelated rebuild.
    _selectedCompanyName = membership.companyName;
    _selectedCompanyId = membership.companyId;
    CompanyWorkspaceSwitcher.companyNamesById[membership.companyId] =
        membership.companyName;

    await startBackgroundInitialization(membership.companyId);
    if (!mounted) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    PaneItemsAndFooters.selectPane('dashboard');
    widget.onCompanyChanged?.call();
    setState(() {});
    _showNotice('Espace « ${membership.companyName} » activé.');
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
    final interactive = session != null;

    return Tooltip(
      message: interactive
          ? platformHome
              ? 'Choisir une entreprise cliente'
              : 'Changer rapidement d’entreprise'
          : 'Connectez-vous pour choisir une entreprise',
      child: GestureDetector(
        onTap: interactive ? _openSwitcher : null,
        child: ParcotoSurface(
          tone: ParcotoSurfaceTone.subtle,
          radius: theme.controlRadius,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact
                ? ParcotoTokens.space3
                : ParcotoTokens.space2,
            vertical: widget.compact
                ? ParcotoTokens.space3
                : ParcotoTokens.space2,
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
              const SizedBox(width: ParcotoTokens.space3),
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


class _PlatformCompanyPickerDialog extends StatefulWidget {
  final List<PlatformCompany> companies;
  final String? currentCompanyId;

  const _PlatformCompanyPickerDialog({
    required this.companies,
    required this.currentCompanyId,
  });

  @override
  State<_PlatformCompanyPickerDialog> createState() =>
      _PlatformCompanyPickerDialogState();
}

class _PlatformCompanyPickerDialogState
    extends State<_PlatformCompanyPickerDialog> {
  final TextEditingController _searchController = TextEditingController();

  List<PlatformCompany> get _visibleCompanies {
    final query = _searchController.text.trim().toLowerCase();
    final values = widget.companies.where((company) {
      if (query.isEmpty) return true;
      return company.name.toLowerCase().contains(query) ||
          company.slug.toLowerCase().contains(query) ||
          company.companyId.toLowerCase().contains(query);
    }).toList(growable: false)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return values;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final companies = _visibleCompanies;
    final screenSize = MediaQuery.sizeOf(context);
    final contentWidth =
        (screenSize.width - 64).clamp(220.0, 460.0).toDouble();
    final contentHeight =
        (screenSize.height - 180).clamp(220.0, 480.0).toDouble();

    return ContentDialog(
      title: const Text('Changer d’entreprise'),
      constraints: BoxConstraints(
        maxWidth: contentWidth + 40,
        maxHeight: contentHeight + 120,
      ),
      content: SizedBox(
        width: contentWidth,
        height: contentHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextBox(
              controller: _searchController,
              placeholder: 'Rechercher par nom, code ou identifiant...',
              prefix: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(FluentIcons.search, size: 15),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text(
              '${companies.length} entreprise(s)',
              style: TextStyle(
                color: theme.mutedTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: companies.isEmpty
                  ? const Center(
                      child: Text('Aucune entreprise ne correspond à la recherche.'),
                    )
                  : ListView.separated(
                      itemCount: companies.length,
                      separatorBuilder: (_, _) => Divider(
                        style: DividerThemeData(
                          decoration: BoxDecoration(color: theme.borderColor),
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final company = companies[index];
                        final active =
                            company.companyId == widget.currentCompanyId;
                        final status = company.status.trim().isEmpty
                            ? 'Statut inconnu'
                            : company.status;
                        return Button(
                          onPressed: active
                              ? null
                              : () => Navigator.of(context).pop(company),
                          style: ButtonStyle(
                            padding: WidgetStatePropertyAll(
                              const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
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
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      company.name.isNotEmpty
                                          ? company.name
                                          : company.slug,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: theme.textColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${company.slug} • $status',
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
