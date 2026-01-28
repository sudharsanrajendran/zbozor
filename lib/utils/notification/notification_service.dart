// ignore_for_file: file_names

import 'dart:async';
import 'dart:developer';
import 'package:Ebozor/app/routes.dart';
import 'package:Ebozor/data/model/chat/chat_message_modal.dart';
import 'package:Ebozor/ui/screens/chat/chat_audio/widgets/chat_widget.dart';
import 'package:Ebozor/utils/constant.dart';
import 'package:Ebozor/utils/LocalStoreage/hive_utils.dart';
import 'package:Ebozor/utils/notification/awsomeNotification.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:Ebozor/ui/screens/chat/chat_screen.dart';

import 'package:Ebozor/ui/screens/main_activity.dart';
import 'package:Ebozor/data/repositories/item/item_repository.dart';
import 'package:Ebozor/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:Ebozor/data/cubits/chat/get_seller_chat_users_cubit.dart';
import 'package:Ebozor/data/cubits/chat/load_chat_messages.dart';
import 'package:Ebozor/data/cubits/chat/send_message.dart';
import 'package:Ebozor/data/model/chat/chated_user_model.dart';
import 'package:Ebozor/data/model/data_output.dart';

import 'package:Ebozor/data/model/item/item_model.dart';

import 'package:Ebozor/utils/helper_utils.dart';
import 'package:Ebozor/utils/notification/chat_message_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

String currentlyChatingWith = "";
String currentlyChatItemId = "";

class NotificationService {
  static FirebaseMessaging messagingInstance = FirebaseMessaging.instance;

  static LocalAwsomeNotification localNotification = LocalAwsomeNotification();

  static late StreamSubscription<RemoteMessage> foregroundStream;
  static late StreamSubscription<RemoteMessage> onMessageOpen;

  static Future<void> requestPermission() async {}

/*  static int? getPrice(dynamic price) {
    if (price == null || price.toString().trim().isEmpty) {
      return null;
    }
    if (price is double) {
      return price.toInt();
    }
    if (price is String) {
      return int.parse(price);
    }
    return price;
  }*/

  static double? getPrice(dynamic price) {
    if (price == null || price.toString().isEmpty) {
      return null;
    }
    if (price is String) {
      if (price == "") return null;
      return double.tryParse(price);
    }
    if (price is int) {
      return price.toDouble();
    }
    if (price is double) {
      return price;
    }
    return null; // In case of unexpected types
  }

  static int? safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /* void updateFCM() async {
    await FirebaseMessaging.instance.getToken();
    // await Api.post(
    //     // url: Api.updateFCMId,
    //     parameter: {Api.fcmId: token},
    //     useAuthToken: true);
  }*/

