import 'package:easy_localization/easy_localization.dart';
import 'package:parc_oto/widgets/forms/parcoto_form_field.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/vehicle/brand/brand_container.dart';
import 'package:parc_oto/theme.dart';
import 'package:parc_oto/utilities/vehicle_util.dart';
import 'package:parc_oto/widgets/page_header.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class BrandList extends StatefulWidget {
  const BrandList({super.key});

  @override
  State<BrandList> createState() => _BrandListState();
}

class _BrandListState extends State<BrandList> {
  TextEditingController searchController = TextEditingController();

  bool notEmpty = false;

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
      header: PageTitle(text: 'brandlist'.tr()),
      content: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final searchWidth = (constraints.maxWidth - 20)
                  .clamp(140.0, 350.0)
                  .toDouble();
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SizedBox(
                    width: searchWidth,
                    height: 45.px,
                    child: ParcotoTextBox(
                    controller: searchController,
                    placeholder: 'search'.tr(),
                    style: appTheme.writingStyle,
                    cursorColor: appTheme.color.darker,
                    placeholderStyle: placeStyle,
                    onChanged: (s) {
                      if (s.isNotEmpty) {
                        notEmpty = true;
                      } else {
                        if (notEmpty) {
                          notEmpty = false;
                        }
                      }
                      setState(() {});
                    },
                    suffix: notEmpty
                        ? IconButton(
                            icon: const Icon(FluentIcons.cancel),
                            onPressed: () {
                              searchController.text = "";
                              notEmpty = false;
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                    ),
                  ),
                ),
              );
            },
          ),
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 520
                    ? 2
                    : constraints.maxWidth < 900
                    ? 3
                    : 4;
                return GridView(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  children: marquesSearched()
                      .map((e) => BrandContainer(key: ValueKey(e), id: e))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<int> marquesSearched() {
    List<int> result = List.empty(growable: true);
    VehiclesUtilities.marques?.forEach((key, value) {
      if (value.toUpperCase().contains(searchController.text.toUpperCase())) {
        result.add(key);
      }
    });
    return result;
  }
}
