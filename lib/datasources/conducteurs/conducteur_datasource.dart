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
import '../../widgets/on_tap_scale.dart';

class ConducteurDataSource extends ParcOtoDatasource<Conducteur>{
  final bool archive;
  ConducteurDataSource({this.archive=false,required super.collectionID, super.selectC,super.searchKey,super.appTheme,super.filters,required super.current}){
    repo=ConducteurWebService(data, collectionID, 1,archive: archive);
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
    return
      [
        DataCell(SelectableText(
          '${element.value.name} ${element.value.prenom}',
          style: tstyle,
        )),
        DataCell(SelectableText(
          element.value.email??'',
          style: tstyle,
        )),
        DataCell(SelectableText(
          element.value.telephone ??'',
          style: tstyle,
        )),
        DataCell(SelectableText(
          ClientDatabase.getEtat(element.value.etat).tr(),
          style: tstyle,
        )),
        DataCell(SelectableText(
          element.value.updatedAt==null?'':
          dateFormat.format(element.value.updatedAt!),
          style: tstyle,
        )),
        DataCell(
        ClientDatabase().isAdmin() || ClientDatabase().isManager()
            ?f.FlyoutTarget(
          controller: element.value.controller,
          child: OnTapScaleAndFade(
              onTap: (){
                element.value.controller.showFlyout(builder: (context){
                  return f.MenuFlyout(
                    items: [
                      if(!archive || ClientDatabase().isAdmin())
                        f.MenuFlyoutItem(
                          text: const Text('mod').tr(),
                          onPressed: (){
                            Navigator.of(current).pop();
                            if(archive){
                              showDialogChauffeur(element.value);
                            }
                            else{
                              modifyChauffeur(element.value);
                            }
                          }
                      ),
                      if(ClientDatabase().isAdmin() && archive)
                        f.MenuFlyoutItem(
                          text: const Text('delete').tr(),
                          onPressed: (){
                            showDeleteConfirmation(element.value);
                          }
                      ),
                      const f.MenuFlyoutSeparator(),
                      f.MenuFlyoutItem(
                          text: const Text('nouvdocument').tr(),
                          onPressed: (){
                            Future.delayed(const Duration(milliseconds: 50)).then((value) =>
                                f.showDialog(context: current,
                                barrierDismissible: true,
                                builder: (context){
                                  return  CDocumentForm(
                                    c: element.value,
                                  );
                                }));
                          }
                      ),
                      if(!archive || ClientDatabase().isAdmin())
                      f.MenuFlyoutSubItem(
                        text: const Text('disponibilite').tr(),
                        items: (BuildContext context) {
                          return [
                            f.MenuFlyoutItem(
                                text: const Text('disponible').tr(),
                                onPressed: (){

                                }
                            ),
                            f.MenuFlyoutItem(
                                text: const Text('mission').tr(),
                                onPressed: (){

                                }
                            ),
                            f.MenuFlyoutItem(
                                text: const Text('absent').tr(),
                                onPressed: (){

                                }
                            ),
                            if(ClientDatabase().isAdmin())
                              f.MenuFlyoutItem(
                                text: const Text('quitteentre').tr(),
                                onPressed: (){

                                }
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
        :const Text('')
        ),
    ];
  }
  @override
  Future<void> addToActivity(c) async{
    await ClientDatabase().ajoutActivity(18, c.id,docName: '${c.name} ${c.prenom}');
  }

void modifyChauffeur(Conducteur conducteur){
  late f.Tab tab;
  tab = f.Tab(
    key: UniqueKey(),
    text: Text('${"mod".tr()} ${'chauffeur'.tr().toLowerCase()} ${conducteur.name}'),
    semanticLabel: '${'mod'.tr()} ${conducteur.name} ${conducteur.prenom}',
    icon: const Icon(f.FluentIcons.edit),
    body: ChauffeurForm(chauf: conducteur,),
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

void showDialogChauffeur(Conducteur conducteur){
  Future.delayed(const Duration(milliseconds: 50)).then((value) =>
  f.showDialog(
      context: current,
      barrierDismissible: true,
      builder: (c){
    return f.ContentDialog(
        title: Text('${"mod".tr()} ${'chauffeur'.tr().toLowerCase()} ${conducteur.name}'),
  constraints: BoxConstraints.loose(f.Size(
  800.px,550.px
  )),
      content: ChauffeurForm(chauf: conducteur,),
    );
      }));
}

}