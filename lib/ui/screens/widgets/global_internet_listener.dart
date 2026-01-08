import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:Ebozor/ui/screens/widgets/errors/no_internet.dart';

class GlobalInternetListener extends StatefulWidget {
  final Widget child;
  const GlobalInternetListener({super.key, required this.child});

  @override
  State<GlobalInternetListener> createState() => _GlobalInternetListenerState();
}

class _GlobalInternetListenerState extends State<GlobalInternetListener> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      _updateStatus(result);
    });
  }

  Future<void> _checkInitialConnection() async {
    List<ConnectivityResult> result = await Connectivity().checkConnectivity();
    _updateStatus(result);
  }

  void _updateStatus(List<ConnectivityResult> result) {
    bool isOffline = result.contains(ConnectivityResult.none) &&
        result.length == 1; // Strictly none
    // Or better: if it doesn't contain any valid connection
    // Valid connections: mobile, wifi, ethernet, vpn, bluetooth, other

    bool hasConnection = result.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);

    isOffline = !hasConnection;

    if (isOffline != _isOffline) {
      setState(() {
        _isOffline = isOffline;
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOffline)
          Positioned.fill(
            child: NoInternet(
              onRetry: () {
                _checkInitialConnection();
              },
            ),
          ),
      ],
    );
  }
}
