import 'package:fluent_ui/fluent_ui.dart';

import 'package:parc_oto/screens/sidemenu/pane_items.dart';
import 'package:parc_oto/ui/design_system/parcoto_tokens.dart';
import 'package:parc_oto/theme.dart';

/// Custom Parcoto shell. The legacy PaneItem registry remains the source of
/// truth for destinations and permissions while its visual presentation is
/// progressively migrated screen by screen.
class ParcotoNavigationShell extends StatefulWidget {
  final List<NavigationPaneItem> items;
  final List<NavigationPaneItem> footerItems;
  final ValueNotifier<int> selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget topBar;
  final Widget search;
  final Widget? emptyState;
  final AppTheme appTheme;

  const ParcotoNavigationShell({
    super.key,
    required this.items,
    required this.footerItems,
    required this.selectedIndex,
    required this.onSelected,
    required this.topBar,
    required this.search,
    required this.appTheme,
    this.emptyState,
  });

  @override
  State<ParcotoNavigationShell> createState() => _ParcotoNavigationShellState();
}

class _ParcotoNavigationShellState extends State<ParcotoNavigationShell> {
  final Set<String> _expanded = <String>{};
  bool _drawerOpen = false;

  List<PaneItem> get _destinations => [
    ..._flatten(widget.items),
    ..._flatten(widget.footerItems),
  ];

  List<PaneItem> _flatten(List<NavigationPaneItem> source) {
    final result = <PaneItem>[];
    for (final item in source) {
      if (item is PaneItem) {
        result.add(item);
        if (item is PaneItemExpander) {
          result.addAll(_flatten(item.items));
        }
      }
    }
    return result;
  }

  int _indexOf(PaneItem target) {
    return _destinations.indexWhere((item) => identical(item, target));
  }

  String _keyOf(PaneItem item) {
    final key = item.key;
    if (key is ValueKey) return key.value.toString();
    return item.hashCode.toString();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < ParcotoBreakpoints.tablet;
    final theme = widget.appTheme;

    return ValueListenableBuilder<int>(
      valueListenable: widget.selectedIndex,
      builder: (context, selected, _) {
        final destinations = _destinations;
        final safeIndex = selected >= 0 && selected < destinations.length
            ? selected
            : 0;
        final active = destinations.isEmpty ? null : destinations[safeIndex];

        return ColoredBox(
          color: theme.backGroundColor,
          child: Column(
            children: [
              if (compact)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(FluentIcons.global_nav_button),
                      onPressed: () => setState(() => _drawerOpen = true),
                    ),
                    Expanded(child: widget.topBar),
                  ],
                )
              else
                widget.topBar,
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!compact)
                      SizedBox(
                        width: 264,
                        child: _sidebar(theme, selected, destinations),
                      ),
                    Expanded(
                      child: active?.body ??
                          widget.emptyState ??
                          const Center(child: Text('Aucune destination disponible')),
                    ),
                  ],
                ),
              ),
              if (compact && _drawerOpen)
                Positioned.fill(
                  child: Material(
                    color: const Color(0x66000000),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 300,
                          child: _sidebar(
                            theme,
                            selected,
                            destinations,
                            onNavigate: () => setState(() => _drawerOpen = false),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _drawerOpen = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _sidebar(
    AppTheme theme,
    int selected,
    List<PaneItem> destinations, {
    VoidCallback? onNavigate,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(
          right: BorderSide(color: theme.borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: widget.search,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
              children: [
                ..._buildItems(widget.items, destinations, selected, onNavigate),
                if (widget.footerItems.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 22, 12, 8),
                    child: Container(height: 1, color: theme.borderColor),
                  ),
                  ..._buildItems(
                    widget.footerItems,
                    destinations,
                    selected,
                    onNavigate,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: Text(
              'PARCOTO',
              style: TextStyle(
                color: theme.mutedTextColor,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildItems(
    List<NavigationPaneItem> items,
    List<PaneItem> destinations,
    int selected,
    VoidCallback? onNavigate,
  ) {
    final widgets = <Widget>[];
    for (final item in items) {
      if (item is PaneItemHeader) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 8, 8),
            child: DefaultTextStyle(
              style: TextStyle(
                color: widget.appTheme.mutedTextColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: .8,
              ),
              child: item.header,
            ),
          ),
        );
      } else if (item is PaneItemSeparator) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Divider(
            style: DividerThemeData(
              decoration: BoxDecoration(color: widget.appTheme.borderColor),
            ),
          ),
        ));
      } else if (item is PaneItemExpander) {
        final index = _indexOf(item);
        final key = _keyOf(item);
        final childSelected = item.items.any(
          (child) => child is PaneItem && _indexOf(child) == selected,
        );
        final isExpanded = _expanded.contains(key) || childSelected;
        widgets.add(_navRow(
          item,
          index,
          selected,
          expandable: true,
          expanded: isExpanded,
          onTap: () {
            if (index >= 0) widget.onSelected(index);
            setState(() {
              if (isExpanded) {
                _expanded.remove(key);
              } else {
                _expanded.add(key);
              }
            });
            onNavigate?.call();
          },
        ));
        if (isExpanded) {
          for (final child in item.items) {
            if (child is PaneItem) {
              widgets.add(Padding(
                padding: const EdgeInsets.only(left: 18),
                child: _navRow(
                  child,
                  _indexOf(child),
                  selected,
                  onTap: () {
                    widget.onSelected(_indexOf(child));
                    onNavigate?.call();
                  },
                ),
              ));
            } else if (child is PaneItemHeader) {
              widgets.add(Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 5),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: widget.appTheme.mutedTextColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    child: child.header,
                  ),
                ),
              ));
            }
          }
        }
      } else if (item is PaneItem) {
        widgets.add(_navRow(
          item,
          _indexOf(item),
          selected,
          onTap: () {
            widget.onSelected(_indexOf(item));
            onNavigate?.call();
          },
        ));
      }
    }
    return widgets;
  }

  Widget _navRow(
    PaneItem item,
    int index,
    int selected, {
    required VoidCallback onTap,
    bool expandable = false,
    bool expanded = false,
  }) {
    final active = index == selected;
    final theme = widget.appTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active
            ? theme.color.withValues(alpha: .13)
            : const Color(0x00000000),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 42,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Row(
                children: [
                  IconTheme(
                    data: IconThemeData(
                      size: 17,
                      color: active ? theme.color : theme.mutedTextColor,
                    ),
                    child: item.icon,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: DefaultTextStyle(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active ? theme.textColor : theme.mutedTextColor,
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                      child: item.title,
                    ),
                  ),
                  if (expandable)
                    Icon(
                      expanded
                          ? FluentIcons.chevron_up
                          : FluentIcons.chevron_down,
                      size: 11,
                      color: theme.mutedTextColor,
                    ),
                  if (active && !expandable)
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: theme.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
