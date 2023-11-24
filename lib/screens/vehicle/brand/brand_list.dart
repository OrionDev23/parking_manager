import 'package:easy_localization/easy_localization.dart';
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


  bool notEmpty=false;
  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return ScaffoldPage(
      header: PageTitle(text: 'brandlist'.tr()),
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 30.w,
                height: 7.h,
                child: TextBox(
                  controller: searchController,
                  placeholder: 'search'.tr(),
                  style: appTheme.writingStyle,
                  cursorColor: appTheme.color.darker,
                  placeholderStyle: placeStyle,
                  decoration: BoxDecoration(
                    color: appTheme.fillColor
                  ),
                  onChanged: (s) {
                    if (s.isNotEmpty) {
                      notEmpty=true;
                    } else {
                      if (notEmpty) {
                        notEmpty=false;
                      }
                    }
                    setState(() {

                    });
                  },
                  suffix: notEmpty
                      ? IconButton(
                      icon: const Icon(FluentIcons.cancel),
                      onPressed: () {
                        searchController.text = "";
                        notEmpty = false;
                        setState(() {});
                      })
                      : null,
                ),
              ),
            ],),
          ),
          Flexible(
            child: GridView(
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).orientation==Orientation.portrait?2:4,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
            
              ),
              children: marquesSearched().map((e) => BrandContainer(key:ValueKey(e),id:e)).toList(),
            ),
          ),
        ],
      )
    );
  }



  List<int> marquesSearched(){

    List<int>result=List.empty(growable: true);
    VehiclesUtilities.marques?.forEach((key, value) {
      if(value.toUpperCase().contains(searchController.text.toUpperCase())){
        result.add(key);
      }
    });
    return result;
  }
}
