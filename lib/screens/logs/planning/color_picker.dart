
import 'package:flutter/material.dart';

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
    return AlertDialog(
      content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            padding: const EdgeInsets.all(0),
            itemCount: widget.listColors!.length - 1,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                contentPadding: const EdgeInsets.all(0),
                leading: Icon(
                    index == widget.selectedColorIndex!
                        ? Icons.lens
                        : Icons.trip_origin,
                    color: widget.listColors![index]),
                title: Text(widget.colorNames![index]),
                onTap: () {
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
          )),
    );
  }
}