import 'package:appwrite/appwrite.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:dzair_data_usage/langs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/vehicle/manager/vehicle_tabs.dart';
import 'package:parc_oto/utilities/vehicle_util.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../serializables/vehicle/vehicle.dart';
import '../../../theme.dart';
import '../../../utilities/algeria_lists.dart';
import '../../../widgets/select_dialog/select_dialog.dart';

class VehicleForm extends StatefulWidget {
  final Vehicle? vehicle;
  final Tab? tab;
  const VehicleForm({super.key, this.vehicle, this.tab});

  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm>
    with AutomaticKeepAliveClientMixin<VehicleForm> {


  TextEditingController matriculeEtr = TextEditingController();
  TextEditingController matr1 = TextEditingController();
  TextEditingController matr2 = TextEditingController();
  TextEditingController matr3 = TextEditingController();
  TextEditingController wilayaCont=TextEditingController();
  TextEditingController dairaCont=TextEditingController();
  TextEditingController communeCont=TextEditingController();
  TextEditingController quittance = TextEditingController(text: '800');
  TextEditingController numero = TextEditingController();
  TextEditingController lname = TextEditingController();
  TextEditingController fname = TextEditingController();
  TextEditingController profession = TextEditingController();
  TextEditingController adresse = TextEditingController();
  TextEditingController type = TextEditingController();
  TextEditingController numSer = TextEditingController();
  TextEditingController caross = TextEditingController();
  TextEditingController energie = TextEditingController();
  TextEditingController puissance = TextEditingController();
  TextEditingController places = TextEditingController();
  TextEditingController poidsT = TextEditingController();
  TextEditingController charg = TextEditingController();
  TextEditingController matrPrec = TextEditingController();
  DateTime? selectedAnnee = DateTime(2023);
  bool autreMat = false;
  int? marque;

  bool erreurMatricule=false;

  int? genre;

  String pays = 'DZ';

  final double height = 9.h;
  final double heightFirst=17.h;




  String wilaya = "16";

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    initValues();
    super.initState();
  }
  void initValues(){
    AlgeriaList();
    if(widget.vehicle!=null){
      documentID=widget.vehicle!.id;
      if(widget.vehicle!.matriculeEtrang){
        autreMat=true;
        matriculeEtr.text=widget.vehicle!.matricule;
      }
      else{
        autreMat=false;
        var mats=widget.vehicle!.matricule.split('-');
        if(mats.length>=3){
          matr1.text=mats[0];
          matr2.text=mats[1];
          matr3.text=mats[2];
        }

      }
      pays=widget.vehicle!.pays??'DZ';
      wilayaCont.text=AlgeriaList().getWilayaByNum(widget.vehicle!.wilaya?.toString()??'16')??'';
      wilaya=widget.vehicle!.wilaya?.toString()??'';
      communeCont.text=widget.vehicle!.commune??'';
      dairaCont.text=widget.vehicle!.daira??'';
      selectedDate=widget.vehicle!.date??DateTime.now();
      quittance.text=widget.vehicle!.quittance?.toString()??'';
      numero.text=widget.vehicle!.numero??'';
      lname.text=widget.vehicle!.nom??'';
      fname.text=widget.vehicle!.prenom??'';
      profession.text=widget.vehicle!.profession??'';
      adresse.text=widget.vehicle!.adresse??'';
      genre=int.tryParse(widget.vehicle!.genre??'-1');
      marque=int.tryParse(widget.vehicle!.marque??'-1');
      type.text=widget.vehicle!.type??'';
      numSer.text=widget.vehicle!.numeroSerie??'';
      caross.text=widget.vehicle!.carrosserie??'';
      energie.text=widget.vehicle!.energie??'';
      puissance.text=widget.vehicle!.puissance?.toString()??'';
      places.text=widget.vehicle!.placesAssises?.toString()??'';
      poidsT.text=widget.vehicle!.poidsTotal?.toString()??'';
      charg.text=widget.vehicle!.charegeUtile?.toString()??'';
      matrPrec.text=widget.vehicle!.matriculePrec??'';
      selectedDate=DateTime(widget.vehicle!.anneeUtil??DateTime.now().year);
    }
    documentID ??= ClientDatabase.ref.difference(DateTime.now()).inMilliseconds.abs().toString();

  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var appTheme = context.watch<AppTheme>();


    return ScaffoldPage(
        content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Container(
                decoration: BoxDecoration(
                  color: appTheme.backGroundColor,
                  boxShadow: kElevationToShadow[4],
                ),
                width: 70.w,
                child: Column(
                  children: [
                    Flexible(
                      child: ListView(
                        primary: true,
                        children: [
                          Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(),
                                ),
                                width: 60.w,
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                       5.0),
                                  child: StaggeredGrid.count(
                                      crossAxisCount:
                                          MediaQuery.of(context).orientation ==
                                                  Orientation.portrait
                                              ? 1
                                              : 6,
                                      mainAxisSpacing: 0,
                                      crossAxisSpacing: 0,
                                      children: [
                                        StaggeredGridTile.fit(
                                            crossAxisCellCount: 2,
                                            child: Container(
                                              height: heightFirst,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'pays',
                                                    style: tstyle,
                                                  ).tr(),
                                                  CountryCodePicker(
                                                    boxDecoration:
                                                        BoxDecoration(
                                                            color: appTheme.backGroundColor,
                                                            boxShadow:
                                                                kElevationToShadow[
                                                                    2]),
                                                    padding:
                                                        const EdgeInsets.all(3),
                                                    searchDecoration:
                                                    appTheme.inputDecoration,
                                                    dialogSize:
                                                        Size(40.w, 60.h),
                                                    initialSelection: pays,
                                                    showCountryOnly: true,
                                                    showDropDownButton: true,
                                                    showFlagDialog: true,
                                                    showOnlyCountryWhenClosed:
                                                        true,
                                                    onChanged: (c) {
                                                      setState(() {
                                                        pays = c.code ?? 'DZ';
                                                      });
                                                    },
                                                  ),
                                                  const Text(
                                                    'wilaya',
                                                    style: tstyle,
                                                  ).tr(),
                                                  SizedBox(
                                                    height: 5.h,
                                                    child:
                                                        AutoSuggestBox<String>(
                                                          controller: wilayaCont,
                                                          placeholder:
                                                          'wilaya'.tr(),
                                                      placeholderStyle:
                                                          placeStyle,
                                                      cursorColor:
                                                          appTheme.color.darker,
                                                      style: appTheme.writingStyle,
                                                      decoration: BoxDecoration(
                                                        color: appTheme.fillColor,
                                                      ),
                                                      items: AlgeriaList.dzair!
                                                          .getWilayat()!
                                                          .map((wilaya) {
                                                        return AutoSuggestBoxItem<
                                                            String>(
                                                          value: wilaya!
                                                              .getWilayaCode()!,
                                                          label: wilaya.getWilayaName(appTheme
                                                                      .locale!
                                                                      .languageCode
                                                                      .toUpperCase() ==
                                                                  "AR"
                                                              ? Language.AR
                                                              : Language.FR)!,
                                                        );
                                                      }).toList(),
                                                      onSelected: (item) {
                                                        setState(() {
                                                          wilaya = item.value!;
                                                          wilayaCont.text = AlgeriaList
                                                                  .dzair!
                                                                  .searchWilayatByName(
                                                                      item
                                                                          .label,
                                                                      appTheme.locale!.languageCode.toUpperCase() ==
                                                                              "AR"
                                                                          ? Language
                                                                              .AR
                                                                          : Language
                                                                              .FR)
                                                                  ?.first
                                                                  ?.getWilayaName(
                                                                      Language
                                                                          .FR) ??
                                                              '';
                                                        });
                                                      },
                                                      onChanged: (s, r) {
                                                        if (r ==
                                                            TextChangedReason
                                                                .userInput) {
                                                          setState(() =>
                                                              wilayaCont.text = s);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 2,
                                          child: Container(
                                            height: heightFirst,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Container(
                                              padding: EdgeInsets.zero,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: appTheme.color,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8.0),
                                                    child: const Text(
                                                      'nummat',
                                                      style: tstyle,
                                                    ).tr(),
                                                  ),
                                                  if(!erreurMatricule)
                                                  const Spacer(),
                                                  if(erreurMatricule)
                                                    Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Text('erreurmat',style:TextStyle(color:Colors.red)).tr(),
                                                    ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 5.0),
                                                    child: autreMat
                                                        ? TextBox(
                                                            controller:
                                                                matriculeEtr,
                                                            maxLength: 30,
                                                            cursorColor:
                                                                appTheme.color
                                                                    .darker,
                                                            style: appTheme.writingStyle,
                                                            placeholder:
                                                                'XXXXXXXXXXXXXX',
                                                            textAlign: TextAlign
                                                                .center,
                                                            placeholderStyle:
                                                                placeStyle,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: appTheme.fillColor,
                                                            ),
                                                      inputFormatters: <TextInputFormatter>[
                                                        FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z.-]")),
                                                      ],
                                                          )
                                                        : Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Flexible(
                                                                flex: 6,
                                                                child: TextBox(
                                                                  controller:
                                                                      matr1,
                                                                  cursorColor:
                                                                      appTheme
                                                                          .color
                                                                          .darker,
                                                                  style:
                                                                  appTheme.writingStyle,
                                                                  placeholder:
                                                                      '123456',
                                                                  placeholderStyle:
                                                                      placeStyle,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: appTheme.fillColor,
                                                                  ),
                                                                  maxLength: 6,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  inputFormatters: [
                                                                    FilteringTextInputFormatter
                                                                        .digitsOnly
                                                                  ],
                                                                ),
                                                              ),
                                                              smallSpace,
                                                              const Text(
                                                                '-',
                                                                style: tstyle,
                                                              ),
                                                              smallSpace,
                                                              Flexible(
                                                                flex: 3,
                                                                child: TextBox(
                                                                  controller:
                                                                      matr2,
                                                                  cursorColor:
                                                                      appTheme
                                                                          .color
                                                                          .darker,
                                                                  style:
                                                                  appTheme.writingStyle,
                                                                  placeholder:
                                                                      '123',
                                                                  maxLength: 3,
                                                                  placeholderStyle:
                                                                      placeStyle,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: appTheme.fillColor,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  inputFormatters: [
                                                                    FilteringTextInputFormatter
                                                                        .digitsOnly
                                                                  ],
                                                                  onChanged: (s){
                                                                    updateOverMatricule(appTheme);
                                                                  },
                                                                ),
                                                              ),
                                                              smallSpace,
                                                              const Text(
                                                                '-',
                                                                style: tstyle,
                                                              ),
                                                              smallSpace,
                                                              Flexible(
                                                                flex: 2,
                                                                child: TextBox(
                                                                  controller:
                                                                      matr3,
                                                                  cursorColor:
                                                                      appTheme
                                                                          .color
                                                                          .darker,
                                                                  style:
                                                                  appTheme.writingStyle,
                                                                  placeholder:
                                                                      '12',
                                                                  maxLength: 2,
                                                                  placeholderStyle:
                                                                      placeStyle,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: appTheme.fillColor,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  inputFormatters: [
                                                                    FilteringTextInputFormatter
                                                                        .digitsOnly
                                                                  ],
                                                                  onChanged: (s){
                                                                    updateOverMatricule(appTheme);
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                  ),
                                                  const Spacer(),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Checkbox(
                                                        checked: autreMat,
                                                        content: Text(
                                                          'autremat',
                                                          style: placeStyle,
                                                        ).tr(),
                                                        onChanged: (s) {
                                                          if (s != null) {
                                                            setState(() {
                                                              autreMat = s;
                                                            });
                                                          }
                                                        },
                                                      ),
                                                      smallSpace,
                                                    ],
                                                  ),
                                                  smallSpace,
                                                  smallSpace,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                            crossAxisCellCount: 2,
                                            child: Container(
                                              height: heightFirst,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'daira',
                                                    style: tstyle,
                                                  ).tr(),
                                                  SizedBox(
                                                    height: 5.h,
                                                    child:
                                                        AutoSuggestBox<String>(
                                                      controller: dairaCont,
                                                          placeholder: 'daira'.tr(),
                                                      cursorColor:
                                                          appTheme.color.darker,
                                                      style: appTheme.writingStyle,
                                                      placeholderStyle:
                                                          placeStyle,
                                                      decoration: BoxDecoration(
                                                        color: appTheme.fillColor,
                                                      ),
                                                      items: AlgeriaList()
                                                          .getDairas(wilayaCont.text)
                                                          .map((daira) {
                                                        return AutoSuggestBoxItem<
                                                            String>(
                                                          value: daira
                                                                  ?.getDairaName(
                                                                      Language
                                                                          .FR) ??
                                                              '',
                                                          label: daira?.getDairaName(appTheme
                                                                          .locale
                                                                          ?.languageCode
                                                                          .toUpperCase() ==
                                                                      "AR"
                                                                  ? Language.AR
                                                                  : Language
                                                                      .FR) ??
                                                              '',
                                                        );
                                                      }).toList(),
                                                      onSelected: (item) {
                                                        setState(() => dairaCont.text =
                                                            item.value ?? "");
                                                      },
                                                      onChanged: (s, r) {
                                                        if (r ==
                                                            TextChangedReason
                                                                .userInput) {
                                                          setState(
                                                              () => dairaCont.text = s);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  const Text(
                                                    'commune',
                                                    style: tstyle,
                                                  ).tr(),
                                                  SizedBox(
                                                    height: 5.h,
                                                    child:
                                                        AutoSuggestBox<String>(
                                                      controller: communeCont,
                                                          placeholder:
                                                          'commune'.tr(),
                                                      placeholderStyle:
                                                          placeStyle,
                                                      cursorColor:
                                                          appTheme.color.darker,
                                                      style: appTheme.writingStyle,
                                                      decoration: BoxDecoration(
                                                        color: appTheme.fillColor,
                                                      ),
                                                      items: AlgeriaList()
                                                          .getCommune(
                                                              wilayaCont.text)
                                                          .map((commune) {
                                                        return AutoSuggestBoxItem<
                                                            String>(
                                                          value: commune == null
                                                              ? ''
                                                              : commune.getCommuneName(
                                                                      Language
                                                                          .FR) ??
                                                                  '',
                                                          label: commune == null
                                                              ? ''
                                                              : commune.getCommuneName(appTheme
                                                                              .locale
                                                                              ?.languageCode
                                                                              .toUpperCase() ==
                                                                          "AR"
                                                                      ? Language
                                                                          .AR
                                                                      : Language
                                                                          .FR) ??
                                                                  '',
                                                        );
                                                      }).toList(),
                                                      onSelected: (item) {
                                                        setState(() => communeCont.text =
                                                            item.value ?? "");
                                                      },
                                                      onChanged: (s, r) {
                                                        if (r ==
                                                            TextChangedReason
                                                                .userInput) {
                                                          setState(() =>
                                                              communeCont.text = s);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                        StaggeredGridTile.fit(
                                            crossAxisCellCount: 2,
                                            child: Container(
                                              height: height,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'date',
                                                    style: tstyle,
                                                  ).tr(),
                                                  DatePicker(
                                                      selected: selectedDate,
                                                    onChanged: (s){
                                                        setState(() {
                                                          selectedDate=s;
                                                        });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            )),
                                        if (MediaQuery.of(context)
                                                .orientation ==
                                            Orientation.landscape)
                                          StaggeredGridTile.fit(
                                            crossAxisCellCount: 1,
                                            child: SizedBox(
                                              height: height,
                                            ),
                                          ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 1,
                                          child: Container(
                                            height: height,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (MediaQuery.of(context)
                                                        .orientation ==
                                                    Orientation.landscape)
                                                  const SizedBox(
                                                    height: 5,
                                                  ),
                                                const Text(
                                                  'quittance',
                                                  style: tstyle,
                                                ).tr(),
                                                TextBox(
                                                  controller: quittance,
                                                  placeholder: 'quittance'.tr(),
                                                  cursorColor:
                                                      appTheme.color.darker,
                                                  style: appTheme.writingStyle,
                                                  placeholderStyle: placeStyle,
                                                  decoration: BoxDecoration(
                                                    color: appTheme.fillColor,
                                                  ),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.allow(
                                                        RegExp(r'^(\d+)?\.?\d{0,2}')
                                                    )
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            height: height,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  'num',
                                                  style: tstyle,
                                                ).tr(),
                                                TextBox(
                                                  controller: numero,
                                                  placeholder: 'num'.tr(),
                                                  maxLength: 30,
                                                  placeholderStyle: placeStyle,
                                                  cursorColor:
                                                      appTheme.color.darker,
                                                  style: appTheme.writingStyle,
                                                  decoration: BoxDecoration(
                                                    color: appTheme.fillColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            height: height,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  'nomf',
                                                  style: tstyle,
                                                ).tr(),
                                                SizedBox(
                                                    height: 5.h,
                                                    child: TextBox(
                                                      controller: lname,
                                                      maxLength: 30,
                                                      placeholder: 'nomf'.tr(),
                                                      placeholderStyle:
                                                          placeStyle,
                                                      cursorColor:
                                                          appTheme.color.darker,
                                                      style: appTheme.writingStyle,
                                                      decoration: BoxDecoration(
                                                        color: appTheme.fillColor,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            height: height,
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'prenom',
                                                    style: tstyle,
                                                  ).tr(),
                                                  SizedBox(
                                                      height: 5.h,
                                                      child: TextBox(
                                                        controller: fname,
                                                        maxLength: 30,
                                                        placeholder:
                                                            'prenom'.tr(),
                                                        placeholderStyle:
                                                            placeStyle,
                                                        cursorColor: appTheme
                                                            .color.darker,
                                                        style: appTheme.writingStyle,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                          appTheme.fillColor,
                                                        ),
                                                      )),
                                                ]),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            height: height,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'profession',
                                                  style: tstyle,
                                                ).tr(),
                                                SizedBox(
                                                    height: 5.h,
                                                    child: TextBox(
                                                      controller: profession,
                                                      maxLength: 40,
                                                      placeholder:
                                                          'profession'.tr(),
                                                      placeholderStyle:
                                                          placeStyle,
                                                      cursorColor:
                                                          appTheme.color.darker,
                                                      style: appTheme.writingStyle,
                                                      decoration: BoxDecoration(
                                                        color: appTheme.fillColor,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            height: height,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  'adresse',
                                                  style: tstyle,
                                                ).tr(),
                                                SizedBox(
                                                    height: 5.h,
                                                    child: TextBox(
                                                      controller: adresse,
                                                      placeholder:
                                                          'adresse'.tr(),
                                                      maxLength: 100,
                                                      placeholderStyle:
                                                          placeStyle,
                                                      cursorColor:
                                                          appTheme.color.darker,
                                                      style: appTheme.writingStyle,
                                                      decoration: BoxDecoration(
                                                        color: appTheme.fillColor,
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (MediaQuery.of(context)
                                                .orientation ==
                                            Orientation.landscape)
                                          StaggeredGridTile.fit(
                                            crossAxisCellCount: 2,
                                            child: SizedBox(
                                              height: height,
                                            ),
                                          ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 1,
                                          child: Container(
                                            height: height,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    'genre',
                                                    style: tstyle,
                                                  ).tr(),
                                                  Flexible(
                                                    child: ListTile(
                                                      title: AutoSizeText(
                                                        (VehiclesUtilities.genres![genre??-1]??'nonind').tr(),
                                                        minFontSize: 5,
                                                        softWrap: true,
                                                        maxLines:1,
                                                      ),
                                                      onPressed: () {
                                                        SelectDialog.showModal<
                                                            int>(context,
                                                          selectedValue: genre,
                                                          backgroundColor: appTheme.backGroundColor,
                                                          items:
                                                          VehiclesUtilities
                                                              .genres!.keys.toList(),
                                                          itemBuilder:
                                                              (c, v, e) {
                                                            return Container(
                                                              padding: const EdgeInsets.all(5.0),
                                                              color: v%2==0?Colors.transparent:appTheme.color.lightest,
                                                              child: Row(
                                                                children:[
                                                                  Text(v.toString()),
                                                                  smallSpace,
                                                                  smallSpace,
                                                                  smallSpace,
                                                                  Text(VehiclesUtilities.genres?[v]??'').tr(),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                          onChange: (s){
                                                            setState(() {
                                                              genre=s;
                                                            });
                                                          },
                                                          onFind: VehiclesUtilities.findGenres,
                                                          emptyBuilder: (s){
                                                            return Center(
                                                              child: Text('lvide',style: TextStyle(color:Colors.grey[100]),).tr(),
                                                            );
                                                          },
                                                          loadingBuilder: (s){
                                                            return Center(
                                                              child: Text('telechargement',style:TextStyle(color:Colors.grey[100])).tr(),
                                                            );
                                                          },
                                                          searchBoxDecoration: appTheme.inputDecoration.copyWith(
                                                            labelText: 'search'.tr(),
                                                            labelStyle: placeStyle,
                                                          ),
                                                          searchTextStyle: appTheme.writingStyle,
                                                          searchCursorColor: appTheme.color,

                                                        );
                                                      },

                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 1,
                                          child: Container(
                                            height: height,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    'marque',
                                                    style: tstyle,
                                                  ).tr(),
                                                  Flexible(
                                                    child: ListTile(
                                                      leading: Image.asset('assets/images/marques/${marque==null || marque!<=0 ?'default':marque!}.webp',width: 4.h,height: 4.h,),
                                                      title: AutoSizeText(VehiclesUtilities.marques![marque==null || marque!<=0?0:marque!]??'nonind'.tr(),minFontSize: 5,maxLines: 1,),
                                                      onPressed: () {
                                                        SelectDialog.showModal<
                                                                int?>(context,
                                                            selectedValue: marque,
                                                            backgroundColor: appTheme.backGroundColor,
                                                            gridView: true,
                                                            numberOfGridCross: 3,
                                                            constraints: BoxConstraints.loose(Size(60.w,70.h)),
                                                            items:
                                                                VehiclesUtilities
                                                                    .marques!.keys.toList(),
                                                            itemBuilder:
                                                                (c, v, e) {
                                                          return Card(
                                                              child: Image.asset(
                                                                  'assets/images/marques/${v??'default'}.webp'));
                                                        },
                                                          onChange: (s){
                                                                  setState(() {
                                                                    marque=s;
                                                                  });
                                                          },
                                                          onFind: VehiclesUtilities.findMarque,
                                                          emptyBuilder: (s){
                                                                  return Center(
                                                                   child: Text('lvide',style: TextStyle(color:Colors.grey[100]),).tr(),
                                                                  );
                                                          },
                                                          loadingBuilder: (s){
                                                                  return Center(
                                                                    child: Text('telechargement',style:TextStyle(color:Colors.grey[100])).tr(),
                                                                  );
                                                          },
                                                          searchBoxDecoration: appTheme.inputDecoration.copyWith(
                                                            labelText: 'search'.tr(),
                                                            labelStyle: placeStyle,
                                                          ),
                                                          searchTextStyle: appTheme.writingStyle,
                                                          searchCursorColor: appTheme.color,

                                                        );
                                                              },

                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 1,
                                          child: Container(
                                            height: height,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    'type',
                                                    style: tstyle,
                                                  ).tr(),
                                                  TextBox(
                                                    controller: type,
                                                    placeholder: 'type'.tr(),
                                                    maxLength: 30,
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor:
                                                        appTheme.color.darker,
                                                    style: appTheme.writingStyle,
                                                    decoration: BoxDecoration(
                                                      color: appTheme.fillColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 3,
                                          child: Container(
                                            height: height,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    'nchassi',
                                                    style: tstyle,
                                                  ).tr(),
                                                  TextBox(
                                                    controller: numSer,
                                                    maxLength: 30,
                                                    placeholder:
                                                        'nchassi'.tr(),
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor:
                                                        appTheme.color.darker,
                                                    style: appTheme.writingStyle,
                                                    decoration: BoxDecoration(
                                                      color: appTheme.fillColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 1,
                                          child: Container(
                                            height: height,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    'caross',
                                                    style: tstyle,
                                                  ).tr(),
                                                  TextBox(
                                                    controller: caross,
                                                    maxLength: 30,
                                                    placeholder: 'caross'.tr(),
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor:
                                                        appTheme.color.darker,
                                                    style: appTheme.writingStyle,
                                                    decoration: BoxDecoration(
                                                      color: appTheme.fillColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 1,
                                          child: Container(
                                            height: height,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    'energie',
                                                    style: tstyle,
                                                  ).tr(),
                                                  TextBox(
                                                    controller: energie,
                                                    maxLength: 20,
                                                    placeholder: 'energie'.tr(),
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor:
                                                        appTheme.color.darker,
                                                    style: appTheme.writingStyle,
                                                    decoration: BoxDecoration(
                                                      color: appTheme.fillColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 1,
                                          child: Container(
                                            height: height,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    'puissance',
                                                    style: tstyle,
                                                  ).tr(),
                                                  TextBox(
                                                    placeholder: '0000',
                                                    controller: puissance,
                                                    maxLength: 4,
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor:
                                                        appTheme.color.darker,
                                                    style: appTheme.writingStyle,
                                                    decoration: BoxDecoration(
                                                      color: appTheme.fillColor,
                                                    ),
                                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 1,
                                          child: Container(
                                            height: height,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    'placeassise',
                                                    style: tstyle,
                                                  ).tr(),
                                                  TextBox(
                                                    placeholder: '000',
                                                    controller: places,
                                                    maxLength: 3,
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor:
                                                        appTheme.color.darker,
                                                    style: appTheme.writingStyle,
                                                    decoration: BoxDecoration(
                                                      color: appTheme.fillColor,
                                                    ),
                                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 1,
                                          child: Container(
                                            height: height,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    'poidstotal',
                                                    style: tstyle,
                                                  ).tr(),
                                                  TextBox(
                                                    placeholder: '000000',
                                                    controller: poidsT,
                                                    maxLength: 15,
                                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor:
                                                        appTheme.color.darker,
                                                    style: appTheme.writingStyle,
                                                    decoration: BoxDecoration(
                                                      color: appTheme.fillColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 1,
                                          child: Container(
                                            height: height,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    'chargeutil',
                                                    style: tstyle,
                                                  ).tr(),
                                                  TextBox(
                                                    placeholder: '000000',
                                                    controller: charg,
                                                    maxLength: 15,
                                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor:
                                                        appTheme.color.darker,
                                                    style: appTheme.writingStyle,
                                                    decoration: BoxDecoration(
                                                      color: appTheme.fillColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 4,
                                          child: Container(
                                            height: height,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    'precmat',
                                                    style: tstyle,
                                                  ).tr(),
                                                  Flexible(
                                                      child: TextBox(
                                                        controller: matrPrec,
                                                    maxLength: 30,
                                                    placeholder: 'precmat'.tr(),
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor:
                                                        appTheme.color.darker,
                                                    style: appTheme.writingStyle,
                                                    decoration: BoxDecoration(
                                                      color: appTheme.fillColor,
                                                    ),
                                                        inputFormatters: <TextInputFormatter>[
                                                          FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z.-]")),
                                                        ],
                                                  )),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 2,
                                          child: Container(
                                            height: height,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    'anneeutil',
                                                    style: tstyle,
                                                  ).tr(),
                                                  Flexible(
                                                      child: DatePicker(
                                                    showDay: false,
                                                    showMonth: false,
                                                    selected: selectedAnnee,
                                                    onChanged: (s) {
                                                      setState(() {
                                                        selectedAnnee = s;
                                                      });
                                                    },
                                                  )),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ]),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ))),
        bottomBar: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if(errorUploading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text('errupld',style:TextStyle(color:Colors.red)).tr(),
                ),
              FilledButton(
                  onPressed: uploading?null:confirmAndUpload,
                  child: uploading?const ProgressRing():const Text('confirmer').tr()),
            ],
          ),
        ));
  }

  void updateOverMatricule(AppTheme appTheme) {
    if(!autreMat){
        if(matr3.text.isNotEmpty){
          wilaya=matr3.text;
          wilayaCont.text=AlgeriaList().getWilayaByNum(matr3.text)??'';
          dairaCont.text=AlgeriaList().getDairas(wilayaCont.text).firstOrNull?.getDairaName(appTheme
              .locale
              ?.languageCode
              .toUpperCase() ==
              "AR"
              ? Language.AR
              : Language
              .FR)??'';
          communeCont.text=AlgeriaList().getCommune(wilayaCont.text).firstOrNull?.getDairaName(appTheme
              .locale
              ?.languageCode
              .toUpperCase() ==
              "AR"
              ? Language.AR
              : Language
              .FR)??'';
          setState(() {
          });
        }
        if(matr2.text.isNotEmpty){
          genre=(int.tryParse(matr2.text)??100)~/100;
          selectedAnnee=DateTime(VehiclesUtilities.getAnneeFromMatricule('0000-${matr2.text}-00'));
          setState(() {
          });
        }
    }
  }
   String? documentID;
  bool uploading=false;
  bool errorUploading=false;
  void confirmAndUpload()async{
    if(autreMat){
      if(matriculeEtr.text.isEmpty || matriculeEtr.text.length<4){
        if(!erreurMatricule){
          setState(() {
            erreurMatricule=true;
          });
        }
      }
      else{
        if(erreurMatricule){
          setState(() {
            erreurMatricule=false;
          });
        }

      }
    }
    else{
      if(matr1.text.isEmpty || matr2.text.length<3 || matr3.text.length<2){
        if(!erreurMatricule){
          setState(() {
            erreurMatricule=true;
          });
        }
      }
      else{
        if(erreurMatricule){
          setState(() {
            erreurMatricule=false;
          });
        }

      }
    }


    if(!erreurMatricule){
      setState(() {
        uploading=true;
        errorUploading=false;
      });
      Vehicle vehicle=Vehicle(
          id: documentID!,
          matricule: autreMat
              ?matriculeEtr.text
              :'${matr1.text}-${matr2.text}-${matr3.text}',
          matriculeEtrang: autreMat,
          wilaya: int.tryParse(wilaya),
          commune: communeCont.text,
          date: selectedDate,
          adresse: adresse.text,
          quittance: double.tryParse(quittance.text),
          numero: numero.text,
          numeroSerie: numSer.text,
          anneeUtil: selectedAnnee?.year,
          energie: energie.text,
          pays: pays,
          placesAssises: int.tryParse(places.text),
          poidsTotal: int.tryParse(poidsT.text),
          prenom: fname.text,
          nom: lname.text,
          type: type.text,
          profession: profession.text,
          puissance: int.tryParse(puissance.text),
          daira: dairaCont.text,
          genre: genre.toString(),
          marque: marque.toString(),
          matriculePrec: matrPrec.text,
          carrosserie: caross.text,
          charegeUtile: int.tryParse(charg.text),
          createdBy: ClientDatabase.me.value?.id,

      );
      if(widget.vehicle!=null){
        await Future.wait([
        updateVehicle(vehicle),
          uploadActivity(true,vehicle),
        ]);

      }
      else{
        await Future.wait([
          createVehicle(vehicle),
          uploadActivity(false,vehicle),
        ]);
      }

    }
  }

  Future<void> updateVehicle(Vehicle vehicle) async{
    await ClientDatabase.database!.updateDocument(
      databaseId: databaseId,
      collectionId: vehiculeid,
      documentId: documentID!,
      data: vehicle.toJson(),

    ).then((value) {
      if(widget.tab!=null){
        VehicleTabsState.tabs.remove(widget.tab);
      }
      if(VehicleTabsState.currentIndex.value>0)VehicleTabsState.currentIndex.value--;
    }).onError((AppwriteException error, stackTrace) {
      setState(() {
        uploading=false;
        errorUploading=true;
      });
    });
  }

  Future<void> createVehicle(Vehicle vehicle) async{
    await ClientDatabase.database!.createDocument(
      databaseId: databaseId,
      collectionId: vehiculeid,
      documentId: documentID!,
      data: vehicle.toJson(),

    ).then((value) {
      if(widget.tab!=null){
        VehicleTabsState.tabs.remove(widget.tab);
      }
      if(VehicleTabsState.currentIndex.value>0)VehicleTabsState.currentIndex.value--;
    }).onError((AppwriteException error, stackTrace) {
      setState(() {
        uploading=false;
        errorUploading=true;
      });
    });
  }

  Future<void> uploadActivity(bool update,Vehicle vehicle) async{
    if(update){
     await ClientDatabase().ajoutActivity(1, vehicle.id,docName: vehicle.matricule);
    }
    else{
      await ClientDatabase().ajoutActivity(0, vehicle.id,docName: vehicle.matricule);

    }
  }


  @override
  bool get wantKeepAlive => true;
}
