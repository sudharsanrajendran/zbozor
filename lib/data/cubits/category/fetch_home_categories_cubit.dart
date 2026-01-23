import 'dart:convert';
import 'package:Ebozor/data/model/category_model.dart';
import 'package:Ebozor/data/model/data_output.dart';
import 'package:Ebozor/data/repositories/category_repository.dart';
import 'package:Ebozor/utils/helper_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchHomeCategoriesState {}

class FetchHomeCategoriesInitial extends FetchHomeCategoriesState {}

class FetchHomeCategoriesInProgress extends FetchHomeCategoriesState {}

class FetchHomeCategoriesSuccess extends FetchHomeCategoriesState {
  final int total;
  final int page;
  final bool isLoadingMore;
  final bool hasError;
  final List<CategoryModel> categories;

  FetchHomeCategoriesSuccess({
    required this.total,
    required this.page,
    required this.isLoadingMore,
    required this.hasError,
    required this.categories,
  });

  FetchHomeCategoriesSuccess copyWith({
    int? total,
    int? page,
    bool? isLoadingMore,
    bool? hasError,
    List<CategoryModel>? categories,
  }) {
    return FetchHomeCategoriesSuccess(
      total: total ?? this.total,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      categories: categories ?? this.categories,
    );
  }
}

class FetchHomeCategoriesFailure extends FetchHomeCategoriesState {
  final String errorMessage;

  FetchHomeCategoriesFailure(this.errorMessage);
}

class FetchHomeCategoriesCubit extends Cubit<FetchHomeCategoriesState> {
  FetchHomeCategoriesCubit() : super(FetchHomeCategoriesInitial());

  final CategoryRepository _categoryRepository = CategoryRepository();

  Future<void> fetchCategories({bool? forceRefresh}) async {
    try {
      emit(FetchHomeCategoriesInProgress());

      DataOutput<CategoryModel> categories =
          await _categoryRepository.fetchCategories(page: 1);

      emit(FetchHomeCategoriesSuccess(
          total: categories.total,
          categories: categories.modelList,
          page: 1,
          hasError: false,
          isLoadingMore: false));
    } catch (e) {
      emit(FetchHomeCategoriesFailure(e.toString()));
    }
  }

  List<CategoryModel> getCategories() {
    if (state is FetchHomeCategoriesSuccess) {
      return (state as FetchHomeCategoriesSuccess).categories;
    }

    return <CategoryModel>[];
  }
}
