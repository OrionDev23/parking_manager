
import 'package:dropdown_search/dropdown_search.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
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

class _CategoryFormState extends State<CategoryForm> {
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
    super.initState();
  }

  Category? selectedCat;
  Widget categoryParents() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'catparnt',
          style: TextStyle(fontWeight: FontWeight.bold),
        ).tr(),
        const Spacer(),
        SizedBox(
          width: 18.w,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            m.Material(
              child: DropdownSearch<Category>(
                popupProps: PopupProps.menu(
                  emptyBuilder: (c, msg) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Text('lvide',
                                style: TextStyle(color: Colors.grey[100]))
                            .tr(),
                      ),
                    );
                  },
                  fit: FlexFit.loose,
                  showSearchBox: true,
                  constraints: const BoxConstraints(
                    maxHeight: 220,
                  ),
                ),
                itemAsString: (c) {
                  return c.name;
                },
                selectedItem: selectedCat,
                dropdownBuilder: (context, category) {
                  if (category == null) {
                    return Text('catparnt',
                            style: TextStyle(color: Colors.grey[100]))
                        .tr();
                  }
                  return Text(category.name);
                },
                items: PartsProvider.categories.values.toList().skipWhile((s) {
                  return categoryKey == s.id;
                }).toList(),
                onChanged: (c) {
                  setState(() {
                    selectedCat = c;
                  });
                },
              ),
            ),
          ]),
        ),
      ],
    );
  }

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
    return SizedBox(
      width: 30.w,
      height: 45.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Row(
                children: [
                  const Text(
                    'code',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ).tr(),
                  const Spacer(),
                  SizedBox(
                    width: 18.w,
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
                  ),
                ],
              ),
              if (errorCode)
                const SizedBox(
                  height: 5,
                ),
              if (errorCode)
                Text(
                  'codetaken',
                  style: TextStyle(color: Colors.red),
                ).tr()
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              const Text(
                'nom',
                style: TextStyle(fontWeight: FontWeight.bold),
              ).tr(),
              const Spacer(),
              SizedBox(
                width: 18.w,
                child: TextBox(
                  controller: catName,
                  placeholder: 'nom'.tr(),
                  onChanged: (s) {
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          categoryParents(),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Button(
                child: const Text('annuler').tr(),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(
                width: 5,
              ),
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
                    DateTime date = DateTime.now();
                    createCategory(
                            Category(
                                id: catCode.text,
                                name: catName.text,
                                code: catCode.text,
                                codeParent: selectedCat?.id,
                                updatedAt: date,
                                createdAt: widget.category == null ||
                                        widget.category!.createdAt == null
                                    ? date
                                    : widget.category!.createdAt),
                            catCode.text);
                  }
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<void> createCategory(Category cat, String key) async {
    setState(() {
      loading = true;
    });

    if(widget.category==null){
      await DatabaseGetter().addDocument(collectionId: categoriesID,
          documentId: categoryKey, data: cat.toJson()).catchError((s){
        showMessage('errupld', 'erreur');
      });
    }
    else{
      await DatabaseGetter().updateDocument(collectionId: categoriesID,
          documentId: categoryKey, data: cat.toJson()).catchError((s){
        showMessage('errupld', 'erreur');
      });
    }

      showMessage('catadd', 'fait');
      PartsProvider.categories[key] = cat;
      if (CatDataSource.instance != null) {
        CatDataSource.instance!.refreshDataSource();
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
