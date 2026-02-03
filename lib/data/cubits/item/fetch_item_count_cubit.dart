import 'package:Ebozor/data/model/item_filter_model.dart';
import 'package:Ebozor/data/repositories/item/item_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchItemCountState {}

class FetchItemCountInitial extends FetchItemCountState {}

class FetchItemCountInProgress extends FetchItemCountState {}

class FetchItemCountSuccess extends FetchItemCountState {
  final int count;

  FetchItemCountSuccess(this.count);
}

class FetchItemCountFailure extends FetchItemCountState {
  final String errorMessage;

  FetchItemCountFailure(this.errorMessage);
}

class FetchItemCountCubit extends Cubit<FetchItemCountState> {
  final ItemRepository _itemRepository;

  // Constructor
  FetchItemCountCubit(this._itemRepository) : super(FetchItemCountInitial());

  void fetchItemCount({
    required int categoryId,
    String? search,
    String? sortBy,
    String? country,
    String? state,
    String? city,
    int? areaId,
    int? minPrice,
    int? maxPrice,
    String? postedSince,
    double? latitude,
    double? longitude,
    ItemFilterModel? filter,
  }) async {
    emit(FetchItemCountInProgress());
    try {
      int count = await _itemRepository.getItemCount(
          categoryId: categoryId,
          search: search,
          sortBy: sortBy,
          country: country,
          state: state,
          city: city,
          areaId: areaId,
          minPrice: minPrice,
          maxPrice: maxPrice,
          postedSince: postedSince,
          latitude: latitude,
          longitude: longitude,
          filter: filter);
      emit(FetchItemCountSuccess(count));
    } catch (e) {
      emit(FetchItemCountFailure(e.toString()));
    }
  }
}
