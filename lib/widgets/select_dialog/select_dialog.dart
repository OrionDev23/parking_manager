library;

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' show Button;
import 'package:flutter/material.dart';

import 'multiple_items_bloc.dart';
import 'select_bloc.dart';

typedef SelectOneItemBuilderType<T> = Widget Function(
    BuildContext context, T item, bool isSelected);

typedef ErrorBuilderType<T> = Widget Function(
    BuildContext context, dynamic exception);
typedef ButtonBuilderType = Widget Function(
    BuildContext context, VoidCallback onPressed);

class SelectDialog<T> extends StatefulWidget {
  final T? selectedValue;
  final List<T>? multipleSelectedValues;
  final List<T>? itemsList;
  final bool? gridView;
  final int? numberOfGridCross;
  final TextStyle? searchTextStyle;
  final Color? searchCursorColor;

  ///![image](https://user-images.githubusercontent.com/16373553/80187339-db365f00-85e5-11ea-81ad-df17d7e7034e.png)
  final bool showSearchBox;
  final void Function(T)? onChange;
  final void Function(List<T>)? onMultipleItemsChange;
  final Future<List<T>> Function(String text)? onFind;
  final SelectOneItemBuilderType<T>? itemBuilder;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? loadingBuilder;

  ///![image](https://user-images.githubusercontent.com/16373553/94357272-d599e500-006d-11eb-9bcb-5f067943011e.png)
  final ButtonBuilderType? okButtonBuilder;
  final ErrorBuilderType? errorBuilder;
  final bool autofocus;
  final bool alwaysShowScrollBar;
  final int searchBoxMaxLines;
  final int searchBoxMinLines;

  ///![image](https://user-images.githubusercontent.com/16373553/80187339-db365f00-85e5-11ea-81ad-df17d7e7034e.png)
  final InputDecoration? searchBoxDecoration;
  @Deprecated("Use 'hintText' property from searchBoxDecoration")
  final String? searchHint;

  ///![image](https://user-images.githubusercontent.com/16373553/80187103-72e77d80-85e5-11ea-9349-e4dc8ec323bc.png)
  final TextStyle? titleStyle;

  ///|**Max width**: 90% of screen width|**Max height**: 70% of screen height|
  ///|---|---|
  ///|![image](https://user-images.githubusercontent.com/16373553/80189438-0a020480-85e9-11ea-8e63-3fabfa42c1c7.png)|![image](https://user-images.githubusercontent.com/16373553/80190562-e2ac3700-85ea-11ea-82ef-3383ae32ab02.png)|
  final BoxConstraints? constraints;
  final TextEditingController? findController;

  const SelectDialog({
    super.key,
    this.itemsList,
    this.showSearchBox = true,
    this.gridView = false,
    this.numberOfGridCross,
    this.searchCursorColor,
    this.searchTextStyle,
    this.onChange,
    this.onMultipleItemsChange,
    this.selectedValue,
    this.multipleSelectedValues,
    this.onFind,
    this.itemBuilder,
    this.searchBoxDecoration,
    this.searchHint,
    this.titleStyle,
    this.emptyBuilder,
    this.okButtonBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.constraints,
    this.autofocus = false,
    this.alwaysShowScrollBar = false,
    this.searchBoxMaxLines = 1,
    this.searchBoxMinLines = 1,
    this.findController,
  });

  static Future<T?> showModal<T>(
    BuildContext context, {
    List<T>? items,
    String? label,
    T? selectedValue,
    bool? gridView,
    TextStyle? searchTextStyle,
    Color? searchCursorColor,
    int? numberOfGridCross,
    List<T>? multipleSelectedValues,
    bool showSearchBox = true,
    Future<List<T>> Function(String text)? onFind,
    SelectOneItemBuilderType<T>? itemBuilder,
    void Function(T)? onChange,
    void Function(List<T>)? onMultipleItemsChange,
    InputDecoration? searchBoxDecoration,
    @Deprecated("Use 'hintText' property from searchBoxDecoration")
    String? searchHint,
    Color? backgroundColor,
    TextStyle? titleStyle,
    WidgetBuilder? emptyBuilder,
    ButtonBuilderType? okButtonBuilder,
    WidgetBuilder? loadingBuilder,
    ErrorBuilderType? errorBuilder,
    BoxConstraints? constraints,
    bool autofocus = false,
    bool alwaysShowScrollBar = false,
    int searchBoxMaxLines = 1,
    int searchBoxMinLines = 1,
    TextEditingController? findController,
    bool useRootNavigator = false,
  }) {
    return showDialog<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      builder: (context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: Text(label ?? "", style: titleStyle),
          content: SelectDialog<T>(
            selectedValue: selectedValue,
            multipleSelectedValues: multipleSelectedValues,
            gridView: gridView,
            searchCursorColor: searchCursorColor,
            numberOfGridCross: numberOfGridCross,
            searchTextStyle: searchTextStyle,
            itemsList: items,
            onChange: onChange,
            onMultipleItemsChange: onMultipleItemsChange,
            onFind: onFind,
            showSearchBox: showSearchBox,
            itemBuilder: itemBuilder,
            searchBoxDecoration: searchBoxDecoration,
            searchHint: searchHint,
            titleStyle: titleStyle,
            emptyBuilder: emptyBuilder,
            okButtonBuilder: okButtonBuilder,
            loadingBuilder: loadingBuilder,
            errorBuilder: errorBuilder,
            constraints: constraints,
            autofocus: autofocus,
            alwaysShowScrollBar: alwaysShowScrollBar,
            searchBoxMaxLines: searchBoxMaxLines,
            searchBoxMinLines: searchBoxMinLines,
            findController: findController,
          ),
          actions: [
            Button(child: const Text('fermer').tr(),onPressed: (){
              Navigator.of(context).pop();
            },),
          ],
        );
      },
    );
  }

  @override
  SelectDialogState<T> createState() => SelectDialogState<T>(
        itemsList,
        onChange,
        onMultipleItemsChange,
        multipleSelectedValues?.toList(),
        onFind,
        findController,
      );
}

