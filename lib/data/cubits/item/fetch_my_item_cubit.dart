import 'package:Ebozor/data/model/data_output.dart';
import 'package:Ebozor/data/repositories/item/item_repository.dart';
import 'package:Ebozor/data/model/item/item_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FetchMyItemsState {}

class FetchMyItemsInitial extends FetchMyItemsState {}

class FetchMyItemsInProgress extends FetchMyItemsState {}

class FetchMyItemsSuccess extends FetchMyItemsState {
  final int total;
  final int page;
  final bool isLoadingMore;
  final bool hasError;
  final List<ItemModel> items;
  final String? getItemsWithStatus;

  FetchMyItemsSuccess(
      {required this.total,
      required this.page,
      required this.isLoadingMore,
      required this.hasError,
      required this.getItemsWithStatus,
      required this.items});

  FetchMyItemsSuccess copyWith({
    int? total,
    int? page,
    bool? isLoadingMore,
    bool? hasError,
    List<ItemModel>? items,
    String? getItemsWithStatus,
    bool? getActiveItems,
  }) {
    return FetchMyItemsSuccess(
      total: total ?? this.total,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      items: items ?? this.items,
      getItemsWithStatus: getItemsWithStatus ?? this.getItemsWithStatus,
    );
  }
}

class FetchMyItemsFailed extends FetchMyItemsState {
  final dynamic error;

  FetchMyItemsFailed(this.error);
}

class FetchMyItemsCubit extends Cubit<FetchMyItemsState> {
  FetchMyItemsCubit() : super(FetchMyItemsInitial());
  final ItemRepository _itemRepository = ItemRepository();

  void fetchMyItems(
      {String? getItemsWithStatus,
      bool forceRefresh = false,
      bool isBackground = false}) async {
    try {
      // If we already have success state and not forcing refresh,
      // we could return immediately to be "fast" (if we had local storage).
      // But since we want to be "fast" on UI load, we rely on the existing state if present.
      if (!forceRefresh && state is FetchMyItemsSuccess) {
        // [OPTIMIZATION] If we already have data, don't show loading, just return.
        // This makes switching tabs instant if data is already there.
        return;
      }

      if (!isBackground) {
        emit(FetchMyItemsInProgress());
      }

      DataOutput<ItemModel> result = await _itemRepository.fetchMyItems(
        page: 1,
        getItemsWithStatus: getItemsWithStatus,
      );
      emit(FetchMyItemsSuccess(
          hasError: false,
          isLoadingMore: false,
          page: 1,
          items: result.modelList,
          total: result.total,
          getItemsWithStatus: getItemsWithStatus));
    } catch (e) {
      emit(FetchMyItemsFailed(e.toString()));
    }
  }

  void addItem(ItemModel item) {
    if (state is FetchMyItemsSuccess) {
      List<ItemModel> items =
          List.from((state as FetchMyItemsSuccess).items); // Make mutable
      items.insert(0, item);

      emit((state as FetchMyItemsSuccess).copyWith(items: items));
    }
  }

  void deleteItem(ItemModel model) {
    if (state is FetchMyItemsSuccess) {
      List<ItemModel> items =
          List.from((state as FetchMyItemsSuccess).items); // Make mutable

      items.removeWhere(((element) => (element.id == model.id)));

      emit((state as FetchMyItemsSuccess).copyWith(items: items));
    }
  }

  void edit(ItemModel item) {
    if (state is FetchMyItemsSuccess) {
      List<ItemModel> items =
          List.from((state as FetchMyItemsSuccess).items); // Make mutable
      int index = items.indexWhere((element) => element.id == item.id);
      if (index != -1) {
        items[index] = item;
        if (!isClosed) {
          emit((state as FetchMyItemsSuccess).copyWith(items: items));
        }
      }
    }
  }

  Future<void> fetchMyMoreItems({String? getItemsWithStatus}) async {
    try {
      if (state is FetchMyItemsSuccess) {
        if ((state as FetchMyItemsSuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchMyItemsSuccess).copyWith(isLoadingMore: true));

        DataOutput<ItemModel> result = await _itemRepository.fetchMyItems(
          getItemsWithStatus: getItemsWithStatus,
          page: (state as FetchMyItemsSuccess).page + 1,
        );

        FetchMyItemsSuccess myItemsState = (state as FetchMyItemsSuccess);
        myItemsState.items.addAll(result.modelList);
        emit(
          FetchMyItemsSuccess(
            isLoadingMore: false,
            hasError: false,
            items: myItemsState.items,
            page: (state as FetchMyItemsSuccess).page + 1,
            getItemsWithStatus: getItemsWithStatus,
            total: result.total,
          ),
        );
      }
    } catch (e) {
      emit(
        (state as FetchMyItemsSuccess).copyWith(
          isLoadingMore: false,
          hasError: true,
        ),
      );
    }
  }

  bool hasMoreData() {
    if (state is FetchMyItemsSuccess) {
      return (state as FetchMyItemsSuccess).items.length <
          (state as FetchMyItemsSuccess).total;
    }
    return false;
  }
}
