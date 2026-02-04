import 'package:Ebozor/data/model/chat/chated_user_model.dart';
import 'package:Ebozor/data/model/data_output.dart';
import 'package:Ebozor/data/model/seller_ratings_model.dart';
import 'package:Ebozor/data/repositories/chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Ebozor/utils/LocalStoreage/hive_utils.dart';

abstract class GetBuyerChatListState {}

class GetBuyerChatListInitial extends GetBuyerChatListState {}

class GetBuyerChatListInProgress extends GetBuyerChatListState {}

class GetBuyerChatListInternalProcess extends GetBuyerChatListState {}

class GetBuyerChatListSuccess extends GetBuyerChatListState {
  final int total;
  final bool isLoadingMore;
  final bool hasError;
  final int page;
  final List<ChatedUser> chatedUserList;

  GetBuyerChatListSuccess({
    required this.total,
    required this.isLoadingMore,
    required this.hasError,
    required this.chatedUserList,
    required this.page,
  });

  GetBuyerChatListSuccess copyWith({
    int? total,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasError,
    int? page,
    List<ChatedUser>? chatedUserList,
  }) {
    return GetBuyerChatListSuccess(
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      chatedUserList: chatedUserList ?? this.chatedUserList,
      page: page ?? this.page,
    );
  }
}

class GetBuyerChatListFailed extends GetBuyerChatListState {
  final dynamic error;

  GetBuyerChatListFailed(this.error);
}

class GetBuyerChatListCubit extends Cubit<GetBuyerChatListState> {
  GetBuyerChatListCubit() : super(GetBuyerChatListInitial());
  final ChatRepostiory _chatRepository = ChatRepostiory();

  ///Setting build context for later use
  void setContext(BuildContext context) {
    _chatRepository.setContext(context);
  }

