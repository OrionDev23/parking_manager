
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/parts_provider.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../datasources/workshop/brand/brand_datasrouce.dart';
import '../../../../providers/client_database.dart';
import '../../../../serializables/pieces/brand.dart';
import '../../../../theme.dart';
import '../../../../widgets/zone_box.dart';


class BrandForm extends StatefulWidget {
  final Brand? brand;

  const BrandForm({super.key,  this.brand,});

  @override
  State<BrandForm> createState() => _BrandFormState();
}

class _BrandFormState extends State<BrandForm> with
    AutomaticKeepAliveClientMixin<BrandForm>{
  TextEditingController brandName = TextEditingController();
  TextEditingController brandCode = TextEditingController();
  late String brandKey;

  bool loading = false;
  bool error = false;

  Future<void> downloadBrands() async {
    if (PartsProvider.errorBrands) {
      loading = true;
      if(mounted){
        setState(() {

        });
      }
      try {
        await PartsProvider().downloadAllBrands();
        loading = false;
        error = false;
      } catch (e) {
        error = true;
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    brandName.text = widget.brand?.name ?? '';
    brandCode.text = widget.brand?.code ?? '';
    brandKey = widget.brand?.id??DateTime.now()
        .difference(DatabaseGetter.ref)
        .inMilliseconds.toString();
    downloadBrands();
    super.initState();
  }

  bool errorCode = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (loading) {
      return SizedBox(
        width: 20.w,
        height: 20.h,
        child: const Center(
          child: ProgressRing(),
        ),
      );
    }
    if (error) {
      return SizedBox(
        width: 20.w,
        height: 20.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('erreur').tr(),
            const SizedBox(
              width: 10,
            ),
            FilledButton(
                child: Row(
                  children: [
                    const Icon(FluentIcons.refresh),
                    const SizedBox(
                      width: 5,
                    ),
                    const Text('retry').tr(),
                  ],
                ),
                onPressed: () {
                  downloadBrands();
                })
          ],
        ),
      );
    }
    var appTheme=context.watch<AppTheme>();
    return SizedBox(
      width: 400.px,
      height: 200.px,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding:const EdgeInsets.all(10),
            height: 180.px,
            width: 380.px,
            decoration: BoxDecoration(
              color: appTheme.backGroundColor,
              boxShadow: kElevationToShadow[2],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Flexible(child: ZoneBox(label: 'code'.tr(),child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Flexible(
                        child: TextBox(
                          controller: brandCode,
                          placeholder: 'code'.tr(),
                          onChanged: (s) {
                            if (PartsProvider.brands.containsKey(s)) {
                              setState(() {
                                errorCode = true;
                              });
                            } else {
                              errorCode = false;
                              setState(() {});
                            }
                          },
                          enabled: widget.brand == null,
                          style: appTheme.writingStyle,
                          placeholderStyle: placeStyle,
                          cursorColor: appTheme.color.darker,
                          decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Button(
                          onPressed: widget.brand == null
                              ? () {
                            setState(() {
                              brandCode.text = PartsProvider
                                  .getUniqueCodeBrand();
                            });
                          }
                              : null,
                          child: const Text('generer').tr())
                    ],
                  ),
                ),)),
                if (errorCode)
                  smallSpace,
                if (errorCode)
                  Text(
                    'codetaken',
                    style: TextStyle(color: Colors.red),
                  ).tr(),
                Flexible(
                  child: ZoneBox(label: 'nom'.tr(),child:  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextBox(
                      controller: brandName,
                      placeholder: 'nom'.tr(),
                      onChanged: (s) {
                        setState(() {});
                      },
                      style: appTheme.writingStyle,
                      placeholderStyle: placeStyle,
                      cursorColor: appTheme.color.darker,
                      decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),

                    ),
                  ),),
                ),
              ],
            ),
          ),
          bigSpace,
          SizedBox(
            width: 380.px,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  child: const Text('confirmer').tr(),
                  onPressed: () {
                    if (brandCode.text.isEmpty || brandName.text.isEmpty) {
                      if (brandCode.text.isEmpty) {
                        showMessage("codeerror", "erreur");
                        return;
                      }
                      if (brandName.text.isEmpty) {
                        showMessage("nomerror", "erreur");
                        return;
                      }
                    } else {
                      createBrand();
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

  Future<void> createBrand() async {
    setState(() {
      loading = true;
    });
    DateTime date = DateTime.now();

    Brand brand=Brand(
        id: brandKey,
        name: brandName.text,
        code: brandCode.text,
        updatedAt: date,
        createdAt: widget.brand == null
            ? date
            : widget.brand!.createdAt);

    if(widget.brand==null){
      await DatabaseGetter().addDocument(
          collectionId: brandsID,
          documentId: brandKey,
          data: brand.toJson()).then((s){
        DatabaseGetter().ajoutActivity(57, brand.id, docName: brand.name);

        showMessage('brandadd', 'fait');
        PartsProvider.brands[brandKey] = brand;
        if (BrandDatasource.instance != null ) {
          BrandDatasource.instance!.refreshDatasource();}
      }).catchError((e){
        showMessage('errupld', 'erreur');
      });
    }
    else{
      await DatabaseGetter().updateDocument(
          collectionId: brandsID,
          documentId: brandKey,
          data: brand.toJson()).then((s){
        DatabaseGetter().ajoutActivity(58, brand.id, docName: brand.name);

        showMessage('brandmod', 'fait');
        PartsProvider.brands[brandKey] = brand;
        if (BrandDatasource.instance != null ) {
          BrandDatasource.instance!.refreshDatasource();
        }
      }).catchError((e){
        showMessage('errupld', 'erreur');
      });
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

  @override
  bool get wantKeepAlive => true;
}
