import 'dart:async';

/// A global class to hold app-wide state or controllers.
class App {
  /// A broadcast stream that widgets can listen to for feed refresh events.
  /// When an event is added, listeners should rebuild their content.
  static final StreamController<bool> refreshFeed = StreamController<bool>.broadcast();
}
