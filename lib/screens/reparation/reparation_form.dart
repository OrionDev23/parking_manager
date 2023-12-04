import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/entreprise.dart';
import 'package:parc_oto/screens/prestataire/prestataire_table.dart';
import 'package:parc_oto/serializables/prestataire.dart';
import 'package:parc_oto/serializables/vehicle.dart';
import 'package:parc_oto/theme.dart';
import 'package:parc_oto/widgets/on_tap_scale.dart';
import 'package:parc_oto/widgets/zone_box.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class ReparationForm extends StatefulWidget {
  const ReparationForm({super.key});

  @override
  State<ReparationForm> createState() => _ReparationFormState();
}

class _ReparationFormState extends State<ReparationForm> {
  bool r1 = false;
  bool r2 = false;
  bool r3 = false;
  bool r4 = false;
  bool r5 = false;
  bool r6 = false;
  bool r7 = false;
  bool r8 = false;
  bool r9 = false;
  bool r10 = false;
  bool r11 = false;
  bool r12 = false;
  bool r13 = false;
  bool r14 = false;
  bool r15 = false;
  bool r16 = false;
  bool r17 = false;
  bool r18 = false;

  double avdp = 100;
  double avgp = 100;
  double ardp = 100;
  double argp = 100;

  bool parAvf = false;
  bool parAvc = false;
  bool parAve = false;
  bool parArf = false;
  bool parArc = false;
  bool parAre = false;

  bool phareG = false;
  bool phareD = false;

  bool feuAVD = false;
  bool feuAVG = false;
  bool feuARD = false;
  bool feuARG = false;

  bool aileAVD=false;
  bool aileAVG=false;
  bool aileARD=false;
  bool aileARG=false;


  bool parAV=false;
  bool parAR=false;

  bool porteAVD=false;
  bool porteAVG=false;
  bool porteARD=false;
  bool porteARG=false;

  bool toit=false;

  bool capot=false;

  bool coffre=false;

  bool siegeAVD=false;
  bool siegeAVG=false;
  bool siegeARD=false;
  bool siegeARG=false;
  bool calandre=false;
 final hstyle=TextStyle(
   fontSize: 14.sp,
   fontWeight: FontWeight.bold,
 );
 final bstyle=TextStyle(
   fontSize: 12.sp,
   fontWeight: FontWeight.bold,
 );
  final tstyle = TextStyle(fontSize: 10.sp);

  TextEditingController numOrdre=TextEditingController();
  DateTime selectedDate=DateTime.now();

