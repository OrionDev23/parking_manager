
import 'package:appwrite/models.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/serializables/conducteur.dart';
import 'package:parc_oto/serializables/disponibilite_chauffeur.dart';
import 'package:parc_oto/widgets/zone_box.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../theme.dart';

int chaufCounter = 0;

class ChauffeurForm extends StatefulWidget {
  final Conducteur? chauf;
  const ChauffeurForm({super.key, this.chauf,});

  @override
  State<ChauffeurForm> createState() => ChauffeurFormState();
}

class ChauffeurFormState extends State<ChauffeurForm> {
  bool uploading = false;
  double progress = 0;
  String? chaufID;

  int ? etat;

  TextEditingController nom = TextEditingController();
  TextEditingController prenom = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController telephone = TextEditingController();
  TextEditingController adresse = TextEditingController();
  DateTime? birthDay;
  @override
  void initState() {
    initValues();
    super.initState();
  }

  void initValues() {
    if (widget.chauf != null) {
      chaufID=widget.chauf!.id;
      etat=widget.chauf!.etat;
      etatID=widget.chauf!.etatactuel;
      nom.text = widget.chauf!.name;
      prenom.text = widget.chauf!.prenom;
      email.text = widget.chauf!.email ?? '';
      telephone.text = widget.chauf!.telephone ?? '';
      adresse.text = widget.chauf!.adresse ?? '';
      birthDay=widget.chauf!.dateNaissance;
    }
  }

  bool? selected = false;


