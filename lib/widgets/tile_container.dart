import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../screens/sidemenu/sidemenu.dart';
import '../theme.dart';

class TileContainer extends StatefulWidget {
  final String image;
  final String title;
  final int index;
  final int? corner;

  const TileContainer({
    super.key,
    required this.image,
    required this.title,
    required this.index,
    this.corner = 0,
  });

  @override
  State<TileContainer> createState() => _TileContainerState();
}

class _TileContainerState extends State<TileContainer> {
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return GestureDetector(
      onTap: () {
        PanesListState.index.value = widget.index;
      },
      child: Card(
        backgroundColor: appTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(appTheme.cardRadius),
          side: BorderSide(color: appTheme.borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Container(
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.bottomCenter,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(widget.image),
                    fit: BoxFit.fitHeight,
                  ),
                  borderRadius: BorderRadius.circular(appTheme.cardRadius),
                ),
              ),
            ),
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: 40,
              child: Text(
                widget.title.toUpperCase(),
                textAlign: TextAlign.center,
                style: appTheme.writingStyle.copyWith(
                  fontSize: 10,
                  letterSpacing: -0.12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
