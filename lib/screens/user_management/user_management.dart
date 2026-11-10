import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/user_management/user_creation.dart';
import 'package:parc_oto/screens/user_management/user_table.dart';
import '../../widgets/module_dashboard_header.dart';



class UserManagement extends StatefulWidget {
  final bool archive;

  const UserManagement({super.key, this.archive = false});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  bool loading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            child: ModuleDashboardHeader(
              title: widget.archive ? 'Archive utilisateurs' : 'Utilisateurs',
              subtitle:
                  'Gérez les comptes, les profils et les accès à ParcOto.',
              eyebrow: 'ParcOto / Identity',
              heroTitle: widget.archive
                  ? 'Comptes archivés'
                  : 'Gestion des utilisateurs',
              heroDescription:
                  'Consultez les comptes, recherchez un utilisateur et gérez les accès de votre organisation.',
              icon: FluentIcons.people,
              trailing: Tooltip(
                message: 'Ajouter un utilisateur',
                child: IconButton(
                  icon: const Icon(FluentIcons.add),
                  onPressed: widget.archive ? null : showUserForm,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: UsersTable(archive: widget.archive),
            ),
          ),
        ],
      ),
    );
  }

  void showUserForm() async {
    await showDialog(
      context: context,
      builder: (c) {
        return const UserForm();
      },
    );
  }
}
