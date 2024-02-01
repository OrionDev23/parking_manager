import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:parc_oto/datasources/conducteurs/conducteur_webservice.dart';
import 'package:parc_oto/datasources/parcoto_datasource.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/chauffeur/manager/chauffeur_form.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../screens/chauffeur/document/chauf_document_form.dart';
import '../../screens/chauffeur/manager/chauffeur_tabs.dart';
import '../../serializables/conducteur/conducteur.dart';
import '../../serializables/conducteur/disponibilite_chauffeur.dart';
import '../../widgets/on_tap_scale.dart';

class ConducteurDataSource extends ParcOtoDatasource<Conducteur> {
  final bool archive;

  ConducteurDataSource(
      {this.archive = false,
      required super.collectionID,
      super.selectC,
      super.searchKey,
      super.appTheme,
      super.filters,
      required super.current}) {
    repo = ConducteurWebService(data, collectionID, 1, archive: archive);
  }

  @override
  String deleteConfirmationMessage(Conducteur c) {
    return '${'supchauf'.tr()} ${c.name} ${c.prenom}';
  }

  @override
  List<DataCell> getCellsToShow(MapEntry<String, Conducteur> element) {
    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');
    final tstyle = TextStyle(
      fontSize: 10.sp,
    );
    return [
      DataCell(SelectableText(
        '${element.value.name} ${element.value.prenom}',
        style: tstyle,
      )),
      DataCell(SelectableText(
        element.value.email ?? '',
        style: tstyle,
      )),
      DataCell(SelectableText(
        element.value.telephone ?? '',
        style: tstyle,
      )),
      DataCell(SelectableText(
        ClientDatabase.getEtat(element.value.etat).tr(),
        style: tstyle,
      )),
      DataCell(SelectableText(
        element.value.updatedAt == null
            ? ''
            : dateFormat.format(element.value.updatedAt!),
        style: tstyle,
      )),
      DataCell(ClientDatabase().isAdmin() || ClientDatabase().isManager()
          ? f.FlyoutTarget(
              controller: element.value.controller,
              child: OnTapScaleAndFade(
                  onTap: () {
                    element.value.controller.showFlyout(builder: (context) {
                      return f.MenuFlyout(
                        items: [
                          if (!archive || ClientDatabase().isAdmin())
                            f.MenuFlyoutItem(
                                text: const Text('mod').tr(),
                                onPressed: () {
                                  Navigator.of(current).pop();
                                  if (archive) {
                                    showDialogChauffeur(element.value);
                                  } else {
                                    modifyChauffeur(element.value);
                                  }
                                }),
                          if (ClientDatabase().isAdmin() && archive)
                            f.MenuFlyoutItem(
                                text: const Text('delete').tr(),
                                onPressed: () {
                                  showDeleteConfirmation(element.value);
                                }),
                          const f.MenuFlyoutSeparator(),
                          f.MenuFlyoutItem(
                              text: const Text('nouvdocument').tr(),
                              onPressed: () {
                                Future.delayed(const Duration(milliseconds: 50))
                                    .then((value) => f.showDialog(
                                        context: current,
                                        barrierDismissible: true,
                                        builder: (context) {
                                          return f.ContentDialog(
                                            title: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('nouvdocument').tr(),
                                                f.Button(child:
                                                const Icon(f.FluentIcons
                                                    .cancel),
                                                    onPressed: ()
                                                    {Navigator.of
                                                      (context).pop();}),
                                              ],
                                            ),
                                            constraints: BoxConstraints
                                                .loose(Size(420.px,450.px)),

                                            content: CDocumentForm(
                                                  c: element.value,
                                                ),
                                          );
                                        }));
                              }),
                          if (!archive || ClientDatabase().isAdmin())
                            f.MenuFlyoutSubItem(
                              text: const Text('disponibilite').tr(),
                              items: (BuildContext context) {
                                return [
                                  f.MenuFlyoutItem(
                                    text: const Text('disponible').tr(),
                                    onPressed: () {
                                      uploadEtat(element.value, 0);
                                    },
                                    selected: element.value.etat == 0,
                                  ),
                                  f.MenuFlyoutItem(
                                    text: const Text('mission').tr(),
                                    onPressed: () {
                                      uploadEtat(element.value, 1);
                                    },
                                    selected: element.value.etat == 1,
                                  ),
                                  f.MenuFlyoutItem(
                                    text: const Text('absent').tr(),
                                    onPressed: () {
                                      uploadEtat(element.value, 2);
                                    },
                                    selected: element.value.etat == 2,
                                  ),
                                  if (ClientDatabase().isAdmin())
                                    f.MenuFlyoutItem(
                                      text: const Text('quitteentre').tr(),
                                      onPressed: () {
                                        uploadEtat(element.value, 3);
                                      },
                                      selected: element.value.etat == 3,
                                    ),
                                ];
                              },
                            ),
                        ],
                      );
                    });
                  },
                  child: const Icon(Icons.more_vert_sharp)),
            )
          : const Text('')),
    ];
  }

  @override
  Future<void> addToActivity(c) async {
    await ClientDatabase()
        .ajoutActivity(18, c.id, docName: '${c.name} ${c.prenom}');
  }

  void modifyChauffeur(Conducteur conducteur) {
    late f.Tab tab;
    tab = f.Tab(
      key: UniqueKey(),
      text: Text(
          '${"mod".tr()} ${'chauffeur'.tr().toLowerCase()} ${conducteur.name}'),
      semanticLabel: '${'mod'.tr()} ${conducteur.name} ${conducteur.prenom}',
      icon: const Icon(f.FluentIcons.edit),
      body: ChauffeurForm(
        chauf: conducteur,
      ),
      onClosed: () {
        ChauffeurTabsState.tabs.remove(tab);

        if (ChauffeurTabsState.currentIndex.value > 0) {
          ChauffeurTabsState.currentIndex.value--;
        }
      },
    );
    final index = ChauffeurTabsState.tabs.length + 1;
    ChauffeurTabsState.tabs.add(tab);
    ChauffeurTabsState.currentIndex.value = index - 1;
  }

  void showDialogChauffeur(Conducteur conducteur) {
    Future.delayed(const Duration(milliseconds: 50))
        .then((value) => f.showDialog(
            context: current,
            barrierDismissible: true,
            builder: (c) {
              return f.ContentDialog(
                title: f.Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${"mod".tr()} ${'chauffeur'.tr().toLowerCase()} ${conducteur.name}'),
                    f.Button(child:
                    const Icon(f.FluentIcons
                        .cancel),
                        onPressed: ()
                        {Navigator.of
                          (current).pop();}),
                  ],
                ),
                constraints: BoxConstraints.loose(f.Size(550.px, 520.px)),
                content: ChauffeurForm(
                  chauf: conducteur,
                ),

              );
            }));
  }

  Future<void> uploadEtat(Conducteur c, int etat) async {
    if (etat != c.etat) {
      String etatID = DateTime.now()
          .difference(ClientDatabase.ref)
          .inMilliseconds
          .abs()
          .toString();
      DisponibiliteChauffeur disp = DisponibiliteChauffeur(
          id: etatID,
          type: etat,
          createdBy: ClientDatabase.me.value?.id,
          chauffeur: c.id,
          chauffeurNom: '${c.name} ${c.prenom}');
      await ClientDatabase.database!
          .createDocument(
              databaseId: databaseId,
              collectionId: chaufDispID,
              documentId: etatID,
              data: disp.toJson())
          .then((value) async {
        await ClientDatabase.database!.updateDocument(
            databaseId: databaseId,
            collectionId: chauffeurid,
            documentId: c.id,
            data: {
              'etatactuel': etatID,
              'etat': etat,
            }).then((value) {
          if (etat == 3) {
            ClientDatabase()
                .ajoutActivity(19, c.id, docName: '${c.name} ${c.prenom}');
          } else {
            ClientDatabase()
                .ajoutActivity(21, c.id, docName: '${c.name} ${c.prenom}');
          }
          displayMessageDone();
          changeEtat(c, disp);
        }).onError((error, stackTrace) {
          displayMessageError();
        });
      }).onError((error, stackTrace) {
        displayMessageError();
      });
    }
  }

  void changeEtat(Conducteur c, DisponibiliteChauffeur e) {
    for (int i = 0; i < data.length; i++) {
      if (data[i].value.id == c.id) {
        data[i].value.etat = e.type;
        data[i].value.etatactuel = e.id;
        refreshDatasource();
        break;
      }
    }
  }

  void displayMessageDone() {
    f.displayInfoBar(current, builder: (co, s) {
      return f.InfoBar(
        severity: f.InfoBarSeverity.success,
        title: const Text('etatmodif').tr(),
      );
    });
  }

  void displayMessageError() {
    f.displayInfoBar(current, builder: (co, s) {
      return f.InfoBar(
        severity: f.InfoBarSeverity.error,
        title: const Text('erreur').tr(),
      );
    });
  }
}
