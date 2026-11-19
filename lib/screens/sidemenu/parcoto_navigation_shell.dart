import 'package:fluent_ui/fluent_ui.dart';

import 'package:parc_oto/ui/design_system/parcoto_tokens.dart';
import 'package:parc_oto/theme.dart';

import 'company_workspace_switcher.dart';

/// Responsive Parcoto application shell.
/// The legacy PaneItem registry remains the source of truth for destinations,
/// access control and page bodies.
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
  State<ParcotoNavigationShell> createState() =>
      _ParcotoNavigationShellState();
}

class _ParcotoNavigationShellState extends State<ParcotoNavigationShell> {
  final Set<String> _expanded = <String>{};
  bool _drawerOpen = false;

  List<NavigationPaneItem> get _destinations => [
        ..._flatten(widget.items),
        ..._flatten(widget.footerItems),
      ];

  List<NavigationPaneItem> _flatten(List<NavigationPaneItem> source) {
    final result = <NavigationPaneItem>[];
    for (final item in source) {
      if (item is PaneItem || item is PaneItemExpander) {
        result.add(item);
        if (item is PaneItemExpander) {
          result.addAll(_flatten(item.items));
        }
      }
    }
    return result;
  }

  int _indexOf(NavigationPaneItem target) {
    return _destinations.indexWhere((item) => identical(item, target));
  }

  NavigationPaneItem? _findByKey(
    List<NavigationPaneItem> source,
    String key,
  ) {
    for (final item in source) {
      if ((item is PaneItem || item is PaneItemExpander) &&
          item.key is ValueKey &&
          (item.key as ValueKey).value.toString() == key) {
        return item;
      }
      if (item is PaneItemExpander) {
        final child = _findByKey(item.items, key);
        if (child != null) return child;
      }
    }
    return null;
  }

  NavigationPaneItem? _destinationForKey(String key) {
    return _findByKey(widget.items, key) ??
        _findByKey(widget.footerItems, key);
  }

  String _keyOf(NavigationPaneItem item) {
    final key = item.key;
    if (key is ValueKey) return key.value.toString();
    return item.hashCode.toString();
  }

  List<_MobileDestination> _mobileDestinations() {
    final result = <_MobileDestination>[];

    final platformCompanies = _destinationForKey('platform-companies');
    if (platformCompanies != null) {
      result.add(
        _MobileDestination(
          label: 'Entreprises',
          icon: FluentIcons.company_directory,
          destination: platformCompanies,
        ),
      );
    }

    final dashboard = _destinationForKey('dashboard');
    if (dashboard != null) {
      result.add(
        _MobileDestination(
          label: 'Accueil',
          icon: FluentIcons.home,
          destination: dashboard,
        ),
      );
    }

    final vehicles = _destinationForKey('vehicles');
    if (vehicles != null) {
      result.add(
        _MobileDestination(
          label: 'Véhicules',
          icon: FluentIcons.car,
          destination: vehicles,
        ),
      );
    }

    final repairs = _destinationForKey('repairs');
    if (repairs != null) {
      result.add(
        _MobileDestination(
          label: 'Maintenance',
          icon: FluentIcons.repair,
          destination: repairs,
        ),
      );
    }

    final planner = _destinationForKey('planner');
    if (planner != null) {
      result.add(
        _MobileDestination(
          label: 'Planning',
          icon: FluentIcons.event,
          destination: planner,
        ),
      );
    }

    result.add(
      const _MobileDestination(
        label: 'Plus',
        icon: FluentIcons.more,
        isMore: true,
      ),
    );
    return result;
  }

  bool _containsSelectedChild(
    NavigationPaneItem destination,
    int selected,
  ) {
    if (destination is! PaneItemExpander) return false;
    for (final child in destination.items) {
      if (child is PaneItem && _indexOf(child) == selected) return true;
      if (child is PaneItemExpander &&
          _containsSelectedChild(child, selected)) {
        return true;
      }
    }
    return false;
  }

