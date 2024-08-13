import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_chip_tags/flutter_chip_tags.dart';
import 'package:parc_oto/datasources/workshop/option/option_datasource.dart';
import 'package:parc_oto/widgets/zone_box.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../providers/client_database.dart';
import '../../../../providers/parts_provider.dart';
import '../../../../serializables/pieces/option.dart';
import '../../../../theme.dart';
class OptionForm extends StatefulWidget {
  final Option? option;
  const OptionForm({super.key, this.option});

  @override
  State<OptionForm> createState() => _OptionFormState();
}

class _OptionFormState extends State<OptionForm> {
  TextEditingController optionName = TextEditingController();
  TextEditingController optionCode = TextEditingController();
  late String optionKey;

  bool loading = false;
  bool error = false;

  @override
  void initState() {
    optionName.text = widget.option?.name ?? '';
    optionCode.text = widget.option?.code ?? '';
    values = widget.option?.values ?? List.empty(growable: true);
    optionKey = widget.option?.id??DateTime.now()
        .difference(DatabaseGetter.ref)
        .inMilliseconds.toString();
    super.initState();
  }

  late List<String> values;

  bool errorCode = false;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        width: 20.w,
        height: 20.h,
        child: const Center(
          child: ProgressRing(),
        ),
      );
    }
    var appTheme = context.watch<AppTheme>();

    return Container(
      padding: const EdgeInsets.all(10),
      height: 450.px,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: appTheme.backGroundColor,
              boxShadow: kElevationToShadow[2],
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: 450.px,
              height: 370.px,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Flexible(
                    flex: 2,
                    child: ZoneBox(
                        label: 'code'.tr(),
                        child:  Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Flexible(
                                child: TextBox(
                                  controller: optionCode,
                                  placeholder: 'code'.tr(),
                                  onChanged: (s) {
                                    if (PartsProvider.options.containsKey(s)) {
                                      setState(() {
                                        errorCode = true;
                                      });
                                    } else {
                                      errorCode = false;
                                      setState(() {});
                                    }
                                  },
                                  enabled: widget.option == null,
                                  style: appTheme.writingStyle,
                                  placeholderStyle: placeStyle,
                                  cursorColor: appTheme.color.darker,
                                  decoration: BoxDecoration(
                                    color: appTheme.fillColor,
                                  ),
                                ),
                              ),
                              smallSpace,
                              Button(
                                  onPressed: widget.option == null
                                      ? () {
                                    setState(() {
                                      optionCode.text =
                                          PartsProvider.getUniqueCodeOption();
                                    });
                                  }
                                      : null,
                                  child: const Text('generer').tr())
                            ],
                          ),
                        ),

                    ),
                  ),
                  smallSpace,
                  if (errorCode)
                    smallSpace,
                  if (errorCode)
                    Text(
                      'codetaken',
                      style: TextStyle(color: Colors.red),
                    ).tr(),
                  smallSpace,

                  Flexible(
                    flex: 2,
                    child: ZoneBox(label: 'nom'.tr(),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextBox(
                        controller: optionName,
                        placeholder: 'nom'.tr(),
                        onChanged: (s) {
                          setState(() {});
                        },
                        style: appTheme.writingStyle,
                        placeholderStyle: placeStyle,
                        cursorColor: appTheme.color.darker,
                        decoration: BoxDecoration(
                          color: appTheme.fillColor,
                        ),
                      ),
                    ),
                    ),
                  ),

                  bigSpace,
                  Flexible(
                    flex: 4,
                    child: ZoneBox(
                      label: 'values'.tr(),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ListView(
                          children: [
                            m.Material(
                              color: appTheme.backGroundColor,
                              child:  ChipTags(
                                list: values,
                                iconColor: appTheme.color.darkest,
                                chipColor: appTheme.color.lightest,
                                textColor: appTheme.writingStyle.color!,
                                decoration: m.InputDecoration(
                                  hintText: 'entervalues'.tr(),
                                  hintStyle: placeStyle,
                                  fillColor: appTheme.backGroundColor,
                                ),

                                createTagOnSubmit: true,
                              ),
                            )

                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          smallSpace,
          Container(
            padding: const EdgeInsets.all(10),
            width: 400.px,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Button(
                  child: const Text('annuler').tr(),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                smallSpace,
                FilledButton(
                  child: const Text('confirmer').tr(),
                  onPressed: () {
                    if (optionCode.text.isEmpty || optionName.text.isEmpty) {
                      if (optionCode.text.isEmpty) {
                        showMessage("codeerror", "erreur");
                        return;
                      }
                      if (optionName.text.isEmpty) {
                        showMessage("nomerror", "erreur");
                        return;
                      }
                    } else {
                      createOption()
                          .whenComplete(() {
                      });
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> createOption() async {
    setState(() {
      loading = true;
    });
    DateTime date = DateTime.now();

    Option option=Option(
        id: optionKey.toString(),
        name: optionName.text,
        code: optionCode.text,
        values: values,
        updatedAt: date,
        createdAt:widget.option == null ||
            widget.option!.createdAt == null
            ? date
            : widget.option!.createdAt);
    if(widget.option!=null){
      await DatabaseGetter().updateDocument(collectionId: optionsID,
          documentId: optionKey, data: option.toJson()).catchError((s){

            showMessage('errupld', 'erreur');});
    }
    else{
      await DatabaseGetter().addDocument(collectionId: optionsID,
          documentId: optionKey, data: option.toJson()).catchError((s){

        showMessage('errupld', 'erreur');});
    }

      showMessage('optionadd', 'fait');
      PartsProvider.options[optionKey] = option;
      if (OptionDatasource.instance != null) {
        OptionDatasource.instance!.repo.data.add(MapEntry(optionKey,
            option));
        OptionDatasource.instance!.refreshDatasource();

      }

      if(mounted){
        Navigator.of(context).pop();
      }
    setState(() {
      loading = false;
    });
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
            child: const Text('ok').tr(),
            onPressed: () async {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
