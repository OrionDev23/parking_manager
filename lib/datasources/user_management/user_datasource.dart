import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:material_ui/material_ui.dart';
import 'package:parc_oto/datasources/user_management/user_webservice.dart';

import '../../providers/client_database.dart';
import '../../screens/user_management/user_creation.dart';
import '../../screens/access/user_access_editor.dart';
import '../../widgets/on_tap_scale.dart';
import '../parcoto_datasource.dart';

class UsersManagementDatasource
    extends ParcOtoDatasourceUsers<String, MapEntry<User, List<String>?>> {
  final bool archive;

  UsersManagementDatasource(
      {required super.current,
      super.appTheme,
      super.searchKey,
      super.selectC,
      this.archive = false}) {
    repo = UsersWebservice(data);
  }

  @override
  Future<void> addToActivity(MapEntry<User, List<String>?> c) async {
    await DatabaseGetter().ajoutActivity(34, c.key.$id,
        docName: c.key.name.isEmpty ? c.key.email : c.key.name);
  }

  @override
  String deleteConfirmationMessage(MapEntry<User, List<String>?> c) {
    return '${'supreuser'.tr()} ${c.key.name.isEmpty ? c.key.email : c.key.name}';
  }

  @override
  void deleteRow(c, t) async {
    var client = (repo as UsersWebservice).client;

    await Future.wait([
      Users(client).delete(userId: t.key.$id).then((value) async {
        if (!current.mounted) return;
        f.displayInfoBar(
          current,
          builder: (co, s) {
            return f.InfoBar(
                title: const Text('done').tr(),
                severity: f.InfoBarSeverity.success);
          },
          alignment:
          Alignment.lerp(Alignment.topCenter, Alignment.center, 0.6)!,
        );
          try{
            await DatabaseGetter.database!.deleteRow(
                databaseId: databaseId,
                tableId: userid,
                rowId: t.key.$id);
          }
          catch(e){
            //
          }

          data.remove(MapEntry(c, t));
          refreshDatasource();
        }
      ),
      addToActivity(t),
    ]);
  }

  @override
  List<DataCell> getCellsToShow(
      MapEntry<String, MapEntry<User, List<String>?>> element) {
    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');
    final teams = element.value.value ?? const <String>[];
    final roles = teams.isEmpty
        ? 'Aucune équipe'
        : teams.map((team) => team.tr()).join(', ');

    return [
      DataCell(SelectableText(element.value.key.name, style: rowTextStyle)),
      DataCell(SelectableText(element.value.key.email, style: rowTextStyle)),
      DataCell(SelectableText(element.value.key.$id, style: rowTextStyle)),
      DataCell(SelectableText((roles), style: rowTextStyle)),
      DataCell(SelectableText(
          dateFormat.format(DateTime.parse(element.value.key.$createdAt)),
          style: rowTextStyle)),
      DataCell(f.FlyoutTarget(
        controller: controllers[element.value.key.$id]!,
        child: OnTapScaleAndFade(
          onTap: () {
            controllers[element.value.key.$id]!.showFlyout(
              builder: (context) {
                return f.MenuFlyout(
                  items: [
                    f.MenuFlyoutItem(
                      text: const Text('Gérer les accès'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Future.delayed(const Duration(milliseconds: 50)).then(
                          (_) {
                            if (!current.mounted) return;
                            f.showDialog(
                              context: current,
                            builder: (_) => UserAccessEditor(
                              userId: element.value.key.$id,
                              userName: element.value.key.name.isEmpty
                                  ? element.value.key.email
                                  : element.value.key.name,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    f.MenuFlyoutItem(
                      text: const Text('Modifier'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Future.delayed(const Duration(milliseconds: 50))
                            .then((_) => showUserForm(element.value.key));
                      },
                    ),
                    f.MenuFlyoutItem(
                      text: const Text('Supprimer'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        showDeleteConfirmation(element.key, element.value);
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: f.Container(
            decoration: BoxDecoration(
              color: appTheme?.color.lightest,
              boxShadow: kElevationToShadow[2],
            ),
            child: Icon(Icons.edit, color: appTheme!.color.darkest),
          ),
        ),
      )),
    ];
  }

  void showUserForm(User user) {
    f.showDialog(
        context: current,
        builder: (c) {
          return UserForm(
            user: user,
          );
        });
  }


}
