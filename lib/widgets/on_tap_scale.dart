import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';

class OnTapScaleAndFade extends StatefulWidget {
  final Widget child;
  final dynamic Function()? onTap;

  const OnTapScaleAndFade({super.key, required this.child, this.onTap});

  @override
  OnTapScaleAndFadeState createState() => OnTapScaleAndFadeState();
}

class OnTapScaleAndFadeState extends State<OnTapScaleAndFade>
    with TickerProviderStateMixin {
  double squareScaleA = 1;
  late AnimationController _controllerA;

  @override
  void initState() {
    _controllerA = AnimationController(
      vsync: this,
      lowerBound: 0.98,
      upperBound: 1.0,
      value: 1,
      duration: const Duration(milliseconds: 10),
    );
    _controllerA.addListener(() {
      setState(() {
        squareScaleA = _controllerA.value;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onTap == null
          ? null
          : () {
              _controllerA.reverse();
              if (widget.onTap != null) {
                widget.onTap!();
              }
            },
      onTapDown: widget.onTap == null
          ? null
          : (dp) {
              _controllerA.reverse();
            },
      onTapUp: widget.onTap == null
          ? null
          : (dp) {
              Timer(const Duration(milliseconds: 150), () {
                if (mounted) {
                  _controllerA.fling();
                }
              });
            },
      onTapCancel: () {
        if (mounted) {
          _controllerA.fling();
        }
      },
      child: Transform.scale(
        scale: squareScaleA,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controllerA.dispose();
    super.dispose();
  }
}
