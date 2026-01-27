import 'dart:convert';

import 'package:Ebozor/data/model/category_model.dart';
import 'package:Ebozor/data/model/data_output.dart';
import 'package:Ebozor/data/repositories/category_repository.dart';
import 'package:Ebozor/utils/helper_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchParentCategoryState {}

class FetchParentCategoryInitial extends FetchParentCategoryState {}

class FetchParentCategoryInProgress extends FetchParentCategoryState {}

class FetchParentCategorySuccess extends FetchParentCategoryState {
  final int total;
  final int page;
  final bool isLoadingMore;
  final bool hasError;
  final List<CategoryModel> categories;

  FetchParentCategorySuccess({
    required this.total,
    required this.page,
    required this.isLoadingMore,
    required this.hasError,
    required this.categories,
  });

  FetchParentCategorySuccess copyWith({
    int? total,
    int? page,
    bool? isLoadingMore,
    bool? hasError,
    List<CategoryModel>? categories,
  }) {
    return FetchParentCategorySuccess(
      total: total ?? this.total,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      categories: categories ?? this.categories,
    );
  }
}

class FetchParentCategoryFailure extends FetchParentCategoryState {
  final String errorMessage;

  FetchParentCategoryFailure(this.errorMessage);
}

class FetchParentCategoryCubit extends Cubit<FetchParentCategoryState> {
  FetchParentCategoryCubit() : super(FetchParentCategoryInitial());

  final CategoryRepository _categoryRepository = CategoryRepository();

  Future<void> fetchParentCategories(
      {bool? forceRefresh, bool? loadWithoutDelay}) async {
    try {
      print("DEBUG: Fetching parent categories...");
      emit(FetchParentCategoryInProgress());

      // Use the specific API for parents
      DataOutput<CategoryModel> categories =
          await _categoryRepository.fetchParentCategories();

      print("DEBUG: Success. Categories count: ${categories.total}");

      emit(FetchParentCategorySuccess(
          total: categories.total,
          categories: categories.modelList,
          page: 1,
          hasError: false,
          isLoadingMore: false));
    } catch (e) {
      print("DEBUG: FetchParentCategoryCubit Error: $e");
      emit(FetchParentCategoryFailure(e.toString()));
    }
  }

  /* List<CategoryModel> getCategories() {
    if (state is FetchParentCategorySuccess) {
      return (state as FetchParentCategorySuccess).categories;
    }
    return <CategoryModel>[];
  } */
}
