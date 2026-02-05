// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:Ebozor/data/model/category_model.dart';
import 'package:Ebozor/data/model/data_output.dart';
import 'package:Ebozor/data/repositories/category_repository.dart';
import 'package:Ebozor/utils/helper_utils.dart';
import 'package:Ebozor/data/repositories/newCategoriesrepo.dart';
import 'package:Ebozor/data/model/newcategorymodel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchCategoryState {}

class FetchCategoryInitial extends FetchCategoryState {}

class FetchCategoryInProgress extends FetchCategoryState {}

//categories models showing model it belongs to categories model
class FetchCategorySuccess extends FetchCategoryState {
  final int total;
  final int page;
  final bool isLoadingMore;
  final bool hasError;
  final List<CategoryModel> categories;

  FetchCategorySuccess({
    required this.total,
    required this.page,
    required this.isLoadingMore,
    required this.hasError,
    required this.categories,
  });

  FetchCategorySuccess copyWith({
    int? total,
    int? page,
    bool? isLoadingMore,
    bool? hasError,
    List<CategoryModel>? categories,
  }) {
    return FetchCategorySuccess(
      total: total ?? this.total,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      categories: categories ?? this.categories,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'total': total,
      ' page': page,
      'isLoadingMore': isLoadingMore,
      'hasError': hasError,
      'categories': categories.map((x) => x.toJson()).toList(),
    };
  }

  factory FetchCategorySuccess.fromMap(Map<String, dynamic> map) {
    return FetchCategorySuccess(
      total: map['total'] as int,
      page: map[' page'] as int,
      isLoadingMore: map['isLoadingMore'] as bool,
      hasError: map['hasError'] as bool,
      categories: List<CategoryModel>.from(
        (map['categories']).map<CategoryModel>(
          (x) => CategoryModel.fromJson(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory FetchCategorySuccess.fromJson(String source) =>
      FetchCategorySuccess.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'FetchCategorySuccess(total: $total,  page: $page, isLoadingMore: $isLoadingMore, hasError: $hasError, categories: $categories)';
  }
}

class FetchCategoryFailure extends FetchCategoryState {
  final String errorMessage;

  FetchCategoryFailure(this.errorMessage);
}

class FetchCategoryCubit extends Cubit<FetchCategoryState> {
  FetchCategoryCubit() : super(FetchCategoryInitial());

  final CategoryRepository _categoryRepository = CategoryRepository();

  Future<void> fetchCategories(
      {bool? forceRefresh, bool? loadWithoutDelay}) async {
    try {
      emit(FetchCategoryInProgress());

      // 1. Trigger BOTH fetches concurrently
      final newCategoriesFuture = NewCategoriesRepository()
          .fetchCategories(page: 1, forceRefresh: forceRefresh ?? false);
      final oldCategoriesFuture = _categoryRepository.fetchCategories(
          page: 1, forceRefresh: forceRefresh ?? false);

      // 2. Wait for BOTH to complete (Safety first)
      final results =
          await Future.wait([newCategoriesFuture, oldCategoriesFuture]);

      final newCategoriesResponse = results[0] as NewCategoryResponseModel;
      final oldCategoriesOutput = results[1] as DataOutput<CategoryModel>;

      // 3. Create Map of ID -> Image from New API
      Map<int, String> imageMap = {};
      if (!newCategoriesResponse.error) {
        for (var item in newCategoriesResponse.data) {
          imageMap[item.id] = item.image;
        }
      }

      // 4. Update Old Data with New Images Only (Revoking Name merge)
      List<CategoryModel> mergedList = oldCategoriesOutput.modelList.map((cat) {
        if (imageMap.containsKey(cat.id)) {
          return CategoryModel(
            id: cat.id,
            name: cat.name, // Keeping Old Name
            url: imageMap[cat.id], // New Image
            subcategoriesCount: cat.subcategoriesCount,
            description: cat.description,
            children: cat.children,
            filters: cat.filters,
          );
        }
        return cat;
      }).toList();

      DataOutput<CategoryModel> finalOutput = DataOutput(
          total: oldCategoriesOutput.total,
          modelList: mergedList,
          extraData: oldCategoriesOutput.extraData);

      print(
          "DEBUG: FetchCategoryCubit - Merged ${mergedList.length} categories.");

      emit(FetchCategorySuccess(
          total: finalOutput.total,
          categories: finalOutput.modelList,
          page: 1,
          hasError: false,
          isLoadingMore: false));
    } catch (e) {
      print("FetchCategoryCubit Error: $e");
      emit(FetchCategoryFailure(e.toString()));
    }
  }

  List<CategoryModel> getCategories() {
    if (state is FetchCategorySuccess) {
      return (state as FetchCategorySuccess).categories;
    }

    return <CategoryModel>[];
  }

  Future<void> fetchCategoriesMore() async {
    try {
      if (state is FetchCategorySuccess) {
        if ((state as FetchCategorySuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchCategorySuccess).copyWith(isLoadingMore: true));
        DataOutput<CategoryModel> result =
            await _categoryRepository.fetchCategories(
          page: (state as FetchCategorySuccess).page + 1,
        );

        FetchCategorySuccess categoryState = (state as FetchCategorySuccess);
        categoryState.categories.addAll(result.modelList);

        List<String> list =
            categoryState.categories.map((e) => e.url!).toList();
        await HelperUtils.precacheSVG(list);

        emit(FetchCategorySuccess(
            isLoadingMore: false,
            hasError: false,
            categories: categoryState.categories,
            page: (state as FetchCategorySuccess).page + 1,
            total: result.total));
      }
    } catch (e) {
      emit((state as FetchCategorySuccess)
          .copyWith(isLoadingMore: false, hasError: true));
    }
  }

  bool hasMoreData() {
    if (state is FetchCategorySuccess) {
      return (state as FetchCategorySuccess).categories.length <
          (state as FetchCategorySuccess).total;
    }
    return false;
  }
}
