import 'package:fluent_ui/fluent_ui.dart';

import '../../widgets/module_dashboard_header.dart';
import 'tenant_members_screen.dart';

class UserManagement extends StatelessWidget {
  final bool archive;

  const UserManagement({super.key, this.archive = false});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;
    final horizontalPadding = compact ? 12.0 : 28.0;
    if (archive) {
      return const ScaffoldPage(
        content: Center(
          child: Text(
            'L’archive des comptes globaux est désactivée en mode multi-entreprise.',
          ),
        ),
      );
    }

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: compact ? 12 : 22,
            ),
            child: ModuleDashboardHeader(
              title: 'Utilisateurs',
              subtitle: 'Gérez les membres et leurs accès à cette entreprise.',
              eyebrow: 'Parcoto / Identity',
              heroTitle: 'Gestion des membres',
              heroDescription:
                  'Les comptes sont globaux ; leurs appartenances et leurs rôles sont propres à chaque entreprise.',
              icon: FluentIcons.people,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: const TenantMembersScreen(),
            ),
          ),
        ],
      ),
    );
  }
}
