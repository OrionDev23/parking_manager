
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/datasources/workshop/category/category_datasource.dart';
import 'package:parc_oto/screens/workshop/parts/categories/category_table.dart';
import 'package:parc_oto/theme.dart';
import 'package:parc_oto/widgets/zone_box.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../providers/client_database.dart';
import '../../../../providers/parts_provider.dart';
import '../../../../serializables/pieces/category.dart';

class CategoryForm extends StatefulWidget {
  final Category? category;
  const CategoryForm({
    super.key,
    this.category,
  });

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> with
    AutomaticKeepAliveClientMixin<CategoryForm>{
  TextEditingController catName = TextEditingController();
  TextEditingController catCode = TextEditingController();
  late String categoryKey;
  bool loading = false;
  bool error = false;

  Future<void> downloadCats() async {
    if (PartsProvider.errorCategories) {
      loading = true;
      try {
        await PartsProvider().downloadAllCategories();
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
    catName.text = widget.category?.name ?? '';
    catCode.text = widget.category?.code ?? '';
    selectedCat = widget.category != null &&
            widget.category!.codeParent != null &&
            PartsProvider.categories.containsKey(widget.category?.codeParent)
        ? PartsProvider.categories[widget.category!.codeParent]!
        : null;
    categoryKey = widget.category?.id ??
        DateTime.now().difference(DatabaseGetter.ref).inMilliseconds.toString();
    downloadCats();
    super.initState();
  }

  Category? selectedCat;
  Widget categoryParents( AppTheme appTheme) {
    return Flexible(
      child: ZoneBox(label: 'catparnt'.tr(),
      child:        Padding(
        padding: const EdgeInsets.all(10.0),
        child: Button(
          child: Text(selectedCat==null?'nonind'.tr():'${selectedCat!.code} : '
              '${selectedCat!.name}'),
          onPressed: () async{
            selectedCat = await showDialog<Category>(
                context: context,
                barrierDismissible: true,
                builder: (context) {
                  return ContentDialog(
                    constraints: BoxConstraints.tight(
                        Size(700.px, 550.px)),
                    title: const Text('catparnt').tr(),
                    style: ContentDialogThemeData(
                        titleStyle: appTheme.writingStyle
                            .copyWith(
                            fontWeight:
                            FontWeight.bold)),
                    content: const CategoryTable(
                      selectD: true,
                    ),
                    actions: [Button(child: const Text('fermer').tr(),
                        onPressed: (){
                          selectedCat=null;
                          setState(() {

                          });
                          Navigator.of(context).pop();
                        })],
                  );
                });
            setState(() {

            });
          },
        ),
      ),),
    );
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
                  downloadCats();
                })
          ],
        ),
      );
    }
    var appTheme=context.watch<AppTheme>();
    return SizedBox(
      width: 400.px,
      height: 400.px,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding:const EdgeInsets.all(10),
            height: 280.px,
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
                          controller: catCode,
                          placeholder: 'code'.tr(),
                          onChanged: (s) {
                            if (PartsProvider.categories.containsKey(s)) {
                              setState(() {
                                errorCode = true;
                              });
                            } else {
                              errorCode = false;
                              setState(() {});
                            }
                          },
                          enabled: widget.category == null,
                          style: appTheme.writingStyle,
                          placeholderStyle: placeStyle,
                          cursorColor: appTheme.color.darker,
                          decoration: BoxDecoration(
                            color: appTheme.fillColor,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Button(
                          onPressed: widget.category == null
                              ? () {
                            setState(() {
                              catCode.text = PartsProvider
                                  .getUniqueCodeCategory();
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
                      controller: catName,
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
                  ),),
                ),
                bigSpace,
                categoryParents(appTheme),
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
                    if (catCode.text.isEmpty || catName.text.isEmpty) {
                      if (catCode.text.isEmpty) {
                        showMessage("codeerror", "erreur");
                        return;
                      }
                      if (catName.text.isEmpty) {
                        showMessage("nomerror", "erreur");
                        return;
                      }
                    } else {
                      createCategory();
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

  Future<void> createCategory() async {
    setState(() {
      loading = true;
    });
    DateTime date = DateTime.now();

    Category cat=Category(
        id: catCode.text,
        name: catName.text,
        code: catCode.text,
        codeParent: selectedCat?.id,
        updatedAt: date,
        createdAt: widget.category == null ||
            widget.category!.createdAt == null
            ? date
            : widget.category!.createdAt);
    if(widget.category==null){
      await DatabaseGetter().addDocument(collectionId: categoriesID,
          documentId: categoryKey, data: cat.toJson()).then((s){
        DatabaseGetter().ajoutActivity(54, cat.id, docName: cat.name);

        showMessage('catadd', 'fait');
        PartsProvider.categories[categoryKey] = cat;
        if (CategoryDatasource.instance != null) {
          CategoryDatasource.instance!.refreshDatasource();
        }
      }).catchError((s){
        showMessage('errupld', 'erreur');
      });
    }
    else{
      await DatabaseGetter().updateDocument(collectionId: categoriesID,
          documentId: categoryKey, data: cat.toJson()).then((s){
        DatabaseGetter().ajoutActivity(55, cat.id, docName: cat.name);

        showMessage('catmod', 'fait');
        PartsProvider.categories[categoryKey] = cat;
        if (CategoryDatasource.instance != null) {
          CategoryDatasource.instance!.refreshDatasource();
        }
      }).catchError
        ((s){
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