class SelectDialogState<T> extends State<SelectDialog<T>> {
  late SelectOneBloc<T> bloc;
  late MultipleItemsBloc<T> multipleItemsBloc;
  void Function(T)? onChange;

  SelectDialogState(
      List<T>? itemsList,
      this.onChange,
      void Function(List<T>)? onMultipleItemsChange,
      List<T>? multipleSelectedValues,
      Future<List<T>> Function(String text)? onFind,
      TextEditingController? findController) {
    bloc = SelectOneBloc(itemsList, onFind, findController);
    multipleItemsBloc =
        MultipleItemsBloc(multipleSelectedValues, onMultipleItemsChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.autofocus) {
      FocusScope.of(context).requestFocus(bloc.focusNode);
    }
  }

  @override
  void dispose() {
    super.dispose();
    bloc.dispose();
  }

  bool get isWeb =>
      MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

  bool get isMultipleItems => widget.onMultipleItemsChange != null;

  BoxConstraints get webDefaultConstraints =>
      const BoxConstraints(maxWidth: 250, maxHeight: 500);

  BoxConstraints get mobileDefaultConstraints => BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.9,
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      );

  SelectOneItemBuilderType<T> get itemBuilder {
    return widget.itemBuilder ??
        (context, item, isSelected) =>
            ListTile(title: Text(item.toString()), selected: isSelected);
  }

  ButtonBuilderType get okButtonBuilder {
    return widget.okButtonBuilder ??
        (context, onPressed) =>
            ElevatedButton(onPressed: onPressed, child: const Text("Ok"));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.height * 0.7,
      constraints: widget.constraints ??
          (isWeb ? webDefaultConstraints : mobileDefaultConstraints),
      child: Column(
        children: <Widget>[
          if (widget.showSearchBox)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: bloc.findController,
                focusNode: bloc.focusNode,
                style: widget.searchTextStyle,
                cursorColor: widget.searchCursorColor,
                maxLines: widget.searchBoxMaxLines,
                minLines: widget.searchBoxMinLines,
                decoration: widget.searchBoxDecoration?.copyWith(
                        hintText: widget.searchBoxDecoration?.hintText ??
                            widget.searchBoxDecoration!.hintText) ?? //
                    InputDecoration(
                        hintText:
                            widget.searchBoxDecoration?.hintText ?? "Find",
                        contentPadding: const EdgeInsets.all(2.0)),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<T>?>(
              stream: bloc.filteredListOut,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return widget.errorBuilder?.call(context, snapshot.error) ??
                      Center(child: Text("Oops. \n${snapshot.error}"));
                } else if (!snapshot.hasData) {
                  return widget.loadingBuilder?.call(context) ??
                      const Center(child: CircularProgressIndicator());
                } else if (snapshot.data!.isEmpty) {
                  return widget.emptyBuilder?.call(context) ??
                      const Center(child: Text("No data found"));
                }
                return Scrollbar(
                  controller: bloc.scrollController,
                  thumbVisibility: widget.alwaysShowScrollBar,
                  child: widget.gridView == true
                      ? GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: widget.numberOfGridCross ?? 2,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 5,
                          ),
                          controller: bloc.scrollController,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            var item = snapshot.data![index];
                            bool isSelected =
                                multipleItemsBloc.selectedItems.contains(item);
                            isSelected =
                                isSelected || item == widget.selectedValue;
                            return InkWell(
                              child: itemBuilder(context, item, isSelected),
                              onTap: () {
                                if (isMultipleItems) {
                                  setState(() => (isSelected)
                                      ? multipleItemsBloc.unselectItem(item)
                                      : multipleItemsBloc.selectItem(item));
                                } else {
                                  onChange?.call(item);
                                  Navigator.pop(context);
                                }
                              },
                            );
                          },
                        )
                      : ListView.builder(
                          controller: bloc.scrollController,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            var item = snapshot.data![index];
                            bool isSelected =
                                multipleItemsBloc.selectedItems.contains(item);
                            isSelected =
                                isSelected || item == widget.selectedValue;
                            return InkWell(
                              child: itemBuilder(context, item, isSelected),
                              onTap: () {
                                if (isMultipleItems) {
                                  setState(() => (isSelected)
                                      ? multipleItemsBloc.unselectItem(item)
                                      : multipleItemsBloc.selectItem(item));
                                } else {
                                  onChange?.call(item);
                                  Navigator.pop(context);
                                }
                              },
                            );
                          },
                        ),
                );
              },
            ),
          ),
          if (isMultipleItems)
            okButtonBuilder(context, () {
              multipleItemsBloc.onSelectButtonPressed();
              Navigator.pop(context);
            }),
        ],
      ),
    );
  }
}
