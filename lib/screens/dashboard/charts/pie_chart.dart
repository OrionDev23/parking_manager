import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../widgets/empty_widget/src/widget.dart';
import '../../../widgets/forms/parcoto_form_field.dart';

class ParcOtoPie extends StatefulWidget {
  final String? title;
  final int refreshVersion;

  final List<MapEntry<String, Future<int>>> labels;

  const ParcOtoPie({super.key, required this.labels, this.title, this.refreshVersion = 0});

  @override
  State<ParcOtoPie> createState() => _ParcOtoPieState();
}

class _ParcOtoPieState extends State<ParcOtoPie> {
  List<MapEntry<String, int>> values = [];

  @override
  void initState() {
    super.initState();
    initValues();
  }

  bool loading = false;
  bool group = true;
  int indexOfBiggest = 0;
  int valueOfBiggest = 0;
  List<Color> colors = [];
  String? error;
  int _loadGeneration = 0;

  bool _sameInputs(ParcOtoPie other) {
    if (widget.refreshVersion != other.refreshVersion || widget.labels.length != other.labels.length) return false;
    for (var i = 0; i < widget.labels.length; i++) {
      if (widget.labels[i].key != other.labels[i].key) return false;
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant ParcOtoPie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameInputs(oldWidget)) initValues();
  }

  Future<void> initValues() async {
    final generation = ++_loadGeneration;
    final labels = widget.labels;
    setState(() {
      loading = true;
      error = null;
      values = <MapEntry<String, int>>[];
      valueOfBiggest = 0;
      indexOfBiggest = 0;
      gotenColors = false;
      colors = <Color>[];
    });

    try {
      final loaded = await Future.wait([
        for (final label in labels)
          label.value.then((value) => MapEntry(label.key, value)),
      ]).timeout(const Duration(seconds: 25));
      if (!mounted || generation != _loadGeneration) return;
      values = _sortAsIntended(loaded);
    } catch (exception) {
      if (generation == _loadGeneration) error = exception.toString();
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  bool notOnlyOne = false;
  List<MapEntry<String, int>> _sortAsIntended(List<MapEntry<String, int>> source) {
    final byKey = {for (final item in source) item.key: item};
    final sorted = <MapEntry<String, int>>[];
    var biggestValue = 0;
    var biggestIndex = 0;
    var positiveCount = 0;

    for (var i = 0; i < widget.labels.length; i++) {
      final item = byKey[widget.labels[i].key];
      if (item == null) continue;
      if (item.value > biggestValue) {
        biggestValue = item.value;
        biggestIndex = i;
      }
      if (item.value > 0) positiveCount++;
      sorted.add(MapEntry(item.key, item.value));
    }

    valueOfBiggest = biggestValue;
    indexOfBiggest = biggestIndex;
    notOnlyOne = positiveCount > 1;
    return sorted;
  }

  int minValue = 10;
  bool gotenColors = false;

  void getColors(AppTheme appTheme) {
    if (!gotenColors) {
      colors = appTheme.getRandomColors(values.length);
      gotenColors = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();

    if (loading) return const Center(child: ProgressRing());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FluentIcons.warning, size: 24),
            const SizedBox(height: 8),
            const Text('Impossible de vérifier ces statistiques.'),
            Text(error!, maxLines: 2, overflow: TextOverflow.ellipsis),
            Button(onPressed: initValues, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    getColors(appTheme);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.title != null)
            Text(
              widget.title!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: appTheme.writingStyle.color,
              ),
            ),
          smallSpace,
          valueOfBiggest == 0
              ? Flexible(
                  child: SizedBox(
                    width: 250.px,
                    child: EmptyWidget(
                      title: 'nodatayet'.tr(),
                      titleTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      image: PackageImage.Image_3.encode(),
                    ),
                  ),
                )
              : Expanded(
                  child: SfCircularChart(
                    legend: const Legend(isVisible: true),
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      format: 'point.x : point.y',
                      color: appTheme.backGroundColor,
                      textStyle: appTheme.writingStyle,
                    ),
                    series: [
                      PieSeries<MapEntry<String, int>, String>(
                        radius: '85%',
                        legendIconType: LegendIconType.circle,
                        explode: true,
                        explodeIndex: indexOfBiggest,
                        groupMode: notOnlyOne && group ? CircularChartGroupMode.value : null,
                        groupTo: minValue.toDouble(),
                        dataSource: values,
                        xValueMapper: (s, t) => s.key.tr(),
                        yValueMapper: (s, t) => s.value,
                        dataLabelMapper: (s, t) => s.key.tr(),
                        pointColorMapper: (s, i) => colors[i],
                        dataLabelSettings: DataLabelSettings(
                          isVisible: true,
                          textStyle: TextStyle(fontSize: 10, color: appTheme.writingStyle.color),
                          showZeroValue: false,
                          connectorLineSettings: const ConnectorLineSettings(type: ConnectorType.line),
                        ),
                      ),
                    ],
                  ),
                ),
          if (valueOfBiggest != 0 && notOnlyOne)
            SizedBox(
              height: 30.px,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('groupvalues').tr(),
                  smallSpace,
                  SizedBox(
                    width: 70.px,
                    child: ParcotoFieldSurface(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minHeight: 30,
                      child: NumberBox(
                        clearButton: false,
                        mode: SpinButtonPlacementMode.none,
                        value: minValue,
                        onChanged: (s) {
                          setState(() {
                            minValue = s ?? 0;
                          });
                        },
                      ),
                    ),
                  ),
                  smallSpace,
                  Checkbox(
                    checked: group,
                    onChanged: (s) => setState(() {
                      group = s ?? false;
                    }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _loadGeneration++;
    super.dispose();
  }
}
