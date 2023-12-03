import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/serializables/entreprise.dart';
import 'package:parc_oto/theme.dart';
import 'package:parc_oto/widgets/zone_box.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class MyEntreprise extends StatefulWidget {

  const MyEntreprise({super.key});

  @override
  State<MyEntreprise> createState() => _MyEntrepriseState();
}

class _MyEntrepriseState extends State<MyEntreprise> {

  TextEditingController nom = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController telephone = TextEditingController();
  TextEditingController adresse = TextEditingController();
  TextEditingController nif = TextEditingController();
  TextEditingController nis = TextEditingController();
  TextEditingController descr = TextEditingController();
  TextEditingController art = TextEditingController();
  TextEditingController rc = TextEditingController();

  static Entreprise? p;

  bool changes=false;

  void checkChanges(){
    if(p!=null){
      if(nom.text==p!.nom && adresse.text==p!.adresse
          && telephone.text==p!.telephone && nif.text==p!.nif
          && nis.text==p!.nis && art.text==p!.art
          && rc.text==p!.rc && descr.text==p!.description
          && email.text==p!.email
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

  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return Container(
      color: appTheme.backGroundColor,
      child: Column(
        children: [
          SizedBox(
            height: 80.h,
            width: 40.w,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  flex: 4,
                  child: ZoneBox(
                    label: 'logo'.tr(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          maxRadius: 50,
                          backgroundColor: appTheme.color.lighter,
                        ),
                        smallSpace,
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(icon: const Icon(FluentIcons.file_image), onPressed: (){}),
                            smallSpace,
                            IconButton(icon: const Icon(FluentIcons.refresh), onPressed: (){}),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  flex:2,
                  child: ZoneBox(
                    label: 'fullname'.tr(),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextBox(
                        controller: nom,
                        placeholder: 'fullname'.tr(),
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
                  ),
                ),
                smallSpace,
                Flexible(
                  flex: 2,
                  child: ZoneBox(
                    label: 'descr'.tr(),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextBox(
                        controller: descr,
                        placeholder: 'descr'.tr(),
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
                  ),
                ),
                smallSpace,
                Flexible(
                  flex: 4,
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
                  flex: 3,
                  child: ZoneBox(
                    label: 'legalinfo'.tr(),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Flexible(
                                    child: TextBox(
                                      controller: nif,
                                      placeholder: 'NIF',
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
                                      controller: nis,
                                      placeholder: 'NIS',
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
                          smallSpace,
                          Flexible(
                            child: Row(
                              children: [
                                Flexible(
                                    child: TextBox(
                                      controller: rc,
                                      placeholder: 'RC',
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
                                      controller: art,
                                      placeholder: 'ART',
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
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bigSpace,
          SizedBox(
            width: 40.w,
            child: Row(mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Button(child: const Text('refresh').tr(), onPressed: (){}),
              smallSpace,
              FilledButton(child: const Text('save').tr(), onPressed: (){}),
            ],),
          ),
        ],
      ),
    );
  }
}
