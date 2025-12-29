import 'dart:async';
import 'package:Ebozor/ui/screens/chat/chat_audio/widgets/chat_widget.dart';
import 'package:Ebozor/utils/notification/chat_message_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:Ebozor/utils/LocalStoreage/hive_utils.dart';

class ChatSocketService {
  // Singleton instance
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal();

  IO.Socket? _socket;
  Timer? _presenceTimer;

  bool get isConnected => _socket?.connected ?? false;
  final ValueNotifier<bool> isOtherUserTyping = ValueNotifier(false);

  /// Connect socket safely
  void socketconnect() {
    // If socket is alive and connected, do nothing
    if (_socket != null && _socket!.connected) return;

    // If socket exists but might be stale, clean it
    if (_socket != null) {
      _socket!.off("message");
      _socket!.disconnect();
      _socket = null;
    }

    _socket = IO.io(
      "http://143.110.251.34:6002",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect() // manual connect
          .setAuth({"token": "Bearer ${HiveUtils.getJWT()}"})
          .build(),
    );


    _socket!.on("typing:start", (data) {
      final myId = HiveUtils.getUserId();
      if (data["userId"].toString() == myId) return;
      isOtherUserTyping.value = true;
    });

    _socket!.on("typing:stop", (data) {
      isOtherUserTyping.value = false;
    });

    // Added generic typing listener as per user snippet reference
    _socket!.on("typing", (data) {
       final myId = HiveUtils.getUserId();
       if (data is Map && data["userId"].toString() == myId) return;
       // Assuming 'typing' event means start typing or carries state
       // If data has a boolean or similar, we could use it. 
       // For now, treat it as 'start' if we receive it. 
       isOtherUserTyping.value = true;
       
       // Auto reset after a few seconds if no stop received? 
       // For now let's rely on stop event or subsequent logic.
    });





    // Add listeners once
    _socket!.off("message");
    _socket!.on("message", _onMessageReceived);

    _socket!.onConnect((_) {
      print("🔥 Socket Connected");
      _startPresencePing();
    });

    _socket!.onDisconnect((_) {
      print("🔥 Socket Disconnected");
      _stopPresencePing();
    });

    _socket!.connect();
  }




  /// Handle incoming messages
  void _onMessageReceived(dynamic data) {
    final senderId = data['sender_id'].toString();
    final myId = HiveUtils.getUserId();

    // Ignore own messages
    if (senderId == myId) {
      print("🔥 Ignored own message");
      return;
    }

    final chat = ChatMessage(
      key: ValueKey(data['id']),
      message: data['message'] ?? "",
      senderId: int.parse(senderId),
      createdAt: data['created_at'],
      updatedAt: data['updated_at'],
      itemOfferId: data['item_offer_id'],
      file: data['file'] ?? "",
      audio: data['audio'] ?? "",
    );

    ChatMessageHandler.addchat(chat);
  }

  /// Join a specific offer room
  void joinOffer(int offerId) {
    if (_socket == null || !_socket!.connected) socketconnect();
    print("🔥 Emitting join: {offerId: $offerId}");
    _socket?.emit("join", {"offerId": offerId});
  }

  /// Send a chat message
  void sendMessage(int offerId, String message) {
    if (_socket == null || !_socket!.connected) socketconnect();
    print("🔥 Emitting message: {offerId: $offerId, message: $message}");
    _socket?.emit("message", {
      "offerId": offerId,
      "message": message,
    });
  }

  void sendMessageFromApi(int offerId, Map<String, dynamic> responseData) {
    if (_socket == null || !_socket!.connected) socketconnect();
    print("🔥 Emitting API message: $responseData");
    _socket?.emit("message", responseData);
  }

  void typingStart(int offerId) {
  _socket?.emit("typing:start", {"offerId": offerId});
}

void typingStop(int offerId) {
  _socket?.emit("typing:stop", {"offerId": offerId});
}



  /// Presence ping
  void _startPresencePing() {
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      print("🔥 Emitting presence:ping");
      _socket?.emit("presence:ping");
    });
  }

  void _stopPresencePing() {
    _presenceTimer?.cancel();
  }

  /// Disconnect socket safely
  void disconnect() {
    _stopPresencePing();
    _socket?.off("message");
    _socket?.disconnect();
    _socket = null;
  }

  /// Hot reload safety
  @mustCallSuper
  void reassemble() {
    // This runs on hot reload
    print("🔥 Hot reload detected, disconnecting old socket");
    disconnect();
  }
}