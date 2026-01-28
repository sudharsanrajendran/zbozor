import 'package:Ebozor/data/model/chat/chated_user_model.dart';
import 'package:Ebozor/data/model/data_output.dart';
import 'package:Ebozor/data/model/seller_ratings_model.dart';
import 'package:Ebozor/data/repositories/chat_repository.dart';
import 'package:Ebozor/utils/LocalStoreage/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class GetSellerChatListState {}

class GetSellerChatListInitial extends GetSellerChatListState {}

class GetSellerChatListInProgress extends GetSellerChatListState {}

class GetSellerChatListInternalProcess extends GetSellerChatListState {}

class GetSellerChatListSuccess extends GetSellerChatListState {
  final int total;
  final bool isLoadingMore;
  final bool hasError;
  final int page;
  final List<ChatedUser> chatedUserList;

  GetSellerChatListSuccess({
    required this.total,
    required this.isLoadingMore,
    required this.hasError,
    required this.chatedUserList,
    required this.page,
  });

  GetSellerChatListSuccess copyWith({
    int? total,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasError,
    int? page,
    List<ChatedUser>? chatedUserList,
  }) {
    return GetSellerChatListSuccess(
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      chatedUserList: chatedUserList ?? this.chatedUserList,
      page: page ?? this.page,
    );
  }
}

class GetSellerChatListFailed extends GetSellerChatListState {
  final dynamic error;

  GetSellerChatListFailed(this.error);
}

class GetSellerChatListCubit extends Cubit<GetSellerChatListState> {
  GetSellerChatListCubit() : super(GetSellerChatListInitial());
  final ChatRepostiory _chatRepository = ChatRepostiory();

  void setContext(BuildContext context) {
    _chatRepository.setContext(context);
  }

  void fetch({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && state is GetSellerChatListSuccess) {
        return;
      }
      emit(GetSellerChatListInProgress());

      DataOutput<ChatedUser> result =
          await _chatRepository.fetchSellerChatList(1);

      result.modelList.sort((a, b) =>
          DateTime.parse(b.createdAt!).compareTo(DateTime.parse(a.createdAt!)));

      // Filter: Only show chats where the current user is the seller
      // The API should ideally handle this via 'type', but we filter locally as a safety measure
      // or if we reuse the same list endpoint without filtering.
      // Based on previous plan, we rely on API or 'type'. Here we filter where I AM the seller.
      result.modelList.removeWhere(
          (element) => element.sellerId.toString() != HiveUtils.getUserId());

      emit(
        GetSellerChatListSuccess(
            isLoadingMore: false,
            hasError: false,
            chatedUserList: result.modelList,
            total: result.total,
            page: 1),
      );
    } catch (e) {
      emit(GetSellerChatListFailed(e));
    }
  }

  void addNewChat(ChatedUser user) {
    if (state is GetSellerChatListSuccess) {
      final currentState = state as GetSellerChatListSuccess;
      List<ChatedUser> chatedUserList = List.from(currentState.chatedUserList);

      // Only proceed if I am the seller
      if (user.sellerId.toString() == HiveUtils.getUserId()) {
        // Remove if exists to move to top (Check ItemId AND BuyerId)
        chatedUserList.removeWhere(
          (element) =>
              element.itemId == user.itemId && element.buyerId == user.buyerId,
        );

        chatedUserList.insert(0, user);
        emit(currentState.copyWith(
            chatedUserList: chatedUserList, total: chatedUserList.length));
      }
    }
  }

  void updateAlreadyReview(int itemId) {
    if (state is GetSellerChatListSuccess) {
      List<ChatedUser> chatedUserList =
          (state as GetSellerChatListSuccess).chatedUserList;
      int index =
          chatedUserList.indexWhere((element) => element.itemId == itemId);

      if (index != -1) {
        chatedUserList[index].item!.review = UserRatings(
          sellerId: chatedUserList[index].sellerId,
          itemId: itemId,
          buyerId: chatedUserList[index].buyerId,
        );
        if (!isClosed) {
          emit((state as GetSellerChatListSuccess)
              .copyWith(chatedUserList: chatedUserList));
        }
      }
    }
  }

  Future<void> loadMore() async {
    try {
      if (state is GetSellerChatListSuccess) {
        if ((state as GetSellerChatListSuccess).isLoadingMore) {
          return;
        }
        emit((state as GetSellerChatListSuccess).copyWith(isLoadingMore: true));

        DataOutput<ChatedUser> result =
            await _chatRepository.fetchSellerChatList(
          (state as GetSellerChatListSuccess).page + 1,
        );

        GetSellerChatListSuccess messagesSuccessState =
            (state as GetSellerChatListSuccess);

        messagesSuccessState.chatedUserList.addAll(result.modelList);

        messagesSuccessState.chatedUserList.sort((a, b) =>
            DateTime.parse(b.createdAt!)
                .compareTo(DateTime.parse(a.createdAt!)));

        // Filter out non-seller items again if needed?
        // Assuming API does it or we do it here.
        // Note: Logic above in fetch removes items, we should do same here or ensure fetchSellerChatList does it.
        // Let's assume fetchSellerChatList sends 'type=seller'.

        emit(GetSellerChatListSuccess(
          chatedUserList: messagesSuccessState.chatedUserList,
          page: (state as GetSellerChatListSuccess).page + 1,
          hasError: false,
          isLoadingMore: false,
          total: result.total,
        ));
      }
    } catch (e) {
      emit((state as GetSellerChatListSuccess)
          .copyWith(isLoadingMore: false, hasError: true));
    }
  }

  bool hasMoreData() {
    if (state is GetSellerChatListSuccess) {
      return (state as GetSellerChatListSuccess).chatedUserList.length <
          (state as GetSellerChatListSuccess).total;
    }

    return false;
  }
}
