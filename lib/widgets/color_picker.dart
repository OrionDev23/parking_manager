
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../theme.dart';

class ColorPicker extends StatefulWidget {

  final List<Color> ? listColors;
  final List<String>? colorNames;

  final int? selectedColorIndex;
  final void Function(int setColor)? setColor;

  const ColorPicker({super.key, this.listColors, this.colorNames, this.selectedColorIndex, this.setColor});

  @override
  State<StatefulWidget> createState() {
    return _ColorPickerState();
  }
}

class _ColorPickerState extends State<ColorPicker> {
  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return Container(
          decoration: BoxDecoration(
            color: appTheme.backGroundColor,
            borderRadius: BorderRadius.circular(5),
            boxShadow: kElevationToShadow[2]
          ),
          padding: const EdgeInsets.all(5),
          width: double.maxFinite,
          child: ListView.builder(
            padding: const EdgeInsets.all(0),
            itemCount: widget.listColors!.length - 1,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                contentPadding: const EdgeInsets.all(0),
                leading: Icon(
                    index == widget.selectedColorIndex!
                        ? FluentIcons.eyedropper
                        : FluentIcons.eye_shadow,
                    color: widget.listColors![index]),
                title: Text(widget.colorNames![index]).tr(),
                onPressed: () {
                  setState(() {
                    widget.setColor!(index);
                  });

                  // ignore: always_specify_types
                  Future.delayed(const Duration(milliseconds: 200), () {
                    // When task is over, close the dialog
                    Navigator.pop(context);
                  });
                },
              );
            },
          ));
  }
}