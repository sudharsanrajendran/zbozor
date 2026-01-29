import 'dart:async';

class EventBus {
  static final EventBus _instance = EventBus._internal();

  factory EventBus() {
    return _instance;
  }

  EventBus._internal();

  final StreamController<void> _itemAddedController =
      StreamController<void>.broadcast();

  Stream<void> get onItemAdded => _itemAddedController.stream;

  void fireItemAdded() {
    _itemAddedController.add(null);
  }

  void dispose() {
    _itemAddedController.close();
  }
}
