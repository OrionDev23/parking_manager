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
        backgroundColor: appTheme.color.withOpacity(0.1),
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
                  borderRadius: widget.corner == 0
                      ? BorderRadius.zero
                      : widget.corner == 1
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(10))
                          : widget.corner == 2
                              ? const BorderRadius.only(
                                  topRight: Radius.circular(10))
                              : widget.corner == 3
                                  ? const BorderRadius.only(
                                      bottomLeft: Radius.circular(10))
                                  : const BorderRadius.only(
                                      bottomRight: Radius.circular(10)),
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
                style: const TextStyle(
                  fontSize: 8,
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