  int _mobileSelectedIndex(
    List<_MobileDestination> destinations,
    int selected,
  ) {
    for (var index = 0; index < destinations.length; index++) {
      final destination = destinations[index];
      if (destination.isMore) continue;
      if (_indexOf(destination.destination!) == selected ||
          _containsSelectedChild(destination.destination!, selected)) {
        return index;
      }
    }
    return destinations.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < ParcotoTokens.tabletBreakpoint;
    final theme = widget.appTheme;

    return ValueListenableBuilder<int>(
      valueListenable: widget.selectedIndex,
      builder: (context, selected, _) {
        final destinations = _destinations;
        final safeIndex = selected >= 0 && selected < destinations.length
            ? selected
            : 0;
        final active = destinations.isEmpty ? null : destinations[safeIndex];
        final activeBody = active is PaneItem
            ? active.body
            : active is PaneItemExpander
                ? active.body
                : null;

        return Stack(
          children: [
            ColoredBox(
              color: theme.backGroundColor,
              child: compact
                  ? Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(FluentIcons.global_nav_button),
                              onPressed: () =>
                                  setState(() => _drawerOpen = true),
                            ),
                            Expanded(child: widget.topBar),
                          ],
                        ),
                        Expanded(
                          child: activeBody ??
                              widget.emptyState ??
                              const Center(
                                child: Text(
                                  'Aucune destination disponible',
                                ),
                              ),
                        ),
                        _mobileBottomBar(
                          theme,
                          _mobileDestinations(),
                          selected,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: ParcotoTokens.sidebarWidth,
                          child: _sidebar(
                            theme,
                            selected,
                            destinations,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              widget.topBar,
                              Expanded(
                                child: activeBody ??
                                    widget.emptyState ??
                                    const Center(
                                      child: Text(
                                        'Aucune destination disponible',
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            if (compact && _drawerOpen)
              Positioned.fill(
                child: Row(
                  children: [
                    SizedBox(
                      width: (width * .86)
                          .clamp(280.0, 340.0)
                          .toDouble(),
                      child: _sidebar(
                        theme,
                        selected,
                        destinations,
                        onNavigate: () =>
                            setState(() => _drawerOpen = false),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _drawerOpen = false),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _mobileBottomBar(
    AppTheme theme,
    List<_MobileDestination> destinations,
    int selected,
  ) {
    final activeIndex = _mobileSelectedIndex(destinations, selected);

    return SafeArea(
      top: false,
      child: Container(
        height: 66,
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 4),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          border: Border(
            top: BorderSide(color: theme.borderColor, width: 1),
          ),
        ),
        child: Row(
          children: [
            for (var index = 0; index < destinations.length; index++)
              Expanded(
                child: _mobileNavItem(
                  theme: theme,
                  item: destinations[index],
                  selected: index == activeIndex,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mobileNavItem({
    required AppTheme theme,
    required _MobileDestination item,
    required bool selected,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (item.isMore) {
          setState(() => _drawerOpen = true);
          return;
        }

        final index = _indexOf(item.destination!);
        if (index >= 0) widget.onSelected(index);
        setState(() => _drawerOpen = false);
      },
      child: AnimatedContainer(
        duration: ParcotoTokens.motionFast,
        curve: ParcotoTokens.motionCurve,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: selected
              ? theme.color.withValues(alpha: .18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 19,
              color: selected ? theme.color : theme.mutedTextColor,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? theme.textColor : theme.mutedTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebar(
    AppTheme theme,
    int selected,
    List<NavigationPaneItem> destinations, {
    VoidCallback? onNavigate,
  }) {
    final drawer = onNavigate != null;

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
            padding: const EdgeInsets.fromLTRB(17, 16, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Image.asset(
                    'assets/images/logo.webp',
                    alignment: Alignment.centerLeft,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                if (drawer)
                  IconButton(
                    icon: const Icon(FluentIcons.cancel, size: 16),
                    onPressed: onNavigate,
                  ),
              ],
            ),
          ),
          if (drawer) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: CompanyWorkspaceSwitcher(compact: true),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: widget.search,
            ),
          ],
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
              children: [
                ..._buildItems(
                  widget.items,
                  destinations,
                  selected,
                  onNavigate,
                ),
                if (widget.footerItems.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
                    child: Container(
                      height: 1,
                      color: theme.borderColor,
                    ),
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
          if (!drawer)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Text(
                'PARCOTO',
                style: TextStyle(
                  color: theme.mutedTextColor,
                  fontSize: 9,
                  letterSpacing: 1.6,
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
    List<NavigationPaneItem> destinations,
    int selected,
    VoidCallback? onNavigate,
  ) {
    final widgets = <Widget>[];

    for (final item in items) {
      if (item is PaneItemHeader) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 15, 8, 7),
            child: DefaultTextStyle(
              style: TextStyle(
                color: widget.appTheme.mutedTextColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.05,
              ),
              child: item.header,
            ),
          ),
        );
      } else if (item is PaneItemSeparator) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 8,
            ),
            child: Container(
              height: 1,
              color: widget.appTheme.borderColor,
            ),
          ),
        );
      } else if (item is PaneItemExpander) {
        final index = _indexOf(item);
        final key = _keyOf(item);
        final childSelected = item.items.any(
          (child) =>
              child is PaneItem && _indexOf(child) == selected ||
              child is PaneItemExpander &&
                  _containsSelectedChild(child, selected),
        );
        final isExpanded = _expanded.contains(key) || childSelected;

        widgets.add(
          _navRow(
            icon: item.icon,
            title: item.title,
            index: index,
            selected: selected,
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
          ),
        );

        if (isExpanded) {
          for (final child in item.items) {
            if (child is PaneItem) {
              widgets.add(
                Padding(
                  padding: const EdgeInsets.only(left: 17),
                  child: _navRow(
                    icon: child.icon,
                    title: child.title,
                    index: _indexOf(child),
                    selected: selected,
                    childItem: true,
                    onTap: () {
                      widget.onSelected(_indexOf(child));
                      onNavigate?.call();
                    },
                  ),
                ),
              );
            } else if (child is PaneItemHeader) {
              widgets.add(
                Padding(
                  padding: const EdgeInsets.only(left: 17),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 9, 8, 5),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: widget.appTheme.mutedTextColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                      ),
                      child: child.header,
                    ),
                  ),
                ),
              );
            } else if (child is PaneItemSeparator) {
              widgets.add(
                Padding(
                  padding: const EdgeInsets.only(left: 17),
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    color: widget.appTheme.borderColor,
                  ),
                ),
              );
            }
          }
        }
      } else if (item is PaneItem) {
        widgets.add(
          _navRow(
            icon: item.icon,
            title: item.title,
            index: _indexOf(item),
            selected: selected,
            onTap: () {
              widget.onSelected(_indexOf(item));
              onNavigate?.call();
            },
          ),
        );
      }
    }

    return widgets;
  }

  Widget _navRow({
    required Widget? icon,
    required Widget? title,
    required int index,
    required int selected,
    required VoidCallback onTap,
    bool expandable = false,
    bool expanded = false,
    bool childItem = false,
  }) {
    final active = index == selected;
    final theme = widget.appTheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: childItem ? 1 : 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: ParcotoTokens.motionFast,
            curve: ParcotoTokens.motionCurve,
            decoration: BoxDecoration(
              color: active
                  ? theme.color.withValues(alpha: .17)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: SizedBox(
              height: childItem ? 36 : 39,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: childItem ? 9 : 11,
                ),
                child: Row(
                  children: [
                    IconTheme(
                      data: IconThemeData(
                        size: childItem ? 15 : 17,
                        color: active
                            ? theme.color
                            : theme.mutedTextColor,
                      ),
                      child: icon ?? const SizedBox.shrink(),
                    ),
                    SizedBox(width: childItem ? 9 : 11),
                    Expanded(
                      child: DefaultTextStyle(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active
                              ? theme.textColor
                              : theme.mutedTextColor,
                          fontSize: childItem ? 11 : 12,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        child: title ?? const SizedBox.shrink(),
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
                        width: 3,
                        height: 17,
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
      ),
    );
  }
}

class _MobileDestination {
  final String label;
  final IconData icon;
  final NavigationPaneItem? destination;
  final bool isMore;

  const _MobileDestination({
    required this.label,
    required this.icon,
    this.destination,
    this.isMore = false,
  });
}