  //chat notification
  static void handleNotification(RemoteMessage? message,
      [BuildContext? context]) {
    var notificationType = message?.data['type'] ?? "";

    print("@notificaiton data is ${message?.data}****${notificationType}");

    if (notificationType == "chat" || notificationType == "offer") {
      var username = message?.data['user_name'];
      var itemImage = message?.data['item_image'];
      var itemName = message?.data['item_name'];
      var userProfile = message?.data['user_profile'];
      var senderId = message?.data['sender_id'];
      var itemId = message?.data['item_id'];
      var date = message?.data['created_at'];
      var itemOfferId = message?.data['item_offer_id'];
      var itemPrice = message?.data['item_price'];
      var itemOfferPrice = message?.data['item_offer_amount'];
      var userType = message?.data['user_type'];

      if (userType == "Buyer") {
        // Sender is Buyer -> I am Seller -> Update Seller List
        (context as BuildContext).read<GetSellerChatListCubit>().addNewChat(
              ChatedUser(
                itemId: safeInt(itemId) ?? 0,
                amount: getPrice(itemOfferPrice),
                createdAt: date,
                userBlocked: false,
                id: safeInt(itemOfferId) ?? 0,
                sellerId: HiveUtils.getUserId() != null
                    ? int.tryParse(HiveUtils.getUserId()!)
                    : 0, // Me
                buyerId: safeInt(senderId) ?? 0, // Sender
                updatedAt: date,
                // For Seller List, we need Buyer details
                buyer: Buyer(
                  name: username,
                  profile: userProfile,
                  id: safeInt(senderId) ?? 0,
                ),
                item: Item(
                  id: safeInt(itemId) ?? 0,
                  price: getPrice((itemPrice)),
                  name: itemName,
                  image: itemImage,
                ),
              ),
            );
      } else {
        // Sender is Seller -> I am Buyer -> Update Buyer List
        (context as BuildContext).read<GetBuyerChatListCubit>().addNewChat(
              ChatedUser(
                itemId: safeInt(itemId) ?? 0,
                userBlocked: false,
                amount: getPrice(itemOfferPrice),
                createdAt: date,
                id: safeInt(itemOfferId) ?? 0,
                buyerId: HiveUtils.getUserId() != null
                    ? int.tryParse(HiveUtils.getUserId()!)
                    : 0, // Me
                sellerId: safeInt(senderId) ?? 0, // Sender
                // For Buyer List, we need Seller details
                seller: Seller(
                  name: username,
                  profile: userProfile,
                  id: safeInt(senderId) ?? 0,
                ),
                item: Item(
                  id: safeInt(itemId) ?? 0,
                  price: getPrice((itemPrice)),
                  name: itemName,
                  image: itemImage,
                ),
              ),
            );
      }

      ///Checking if this is user we are chatiing with

      if (senderId == currentlyChatingWith && itemId == currentlyChatItemId) {
        ChatMessageModal chatMessageModel = ChatMessageModal(
            id: safeInt(message?.data['id']) ?? 0,
            updatedAt: message?.data['updated_at'],
            createdAt: message?.data['created_at'],
            itemId: safeInt(message?.data['item_id']) ?? 0,
            audio: message?.data['audio'],
            file: message?.data['file'],
            message: message?.data['message'],
            receiverId: int.parse(HiveUtils.getUserId().toString()),
            senderId: safeInt(message?.data['sender_id']) ?? 0);

        ChatMessageHandler.addchat(BlocProvider(
          create: (context) => SendMessageCubit(),
          child: ChatMessage(
            key: ValueKey(chatMessageModel.id),
            message: chatMessageModel.message,
            senderId: chatMessageModel.senderId!,
            createdAt: chatMessageModel.createdAt!,
            isSentNow: false,
            updatedAt: chatMessageModel.updatedAt!,
            audio: chatMessageModel.audio,
            file: chatMessageModel.file,
            itemOfferId: chatMessageModel.id!,
          ),
        ));

        totalMessageCount++;
      } else {
        localNotification.createNotification(
          isLocked: false,
          notificationData: message!,
        );
      }
    } else {
      localNotification.createNotification(
        isLocked: false,
        notificationData: message!,
      );
    }
  }

  static bool _isInitialized = false;

  static void init(context) {
    if (_isInitialized) return; // Prevent multiple initializations
    _isInitialized = true;
    localNotification.init(context);
    registerListeners(context);
  }

