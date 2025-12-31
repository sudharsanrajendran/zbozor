import 'package:Ebozor/data/cubits/chat/delete_message_cubit.dart';
import 'package:Ebozor/data/cubits/chat/load_chat_messages.dart';
import 'package:Ebozor/ui/screens/chat/chat_screen.dart';
import 'package:Ebozor/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/app_icon.dart';
import 'package:Ebozor/utils/extensions/lib/build_context.dart';
import 'package:Ebozor/utils/extensions/lib/textWidgetExtention.dart';
import 'package:Ebozor/utils/notification/notification_service.dart';
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
class ChatTile extends StatelessWidget {
  final String profilePicture;
  final String userName;
  final String itemPicture;
  final String itemName;
  final String itemId;
  final String pendingMessageCount;
  final String id;
  final String date;
  final int itemOfferId;
  final double itemPrice;
  final double? itemAmount;
  final String? status;
  final String? buyerId;
  final int isPurchased;
  final bool alreadyReview;

  const ChatTile({
    super.key,
    required this.profilePicture,
    required this.userName,
    required this.itemPicture,
    required this.itemName,
    required this.pendingMessageCount,
    required this.id,
    required this.date,
    required this.itemId,
    required this.itemOfferId,
    required this.itemPrice,
    this.status,
    this.itemAmount,
    this.buyerId,
    required this.isPurchased,
    required this.alreadyReview,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, BlurredRouter(
          builder: (context) {
            currentlyChatingWith = id;
            currentlyChatItemId = itemId;
            return MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => LoadChatMessagesCubit(),
                ),
                BlocProvider(
                  create: (context) => DeleteMessageCubit(),
                ),
              ],
              child: Builder(builder: (context) {
                return ChatScreen(
                  profilePicture: profilePicture,
                  itemTitle: itemName,
                  userId: id,
                  itemImage: itemPicture,
                  userName: userName,
                  itemId: itemId,
                  date: date,
                  itemOfferId: itemOfferId,
                  itemPrice: itemPrice,
                  itemOfferPrice: itemAmount??null,
                  status: status,
                  buyerId: buyerId,
                  alreadyReview: alreadyReview,
                  isPurchased: isPurchased,
                );
              }),
            );
          },
        ));
      },
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          width: MediaQuery.of(context).size.width,
          color: Colors.transparent, // Transparent background
          child: Row(
            children: [
              // 1. Large User Avatar
              // 1. Stack for Avatar (Item Image + User Image)
              Stack(
                children: [
                   // Large Circle: Item/Ad Image
                   Container(
                     width: 50,
                     height: 50,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       image: DecorationImage(
                         image: NetworkImage(itemPicture), // Big Image = Item Image
                         fit: BoxFit.cover,
                         onError: (exception, stackTrace) {},
                       ),
                       border: Border.all(color: Colors.transparent)
                     ),
                     child: itemPicture.isEmpty
                        ? CircleAvatar(
                             radius: 25,
                             backgroundColor: context.color.territoryColor,
                            child: SvgPicture.asset(AppIcons.profile, colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn))
                          )
                        : null,
                   ),
                   
                   // Small Circle: User/Profile Image (Badge)
                   Positioned(
                     bottom: 0,
                     right: 0,
                     child: Container(
                       width: 20, // Smaller size for badge
                       height: 20,
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         border: Border.all(color: context.color.secondaryColor, width: 1.5), // Border to separate from bg
                         image: DecorationImage(
                           image: NetworkImage(profilePicture), // Small Image = User Profile
                           fit: BoxFit.cover,
                           onError: (exception, stackTrace) {},
                         ),
                         color: Colors.grey[300] // Fallback color
                       ),
                         child: profilePicture.isEmpty ? 
                            Icon(Icons.person, size: 12, color: Colors.grey[600]) : null,
                     ),
                   )
                ],
              ),
              
              const SizedBox(width: 15),
              
              // 2. Name and Item Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.color.textColorDark
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      itemName, // Or "Property For Selling" based on context, but using itemName is safer dynamic data
                      style: TextStyle(
                        fontSize: 14,
                        color: context.color.textDefaultColor.withOpacity(0.6)
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // 3. Date (Right Side)
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   Text(
                      date, // Ensure 'date' format is short (e.g. "Yesterday" or "10:30")
                      style: TextStyle(
                        fontSize: 12,
                         color: context.color.textDefaultColor.withOpacity(0.5)
                      ),
                   ),
                   // Optional: Unread count badge could go here if needed
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
