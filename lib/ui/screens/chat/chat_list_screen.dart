import 'package:Ebozor/app/routes.dart';
import 'package:Ebozor/data/cubits/chat/blocked_users_list_cubit.dart';
import 'package:Ebozor/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:Ebozor/data/cubits/chat/get_seller_chat_users_cubit.dart';
import 'package:Ebozor/data/cubits/chat/unblock_user_cubit.dart';
import 'package:Ebozor/data/model/chat/chated_user_model.dart';
import 'package:Ebozor/ui/screens/chat/chatTile.dart' show ChatTile;
import 'package:Ebozor/ui/screens/home/home_screen.dart';
import 'package:Ebozor/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:Ebozor/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:Ebozor/ui/screens/widgets/errors/no_data_found.dart';
import 'package:Ebozor/ui/screens/widgets/errors/no_internet.dart';
import 'package:Ebozor/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:Ebozor/ui/screens/widgets/shimmerLoadingContainer.dart' show CustomShimmer;
import 'package:Ebozor/ui/theme/theme.dart';
import 'package:Ebozor/utils/ApiService/api.dart';
import 'package:Ebozor/utils/LocalStoreage/hive_utils.dart';
import 'package:Ebozor/utils/app_icon.dart';
import 'package:Ebozor/utils/extensions/lib/build_context.dart' show CustomContext;
import 'package:Ebozor/utils/extensions/lib/textWidgetExtention.dart';
import 'package:Ebozor/utils/extensions/lib/translate.dart';
import 'package:Ebozor/utils/helper_utils.dart';
import 'package:Ebozor/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  static Route route(RouteSettings settings) {
    return BlurredRouter(
      builder: (context) {
        return const ChatListScreen();
      },
    );
  }

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with AutomaticKeepAliveClientMixin {
  ScrollController chatBuyerScreenController = ScrollController();
  ScrollController chatSellerScreenController = ScrollController();
  int _selectedTabIndex = 0;

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime yesterday = today.subtract(const Duration(days: 1));
      DateTime checkDate = DateTime(date.year, date.month, date.day);

      if (checkDate == today) {
        return "Today";
      } else if (checkDate == yesterday) {
        return "Yesterday";
      } else {
        return DateFormat("MMM d").format(date);
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  void initState() {
    if (HiveUtils.isUserAuthenticated()) {
      context.read<GetBuyerChatListCubit>().setContext(context);
      context.read<GetSellerChatListCubit>().setContext(context);
      context.read<GetBuyerChatListCubit>().fetch();
      context.read<GetSellerChatListCubit>().fetch();
      context.read<BlockedUsersListCubit>().blockedUsersList();
      chatBuyerScreenController.addListener(() {
        if (chatBuyerScreenController.isEndReached()) {
          if (context.read<GetBuyerChatListCubit>().hasMoreData()) {
            context.read<GetBuyerChatListCubit>().loadMore();
          }
        }
      });
      chatSellerScreenController.addListener(() {
        if (chatSellerScreenController.isEndReached()) {
          if (context.read<GetSellerChatListCubit>().hasMoreData()) {
            context.read<GetSellerChatListCubit>().loadMore();
          }
        }
      });
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.secondaryColor,
      ),
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: UiUtils.buildAppBar(
          context,
          title: "Chats",
          bottomHeight: 0,
          actions: [
            InkWell(
              child: UiUtils.getSvg(AppIcons.blockedUserIcon,
                  color: context.color.textDefaultColor),
              onTap: () {
                Navigator.pushNamed(context, Routes.blockedUserListScreen);
              },
            )
          ],
        ),
        body: Column(
          children: [
            Container(
              color: context.color.secondaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _buildTabChip(0, "buying".translate(context)),
                  const SizedBox(width: 12),
                  _buildTabChip(1, "selling".translate(context)),
                ],
              ),
            ),
            Expanded(
              child: _selectedTabIndex == 0
                  ? buyingChatListData()
                  : sellingChatListData(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(int index, String title) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
         // color: isSelected ? context.color.textLightColor : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected ? context.color.textColorDark : context.color.borderColor,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? context.color.textColorDark
                : context.color.textDefaultColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget buyingChatListData() {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<GetBuyerChatListCubit>().setContext(context);

        context.read<GetBuyerChatListCubit>().fetch();
      },
      color: context.color.territoryColor,
      child: BlocBuilder<GetBuyerChatListCubit, GetBuyerChatListState>(
        builder: (context, state) {
          if (state is GetBuyerChatListFailed) {
            if (state.error is ApiException) {
              if (state.error.errorMessage == "no-internet") {
                return NoInternet(
                  onRetry: () {
                    context.read<GetBuyerChatListCubit>().fetch();
                  },
                );
              }
            }
            return const NoChatFound();
          }

          if (state is GetBuyerChatListInProgress) {
            return buildChatListLoadingShimmer();
          }
          if (state is GetBuyerChatListSuccess) {
            if (state.chatedUserList.isEmpty) {
              return NoChatFound();
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                      controller: chatBuyerScreenController,
                      shrinkWrap: true,
                      itemCount: state.chatedUserList.length,
                      padding: const EdgeInsetsDirectional.all(16),
                      itemBuilder: (
                        context,
                        index,
                      ) {
                        ChatedUser chatedUser = state.chatedUserList[index];

                        return Padding(
                          padding: const EdgeInsets.only(top: 9.0),
                          child: ChatTile(
                            id: chatedUser.sellerId.toString(),
                            itemId: chatedUser.itemId.toString(),
                            profilePicture: chatedUser.seller != null &&
                                    chatedUser.seller!.profile != null
                                ? chatedUser.seller!.profile!
                                : "",
                            userName: chatedUser.seller != null &&
                                    chatedUser.seller!.name != null
                                ? chatedUser.seller!.name!
                                : "",
                            itemPicture: chatedUser.item != null &&
                                    chatedUser.item!.image != null
                                ? chatedUser.item!.image!
                                : "",
                            itemName: chatedUser.item != null &&
                                    chatedUser.item!.name != null
                                ? chatedUser.item!.name!
                                : "",
                            pendingMessageCount: "5",
                            date: _formatDate(chatedUser.createdAt!),
                            itemOfferId: chatedUser.id!,
                            itemPrice: chatedUser.item != null &&
                                    chatedUser.item!.price != null
                                ? chatedUser.item!.price!
                                : 0.0,
                            itemAmount: chatedUser.amount??null,
                            status: chatedUser.item != null &&
                                    chatedUser.item!.status != null
                                ? chatedUser.item!.status!
                                : null,
                            buyerId: chatedUser.buyerId.toString(),
                            isPurchased: chatedUser.item!.isPurchased??0,
                            alreadyReview:
                                chatedUser.item!.review == null ? false : true,
                          ),
                        );
                      }),
                ),
                if (state.isLoadingMore) UiUtils.progress()
              ],
            );
          }

          return Container();
        },
      ),
    );
  }

  Widget sellingChatListData() {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<GetSellerChatListCubit>().setContext(context);

        context.read<GetSellerChatListCubit>().fetch();
      },
      color: context.color.territoryColor,
      child: BlocBuilder<GetSellerChatListCubit, GetSellerChatListState>(
        builder: (context, state) {
          if (state is GetSellerChatListFailed) {
            if (state.error is ApiException) {
              if (state.error.errorMessage == "no-internet") {
                return NoInternet(
                  onRetry: () {
                    context.read<GetSellerChatListCubit>().fetch();
                  },
                );
              }
            }

            return const NoChatFound();
          }

          if (state is GetSellerChatListInProgress) {
            return buildChatListLoadingShimmer();
          }
          if (state is GetSellerChatListSuccess) {
            if (state.chatedUserList.isEmpty) {
              return NoChatFound();
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                      controller: chatSellerScreenController,
                      shrinkWrap: true,
                      itemCount: state.chatedUserList.length,
                      padding: const EdgeInsetsDirectional.all(16),
                      itemBuilder: (
                        context,
                        index,
                      ) {
                        ChatedUser chatedUser = state.chatedUserList[index];

                        return Padding(
                          padding: const EdgeInsets.only(top: 9.0),
                          child: ChatTile(
                            id: chatedUser.buyerId.toString(),
                            itemId: chatedUser.itemId.toString(),
                            profilePicture: chatedUser.buyer!.profile ?? "",
                            userName: chatedUser.buyer!.name ?? "",
                            itemPicture: chatedUser.item != null &&
                                    chatedUser.item!.image != null
                                ? chatedUser.item!.image!
                                : "",
                            itemName: chatedUser.item != null &&
                                    chatedUser.item!.name != null
                                ? chatedUser.item!.name!
                                : "",
                            pendingMessageCount: "5",
                            date: _formatDate(chatedUser.createdAt!),
                            itemOfferId: chatedUser.id!,
                            itemPrice: chatedUser.item != null &&
                                    chatedUser.item!.price != null
                                ? chatedUser.item!.price!
                                : 0,
                            itemAmount: chatedUser.amount??null,
                            status: chatedUser.item != null &&
                                    chatedUser.item!.status != null
                                ? chatedUser.item!.status!
                                : null,
                            buyerId: chatedUser.buyerId.toString(),
                            isPurchased: chatedUser.item!.isPurchased!,
                            alreadyReview:
                                chatedUser.item!.review == null ? false : true,
                          ),
                        );
                      }),
                ),
                if (state.isLoadingMore) UiUtils.progress()
              ],
            );
          }

          return Container();
        },
      ),
    );
  }

  Widget buildChatListLoadingShimmer() {
    return ListView.builder(
        itemCount: 10,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(16),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(top: 9.0),
            child: SizedBox(
              height: 74,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Shimmer.fromColors(
                      baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
                      highlightColor:
                          Theme.of(context).colorScheme.shimmerHighlightColor,
                      child: Stack(
                        children: [
                          const SizedBox(
                            width: 58,
                            height: 58,
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: 42,
                              height: 42,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                  color: Colors.grey,
                                  border: Border.all(
                                      width: 1.5, color: Colors.white),
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          PositionedDirectional(
                            end: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2)),
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: context.color.territoryColor,
                                  // backgroundImage: NetworkImage(profilePicture),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomShimmer(
                          height: 10,
                          borderRadius: 5,
                          width: context.screenWidth * 0.53,
                        ),
                        CustomShimmer(
                          height: 10,
                          borderRadius: 5,
                          width: context.screenWidth * 0.3,
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  @override
  bool get wantKeepAlive => true;
}
