import 'package:country_code_picker/country_code_picker.dart';
import 'package:dzair_data_usage/commune.dart';
import 'package:dzair_data_usage/daira.dart';
import 'package:dzair_data_usage/dzair.dart';
import 'package:dzair_data_usage/langs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:parc_oto/serializables/vehicle.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../theme.dart';

class VehicleForm extends StatefulWidget {
  final Vehicle? vehicle;
  const VehicleForm({super.key, this.vehicle});

  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm>
    with AutomaticKeepAliveClientMixin<VehicleForm> {
  final smallSpace = const SizedBox(
    width: 5,
    height: 5,
  );

  TextEditingController matriculeEtr = TextEditingController();
  TextEditingController matr1 = TextEditingController();
  TextEditingController matr2 = TextEditingController();
  TextEditingController matr3 = TextEditingController();
  bool autreMat = false;

  String pays = 'DZ';
  Dzair dzair = Dzair();

  final tstyle = const TextStyle(fontWeight: FontWeight.bold);
  final placeStyle = TextStyle(color: Colors.grey[100]);
  final wrtingStyle=const TextStyle(color: Colors.black);
  final inputDecoration = m.InputDecoration(
    fillColor: Colors.grey[100],
    filled: true,
    isDense: true,
  );

  String wilaya = "01";
  String wilayaName = "Adrar";
  String commune = "";
  String daira = "";

  DateTime selectedDate = DateTime.now();
  @override
  Widget build(BuildContext context) {
    super.build(context);
    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
        content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Container(
                decoration: BoxDecoration(
                  color: appTheme.mode == ThemeMode.dark
                      ? Colors.grey
                      : appTheme.mode == ThemeMode.light
                          ? Colors.white
                          : ThemeMode.system == ThemeMode.light
                              ? Colors.white
                              : Colors.grey,
                  boxShadow: kElevationToShadow[4],
                ),
                width: 80.w,
                height: 90.h,
                child: Column(
                  children: [
                    Flexible(
                      child: ListView(
                        children: [
                          Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                  ),
                                ),
                                width: 70.w,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: StaggeredGrid.count(
                                      axisDirection: AxisDirection.down,
                                      crossAxisCount: MediaQuery.of(context)
                                                  .orientation ==
                                              Orientation.portrait
                                          ? 1
                                          : 6,
                                      mainAxisSpacing: 0,
                                      crossAxisSpacing: 0,
                                      children: [
                                        StaggeredGridTile.fit(
                                            crossAxisCellCount: 2,
                                            child: Container(
                                              height: 17.h,
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 10),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Text(
                                                    'pays',
                                                    style: tstyle,
                                                  ).tr(),
                                                  CountryCodePicker(
                                                    boxDecoration:
                                                        BoxDecoration(
                                                            color: appTheme
                                                                        .mode ==
                                                                    ThemeMode
                                                                        .dark
                                                                ? Colors
                                                                    .grey
                                                                : appTheme.mode ==
                                                                        ThemeMode
                                                                            .light
                                                                    ? Colors
                                                                        .white
                                                                    : ThemeMode.system ==
                                                                            ThemeMode
                                                                                .light
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .grey,
                                                            boxShadow:
                                                                kElevationToShadow[
                                                                    2]),
                                                    padding:
                                                        const EdgeInsets
                                                            .all(3),
                                                    searchDecoration:
                                                        inputDecoration,
                                                    dialogSize:
                                                        Size(40.w, 60.h),
                                                    initialSelection: pays,
                                                    showCountryOnly: true,
                                                    showDropDownButton:
                                                        true,
                                                    showFlagDialog: true,
                                                    showOnlyCountryWhenClosed:
                                                        true,
                                                    onChanged: (c) {
                                                      setState(() {
                                                        pays =
                                                            c.code ?? 'DZ';
                                                      });
                                                    },
                                                  ),
                                                  Text(
                                                    'wilaya',
                                                    style: tstyle,
                                                  ).tr(),
                                                  SizedBox(
                                                    height: 5.h,
                                                    child: AutoSuggestBox<
                                                        String>(
                                                      placeholder:
                                                          'wilaya'.tr(),
                                                      placeholderStyle:
                                                          placeStyle,
                                                      cursorColor: appTheme.color.darker,
                                                      style: wrtingStyle,
                                                      decoration:
                                                          BoxDecoration(
                                                        color:
                                                            Colors.grey[20],
                                                      ),
                                                      items: dzair
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
                                                              : Language
                                                                  .FR)!,
                                                        );
                                                      }).toList(),
                                                      onSelected: (item) {
                                                        setState(() {
                                                          wilaya =
                                                              item.value!;
                                                          wilayaName = dzair
                                                                  .searchWilayatByName(
                                                                      item
                                                                          .label,
                                                                      appTheme.locale!.languageCode.toUpperCase() == "AR"
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
                                                              wilayaName =
                                                                  s);
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
                                            height: 17.h,
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10),
                                            child: Container(
                                              padding: EdgeInsets.zero,
                                              decoration:
                                                   BoxDecoration(
                                                border: Border.all(
                                                  color: appTheme.color,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal:
                                                                8.0),
                                                    child: Text(
                                                      'nummat',
                                                      style: tstyle,
                                                    ).tr(),
                                                  ),
                                                  const Spacer(),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal:
                                                                5.0),
                                                    child: autreMat
                                                        ? TextBox(
                                                            controller:
                                                                matriculeEtr,
                                                            cursorColor: appTheme.color.darker,
                                                            style: wrtingStyle,
                                                            placeholder:
                                                                'XXXXXXXXXXXXXX',
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                            placeholderStyle:
                                                                placeStyle,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .grey[20],
                                                            ),
                                                          )
                                                        : Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Flexible(
                                                                flex: 6,
                                                                child:
                                                                    TextBox(
                                                                  controller:
                                                                      matr1,
                                                                      cursorColor: appTheme.color.darker,
                                                                      style: wrtingStyle,
                                                                  placeholder:
                                                                      '123456',
                                                                  placeholderStyle:
                                                                      placeStyle,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .grey[20],
                                                                  ),
                                                                  maxLength:
                                                                      6,
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
                                                              Text(
                                                                '-',
                                                                style:
                                                                    tstyle,
                                                              ),
                                                              smallSpace,
                                                              Flexible(
                                                                flex: 3,
                                                                child:
                                                                    TextBox(
                                                                  controller:
                                                                      matr2,
                                                                      cursorColor: appTheme.color.darker,
                                                                      style: wrtingStyle,
                                                                  placeholder:
                                                                      '123',
                                                                  maxLength:
                                                                      3,
                                                                  placeholderStyle:
                                                                      placeStyle,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .grey[20],
                                                                  ),
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
                                                              Text(
                                                                '-',
                                                                style:
                                                                    tstyle,
                                                              ),
                                                              smallSpace,
                                                              Flexible(
                                                                flex: 2,
                                                                child:
                                                                    TextBox(
                                                                  controller:
                                                                      matr3,
                                                                      cursorColor: appTheme.color.darker,
                                                                      style: wrtingStyle,
                                                                  placeholder:
                                                                      '12',
                                                                  maxLength:
                                                                      2,
                                                                  placeholderStyle:
                                                                      placeStyle,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .grey[20],
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  inputFormatters: [
                                                                    FilteringTextInputFormatter
                                                                        .digitsOnly
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                  ),
                                                  const Spacer(),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .end,
                                                    children: [
                                                      Checkbox(
                                                        checked: autreMat,
                                                        content: Text(
                                                          'autremat',
                                                          style: TextStyle(
                                                              color: Colors
                                                                      .grey[
                                                                  100]),
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
                                              height: 17.h,
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 10),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Text(
                                                    'daira',
                                                    style: tstyle,
                                                  ).tr(),
                                                  SizedBox(
                                                    height: 5.h,
                                                    child: AutoSuggestBox<
                                                        String>(
                                                      placeholder:
                                                          'daira'.tr(),
                                                      cursorColor: appTheme.color.darker,
                                                      style: wrtingStyle,
                                                      placeholderStyle:
                                                          placeStyle,
                                                      decoration:
                                                          BoxDecoration(
                                                        color:
                                                            Colors.grey[20],
                                                      ),
                                                      items: getDairas()
                                                          .map((daira) {
                                                        return AutoSuggestBoxItem<
                                                            String>(
                                                          value: daira?.getDairaName(
                                                                  Language
                                                                      .FR) ??
                                                              '',
                                                          label: daira?.getDairaName(appTheme
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
                                                        setState(() =>
                                                            daira =
                                                                item.value ??
                                                                    "");
                                                      },
                                                      onChanged: (s, r) {
                                                        if (r ==
                                                            TextChangedReason
                                                                .userInput) {
                                                          setState(() =>
                                                              daira = s);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  Text(
                                                    'commune',
                                                    style: tstyle,
                                                  ).tr(),
                                                  SizedBox(
                                                    height: 5.h,
                                                    child: AutoSuggestBox<
                                                        String>(
                                                      placeholder:
                                                          'commune'.tr(),
                                                      placeholderStyle:
                                                          placeStyle,
                                                      cursorColor: appTheme.color.darker,
                                                      style: wrtingStyle,
                                                      decoration:
                                                          BoxDecoration(
                                                        color:
                                                            Colors.grey[20],
                                                      ),
                                                      items: getCommune()
                                                          .map((commune) {
                                                        return AutoSuggestBoxItem<
                                                            String>(
                                                          value: commune ==
                                                                  null
                                                              ? ''
                                                              : commune.getCommuneName(
                                                                      Language
                                                                          .FR) ??
                                                                  '',
                                                          label: commune ==
                                                                  null
                                                              ? ''
                                                              : commune.getCommuneName(appTheme.locale?.languageCode.toUpperCase() ==
                                                                          "AR"
                                                                      ? Language
                                                                          .AR
                                                                      : Language
                                                                          .FR) ??
                                                                  '',
                                                        );
                                                      }).toList(),
                                                      onSelected: (item) {
                                                        setState(() =>
                                                            commune =
                                                                item.value ??
                                                                    "");
                                                      },
                                                      onChanged: (s, r) {
                                                        if (r ==
                                                            TextChangedReason
                                                                .userInput) {
                                                          setState(() =>
                                                              commune = s);
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
                                              height: 10.h,
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 10),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .center,
                                                children: [
                                                  Text(
                                                    'date',
                                                    style: tstyle,
                                                  ).tr(),
                                                  smallSpace,
                                                  DatePicker(
                                                      selected:
                                                          selectedDate),
                                                ],
                                              ),
                                            )),
                                        if(MediaQuery.of(context).orientation==Orientation.landscape)
                                          StaggeredGridTile.fit(
                                           crossAxisCellCount: 1,
                                           child: SizedBox(
                                             height: 5.h,
                                           ),
                                          ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 1,
                                          child: Container(
                                            height: 10.h,
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (MediaQuery.of(context)
                                                        .orientation ==
                                                    Orientation.landscape)
                                                  const SizedBox(
                                                    height: 8,
                                                  ),
                                                Text(
                                                  'quittance',
                                                  style: tstyle,
                                                ).tr(),
                                                smallSpace,
                                                TextBox(
                                                  placeholder:
                                                      'quittance'.tr(),
                                                  cursorColor: appTheme.color.darker,
                                                  style: wrtingStyle,
                                                  placeholderStyle:
                                                      placeStyle,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[20],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 2,
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10),
                                            height: 10.h,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'num',
                                                  style: tstyle,
                                                ).tr(),
                                                smallSpace,
                                                TextBox(
                                                  placeholder: 'num'.tr(),
                                                  placeholderStyle:
                                                      placeStyle,
                                                  cursorColor: appTheme.color.darker,
                                                  style: wrtingStyle,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[20],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 2,
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10),
                                            height: 10.h,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'nomf',
                                                  style: tstyle,
                                                ).tr(),
                                                smallSpace,
                                                SizedBox(
                                                    height: 5.h,
                                                    child: TextBox(
                                                      placeholder:
                                                          'nomf'.tr(),
                                                      placeholderStyle:
                                                          placeStyle,
                                                      cursorColor: appTheme.color.darker,
                                                      style: wrtingStyle,
                                                      decoration:
                                                          BoxDecoration(
                                                        color:
                                                            Colors.grey[20],
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 2,
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10),
                                            height: 10.h,
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Text(
                                                    'prenom',
                                                    style: tstyle,
                                                  ).tr(),
                                                  smallSpace,
                                                  SizedBox(
                                                      height: 5.h,
                                                      child: TextBox(
                                                        placeholder:
                                                            'prenom'.tr(),
                                                        placeholderStyle:
                                                            placeStyle,
                                                        cursorColor: appTheme.color.darker,
                                                        style: wrtingStyle,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .grey[20],
                                                        ),
                                                      )),
                                                ]),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 2,
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10),
                                            height: 10.h,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'profession',
                                                  style: tstyle,
                                                ).tr(),
                                                smallSpace,
                                                SizedBox(
                                                    height: 5.h,
                                                    child: TextBox(
                                                      placeholder:
                                                          'profession'.tr(),
                                                      placeholderStyle:
                                                          placeStyle,
                                                      cursorColor: appTheme.color.darker,
                                                      style: wrtingStyle,
                                                      decoration:
                                                          BoxDecoration(
                                                        color:
                                                            Colors.grey[20],
                                                      ),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 4,
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10),
                                            height: 10.h,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'adresse',
                                                  style: tstyle,
                                                ).tr(),
                                                smallSpace,
                                                SizedBox(
                                                    height: 5.h,
                                                    child: TextBox(
                                                      placeholder:
                                                          'adresse'.tr(),
                                                      placeholderStyle:
                                                          placeStyle,
                                                      cursorColor: appTheme.color.darker,
                                                      style: wrtingStyle,
                                                      decoration:
                                                          BoxDecoration(
                                                        color:
                                                            Colors.grey[20],
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
                                              height: 10.h,
                                            ),
                                          ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 1,
                                          child: Container(
                                            height: 10.h,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'genre',
                                                    style: tstyle,
                                                  ).tr(),
                                                  smallSpace,
                                                  TextBox(
                                                    placeholder:
                                                        'genre'.tr(),
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor: appTheme.color.darker,
                                                    style: wrtingStyle,
                                                    decoration:
                                                        BoxDecoration(
                                                      color:
                                                          Colors.grey[20],
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
                                            height: 10.h,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'marque',
                                                    style: tstyle,
                                                  ).tr(),
                                                  smallSpace,
                                                  TextBox(
                                                    placeholder:
                                                        'marque'.tr(),
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor: appTheme.color.darker,
                                                    style: wrtingStyle,
                                                    decoration:
                                                        BoxDecoration(
                                                      color:
                                                          Colors.grey[20],
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
                                            height: 10.h,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'type',
                                                    style: tstyle,
                                                  ).tr(),
                                                  smallSpace,
                                                  TextBox(
                                                    placeholder:
                                                        'type'.tr(),
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor: appTheme.color.darker,
                                                    style: wrtingStyle,
                                                    decoration:
                                                        BoxDecoration(
                                                      color:
                                                          Colors.grey[20],
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
                                            height: 10.h,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'numerserie',
                                                    style: tstyle,
                                                  ).tr(),
                                                  smallSpace,
                                                  TextBox(
                                                    placeholder:
                                                        'numerserie'.tr(),
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor: appTheme.color.darker,
                                                    style: wrtingStyle,
                                                    decoration:
                                                        BoxDecoration(
                                                      color:
                                                          Colors.grey[20],
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
                                            height: 10.h,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'caross',
                                                    style: tstyle,
                                                  ).tr(),
                                                  smallSpace,
                                                  TextBox(
                                                    placeholder:
                                                        'caross'.tr(),
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor: appTheme.color.darker,
                                                    style: wrtingStyle,
                                                    decoration:
                                                        BoxDecoration(
                                                      color:
                                                          Colors.grey[20],
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
                                            height: 10.h,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'energie',
                                                    style: tstyle,
                                                  ).tr(),
                                                  smallSpace,
                                                  TextBox(
                                                    placeholder:
                                                        'energie'.tr(),
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor: appTheme.color.darker,
                                                    style: wrtingStyle,
                                                    decoration:
                                                        BoxDecoration(
                                                      color:
                                                          Colors.grey[20],
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
                                            height: 10.h,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'puissance',
                                                    style: tstyle,
                                                  ).tr(),
                                                  smallSpace,
                                                  TextBox(
                                                    placeholder: '000',
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor: appTheme.color.darker,
                                                    style: wrtingStyle,
                                                    decoration:
                                                        BoxDecoration(
                                                      color:
                                                          Colors.grey[20],
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
                                            height: 10.h,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'placeassise',
                                                    style: tstyle,
                                                  ).tr(),
                                                  smallSpace,
                                                  TextBox(
                                                    placeholder: '000',
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor: appTheme.color.darker,
                                                    style: wrtingStyle,
                                                    decoration:
                                                        BoxDecoration(
                                                      color:
                                                          Colors.grey[20],
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
                                            height: 10.h,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'poidstotal',
                                                    style: tstyle,
                                                  ).tr(),
                                                  smallSpace,
                                                  TextBox(
                                                    placeholder: '000000',
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor: appTheme.color.darker,
                                                    style: wrtingStyle,
                                                    decoration:
                                                        BoxDecoration(
                                                      color:
                                                          Colors.grey[20],
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
                                            height: 10.h,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'chargeutil',
                                                    style: tstyle,
                                                  ).tr(),
                                                  smallSpace,
                                                  TextBox(
                                                    placeholder: '000000',
                                                    placeholderStyle:
                                                        placeStyle,
                                                    cursorColor: appTheme.color.darker,
                                                    style: wrtingStyle,
                                                    decoration:
                                                        BoxDecoration(
                                                      color:
                                                          Colors.grey[20],
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
                                            height: 10.h,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'precmat',
                                                    style: tstyle,
                                                  ).tr(),
                                                  smallSpace,
                                                  Flexible(
                                                      child: TextBox(
                                                    placeholder:
                                                        'precmat'.tr(),
                                                    placeholderStyle:
                                                        placeStyle,
                                                        cursorColor: appTheme.color.darker,
                                                        style: wrtingStyle,
                                                    decoration:
                                                        BoxDecoration(
                                                      color:
                                                          Colors.grey[20],
                                                    ),
                                                  )),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        StaggeredGridTile.fit(
                                          crossAxisCellCount: 2,
                                          child: Container(
                                            height: 10.h,
                                            padding: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: appTheme.color,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 5.0),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'anneeutil',
                                                    style: tstyle,
                                                  ).tr(),
                                                  smallSpace,
                                                  Flexible(
                                                      child: TextBox(
                                                    placeholder: 'XXXX',
                                                    placeholderStyle:
                                                        placeStyle,
                                                        cursorColor: appTheme.color.darker,
                                                        style: wrtingStyle,
                                                    decoration:
                                                        BoxDecoration(
                                                      color:
                                                          Colors.grey[20],
                                                    ),
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
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                  child: const Text('confirmer').tr(), onPressed: () {}),
            ],
          ),
        ));
  }

  List<Commune?> getCommune() {
    List<Commune?> result = List.empty(growable: true);
    for (var element in dzair.getWilayat()!) {
      if (element!.getWilayaName(Language.FR) == wilayaName) {
        result.addAll(element.getCommunes()!);
        break;
      }
    }
    return result;
  }

  List<Daira?> getDairas() {
    List<Daira?> result = List.empty(growable: true);
    for (var element in dzair.getWilayat()!) {
      if (element!.getWilayaName(Language.FR) == wilayaName) {
        result.addAll(element.getDairas()!);
        break;
      }
    }
    return result;
  }

  @override
  bool get wantKeepAlive => true;
}
