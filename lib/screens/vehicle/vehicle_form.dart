import 'package:country_code_picker/country_code_picker.dart';
import 'package:dzair_data_usage/commune.dart';
import 'package:dzair_data_usage/daira.dart';
import 'package:dzair_data_usage/dzair.dart';
import 'package:dzair_data_usage/langs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:parc_oto/serializables/vehicle.dart';
import 'package:parc_oto/widgets/page_header.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../theme.dart';

class VehicleForm extends StatefulWidget {
  final Vehicle? vehicle;
  const VehicleForm({super.key, this.vehicle});

  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm> {
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

  String wilaya = "01";
  String wilayaName = "Adrar";
  String commune = "";
  String daira = "";

  DateTime selectedDate = DateTime.now();
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
      header: PageTitle(
        text: 'nouvvehicule'.tr(),
      ),
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
              boxShadow: kElevationToShadow[2],
            ),
            width: 70.w,
            height: 80.h,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(),
                    left: BorderSide(),
                    right: BorderSide(),
                    bottom: BorderSide(),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: SizedBox(
                        height: 20.h,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                                child: Column(
                              children: [
                                const Text(
                                  'pays',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ).tr(),
                                smallSpace,
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
                                      backgroundBlendMode: BlendMode.difference,
                                      boxShadow: kElevationToShadow[2]),
                                  padding: const EdgeInsets.all(3),
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
                                smallSpace,
                                const Text(
                                  'wilaya',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ).tr(),
                                smallSpace,
                                SizedBox(
                                  width: 13.w,
                                  child: AutoSuggestBox<String>(
                                    placeholder: 'wilaya'.tr(),
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
                                                ?.getWilayaName(Language.FR) ??
                                            '';
                                      });
                                    },
                                  ),
                                ),
                              ],
                            )),
                            Expanded(
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'nummat',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ).tr(),
                                    smallSpace,
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5.0),
                                      child: autreMat
                                          ? TextBox(
                                              controller: matriculeEtr,
                                              placeholder: 'XXXXXXXXXXXXXX',
                                              textAlign: TextAlign.center,
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
                                                    maxLength: 6,
                                                    textAlign: TextAlign.center,
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter
                                                          .digitsOnly
                                                    ],
                                                  ),
                                                ),
                                                smallSpace,
                                                const Text('-'),
                                                smallSpace,
                                                Flexible(
                                                  flex: 3,
                                                  child: TextBox(
                                                    controller: matr2,
                                                    placeholder: '123',
                                                    maxLength: 3,
                                                    textAlign: TextAlign.center,
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter
                                                          .digitsOnly
                                                    ],
                                                  ),
                                                ),
                                                smallSpace,
                                                const Text('-'),
                                                smallSpace,
                                                Flexible(
                                                  flex: 2,
                                                  child: TextBox(
                                                    controller: matr3,
                                                    placeholder: '12',
                                                    maxLength: 2,
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
                                    smallSpace,
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
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                                child: Column(
                              children: [
                                const Text(
                                  'daira',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ).tr(),
                                smallSpace,
                                SizedBox(
                                  width: 13.w,
                                  child: AutoSuggestBox<String>(
                                    placeholder: 'daira'.tr(),
                                    items: getDairas().map((daira) {
                                      return AutoSuggestBoxItem<String>(
                                        value:
                                            daira!.getDairaName(Language.FR)!,
                                        label: daira.getDairaName(appTheme
                                                    .locale!.languageCode
                                                    .toUpperCase() ==
                                                "AR"
                                            ? Language.AR
                                            : Language.FR)!,
                                      );
                                    }).toList(),
                                    onSelected: (item) {
                                      setState(() => daira = item.value ?? "");
                                    },
                                    onChanged: (s, r) {
                                      if (r == TextChangedReason.userInput) {
                                        setState(() => daira = s);
                                      }
                                    },
                                  ),
                                ),
                                smallSpace,
                                const Text(
                                  'commune',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ).tr(),
                                smallSpace,
                                SizedBox(
                                  width: 13.w,
                                  child: AutoSuggestBox<String>(
                                    placeholder: 'commune'.tr(),
                                    items: getCommune().map((commune) {
                                      return AutoSuggestBoxItem<String>(
                                        value: commune!
                                            .getCommuneName(Language.FR)!,
                                        label: commune.getCommuneName(appTheme
                                                    .locale!.languageCode
                                                    .toUpperCase() ==
                                                "AR"
                                            ? Language.AR
                                            : Language.FR)!,
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
                            )),
                          ],
                        ),
                      ),
                    ),
                    smallSpace,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SizedBox(
                        height: 7.h,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'date',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ).tr(),
                            smallSpace,
                            SizedBox(
                                width: 15.w,
                                child: DatePicker(selected: selectedDate)),
                            smallSpace,
                            smallSpace,
                            const Text(
                              'quittance',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ).tr(),
                            smallSpace,
                            SizedBox(
                                width: 10.w,
                                child: TextBox(
                                  placeholder: 'quittance'.tr(),
                                )),
                            smallSpace,
                            smallSpace,
                            const Text(
                              'num',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ).tr(),
                            smallSpace,
                            SizedBox(
                                width: 20.w,
                                child: TextBox(
                                  placeholder: 'num'.tr(),
                                )),
                          ],
                        ),
                      ),
                    ),
                    smallSpace,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SizedBox(
                        height: 7.h,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'nomf',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ).tr(),
                            smallSpace,
                            SizedBox(
                                width: 15.w,
                                child: TextBox(
                                  placeholder: 'nomf'.tr(),
                                )),
                            smallSpace,
                            smallSpace,
                            const Text(
                              'prenom',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ).tr(),
                            smallSpace,
                            SizedBox(
                                width: 15.w,
                                child: TextBox(
                                  placeholder: 'prenom'.tr(),
                                )),
                            smallSpace,
                            smallSpace,
                            const Text(
                              'profession',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ).tr(),
                            smallSpace,
                            SizedBox(
                                width: 15.w,
                                child: TextBox(
                                  placeholder: 'profession'.tr(),
                                )),
                          ],
                        ),
                      ),
                    ),
                    smallSpace,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SizedBox(
                        height: 7.h,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'adresse',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ).tr(),
                            smallSpace,
                            SizedBox(
                                width: 30.w,
                                child: TextBox(
                                  placeholder: 'adresse'.tr(),
                                )),
                          ],
                        ),
                      ),
                    ),
                    smallSpace,
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        padding: EdgeInsets.zero,
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(),
                            right: BorderSide(),
                            top: BorderSide(),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
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
                                          const Text('genre').tr(),
                                          smallSpace,
                                          const TextBox(),
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
                                          const Text('marque').tr(),
                                          smallSpace,
                                          const TextBox(),
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
                                          const Text('type').tr(),
                                          smallSpace,
                                          const TextBox(),
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
                                          const Text('numerserie').tr(),
                                          smallSpace,
                                          const TextBox(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
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
                                          const Text('caross').tr(),
                                          smallSpace,
                                          const TextBox(),
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
                                          const Text('energie').tr(),
                                          smallSpace,
                                          const TextBox(),
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
                                          const Text('puissance').tr(),
                                          smallSpace,
                                          const TextBox(),
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
                                          const Text('placeassise').tr(),
                                          smallSpace,
                                          const TextBox(),
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
                                          const Text('poidstotal').tr(),
                                          smallSpace,
                                          const TextBox(),
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
                                          const Text('chargeutil').tr(),
                                          smallSpace,
                                          const TextBox(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
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
                                            const Text('precmat',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold))
                                                .tr(),
                                            smallSpace,
                                            const Flexible(child: TextBox()),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Container(
                                      padding: EdgeInsets.zero,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5.0),
                                        child: Row(
                                          children: [
                                            const Text('anneeutil',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold))
                                                .tr(),
                                            smallSpace,
                                            const Flexible(child: TextBox()),
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
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
}