  @override
  Widget build(BuildContext context) {

    var appTheme=context.watch<AppTheme>();
    if (uploading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Sauvegarde en cours ...'),
            smallSpace,
            ProgressBar(
              value: progress,
            ),
          ],
        ),
      );
    }
    return Container(
      color: appTheme.backGroundColor,
      child: Column(
        children: [
          Container(
            color: appTheme.backGroundColor,
            child: Column(
              children: [
                SizedBox(
                  height: 55.h,
                  width: 40.w,
                  child: Column(
                    children: [
                      Flexible(
                        child: ZoneBox(
                          label: 'fullname'.tr(),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              children: [
                                Flexible(
                                    child: TextBox(
                                      controller: nom,
                                      placeholder: 'Nom',
                                      style: appTheme.writingStyle,
                                      placeholderStyle: placeStyle,
                                      cursorColor: appTheme.color.darker,
                                      decoration: BoxDecoration(
                                        color: appTheme.fillColor,
                                      ),
                                      onChanged: (s){
                                        checkChanges();
                                      },
                                    )),
                                smallSpace,
                                Flexible(
                                    child: TextBox(
                                      controller: prenom,
                                      placeholder: 'Prénom',
                                      style: appTheme.writingStyle,
                                      placeholderStyle: placeStyle,
                                      cursorColor: appTheme.color.darker,
                                      decoration: BoxDecoration(
                                        color: appTheme.fillColor,
                                      ),
                                      onChanged: (s){
                                        checkChanges();
                                      },
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      smallSpace,
                      Flexible(
                        child: ZoneBox(label: 'birthday'.tr(),
                            child:
                            Container(height: 5.h,
                              padding: const EdgeInsets.all(10),
                              child: DatePicker(selected: birthDay,onChanged: (d){
                                setState(() {
                                  birthDay=d;
                                });
                                checkChanges();
                              },),)
                        ),
                      ),
                      smallSpace,
                      Flexible(
                        flex: 2,
                        child: ZoneBox(
                          label:'contact'.tr(),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 250,
                                      child: TextBox(
                                        controller: email,
                                        placeholder: 'email'.tr(),
                                        style: appTheme.writingStyle,
                                        placeholderStyle: placeStyle,
                                        cursorColor: appTheme.color.darker,
                                        decoration: BoxDecoration(
                                          color: appTheme.fillColor,
                                        ),
                                        onChanged: (s){
                                          checkChanges();
                                        },
                                      ),
                                    ),
                                    smallSpace,
                                    SizedBox(
                                        width: 187,
                                        child: TextBox(
                                          controller: telephone,
                                          placeholder: 'telephone'.tr(),
                                          style: appTheme.writingStyle,
                                          placeholderStyle: placeStyle,
                                          cursorColor: appTheme.color.darker,
                                          decoration: BoxDecoration(
                                            color: appTheme.fillColor,
                                          ),
                                          onChanged: (s){
                                            checkChanges();
                                          },
                                        )),
                                  ],
                                ),
                                smallSpace,
                                Flexible(child: TextBox(
                                  controller: adresse,
                                  placeholder: 'adresse'.tr(),
                                  maxLines: 3,
                                  style: appTheme.writingStyle,
                                  placeholderStyle: placeStyle,
                                  cursorColor: appTheme.color.darker,
                                  decoration: BoxDecoration(
                                    color: appTheme.fillColor,
                                  ),
                                  onChanged: (s){
                                    checkChanges();
                                  },
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      smallSpace,
                      Flexible(
                        child: ZoneBox(
                          label: 'disponibilite'.tr(),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: DropDownButton(
                              title: Text(ClientDatabase.getEtat(etat)).tr(),
                              placement: FlyoutPlacementMode.bottomLeft,
                              items: [
                                MenuFlyoutItem(text: const Text('disponible').tr(), onPressed: () {
                                  setState(() {
                                    etat=0;
                                    checkChanges();
                                  });
                                },
                                    selected:etat==0,
                                ),
                                const MenuFlyoutSeparator(),
                                MenuFlyoutItem(text: const Text('mission').tr(), onPressed: () {
                                  setState(() {
                                    etat=1;
                                    checkChanges();
                                  });
                                },
                                  selected:etat==1,
                                ),
                                const MenuFlyoutSeparator(),
                                MenuFlyoutItem(text: const Text('absent').tr(), onPressed: () {
                                  setState(() {
                                    etat=2;
                                    checkChanges();
                                  });
                                },
                                  selected:etat==2,),
                                const MenuFlyoutSeparator(),
                                MenuFlyoutItem(text: const Text('quitteentre').tr(), onPressed: () {
                                  setState(() {
                                    etat=3;
                                    checkChanges();
                                  });
                                },
                                  selected:etat==3,),
                              ],

                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            width: 40.w,

            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: changes && !uploading ? upload : null,
                  child: const Text('confirmer').tr(),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
  bool changes=false;

  void checkChanges(){
    if(widget.chauf!=null){
      if(nom.text==widget.chauf!.name && prenom.text==widget.chauf!.prenom
      && birthDay==widget.chauf!.dateNaissance && ((disp==null && etat==widget.chauf!.etat)|| (disp!=null && disp!.type ==etat) )
      && adresse.text==widget.chauf!.adresse && telephone.text==widget.chauf!.telephone
      && email.text==widget.chauf!.email
      ){
        if(changes){
          setState(() {
            changes=false;
          });
        }
      }
      else{
        if(!changes){
          setState(() {
            changes=true;
          });
        }
      }
    }
    else{
      if(!changes){
        setState(() {
          changes=true;
        });
      }
    }
  }

  void upload() async {
    if (nom.value.text.isEmpty || prenom.text.isEmpty) {
      showMessage('nomprenreq', 'erreur');
      return;
    }
    if (!uploading) {
      setState(() {
        uploading = true;
        progress = 0;
      });
      chaufID ??= DateTime.now()
          .difference(ClientDatabase.ref)
          .inMilliseconds
          .toString();
      etatID??=DateTime.now().difference(ClientDatabase.ref).inMilliseconds.abs().toString();
      try {
        await uploadEtat();
        setState(() {
          progress = 50;
        });
        await uploadChauffeur();

        setState(() {
          progress = 90;
          changes=false;
        });
        if (widget.chauf == null) {
          showMessage('chaufsuccess', "ok");
        } else {
          showMessage('chaufupdate', "ok");
        }
      } catch (e) {
        setState(() {
          uploading = false;
          showMessage('errupld',
              'erreur');
        });
      }
      setState(() {
        uploading = false;
        progress = 100;
      });
    }
  }


  DisponibiliteChauffeur? disp;
  String? etatID;

  Future<Document> uploadChauffeur() async {

    var dateFormat=DateFormat('y/MM/dd','fr');
    Conducteur chauf = Conducteur(
        id:chaufID!,
        name: nom.value.text,
        prenom: prenom.value.text,
        email: email.value.text,
        telephone: telephone.value.text,
        adresse: adresse.value.text,
        dateNaissance: birthDay,
        etat: etat,
        etatactuel: etatID,
        search: '${dateFormat.format(birthDay??DateTime.now())} '
            '${nom.value.text} ${prenom.value.text} ${email.value.text} '
            '${telephone.value.text} ${adresse.value.text} $chaufID ${ClientDatabase.getEtat(etat)}',
        );
    if(widget.chauf!=null){
      return await ClientDatabase.database!.updateDocument(
          databaseId: databaseId,
          collectionId: chauffeurid,
          documentId: chaufID!,
          data: chauf.toJson());
    }
    else{
      return await ClientDatabase.database!.createDocument(
          databaseId: databaseId,
          collectionId: chauffeurid,
          documentId: chaufID!,
          data: chauf.toJson());
    }

  }

  Future<Document?> uploadEtat() async{
    if(disp==null || disp!.type!=etat  ){
      if(disp?.id==etatID || etatID==null || etatID==widget.chauf?.etatactuel){
        etatID=DateTime.now().difference(ClientDatabase.ref).inMilliseconds.abs().toString();
      }
      disp=DisponibiliteChauffeur(id: etatID!, type: etat??0,createdBy: ClientDatabase.me.value?.id,chauffeur: chaufID!,chauffeurNom: '${nom.text} ${prenom.text}');
      return await ClientDatabase.database!.createDocument(
          databaseId: databaseId,
          collectionId: chaufDispID,
          documentId: etatID!,
          data: disp!.toJson()
      );
    }
    else{
      return null;
    }

  }


  void showMessage(String message, String title) {
    showDialog<String>(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(title).tr(),
        content: Text(
          message,
        ).tr(),
        actions: [
          Button(
            child: const Text('OK').tr(),
            onPressed: () async {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