  void fetch({bool forceRefresh = false}) async {
    // 1. Load from Cache immediately (safeguarded)
    if (!forceRefresh && state is! GetBuyerChatListSuccess) {
      try {
        List<dynamic> cachedData = HiveUtils.getBuyerChatList();
        if (cachedData.isNotEmpty) {
          List<ChatedUser> cachedList = cachedData
              .map((e) => ChatedUser.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          emit(GetBuyerChatListSuccess(
              isLoadingMore: false,
              hasError: false,
              chatedUserList: cachedList,
              total: cachedList.length,
              page: 1));
        } else {
          emit(GetBuyerChatListInProgress());
        }
      } catch (e) {
        // If cache fails, just show loading and proceed to API
        emit(GetBuyerChatListInProgress());
      }
    }

    try {
      if (!forceRefresh && state is GetBuyerChatListSuccess) {
        // If we already have success state (from cache or previous),
        // and not forced, we might stop here?
        // NO, the original logic was to return if success.
        // But now we want to BACKGROUND refresh.
        // So we continue to fetch API.
        // However, we shouldn't return if we just loaded from cache!
        // We must distinguish "Loaded from Cache" vs "Loaded from API".
        // For now, let's assume if we are here, we want to fetch API.
      }

      // 2. Fetch from API
      DataOutput<ChatedUser> result =
          await _chatRepository.fetchBuyerChatList(1);

      // print("Buyer Chat List BEFORE filter: ${result.modelList.length} items");
      // for (var item in result.modelList) {
      //   print(
      //       "Chat Item: SellerId: ${item.sellerId}, ItemId: ${item.itemId}, Myself: ${HiveUtils.getUserId()}");
      // }

      result.modelList.sort((a, b) {
        DateTime updatedA =
            DateTime.tryParse(a.updatedAt ?? "") ?? DateTime(1970);
        DateTime createdA =
            DateTime.tryParse(a.createdAt ?? "") ?? DateTime(1970);
        DateTime dateA = updatedA.isAfter(createdA) ? updatedA : createdA;

        DateTime updatedB =
            DateTime.tryParse(b.updatedAt ?? "") ?? DateTime(1970);
        DateTime createdB =
            DateTime.tryParse(b.createdAt ?? "") ?? DateTime(1970);
        DateTime dateB = updatedB.isAfter(createdB) ? updatedB : createdB;

        return dateB.compareTo(dateA);
      });

      result.modelList.removeWhere(
          (element) => element.sellerId.toString() == HiveUtils.getUserId());

      // print("Buyer Chat List AFTER filter: ${result.modelList.length} items");

      // 3. Emit Success FIRST (Update UI)
      emit(
        GetBuyerChatListSuccess(
            isLoadingMore: false,
            hasError: false,
            chatedUserList: result.modelList,
            total: result.total,
            page: 1),
      );

      // 4. Update Cache (Safely)
      try {
        List<Map<String, dynamic>> listMap =
            result.modelList.map((e) => e.toJson()).toList();
        await HiveUtils.setBuyerChatList(listMap);
      } catch (e) {
        print("Error updating buyer chat cache: $e");
      }
    } catch (e) {
      // Only emit failure if we don't have any data shown (i.e. if we didn't load from cache successfully)
      if (state is! GetBuyerChatListSuccess) {
        emit(GetBuyerChatListFailed(e));
      }
    }
  }

  void addNewChat(ChatedUser user) {
    //this will create new chat in chat list if there is no already
    if (state is GetBuyerChatListSuccess) {
      final currentState = state as GetBuyerChatListSuccess;
      List<ChatedUser> chatedUserList = List.from(currentState.chatedUserList);

      // Remove if exists to move to top
      chatedUserList.removeWhere(
        (element) => element.itemId == user.itemId,
      );

      chatedUserList.insert(0, user);

      chatedUserList.sort((a, b) {
        DateTime updatedA =
            DateTime.tryParse(a.updatedAt ?? "") ?? DateTime(1970);
        DateTime createdA =
            DateTime.tryParse(a.createdAt ?? "") ?? DateTime(1970);
        DateTime dateA = updatedA.isAfter(createdA) ? updatedA : createdA;

        DateTime updatedB =
            DateTime.tryParse(b.updatedAt ?? "") ?? DateTime(1970);
        DateTime createdB =
            DateTime.tryParse(b.createdAt ?? "") ?? DateTime(1970);
        DateTime dateB = updatedB.isAfter(createdB) ? updatedB : createdB;

        return dateB.compareTo(dateA);
      });

      // Update Cache
      List<Map<String, dynamic>> listMap =
          chatedUserList.map((e) => e.toJson()).toList();
      HiveUtils.setBuyerChatList(listMap);

      emit(currentState.copyWith(
          chatedUserList: chatedUserList, total: chatedUserList.length));
    }
  }

  void updateAlreadyReview(int itemId) {
    //this will create new chat in chat list if there is no already
    if (state is GetBuyerChatListSuccess) {
      List<ChatedUser> chatedUserList =
          (state as GetBuyerChatListSuccess).chatedUserList;
      int index =
          chatedUserList.indexWhere((element) => element.itemId == itemId);

      chatedUserList[index].item!.review = UserRatings(
        sellerId: chatedUserList[index].sellerId,
        itemId: itemId,
        buyerId: chatedUserList[index].buyerId,
      );
      if (!isClosed) {
        emit((state as GetBuyerChatListSuccess)
            .copyWith(chatedUserList: chatedUserList));
      }
    }
  }

  Future<void> loadMore() async {
    try {
      if (state is GetBuyerChatListSuccess) {
        if ((state as GetBuyerChatListSuccess).isLoadingMore) {
          return;
        }
        emit((state as GetBuyerChatListSuccess).copyWith(isLoadingMore: true));

        DataOutput<ChatedUser> result =
            await _chatRepository.fetchBuyerChatList(
          (state as GetBuyerChatListSuccess).page + 1,
        );

        GetBuyerChatListSuccess messagesSuccessState =
            (state as GetBuyerChatListSuccess);

        // messagesSuccessState.await.insertAll(0, result.modelList);
        messagesSuccessState.chatedUserList.addAll(result.modelList);

        messagesSuccessState.chatedUserList.sort((a, b) {
          DateTime updatedA =
              DateTime.tryParse(a.updatedAt ?? "") ?? DateTime(1970);
          DateTime createdA =
              DateTime.tryParse(a.createdAt ?? "") ?? DateTime(1970);
          DateTime dateA = updatedA.isAfter(createdA) ? updatedA : createdA;

          DateTime updatedB =
              DateTime.tryParse(b.updatedAt ?? "") ?? DateTime(1970);
          DateTime createdB =
              DateTime.tryParse(b.createdAt ?? "") ?? DateTime(1970);
          DateTime dateB = updatedB.isAfter(createdB) ? updatedB : createdB;

          return dateB.compareTo(dateA);
        });
        emit(GetBuyerChatListSuccess(
          chatedUserList: messagesSuccessState.chatedUserList,
          page: (state as GetBuyerChatListSuccess).page + 1,
          hasError: false,
          isLoadingMore: false,
          total: result.total,
        ));
      }
    } catch (e) {
      emit((state as GetBuyerChatListSuccess)
          .copyWith(isLoadingMore: false, hasError: true));
    }
  }

  bool hasMoreData() {
    if (state is GetBuyerChatListSuccess) {
      return (state as GetBuyerChatListSuccess).chatedUserList.length <
          (state as GetBuyerChatListSuccess).total;
    }

    return false;
  }

  GetBuyerChatListState? fromJson(Map<String, dynamic> json) {
    return null;
  }

  Map<String, dynamic>? toJson(GetBuyerChatListState state) {
    return null;
  }

  ChatedUser? getOfferForItem(int itemId) {
    if (state is GetBuyerChatListSuccess) {
      List<ChatedUser> offerList =
          (state as GetBuyerChatListSuccess).chatedUserList;

      int matchingOffer = offerList.indexWhere(
        (offer) => offer.itemId == itemId,
      );
      if (matchingOffer != -1) {
        return (state as GetBuyerChatListSuccess).chatedUserList[matchingOffer];
      } else {
        return null;
      }
    }
    return null; // Return null if state is not GetBuyerChatListSuccess
  }

  void resetState() {
    emit(GetBuyerChatListInProgress());
  }
}
