import 'package:appwrite/appwrite.dart' as client_aw;
import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parc_oto/datasources/user_management/user_webservice.dart';
import 'package:parc_oto/theme.dart';

import '../../providers/client_database.dart';
import '../../screens/user_management/user_creation.dart';
import '../../widgets/on_tap_scale.dart';
import '../parcoto_datasource.dart';

class UsersManagementDatasource
    extends ParcOtoDatasourceUsers<String, MapEntry<User, List<Membership>?>> {
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
  Future<void> addToActivity(MapEntry<User, List<Membership>?> c) async {
    await ClientDatabase().ajoutActivity(34, c.key.$id,
        docName: c.key.name.isEmpty ? c.key.email : c.key.name);
  }

  @override
  String deleteConfirmationMessage(MapEntry<User, List<Membership>?> c) {
    return '${'supreuser'.tr()} ${c.key.name.isEmpty ? c.key.email : c.key.name}';
  }

  @override
  void deleteRow(c, t) async {
    var client = (repo as UsersWebservice).client;

    await Future.wait([
      Users(client).delete(userId: t.key.$id).then((value) async {
        await Databases(client).deleteDocument(
            databaseId: databaseId,
            collectionId: userid,
            documentId: t.key.$id);
        data.remove(MapEntry(c, t));
        refreshDatasource();
      }),
      addToActivity(t),
    ]).onError((error, stackTrace) {
      return [
        f.displayInfoBar(
          current,
          builder: (c, s) {
            return f.InfoBar(
                title: const Text('erreur').tr(),
                severity: f.InfoBarSeverity.error);
          },
          alignment:
              Alignment.lerp(Alignment.topCenter, Alignment.center, 0.6)!,
        )
      ];
    });
  }

  @override
  List<DataCell> getCellsToShow(
      MapEntry<String, MapEntry<User, List<Membership>?>> element) {
    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');
    String roles = '';
    if (isInvitedButNotJoined(element.value.value)) {
      roles = "enattente".tr();
    } else {
      element.value.value?.forEach((element) {
        if (roles.isNotEmpty) {
          roles += ', ';
        }
        roles += element.teamName.tr();
      });
      roles = roles.toLowerCase().tr();
    }

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
        child: !isAdmin(element.value.value)?OnTapScaleAndFade(
            onTap: () {
              controllers[element.value.key.$id]!.showFlyout(
                  builder: (context) {
                return f.MenuFlyout(
                  items: [
                    if (!isManager(element.value.value) &&
                        !isInvitedButNotJoined(element.value.value))
                      f.MenuFlyoutItem(
                        text: const Text('invitmanager').tr(),
                        onPressed: () {
                          inviteToBecomeManager(
                              element.value.key, element.value.value);
                        },
                      ),
                    if (isInvitedButNotJoined(element.value.value))
                      f.MenuFlyoutItem(
                          text: Text(
                            'alreadyinvited',
                            style: TextStyle(color: placeStyle.color),
                          ).tr(),
                          onPressed: null),
                    f.MenuFlyoutItem(
                        text: const Text('mod').tr(),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Future.delayed(const Duration(milliseconds: 50))
                              .then((value) => showUserForm(element.value.key));
                        }),
                    f.MenuFlyoutItem(
                        text: const Text('delete').tr(),
                        onPressed: () {
                          Navigator.of(context).pop();
                          showDeleteConfirmation(element.key, element.value);
                        }),
                  ],
                );
              });
            },
            child: f.Container(
                decoration: BoxDecoration(
                  color: appTheme?.color.lightest,
                  boxShadow: kElevationToShadow[2],
                ),
                child: Icon(
                  Icons.edit,
                  color: appTheme!.color.darkest,
                ))):
        const Text(''),
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

  bool isManager(List<Membership>? e) {
    if (e != null) {
      for (var t in e) {
        if (t.teamName.toLowerCase() == 'managers') {
          return true;
        }
      }
    }

    return false;
  }

  bool isAdmin(List<Membership>? e) {
    if (e != null) {
      for (var t in e) {
        if (t.teamName.toLowerCase() == 'admins') {
          return true;
        }
      }
    }

    return false;
  }
  bool isInvitedButNotJoined(List<Membership>? e) {
    if (e != null) {
      for (var t in e) {
        if (t.teamName.toLowerCase() == 'managers') {
          if (t.joined.isEmpty) {
            return true;
          } else {
            if (kDebugMode) {
              print("joined :${t.joined}");
            }
            return false;
          }
        }
      }
    }

    return false;
  }

  String getMembershipID(List<Membership>? t) {
    if (t != null) {
      for (var e in t) {
        if (e.teamId == 'managers') {
          return e.$id;
        }
      }
    }

    return '';
  }

  void inviteToBecomeManager(User user, List<Membership>? t) async {
    await client_aw.Teams(ClientDatabase.client!)
        .createMembership(
            teamId: 'managers',
            roles: ['member'],
            userId: user.$id,
            email: user.email,
            name: user.name,
            url:
                'https://app.parcoto.com/acceptinvitation?projectId=$project&endpoint=$endpoint')
        .then((value) {
      f.displayInfoBar(current, builder: (co, s) {
        return f.InfoBar(
          severity: f.InfoBarSeverity.success,
          title: const Text('invitationsent').tr(),
        );
      });
    }).onError((client_aw.AppwriteException error, stackTrace) {
      if (kDebugMode) {
        print('====================================================');
        print('error sending invitation');
        print('type: ${error.type}');
        print('code: ${error.code}');
        print('message: ${error.message}');
        print('response: ${error.response}');
        print('stacktrace: $stackTrace');
        print('====================================================');
      }
    });
  }
}
