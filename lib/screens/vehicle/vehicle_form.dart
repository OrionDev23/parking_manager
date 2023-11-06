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
        content: Center(
          child: Padding(
            padding: const EdgeInsets.all(5.0),
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
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(),
                      left: BorderSide(),
                      right: BorderSide(),
                      bottom: BorderSide(),
                    ),
                  ),
                  width: 70.w,
                  height: 80.h,
                  child: MasonryGridView.count(
                    crossAxisCount: 3,
                    itemCount: 4,
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    itemBuilder: (c, index) {
                      switch (index) {
                        case 0:
                          return SizedBox(
                            width: double.infinity,
                              height: 17.h,
                              child: Column(
                                children: [
                                  Text(
                                    'pays',
                                    style: tstyle,
                                  ).tr(),
                                  CountryCodePicker(
                                    boxDecoration: BoxDecoration(
                                        color: appTheme.mode == ThemeMode.dark
                                            ? Colors.grey
                                            : appTheme.mode == ThemeMode.light
                                                ? Colors.white
                                                : ThemeMode.system ==
                                                        ThemeMode.light
                                                    ? Colors.white
                                                    : Colors.grey,
                                        boxShadow: kElevationToShadow[2]),
                                    padding: const EdgeInsets.all(3),
                                    searchDecoration: inputDecoration,
                                    dialogSize: Size(40.w, 60.h),
                                    initialSelection: pays,
                                    showCountryOnly: true,
                                    showDropDownButton: true,
                                    showFlagDialog: true,
                                    showOnlyCountryWhenClosed: true,
                                    onChanged: (c) {
                                      setState(() {
                                        pays = c.code ?? 'DZ';
                                      });
                                    },
                                  ),
                                  Text(
                                    'wilaya',
                                    style: tstyle,
                                  ).tr(),
                                  SizedBox(
                                    width: 13.w,
                                    height: 5.h,
                                    child: AutoSuggestBox<String>(
                                      placeholder: 'wilaya'.tr(),
                                      placeholderStyle: placeStyle,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[20],
                                      ),
                                      items: dzair.getWilayat()!.map((wilaya) {
                                        return AutoSuggestBoxItem<String>(
                                          value: wilaya!.getWilayaCode()!,
                                          label: wilaya.getWilayaName(appTheme
                                                      .locale!.languageCode
                                                      .toUpperCase() ==
                                                  "AR"
                                              ? Language.AR
                                              : Language.FR)!,
                                        );
                                      }).toList(),
                                      onSelected: (item) {
                                        setState(() {
                                          wilaya = item.value!;
                                          wilayaName = dzair
                                                  .searchWilayatByName(
                                                      item.label,
                                                      appTheme.locale!
                                                                  .languageCode
                                                                  .toUpperCase() ==
                                                              "AR"
                                                          ? Language.AR
                                                          : Language.FR)
                                                  ?.first
                                                  ?.getWilayaName(
                                                      Language.FR) ??
                                              '';
                                        });
                                      },
                                      onChanged: (s, r) {
                                        if (r == TextChangedReason.userInput) {
                                          setState(() => wilayaName = s);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ));

                        case 1:
                          return SizedBox(
                            width: double.infinity,
                            height: 17.h,
                            child: Container(
                              padding: EdgeInsets.zero,
                              decoration: const BoxDecoration(
                                border: Border(
                                  left: BorderSide(),
                                  right: BorderSide(),
                                  bottom: BorderSide(),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'nummat',
                                    style: tstyle,
                                  ).tr(),
                                  const Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0),
                                    child: autreMat
                                        ? TextBox(
                                            controller: matriculeEtr,
                                            placeholder: 'XXXXXXXXXXXXXX',
                                            textAlign: TextAlign.center,
                                            placeholderStyle: placeStyle,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[20],
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                flex: 6,
                                                child: TextBox(
                                                  controller: matr1,
                                                  placeholder: '123456',
                                                  placeholderStyle: placeStyle,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[20],
                                                  ),
                                                  maxLength: 6,
                                                  textAlign: TextAlign.center,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly
                                                  ],
                                                ),
                                              ),
                                              smallSpace,
                                              Text(
                                                '-',
                                                style: tstyle,
                                              ),
                                              smallSpace,
                                              Flexible(
                                                flex: 3,
                                                child: TextBox(
                                                  controller: matr2,
                                                  placeholder: '123',
                                                  maxLength: 3,
                                                  placeholderStyle: placeStyle,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[20],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly
                                                  ],
                                                ),
                                              ),
                                              smallSpace,
                                              Text(
                                                '-',
                                                style: tstyle,
                                              ),
                                              smallSpace,
                                              Flexible(
                                                flex: 2,
                                                child: TextBox(
                                                  controller: matr3,
                                                  placeholder: '12',
                                                  maxLength: 2,
                                                  placeholderStyle: placeStyle,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[20],
                                                  ),
                                                  textAlign: TextAlign.center,
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
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Checkbox(
                                        checked: autreMat,
                                        content: Text(
                                          'autremat',
                                          style: TextStyle(
                                              color: Colors.grey[100]),
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
                          );
                        case 2:
                          return SizedBox(
                              width: double.infinity,
                              height: 17.h,
                              child: Column(
                                children: [
                                  Text(
                                    'daira',
                                    style: tstyle,
                                  ).tr(),
                                  SizedBox(
                                    width: 13.w,
                                    height: 5.h,
                                    child: AutoSuggestBox<String>(
                                      placeholder: 'daira'.tr(),
                                      placeholderStyle: placeStyle,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[20],
                                      ),
                                      items: getDairas().map((daira) {
                                        return AutoSuggestBoxItem<String>(
                                          value: daira
                                                  ?.getDairaName(Language.FR) ??
                                              '',
                                          label: daira?.getDairaName(appTheme
                                                          .locale?.languageCode
                                                          .toUpperCase() ==
                                                      "AR"
                                                  ? Language.AR
                                                  : Language.FR) ??
                                              '',
                                        );
                                      }).toList(),
                                      onSelected: (item) {
                                        setState(
                                            () => daira = item.value ?? "");
                                      },
                                      onChanged: (s, r) {
                                        if (r == TextChangedReason.userInput) {
                                          setState(() => daira = s);
                                        }
                                      },
                                    ),
                                  ),
                                  Text(
                                    'commune',
                                    style: tstyle,
                                  ).tr(),
                                  SizedBox(
                                    width: 13.w,
                                    height: 5.h,

                                    child: AutoSuggestBox<String>(
                                      placeholder: 'commune'.tr(),
                                      placeholderStyle: placeStyle,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[20],
                                      ),
                                      items: getCommune().map((commune) {
                                        return AutoSuggestBoxItem<String>(
                                          value: commune == null
                                              ? ''
                                              : commune.getCommuneName(
                                                      Language.FR) ??
                                                  '',
                                          label: commune == null
                                              ? ''
                                              : commune.getCommuneName(appTheme
                                                              .locale
                                                              ?.languageCode
                                                              .toUpperCase() ==
                                                          "AR"
                                                      ? Language.AR
                                                      : Language.FR) ??
                                                  '',
                                        );
                                      }).toList(),
                                      onSelected: (item) {
                                        setState(
                                            () => commune = item.value ?? "");
                                      },
                                      onChanged: (s, r) {
                                        if (r == TextChangedReason.userInput) {
                                          setState(() => commune = s);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ));

                        case 3:
                          return SizedBox(
                              width: 17.w,
                              height: 7.h,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'date',
                                    style: tstyle,
                                  ).tr(),
                                  smallSpace,
                                  SizedBox(
                                      width: 15.w,
                                      child:
                                          DatePicker(selected: selectedDate)),
                                  smallSpace,
                                ],
                              ));
                              /*
                        case 4:
                          return SizedBox(
                              width: 17.w,
                              height: 15.h,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'quittance',
                                    style: tstyle,
                                  ).tr(),
                                  smallSpace,
                                  SizedBox(
                                      width: 10.w,
                                      child: TextBox(
                                        placeholder: 'quittance'.tr(),
                                        placeholderStyle: placeStyle,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[20],
                                        ),
                                      )),
                                ],
                              ));
                        case 5:
                          return SizedBox(
                              width: 17.w,
                              height: 15.h,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'num',
                                    style: tstyle,
                                  ).tr(),
                                  smallSpace,
                                  SizedBox(
                                      width: 20.w,
                                      child: TextBox(
                                        placeholder: 'num'.tr(),
                                        placeholderStyle: placeStyle,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[20],
                                        ),
                                      )),
                                ],
                              ));
                        case 6:
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'nomf',
                                style: tstyle,
                              ).tr(),
                              smallSpace,
                              SizedBox(
                                  width: 15.w,
                                  child: TextBox(
                                    placeholder: 'nomf'.tr(),
                                    placeholderStyle: placeStyle,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[20],
                                    ),
                                  )),
                            ],
                          );
                        case 7:
                          return SizedBox(
                              width: 17.w,
                              height: 15.h,
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'prenom',
                                      style: tstyle,
                                    ).tr(),
                                    smallSpace,
                                    SizedBox(
                                        width: 15.w,
                                        child: TextBox(
                                          placeholder: 'prenom'.tr(),
                                          placeholderStyle: placeStyle,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[20],
                                          ),
                                        )),
                                  ]));
                        case 8:
                          return SizedBox(
                              width: 17.w,
                              height: 15.h,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'profession',
                                    style: tstyle,
                                  ).tr(),
                                  smallSpace,
                                  SizedBox(
                                      width: 15.w,
                                      child: TextBox(
                                        placeholder: 'profession'.tr(),
                                        placeholderStyle: placeStyle,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[20],
                                        ),
                                      )),
                                ],
                              ));
                        case 9:
                          SizedBox(
                              width: 17.w,
                              height: 15.h,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'adresse',
                                    style: tstyle,
                                  ).tr(),
                                  smallSpace,
                                  SizedBox(
                                      width: 30.w,
                                      child: TextBox(
                                        placeholder: 'adresse'.tr(),
                                        placeholderStyle: placeStyle,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[20],
                                        ),
                                      )),
                                ],
                              ));
                        case 10:
                          SizedBox(
                              width: 17.w,
                              height: 15.h,
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      height: 10.h,
                                      padding: EdgeInsets.zero,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(),
                                          bottom: BorderSide(),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5.0),
                                        child: Column(
                                          children: [
                                            Text(
                                              'genre',
                                              style: tstyle,
                                            ).tr(),
                                            smallSpace,
                                            TextBox(
                                              placeholder: 'genre'.tr(),
                                              placeholderStyle: placeStyle,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[20],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    flex: 2,
                                    child: Container(
                                      height: 10.h,
                                      padding: EdgeInsets.zero,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(),
                                          bottom: BorderSide(),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5.0),
                                        child: Column(
                                          children: [
                                            Text(
                                              'marque',
                                              style: tstyle,
                                            ).tr(),
                                            smallSpace,
                                            TextBox(
                                              placeholder: 'marque'.tr(),
                                              placeholderStyle: placeStyle,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[20],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Container(
                                      height: 10.h,
                                      padding: EdgeInsets.zero,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(),
                                          bottom: BorderSide(),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5.0),
                                        child: Column(
                                          children: [
                                            Text(
                                              'type',
                                              style: tstyle,
                                            ).tr(),
                                            smallSpace,
                                            TextBox(
                                              placeholder: 'type'.tr(),
                                              placeholderStyle: placeStyle,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[20],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    flex: 2,
                                    child: Container(
                                      height: 10.h,
                                      padding: EdgeInsets.zero,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5.0),
                                        child: Column(
                                          children: [
                                            Text(
                                              'numerserie',
                                              style: tstyle,
                                            ).tr(),
                                            smallSpace,
                                            TextBox(
                                              placeholder: 'numerserie'.tr(),
                                              placeholderStyle: placeStyle,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[20],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ));
                        case 11:
                          SizedBox(
                              width: 17.w,
                              height: 15.h,
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      height: 10.h,
                                      padding: EdgeInsets.zero,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(),
                                          bottom: BorderSide(),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5.0),
                                        child: Column(
                                          children: [
                                            Text(
                                              'caross',
                                              style: tstyle,
                                            ).tr(),
                                            smallSpace,
                                            TextBox(
                                              placeholder: 'caross'.tr(),
                                              placeholderStyle: placeStyle,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[20],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Container(
                                      height: 10.h,
                                      padding: EdgeInsets.zero,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(),
                                          bottom: BorderSide(),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5.0),
                                        child: Column(
                                          children: [
                                            Text(
                                              'energie',
                                              style: tstyle,
                                            ).tr(),
                                            smallSpace,
                                            TextBox(
                                              placeholder: 'energie'.tr(),
                                              placeholderStyle: placeStyle,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[20],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Container(
                                      height: 10.h,
                                      padding: EdgeInsets.zero,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(),
                                          bottom: BorderSide(),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
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
                                              placeholderStyle: placeStyle,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[20],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Container(
                                      height: 10.h,
                                      padding: EdgeInsets.zero,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(),
                                          bottom: BorderSide(),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
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
                                              placeholderStyle: placeStyle,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[20],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Container(
                                      height: 10.h,
                                      padding: EdgeInsets.zero,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          right: BorderSide(),
                                          bottom: BorderSide(),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
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
                                              placeholderStyle: placeStyle,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[20],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Container(
                                      height: 10.h,
                                      padding: EdgeInsets.zero,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
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
                                              placeholderStyle: placeStyle,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[20],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ));
                        case 12:
                          SizedBox(
                            width: 70.w,
                            height: 15.h,
                            child: Row(
                              children: [
                                Flexible(
                                  flex: 2,
                                  child: Container(
                                    height: 10.h,
                                    padding: EdgeInsets.zero,
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        right: BorderSide(),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5.0),
                                      child: Row(
                                        children: [
                                          Text(
                                            'precmat',
                                            style: tstyle,
                                          ).tr(),
                                          smallSpace,
                                          Flexible(
                                              child: TextBox(
                                            placeholder: 'precmat'.tr(),
                                            placeholderStyle: placeStyle,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[20],
                                            ),
                                          )),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.zero,
                                    decoration: const BoxDecoration(
                                      border: Border(),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5.0),
                                      child: Row(
                                        children: [
                                          Text(
                                            'anneeutil',
                                            style: tstyle,
                                          ).tr(),
                                          smallSpace,
                                          Flexible(
                                              child: TextBox(
                                            placeholder: 'XXXX',
                                            placeholderStyle: placeStyle,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[20],
                                            ),
                                          )),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );*/
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomBar: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(child: const Text('confirm').tr(), onPressed: () {}),
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