  @pragma('vm:entry-point')
  static Future<void> onBackgroundMessageHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    handleNotification(message);
  }

  static Future<void> forgroundNotificationHandler(BuildContext context) async {
    foregroundStream =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("foreground notification***${message.toString()}");
      handleNotification(message, context);
    });
  }

  static Future<void> terminatedStateNotificationHandler(
      BuildContext context) async {
    final RemoteMessage? message =
        await FirebaseMessaging.instance.getInitialMessage();
    if (message == null) {
      return;
    }
    if (message.notification == null) {
      handleNotification(message, context);
    }
  }

  static void onTapNotificationHandler(context) {
    onMessageOpen = FirebaseMessaging.onMessageOpenedApp
        .listen((RemoteMessage message) async {
      print("message.data on tap***${message.data.toString()}");
      if (message.data['type'] == "chat") {
        var username = message.data['user_name'];
        var itemTitleImage = message.data['item_title_image'];
        var itemTitle = message.data['item_title'];
        var userProfile = message.data['user_profile'];
        var senderId = message.data['sender_id'];
        var itemId = message.data['item_id'];
        var date = message.data['created_at'];
        var itemOfferId = message.data['item_offer_id'];
        var itemPrice = message.data['item_price'];
        var itemOfferPrice = message.data['item_offer_amount'] ?? null;
        Future.delayed(
          Duration.zero,
          () {
            Navigator.push(Constant.navigatorKey.currentContext!,
                MaterialPageRoute(
              builder: (context) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (context) => SendMessageCubit(),
                    ),
                    BlocProvider(
                      create: (context) => LoadChatMessagesCubit(),
                    ),
                  ],
                  child: Builder(builder: (context) {
                    return ChatScreen(
                      profilePicture: userProfile ?? "",
                      userName: username ?? "",
                      itemImage: itemTitleImage ?? "",
                      itemTitle: itemTitle ?? "",
                      userId: senderId ?? "",
                      itemId: itemId ?? "",
                      date: date ?? "",
                      itemOfferId: int.parse(itemOfferId),
                      itemPrice: getPrice(itemPrice)!,
                      itemOfferPrice: getPrice(itemOfferPrice),
                      buyerId: HiveUtils.getUserId(),
                      alreadyReview: false,
                      isPurchased: 0,
                    );
                  }),
                );
              },
            ));
          },
        );
      } else if (message.data['type'] == "offer") {
        if (HiveUtils.isUserAuthenticated()) {
          var username = message.data['user_name'];
          var itemTitleImage = message.data['item_title_image'];
          var itemTitle = message.data['item_title'];
          var userProfile = message.data['user_profile'];
          var senderId = message.data['sender_id'];
          var itemId = message.data['item_id'];
          var date = message.data['created_at'];
          var itemOfferId = message.data['item_offer_id'];
          var itemPrice = message.data['item_price'];
          var itemOfferPrice = message.data['item_offer_amount'] ?? null;

          /* var username = message.data['user_name'];
          var itemTitleImage = message.data['image'];
          var itemTitle = message.data['name'];
          var userProfile = message.data['user_profile'];
          var senderId = message.data['user_id'];
          var itemId = message.data['id'];
          var date = message.data['created_at'];
          var itemOfferId = message.data['item_offer_id'];
          var itemPrice = message.data['price'];
          var itemOfferPrice = message.data['item_offer_amount'] ?? null;*/
          Future.delayed(
            Duration.zero,
            () {
              Navigator.push(Constant.navigatorKey.currentContext!,
                  MaterialPageRoute(
                builder: (context) {
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (context) => SendMessageCubit(),
                      ),
                      BlocProvider(
                        create: (context) => LoadChatMessagesCubit(),
                      ),
                    ],
                    child: Builder(builder: (context) {
                      return ChatScreen(
                        profilePicture: userProfile ?? "",
                        userName: username ?? "",
                        itemImage: itemTitleImage ?? "",
                        itemTitle: itemTitle ?? "",
                        userId: senderId ?? "",
                        itemId: itemId ?? "",
                        date: date ?? "",
                        itemOfferId: int.parse(itemOfferId),
                        itemPrice: getPrice(itemPrice)!,
                        itemOfferPrice: getPrice(itemOfferPrice),
                        buyerId: HiveUtils.getUserId(),
                        alreadyReview: false,
                        isPurchased: 0,
                      );
                    }),
                  );
                },
              ));
            },
          );
          /*Future.delayed(Duration.zero, () {
            HelperUtils.goToNextPage(
              Routes.main,
              Constant.navigatorKey.currentContext!,
              false,
            );
            MainActivity.globalKey.currentState?.onItemTapped(1);
          });*/
        } else {
          Future.delayed(Duration.zero, () {
            HelperUtils.goToNextPage(Routes.notificationPage,
                Constant.navigatorKey.currentContext!, false);
          });
        }
      } else if (message.data['type'] == "item-update") {
        Future.delayed(Duration.zero, () {
          HelperUtils.goToNextPage(
            Routes.main,
            Constant.navigatorKey.currentContext!,
            false,
          );
          MainActivity.globalKey.currentState?.onItemTapped(2);
        });
      } else if (message.data["item_id"] != null &&
          message.data["item_id"] != '') {
        String id = message.data["item_id"] ?? "";
        DataOutput<ItemModel> item =
            await ItemRepository().fetchItemFromItemId(int.parse(id));
        Future.delayed(Duration.zero, () {
          Navigator.pushNamed(
              Constant.navigatorKey.currentContext!, Routes.adDetailsScreen,
              arguments: {
                'model': item.modelList[0],
              });
          /* HelperUtils.goToNextPage(Routes.adDetailsScreen,
              Constant.navigatorKey.currentContext!, false,
              args: {
                'model': item.modelList[0],
              });*/
        });
      } else if (message.data['type'] == "payment") {
        if (HiveUtils.isUserAuthenticated()) {
          Future.delayed(Duration.zero, () {
            Navigator.pushNamed(Constant.navigatorKey.currentContext!,
                Routes.subscriptionPackageListRoute);
          });
        } else {
          Future.delayed(Duration.zero, () {
            HelperUtils.goToNextPage(Routes.notificationPage,
                Constant.navigatorKey.currentContext!, false);
          });
        }
      } else {
        Future.delayed(Duration.zero, () {
          HelperUtils.goToNextPage(Routes.notificationPage,
              Constant.navigatorKey.currentContext!, false);
        });
      }
    }
// if (message.data["screen"] == "profile") {
//   Navigator.pushNamed(context, profileRoute);
// }

            );
  }

  static Future<void> registerListeners(context) async {
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);
    await forgroundNotificationHandler(context);
    await terminatedStateNotificationHandler(context);
    onTapNotificationHandler(context);
  }

  static void disposeListeners() {
    onMessageOpen.cancel();
    foregroundStream.cancel();
  }
}
