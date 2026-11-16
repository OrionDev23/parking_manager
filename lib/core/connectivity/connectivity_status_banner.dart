import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityStatusBanner extends StatefulWidget {
  const ConnectivityStatusBanner({super.key, required this.child});
  final Widget child;

  @override
  State<ConnectivityStatusBanner> createState() => _ConnectivityStatusBannerState();
}

class _ConnectivityStatusBannerState extends State<ConnectivityStatusBanner> {
  final InternetConnection _connection = InternetConnection();
  StreamSubscription<InternetStatus>? _subscription;
  InternetStatus? _status;

  @override
  void initState() {
    super.initState();
    _subscription = _connection.onStatusChange.listen(_handleStatus);
    _connection.hasInternetAccess.then((online) {
      if (mounted) _handleStatus(
        online ? InternetStatus.connected : InternetStatus.disconnected,
      );
    });
  }

  void _handleStatus(InternetStatus next) {
    if (!mounted) return;
    final previous = _status;
    if (previous == next) return;
    setState(() => _status = next);

    // The initial successful check is intentionally silent. Only meaningful
    // connectivity changes should interrupt the user with a transient notice.
    if (previous == null && next == InternetStatus.connected) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: Text(
            next == InternetStatus.connected
                ? 'Connexion Internet rétablie'
                : 'Connexion Internet perdue',
          ),
          content: Text(
            next == InternetStatus.connected
                ? 'Vous êtes de nouveau en ligne.'
                : 'Vérifiez votre connexion. Certaines opérations nécessitent Internet.',
          ),
          severity: next == InternetStatus.connected
              ? InfoBarSeverity.success
              : InfoBarSeverity.warning,
          onClose: close,
        ),
        duration: const Duration(seconds: 4),
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