  Prestataire? selectedPrest;
  Vehicle? selectedVehicle;
  TextEditingController marque=TextEditingController();
  TextEditingController type=TextEditingController();
  TextEditingController numSerie=TextEditingController();
  TextEditingController matricule=TextEditingController();
  TextEditingController km=TextEditingController();
  TextEditingController couleur=TextEditingController();
  DateTime anneeUtil=DateTime.now();
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: appTheme.backGroundColor,
        border: Border.all(),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          if(MyEntrepriseState.p!=null)
          Row(

            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.file(File('mylogo.png'),width: 80.px,height: 80.px,),
             bigSpace,
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(MyEntrepriseState.p!.nom,style: bstyle,),
                  Text(MyEntrepriseState.p!.adresse,style: bstyle,),
                ],
              ),
              const Spacer(),
              Text('ORDRE DE REPARATION',style: hstyle,),
              smallSpace,
              Container(
                width: 200.px,
                height: 40.px,
                decoration: BoxDecoration(
                  border: Border.all(),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text('num',style: bstyle,).tr(),
                      smallSpace,
                      Flexible(
                        child: TextBox(
                          controller: numOrdre,
                          placeholder: 'num'.tr(),
                          placeholderStyle: placeStyle,
                          style: appTheme.writingStyle,
                          cursorColor: appTheme.color.darker,
                          decoration: BoxDecoration(
                            color: appTheme.fillColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('date',style: bstyle,).tr(),
              smallSpace,
              SizedBox(
                width: 200.px,
                height: 30.px,
                child: DatePicker(selected: selectedDate,
                onChanged: (s){
                  setState(() {
                    selectedDate=s;
                  });
                },),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 250.px,
                height: 50.px,
                child: ListTile(
                  leading: Text('prestataire',style: bstyle,).tr(),
                  title: Text(selectedPrest?.nom??''),
                  onPressed: ()async{
                    selectedPrest=await showDialog<Prestataire?>(context: context, builder: (c,)=>const PrestataireTable(selectD: true,));
                    setState(() {

                    });
                    },
                ),
              ),
            ],
          ),
          SizedBox(
            height: 100.px,
            child: Table(
              border: TableBorder.all(),
              columnWidths: {
                0:FixedColumnWidth(80.px),
                1:FixedColumnWidth(80.px),
                2:FixedColumnWidth(80.px),
                3:FixedColumnWidth(80.px),
              },
              children: [
                TableRow(
                  children: [
                    TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            children: [
                              Text('marque',style: tstyle,).tr(),
                              smallSpace,
                              Flexible(
                                child: TextBox(
                                  controller:marque,
                                  placeholder: 'marque'.tr(),
                                  style: appTheme.writingStyle,
                                  decoration: BoxDecoration(
                                    color: appTheme.fillColor,
                                  ),
                                  cursorColor: appTheme.color.darker,
                                  placeholderStyle: placeStyle,
                                ),
                              ),
                            ],
                          ),

                        )),
                    TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            children: [
                              Text('type',style: tstyle,).tr(),
                              smallSpace,
                              Flexible(
                                child: TextBox(
                                  controller:type,
                                  placeholder: 'type'.tr(),
                                  style: appTheme.writingStyle,
                                  decoration: BoxDecoration(
                                    color: appTheme.fillColor,
                                  ),
                                  cursorColor: appTheme.color.darker,
                                  placeholderStyle: placeStyle,
                                ),
                              ),
                            ],
                          ),

                        )),
                    TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            children: [
                              Text('numerserie',style: tstyle,).tr(),
                              smallSpace,
                              Flexible(
                                child: TextBox(
                                  controller:numSerie,
                                  placeholder: 'numerserie'.tr(),
                                  style: appTheme.writingStyle,
                                  decoration: BoxDecoration(
                                    color: appTheme.fillColor,
                                  ),
                                  cursorColor: appTheme.color.darker,
                                  placeholderStyle: placeStyle,
                                ),
                              ),
                            ],
                          ),

                        )),
                    TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            children: [
                              Text('matricule',style: tstyle,).tr(),
                              smallSpace,
                              Flexible(
                                child: TextBox(
                                  controller:matricule,
                                  placeholder: 'matricule'.tr(),
                                  style: appTheme.writingStyle,
                                  decoration: BoxDecoration(
                                    color: appTheme.fillColor,
                                  ),
                                  cursorColor: appTheme.color.darker,
                                  placeholderStyle: placeStyle,
                                ),
                              ),
                            ],
                          ),

                        )),
                  ]
                ),
                TableRow(
                  children: [
                    TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            children: [
                              Text('Km',style: tstyle,).tr(),
                              smallSpace,
                              Flexible(
                                child: TextBox(
                                  controller:km,
                                  placeholder: 'Km'.tr(),
                                  style: appTheme.writingStyle,
                                  decoration: BoxDecoration(
                                    color: appTheme.fillColor,
                                  ),
                                  cursorColor: appTheme.color.darker,
                                  placeholderStyle: placeStyle,
                                ),
                              ),
                            ],
                          ),

                        )),
                    TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            children: [
                              Text('type',style: tstyle,).tr(),
                              smallSpace,
                              Flexible(child: Container()),
                            ],
                          ),

                        )),
                    TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            children: [
                              Text('couleur',style: tstyle,).tr(),
                              smallSpace,
                              Flexible(
                                child: TextBox(
                                  controller:couleur,
                                  placeholder: 'couleur'.tr(),
                                  style: appTheme.writingStyle,
                                  decoration: BoxDecoration(
                                    color: appTheme.fillColor,
                                  ),
                                  cursorColor: appTheme.color.darker,
                                  placeholderStyle: placeStyle,
                                ),
                              ),
                            ],
                          ),

                        )),
                    TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            children: [
                              Text('anneeutil',style: tstyle,).tr(),
                              smallSpace,
                              Flexible(child: DatePicker(selected: anneeUtil,showDay: false,showMonth: false,))
                            ],
                          ),

                        )),
                  ]
                ),
              ],
            ),
          ),
          bigSpace,
          Container(
            height: 7.h,
            width: 80.w,
            decoration: BoxDecoration(
              color: appTheme.color.lightest,
              border: Border.all(),
            ),
            padding: const EdgeInsets.all(10),
            child: Text('ETAT DU VEHICULE',textAlign: TextAlign.center,style: hstyle,),
          ),
          etatVehicule(appTheme),
          Container(
            height: 7.h,
            width: 80.w,
            decoration: BoxDecoration(
              color: appTheme.color.lightest,
              border: Border.all(),
            ),
            padding: const EdgeInsets.all(10),
            child: Text('ENTRETIEN DU VEHICULE',textAlign: TextAlign.center,style: hstyle,),
          ),
          entretienWidgets(appTheme),
        ],
      ),
    );
  }




  Widget etatVehicule(AppTheme appTheme){
    return  Container(
      decoration:BoxDecoration(
        border: Border.all(),
      ),
      width: 80.w,
      height: 45.h,
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          topTable(appTheme),
          bigSpace,
          bigSpace,
          bigSpace,
          bigSpace,
          bigSpace,
          vehicleDamage(appTheme),
        ],
      ),
    );
  }
  Widget topTable(AppTheme appTheme){
    return SizedBox(
      width: 40.w,
      height: 45.h,
      child: Table(
        border: TableBorder.all(),
        columnWidths: {
          0:FixedColumnWidth(6.w),
          1: FixedColumnWidth(6.w),
          2: FixedColumnWidth(4.w),
          3: FixedColumnWidth(4.w),
          4:  FixedColumnWidth(11.w),
        },
        children: [
          ...getTopRow(appTheme),
          ...getBottomRows(appTheme),

        ],
      ),
    );
  }

  List<TableRow> getTopRow(AppTheme appTheme){
    return [
      TableRow(children: [

        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('PARE-BRISE AV', style: tstyle),
            )),
        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('PARE-BRISE AR', style: tstyle),
            )),
        TableCell(
            child:Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('PHARE', style: tstyle),
            )),
        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('FEUX', style: tstyle),
            )),
        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('PNEUMATIQUE', style: tstyle),
            )),
      ]),
      TableRow(children: [

        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'FELURE',
                    style: tstyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: parAvf,
                      onChanged: (s) {
                        if (s == true) {
                          parAvf = s!;
                          parAvc = false;
                          parAve = false;
                        } else if (s == false) {
                          parAvf = false;
                        }
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'FELURE',
                    style: tstyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: parArf,
                      onChanged: (s) {
                        if (s == true) {
                          parArf = s!;
                          parArc = false;
                          parAre = false;
                        } else if (s == false) {
                          parArf = false;
                        }
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'D',
                    style: tstyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: phareD,
                      onChanged: (s) {
                        if (s == true) {
                          phareD = s!;
                        } else if (s == false) {
                          phareD = false;
                        }
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'AVD',
                    style: tstyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: feuAVD,
                      onChanged: (s) {
                        feuAVD = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'AVD',
                    style: tstyle,
                  ),
                  smallSpace,
                  smallSpace,
                  smallSpace,
                  SizedBox(
                    width: 5.w,
                    child: Slider(
                      value: avdp,
                      onChanged: (s) {
                        avdp = s;
                        setState(() {});
                      },
                      divisions: 100,
                      label: 'AVD',
                    ),
                  ),
                  smallSpace,
                  smallSpace,
                  smallSpace,
                  Text(
                    '${avdp.ceil()} %',
                    style: tstyle,
                  ),
                ],
              ),
            )),
      ]),
      TableRow(children: [

        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'CASSURE',
                    style: tstyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: parAvc,
                      onChanged: (s) {
                        if (s == true) {
                          parAvf = false;
                          parAvc = s!;
                          parAve = false;
                        } else if (s == false) {
                          parAvc = false;
                        }
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'CASSURE',
                    style: tstyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: parArc,
                      onChanged: (s) {
                        if (s == true) {
                          parArc = s!;
                          parArf = false;
                          parAre = false;
                        } else if (s == false) {
                          parArc = false;
                        }
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'G',
                    style: tstyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: phareG,
                      onChanged: (s) {
                        if (s == true) {
                          phareG = s!;
                        } else if (s == false) {
                          phareG = false;
                        }
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'AVG',
                    style: tstyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: feuAVG,
                      onChanged: (s) {
                        feuAVG = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'AVG',
                    style: tstyle,
                  ),
                  smallSpace,
                  smallSpace,
                  smallSpace,
                  SizedBox(
                    width: 5.w,
                    child: Slider(
                      value: avgp,
                      onChanged: (s) {
                        avgp = s;
                        setState(() {});
                      },
                      divisions: 100,
                      label: 'AVG',
                    ),
                  ),
                  smallSpace,
                  smallSpace,
                  smallSpace,
                  Text(
                    '${avgp.ceil()} %',
                    style: tstyle,
                  ),
                ],
              ),
            )),
      ]),
      TableRow(children: [

        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ECLAT',
                    style: tstyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: parAve,
                      onChanged: (s) {
                        if (s == true) {
                          parAve = s!;
                          parAvc = false;
                          parAvf = false;
                        } else if (s == false) {
                          parAve = false;
                        }
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ECLAT',
                    style: tstyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: parAre,
                      onChanged: (s) {
                        if (s == true) {
                          parAre = s!;
                          parArf = false;
                          parArc = false;
                        } else if (s == false) {
                          parAre = false;
                        }
                        setState(() {});
                      })
                ],
              ),
            )),
        const TableCell(
          child: SizedBox(),
        ),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ARD',
                    style: tstyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: feuARD,
                      onChanged: (s) {
                        feuARD = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ARD',
                    style: tstyle,
                  ),
                  smallSpace,
                  smallSpace,
                  smallSpace,
                  SizedBox(
                    width: 5.w,
                    child: Slider(
                      value: ardp,
                      onChanged: (s) {
                        ardp = s;
                        setState(() {});
                      },
                      divisions: 100,
                      label: 'ARD',
                    ),
                  ),
                  smallSpace,
                  smallSpace,
                  smallSpace,
                  Text(
                    '${ardp.ceil()} %',
                    style: tstyle,
                  ),
                ],
              ),
            )),
      ]),
      TableRow(children: [

        const TableCell(child: SizedBox()),
        const TableCell(child: SizedBox()),
        const TableCell(
          child: SizedBox(),
        ),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ARG',
                    style: tstyle,
                  ),
                  const Spacer(),
                  Checkbox(
                      checked: feuARG,
                      onChanged: (s) {
                        feuARG = s ?? false;
                        setState(() {});
                      })
                ],
              ),
            )),
        TableCell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    'ARG',
                    style: tstyle,
                  ),
                  smallSpace,
                  smallSpace,
                  smallSpace,
                  SizedBox(
                    width: 5.w,
                    child: Slider(
                      value: argp,
                      onChanged: (s) {
                        argp = s;
                        setState(() {});
                      },
                      divisions: 100,
                      label: 'ARG',
                    ),
                  ),
                  smallSpace,
                  smallSpace,
                  smallSpace,
                  Text(
                    '${ardp.ceil()} %',
                    style: tstyle,
                  ),
                ],
              ),
            )),
      ]),
    ];
  }

  List<TableRow> getBottomRows(AppTheme appTheme){
    return [
      TableRow(children: [
        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('AILE', style: tstyle),
            )),
        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('PARE-CHOC', style: tstyle),
            )),
        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('PORTE', style: tstyle),
            )),
        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('SIEGE', style: tstyle),
            )),
        TableCell(
            child: Container(
              color: appTheme.color.lightest,
              padding: const EdgeInsets.all(5.0),
              child: Text('AUTRE', style: tstyle),
            )),
      ]),
      TableRow(
          children:[
            TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text(
                        'AVD',
                        style: tstyle,
                      ),
                      const Spacer(),
                      Checkbox(
                          checked: aileAVD,
                          onChanged: (s) {
                            aileAVD = s ?? false;
                            setState(() {});
                          })
                    ],
                  ),
                )),
            TableCell(child: Padding(padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Text('AV',style:tstyle),
                  const Spacer(),
                  Checkbox(checked: parAV, onChanged: (s){
                    setState(() {
                      parAV=s??false;

                    });
                  })
                ],
              ),
            )),
            TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text(
                        'AVD',
                        style: tstyle,
                      ),
                      const Spacer(),
                      Checkbox(
                          checked: porteAVD,
                          onChanged: (s) {
                            porteAVD = s ?? false;
                            setState(() {});
                          })
                    ],
                  ),
                )),
            TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text(
                        'AVD',
                        style: tstyle,
                      ),
                      const Spacer(),
                      Checkbox(
                          checked: siegeAVD,
                          onChanged: (s) {
                            siegeAVD = s ?? false;
                            setState(() {});
                          })
                    ],
                  ),
                )),
            TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text(
                        'CALANDRE',
                        style: tstyle,
                      ),
                      const Spacer(),
                      Checkbox(
                          checked: calandre,
                          onChanged: (s) {
                            calandre = s ?? false;
                            setState(() {});
                          })
                    ],
                  ),
                )),

          ]
      ),
      TableRow(
          children: [
            TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text(
                        'AVG',
                        style: tstyle,
                      ),
                      const Spacer(),
                      Checkbox(
                          checked: aileAVG,
                          onChanged: (s) {
                            aileAVG = s ?? false;
                            setState(() {});
                          })
                    ],
                  ),
                )),
            TableCell(child: Padding(padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  Text('AR',style:tstyle),
                  const Spacer(),
                  Checkbox(checked: parAR, onChanged: (s){
                    setState(() {
                      parAR=s??false;

                    });
                  })
                ],
              ),
            )),
            TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text(
                        'AVG',
                        style: tstyle,
                      ),
                      const Spacer(),
                      Checkbox(
                          checked: porteAVG,
                          onChanged: (s) {
                            porteAVG = s ?? false;
                            setState(() {});
                          })
                    ],
                  ),
                )),
            TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text(
                        'AVG',
                        style: tstyle,
                      ),
                      const Spacer(),
                      Checkbox(
                          checked: siegeAVG,
                          onChanged: (s) {
                            siegeAVG = s ?? false;
                            setState(() {});
                          })
                    ],
                  ),
                )),
            TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text(
                        'CAPOT',
                        style: tstyle,
                      ),
                      const Spacer(),
                      Checkbox(
                          checked: capot,
                          onChanged: (s) {
                            capot = s ?? false;
                            setState(() {});
                          })
                    ],
                  ),
                )),
          ]
      ),
      TableRow(
          children: [
            TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text(
                        'ARD',
                        style: tstyle,
                      ),
                      const Spacer(),
                      Checkbox(
                          checked: aileARD,
                          onChanged: (s) {
                            setState(() {
                              aileARD = s ?? false;

                            });
                          })
                    ],
                  ),
                )),
            const TableCell(child: SizedBox()),
            TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text(
                        'ARD',
                        style: tstyle,
                      ),
                      const Spacer(),
                      Checkbox(
                          checked: porteARD,
                          onChanged: (s) {
                            porteARD = s ?? false;
                            setState(() {});
                          })
                    ],
                  ),
                )),
            TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text(
                        'ARD',
                        style: tstyle,
                      ),
                      const Spacer(),
                      Checkbox(
                          checked: siegeARD,
                          onChanged: (s) {
                            siegeARD = s ?? false;
                            setState(() {});
                          })
                    ],
                  ),
                )),
            TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text(
                        'TOIT',
                        style: tstyle,
                      ),
                      const Spacer(),
                      Checkbox(
                          checked: toit,
                          onChanged: (s) {
                            toit = s ?? false;
                            setState(() {});
                          })
                    ],
                  ),
                )),
          ]
      ),
      TableRow(
          children: [
            TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text(
                        'ARG',
                        style: tstyle,
                      ),
                      const Spacer(),
                      Checkbox(
                          checked: aileARG,
                          onChanged: (s) {
                            setState(() {
                              aileARG = s ?? false;

                            });
                          })
                    ],
                  ),
                )),
            const TableCell(child: SizedBox()),
            TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text(
                        'ARG',
                        style: tstyle,
                      ),
                      const Spacer(),
                      Checkbox(
                          checked: porteARG,
                          onChanged: (s) {
                            porteARG = s ?? false;
                            setState(() {});
                          })
                    ],
                  ),
                )),
            TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text(
                        'ARG',
                        style: tstyle,
                      ),
                      const Spacer(),
                      Checkbox(
                          checked: siegeARG,
                          onChanged: (s) {
                            siegeARG = s ?? false;
                            setState(() {});
                          })
                    ],
                  ),
                )),
            TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Text(
                        'COFFRE',
                        style: tstyle,
                      ),
                      const Spacer(),
                      Checkbox(
                          checked: coffre,
                          onChanged: (s) {
                            coffre = s ?? false;
                            setState(() {});
                          })
                    ],
                  ),
                )),
          ]
      ),
    ];
  }

  Widget vehicleDamage(AppTheme appTheme){
    return SizedBox(
      width: 317.px,
      height: 148.px,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            left: 0.px,
              child: Image.asset('assets/images/car.webp',fit: BoxFit.fitWidth,
                color:appTheme.writingStyle.color

              )),
          Positioned(
              left: -15.px,
              top: 0,
              child: SizedBox(
                width: 4.75.w,
                height: 30.h,
                child: Column(
                  children: [
                    OnTapScaleAndFade(
                      child: Container(
                        height: 3.75.h,
                        decoration: BoxDecoration(
                          gradient: phareD == true
                              ? appTheme.getRadiantLighter()
                              : null,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          phareD=!phareD;
                        });
                      },
                    ),
                    OnTapScaleAndFade(
                      child: Container(
                        height: 3.75.h,
                        decoration: BoxDecoration(
                          gradient: feuAVD == true
                              ? appTheme.getRadiantLighter()
                              : null,
                        ),
                      ),
                      onTap: (){
                        setState(() {
                          feuAVD=!feuAVD;
                        });
                      },
                    ),
                    SizedBox(
                      height: 5.75.h,
                    ),
                    OnTapScaleAndFade(
                      child: Container(
                        height: 3.75.h,
                        decoration: BoxDecoration(
                          gradient: feuAVG == true
                              ? appTheme.getRadiantLighter()
                              : null,
                        ),
                      ),
                      onTap: (){
                        setState(() {
                          feuAVG=!feuAVG;
                        });
                      },
                    ),
                    OnTapScaleAndFade(
                      child: Container(
                        height: 3.75.h,
                        decoration: BoxDecoration(
                          gradient: phareG == true
                              ? appTheme.getRadiantLighter()
                              : null,
                        ),
                      ),
                      onTap: (){
                        setState(() {
                          phareG=!phareG;
                        });
                      },
                    ),
                  ],
                ),
              )),
          Positioned(
              left: 35.px,
              top: 0,
              child: SizedBox(
                width: 4.75.w,
                height: 30.h,
                child: Column(
                  children: [
                    OnTapScaleAndFade(
                      child: Container(
                        height: 3.75.h,
                        decoration: BoxDecoration(
                          gradient: avdp<=20?
                          appTheme.getRadiantLighter()
                              :avdp<=60?appTheme.getRadiantStandard():
                          avdp<=80?appTheme.getRadiantStandard()
                              : null,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if(avdp<=20){
                            avdp=50;
                          }
                          else if(avdp<=60){
                            avdp=80;
                          }
                          else if(avdp<=80){
                            avdp=100;
                          }
                          else{
                            avdp=20;
                          }
                        });
                      },
                    ),
                    SizedBox(
                      height: 100.px,
                    ),
                    OnTapScaleAndFade(
                      child: Container(
                        height: 3.75.h,
                        decoration: BoxDecoration(
                          gradient: avgp<=20?
                          appTheme.getRadiantLighter()
                              :avgp<=60?appTheme.getRadiantStandard():
                          avgp<=80?appTheme.getRadiantDarker()
                              : null,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if(avgp<=20){
                            avgp=50;
                          }
                          else if(avgp<=60){
                            avgp=80;
                          }
                          else if(avgp<=80){
                            avgp=100;
                          }
                          else{
                            avgp=20;
                          }
                        });
                      },
                    ),
                  ],
                ),
              )),
          Positioned(
              left: 11.w,
              top:65.px,
              child: SizedBox(
                width: 4.75.w,
                height: 30.h,
                child: Column(
                  children: [
                    OnTapScaleAndFade(
                      child: Container(
                        height: 3.75.h,
                        decoration: BoxDecoration(
                          gradient: parAve?
                          appTheme.getRadiantLighter()
                              :parAvc?appTheme.getRadiantLighter():
                          parAvf?appTheme.getRadiantLighter()
                              : null,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if(parAvf){
                            parAvf=false;
                            parAvc=true;
                            parAve=false;
                          }
                          else if(parAvc){
                            parAvc=false;
                            parAve=true;
                            parAvf=false;
                          }
                          else if(parAve){
                            parAve=false;
                            parAvf=false;
                            parAvc=false;
                          }
                          else {
                            parAve=false;
                            parAvf=true;
                            parAvc=false;
                          }
                        });
                      },
                    ),
                  ],
                ),
              )),
          Positioned(
              left: 22.w,
              top:12.h,
              child: SizedBox(
                width: 4.75.w,
                height: 30.h,
                child: Column(
                  children: [
                    OnTapScaleAndFade(
                      child: Container(
                        height: 3.75.h,
                        decoration: BoxDecoration(
                          gradient: parAre?
                          appTheme.getRadiantLighter()
                              :parArc?appTheme.getRadiantLighter():
                          parArf?appTheme.getRadiantLighter()
                              : null,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if(parArf){
                            parArf=false;
                            parArc=true;
                            parAre=false;
                          }
                          else if(parArc){
                            parArc=false;
                            parAre=true;
                            parArf=false;
                          }
                          else if(parAre){
                            parAre=false;
                            parArf=false;
                            parArc=false;
                          }
                          else {
                            parAre=false;
                            parArf=true;
                            parArc=false;
                          }
                        });
                      },
                    ),
                  ],
                ),
              )),
          Positioned(
              left: 22.w,
              top: 2.5.h,
              child: SizedBox(
                width: 4.75.w,
                height: 30.h,
                child: Column(
                  children: [
                    OnTapScaleAndFade(
                      child: Container(
                        height: 3.75.h,
                        decoration: BoxDecoration(
                          gradient: ardp<=20?
                          appTheme.getRadiantLighter()
                              :ardp<=60?appTheme.getRadiantLighter():
                          ardp<=80?appTheme.getRadiantLighter()
                              : null,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if(ardp<=20){
                            ardp=50;
                          }
                          else if(ardp<=60){
                            ardp=80;
                          }
                          else if(ardp<=80){
                            ardp=100;
                          }
                          else{
                            ardp=20;
                          }
                        });
                      },
                    ),
                    SizedBox(
                      height: 16.h,
                    ),
                    OnTapScaleAndFade(
                      child: Container(
                        height: 3.75.h,
                        decoration: BoxDecoration(
                          gradient: argp<=20?
                          appTheme.getRadiantLighter()
                              :argp<=60?appTheme.getRadiantLighter():
                          argp<=80?appTheme.getRadiantLighter()
                              : null,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          if(argp<=20){
                            argp=50;
                          }
                          else if(argp<=60){
                            argp=80;
                          }
                          else if(argp<=80){
                            argp=100;
                          }
                          else{
                            argp=20;
                          }
                        });
                      },
                    ),
                  ],
                ),
              )),
          Positioned(
              left: 26.5.w,
              top: 5.h,
              child: SizedBox(
                width: 4.75.w,
                height: 30.h,
                child: Column(
                  children: [
                    OnTapScaleAndFade(
                      child: Container(
                        height: 3.75.h,
                        decoration: BoxDecoration(
                          gradient: feuARD == true
                              ? appTheme.getRadiantLighter()
                              : null,
                        ),
                      ),
                      onTap: (){
                        setState(() {
                          feuARD=!feuARD;
                        });
                      },
                    ),
                    SizedBox(
                      height: 9.5.h,
                    ),
                    OnTapScaleAndFade(
                      child: Container(
                        height: 3.75.h,
                        decoration: BoxDecoration(
                          gradient: feuARG == true
                              ? appTheme.getRadiantLighter()
                              : null,
                        ),
                      ),
                      onTap: (){
                        setState(() {
                          feuARG=!feuARG;
                        });
                      },
                    ),

                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget entretienWidgets(AppTheme appTheme){
    return  Container(
      width: 80.w,
      height: 24.h,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToggleSwitch(
                content: Text(
                  'Vidange moteur',
                  style: tstyle,
                ),
                checked: r1,
                onChanged: (s) {
                  setState(() {
                    r1 = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Vidange boite',
                  style: tstyle,
                ),
                checked: r2,
                onChanged: (s) {
                  setState(() {
                    r2 = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Vidange pont AV AR',
                  style: tstyle,
                ),
                checked: r3,
                onChanged: (s) {
                  setState(() {
                    r3 = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Filtre à air',
                  style: tstyle,
                ),
                checked: r4,
                onChanged: (s) {
                  setState(() {
                    r4 = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Filtre à huile',
                  style: tstyle,
                ),
                checked: r5,
                onChanged: (s) {
                  setState(() {
                    r5 = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Filtre à carburant',
                  style: tstyle,
                ),
                checked: r6,
                onChanged: (s) {
                  setState(() {
                    r6 = s;
                  });
                },
              ),
            ],
          ),
          smallSpace,
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToggleSwitch(
                content: Text(
                  "Filtre d'habitacle",
                  style: tstyle,
                ),
                checked: r7,
                onChanged: (s) {
                  setState(() {
                    r7 = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Liquide de frein',
                  style: tstyle,
                ),
                checked: r8,
                onChanged: (s) {
                  setState(() {
                    r8 = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Liquide de refroidissement',
                  style: tstyle,
                ),
                checked: r9,
                onChanged: (s) {
                  setState(() {
                    r9 = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Equilibrage roues',
                  style: tstyle,
                ),
                checked: r10,
                onChanged: (s) {
                  setState(() {
                    r10 = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Controle niveaux',
                  style: tstyle,
                ),
                checked: r13,
                onChanged: (s) {
                  setState(() {
                    r13 = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Entretien climatisation',
                  style: tstyle,
                ),
                checked: r14,
                onChanged: (s) {
                  setState(() {
                    r14 = s;
                  });
                },
              ),
            ],
          ),
          smallSpace,
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              ToggleSwitch(
                content: Text(
                  'Balais essuie-glace',
                  style: tstyle,
                ),
                checked: r15,
                onChanged: (s) {
                  setState(() {
                    r15 = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Eclairage',
                  style: tstyle,
                ),
                checked: r16,
                onChanged: (s) {
                  setState(() {
                    r16 = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'OBD',
                  style: tstyle,
                ),
                checked: r17,
                onChanged: (s) {
                  setState(() {
                    r17 = s;
                  });
                },
              ),
              smallSpace,
              ToggleSwitch(
                content: Text(
                  'Bougies',
                  style: tstyle,
                ),
                checked: r18,
                onChanged: (s) {
                  setState(() {
                    r18 = s;
                  });
                },
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}
