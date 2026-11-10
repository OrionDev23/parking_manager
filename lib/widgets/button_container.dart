import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import 'on_tap_scale.dart';

class ButtonContainer extends StatefulWidget {
  final IconData icon;
  final int? counter;

  final int? maxCounter;
  final String text;
  final String textList;
  final String textNouveau;

  final Future<int> Function()? getCount;

  final bool showBottom;
  final bool showBothLN;

  final bool showCounter;
  final Color? color;
  final Function()? action;
  final Function()? actionList;
  final Function()? actionNouveau;

  const ButtonContainer({
    super.key,
    required this.icon,
    this.action,
    this.actionList,
    this.actionNouveau,
    this.counter,
    this.maxCounter,
    required this.text,
    this.color,
    this.textList = "Liste",
    this.textNouveau = "Nouveau",
    this.showBothLN = true,
    this.showBottom = true,
    this.showCounter = true,
    this.getCount,
  });

  @override
  State<ButtonContainer> createState() => _ButtonContainerState();
}

class _ButtonContainerState extends State<ButtonContainer> {
  bool loadingCount = true;

  int count = 0;

  @override
  void initState() {
    getCount();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    final accent = widget.color ?? appTheme.color;
    final textColor = appTheme.writingStyle.color;

    final countLabel = loadingCount
        ? '-${widget.maxCounter != null ? ' / ${widget.maxCounter}' : ''}'
        : widget.counter != null
        ? '${widget.counter}${widget.maxCounter != null ? ' / ${widget.maxCounter}' : ''}'
        : widget.getCount != null
        ? '$count${widget.maxCounter != null ? ' / ${widget.maxCounter}' : ''}'
        : null;

    return OnTapScaleAndFade(
      onTap: widget.action,
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: appTheme.backGroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[30]),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(widget.icon, size: 22, color: accent),
            ),
            const SizedBox(width: 13),
            Flexible(
              fit: FlexFit.loose,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showCounter && countLabel != null)
                    Text(
                      countLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 3),
                  Text(
                    widget.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.showBottom) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        if (widget.actionList != null)
                          HyperlinkButton(
                            onPressed: widget.actionList,
                            child: Text(
                              widget.textList,
                              style: TextStyle(fontSize: 11, color: accent),
                            ),
                          ),
                        if (widget.showBothLN && widget.actionNouveau != null)
                          HyperlinkButton(
                            onPressed: widget.actionNouveau,
                            child: Text(
                              widget.textNouveau,
                              style: TextStyle(fontSize: 11, color: accent),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (widget.action != null)
              Icon(
                FluentIcons.chevron_right,
                size: 13,
                color: Colors.grey[100],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> getCount() async {
    if (widget.getCount == null) {
      loadingCount = false;
      count = 0;
    } else {
      loadingCount = true;
      if (mounted) {
        setState(() {});
      }

      count = await widget.getCount!();

      if (mounted) {
        setState(() {
          loadingCount = false;
        });
      }
    }
  }
}
