import 'package:flutter/material.dart';

/// A base provider that adds safety to [notifyListeners] by checking
/// if the provider has already been disposed.
class BaseProvider extends ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Notifies listeners only if the provider has not been disposed.
  /// Use this for asynchronous operations that might complete after
  /// the provider is removed from the widget tree.
  void safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
