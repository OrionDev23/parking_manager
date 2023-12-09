import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../theme.dart';
import '../../entreprise.dart';

class EntreprisePlacement extends StatelessWidget {
  const EntreprisePlacement({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.file(
          File('mylogo.png'),
          width: 80.px,
          height: 80.px,
        ),
        bigSpace,
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              MyEntrepriseState.p!.nom,
              style: boldStyle,
            ),
            Text(
              MyEntrepriseState.p!.adresse,
              style: boldStyle,
            ),
          ],
        ),

      ],
    );
  }
}