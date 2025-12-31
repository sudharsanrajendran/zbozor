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
  Timer? _typingResetTimer;

  bool get isConnected => _socket?.connected ?? false;
  // Map contains { 'userId': String, 'userName': String }
  final ValueNotifier<Map<String, String>?> typingStatus = ValueNotifier(null);

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


    // Generic typing listener based on server logic: "typing" event with boolean payload
    _socket!.on("typing", (data) {
      print("🔥 Received typing event: $data");
      if (data is Map) {
        final isTyping = data['typing'] ?? false;
        final userId = data['user_id']?.toString();
        final userName = data['user_name']?.toString() ?? "User";
        final myId = HiveUtils.getUserId();

        // Ignore our own typing events if they bounce back
        if (userId == myId) return;

        if (isTyping) {
          if (userId != null) {
            typingStatus.value = {'userId': userId, 'userName': userName};
            
            // Auto-reset timer in case we miss the stop event
            _typingResetTimer?.cancel();
            _typingResetTimer = Timer(const Duration(seconds: 9), () {
              if (typingStatus.value?['userId'] == userId) {
                 typingStatus.value = null;
              }
            });
          }
        } else {
          // If typing is false, clear the status
           typingStatus.value = null;
           _typingResetTimer?.cancel();
        }
      }
    });





    // Add listeners once
    _socket!.off("message");
    _socket!.on("message", _onMessageReceived);

    _socket!.onConnect((_) {
      print("🔥 Socket Connected: ${_socket?.id}");
      _startPresencePing();
      if (_currentOfferId != null) {
         print("🔥 Re-emitting join on connect: {offerId: $_currentOfferId}");
         _socket?.emit("join", {"offerId": _currentOfferId});
      }
    });

    _socket!.onConnectError((data) => print("🔥 Socket Connect Error: $data"));
    _socket!.onError((data) => print("🔥 Socket Error: $data"));
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

  int? _currentOfferId;

  /// Join a specific offer room
  void joinOffer(int offerId) {
    _currentOfferId = offerId;
    if (_socket == null || !_socket!.connected) {
      print("🔥 Cannot join offer $offerId immediately - Socket connecting/disconnected");
      socketconnect();
      // The onConnect listener will handle the join now
      return; 
    }
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
    if (_socket == null || !_socket!.connected) {
      print("🔥 Cannot emit typing:start - Socket disconnected or null");
      socketconnect();
      return; 
    }
    print("🔥 Emitting typing:start: {offerId: $offerId}");
    _socket?.emit("typing:start", {"offerId": offerId});
  }

  void typingStop(int offerId) {
     if (_socket == null || !_socket!.connected) {
       print("🔥 Cannot emit typing:stop - Socket disconnected or null");
       return;
     }
    print("🔥 Emitting typing:stop: {offerId: $offerId}");
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