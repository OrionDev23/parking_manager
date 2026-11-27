import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';

typedef PageRefreshCallback = Future<void> Function();

/// Routes the topbar refresh action to the currently active screen.
///
/// Screens register their real data reload operation under their navigation
/// key. Unsupported screens do not display an inert refresh button.
class PageRefreshRegistry extends ChangeNotifier {
  PageRefreshRegistry._();

  static final PageRefreshRegistry instance = PageRefreshRegistry._();

  final Map<String, PageRefreshCallback> _handlers = {};
  final Set<String> _refreshingKeys = {};

  bool canRefresh(String? pageKey) =>
      pageKey != null && _handlers.containsKey(pageKey);

  bool isRefreshing(String? pageKey) =>
      pageKey != null && _refreshingKeys.contains(pageKey);

  void register(String pageKey, PageRefreshCallback callback) {
    _handlers[pageKey] = callback;
    notifyListeners();
  }

  void unregister(String pageKey, PageRefreshCallback callback) {
    if (!identical(_handlers[pageKey], callback)) return;
    _handlers.remove(pageKey);
    notifyListeners();
  }

  Future<void> refresh(String? pageKey) async {
    if (pageKey == null) return;
    final callback = _handlers[pageKey];
    if (callback == null || !_refreshingKeys.add(pageKey)) return;

    notifyListeners();
    try {
      await callback();
    } finally {
      _refreshingKeys.remove(pageKey);
      notifyListeners();
    }
  }
}

/// Topbar action. It only appears when the active screen has registered a
/// refresh callback.
class PageRefreshButton extends StatelessWidget {
  final String? pageKey;

  const PageRefreshButton({super.key, required this.pageKey});

  @override
  Widget build(BuildContext context) {
    final registry = PageRefreshRegistry.instance;

    return ListenableBuilder(
      listenable: registry,
      builder: (context, _) {
        if (!registry.canRefresh(pageKey)) return const SizedBox.shrink();

        final refreshing = registry.isRefreshing(pageKey);
        return Tooltip(
          message: 'Actualiser l’écran',
          child: IconButton(
            icon: refreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: ProgressRing(),
                  )
                : const Icon(FluentIcons.refresh, size: 17),
            onPressed: refreshing
                ? null
                : () {
                    unawaited(registry.refresh(pageKey));
                  },
          ),
        );
      },
    );
  }
}
