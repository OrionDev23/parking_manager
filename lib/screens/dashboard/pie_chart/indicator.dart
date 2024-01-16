import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';

class Indicator extends StatelessWidget{

  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  const Indicator({super.key,required this.color,required this.text,required this.isSquare,this.size=16});



  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return Row(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare? BoxShape.rectangle:BoxShape.circle,
            color: color,
          ),),
        smallSpace,
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: appTheme.writingStyle.color,
          ),
        ),
      ],
    );
  }

}