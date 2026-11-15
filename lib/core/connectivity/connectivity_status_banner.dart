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
    _subscription = _connection.onStatusChange.listen((status) {
      if (mounted) setState(() => _status = status);
    });
    _connection.hasInternetAccess.then((online) {
      if (mounted) {
        setState(() => _status = online ? InternetStatus.connected : InternetStatus.disconnected);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return widget.child;
    final online = _status == InternetStatus.connected;
    final checking = _status == null;
    final background = checking
        ? const Color(0xFF64748B)
        : online ? const Color(0xFF16835D) : const Color(0xFFB42318);
    final message = checking
        ? 'Vérification de la connexion…'
        : online
            ? 'En ligne · Connexion Internet disponible'
            : 'Hors ligne · Connexion requise. Les modifications sont désactivées.';
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 30,
          color: background,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(
                checking ? FluentIcons.sync : online ? FluentIcons.cloud : FluentIcons.cloud_offline,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(message, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
