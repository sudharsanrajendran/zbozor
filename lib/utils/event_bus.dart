import 'dart:async';

class EventBus {
  static final EventBus _instance = EventBus._internal();

  factory EventBus() {
    return _instance;
  }

  EventBus._internal();

  final StreamController<void> _itemAddedController =
      StreamController<void>.broadcast();
  final StreamController<void> _itemUpdateController =
      StreamController<void>.broadcast();
  final StreamController<void> _chatListUpdateController =
      StreamController<void>.broadcast();

  Stream<void> get onItemAdded => _itemAddedController.stream;
  Stream<void> get onItemUpdate => _itemUpdateController.stream;
  Stream<void> get onChatListUpdate => _chatListUpdateController.stream;

  void fireItemAdded() {
    _itemAddedController.add(null);
  }

  void fireItemUpdate() {
    _itemUpdateController.add(null);
  }

  void fireChatListUpdate() {
    _chatListUpdateController.add(null);
  }

  void dispose() {
    _itemAddedController.close();
    _itemUpdateController.close();
    _chatListUpdateController.close();
  }
}
