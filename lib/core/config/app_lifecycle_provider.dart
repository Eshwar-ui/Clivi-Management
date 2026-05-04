import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides app lifecycle state changes as a stream
final appLifecycleProvider = StreamProvider<AppLifecycleState>((ref) {
  final controller = StreamController<AppLifecycleState>();
  final observer = _AppLifecycleObserver(controller);

  WidgetsBinding.instance.addObserver(observer);

  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(observer);
    controller.close();
  });

  return controller.stream;
});

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final StreamController<AppLifecycleState> _controller;

  _AppLifecycleObserver(this._controller);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.add(state);
  }
}
