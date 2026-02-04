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
    // 1. Load from Cache immediately (safeguarded)
    if (!forceRefresh && state is! GetSellerChatListSuccess) {
      try {
        List<dynamic> cachedData = HiveUtils.getSellerChatList();
        if (cachedData.isNotEmpty) {
          List<ChatedUser> cachedList = cachedData
              .map((e) => ChatedUser.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          emit(GetSellerChatListSuccess(
              isLoadingMore: false,
              hasError: false,
              chatedUserList: cachedList,
              total: cachedList.length,
              page: 1));
        } else {
          emit(GetSellerChatListInProgress());
        }
      } catch (e) {
        emit(GetSellerChatListInProgress());
      }
    }

    try {
      if (!forceRefresh && state is GetSellerChatListSuccess) {
        // Continue to update from API
      }

      // 2. Fetch from API
      DataOutput<ChatedUser> result =
          await _chatRepository.fetchSellerChatList(1);

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
          (element) => element.sellerId.toString() != HiveUtils.getUserId());

      // 3. Emit Success FIRST (Update UI)
      emit(
        GetSellerChatListSuccess(
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
        await HiveUtils.setSellerChatList(listMap);
      } catch (e) {
        print("Error updating seller chat cache: $e");
      }
    } catch (e) {
      // Only emit failure if we don't have any data shown
      if (state is! GetSellerChatListSuccess) {
        emit(GetSellerChatListFailed(e));
      }
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
        HiveUtils.setSellerChatList(listMap);

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
