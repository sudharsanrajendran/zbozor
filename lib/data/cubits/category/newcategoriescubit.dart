import 'package:Ebozor/data/model/newcategorymodel.dart';
import 'package:Ebozor/data/repositories/newCategoriesrepo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class NewCategoriesState {}

class NewCategoriesInitial extends NewCategoriesState {}

class NewCategoriesInProgress extends NewCategoriesState {}

class NewCategoriesSuccess extends NewCategoriesState {
  final int total;
  final int page;
  final bool isLoadingMore;
  final bool hasError;
  final List<NewCategory> categories;

  NewCategoriesSuccess({
    required this.total,
    required this.page,
    required this.isLoadingMore,
    required this.hasError,
    required this.categories,
  });

  NewCategoriesSuccess copyWith({
    int? total,
    int? page,
    bool? isLoadingMore,
    bool? hasError,
    List<NewCategory>? categories,
  }) {
    return NewCategoriesSuccess(
      total: total ?? this.total,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      categories: categories ?? this.categories,
    );
  }
}

class NewCategoriesFailure extends NewCategoriesState {
  final String errorMessage;

  NewCategoriesFailure(this.errorMessage);
}

class NewCategoriesCubit extends Cubit<NewCategoriesState> {
  NewCategoriesCubit() : super(NewCategoriesInitial());

  final NewCategoriesRepository _newCategoriesRepository =
      NewCategoriesRepository();

  Future<void> fetchCategories({bool? forceRefresh}) async {
    try {
      emit(NewCategoriesInProgress());

      NewCategoryResponseModel categories = await _newCategoriesRepository
          .fetchCategories(page: 1, forceRefresh: forceRefresh ?? false);

      if (!categories.error) {
        emit(NewCategoriesSuccess(
            total: categories.data.length,
            categories: categories.data, // This is List<NewCategory>
            page: 1,
            hasError: false,
            isLoadingMore: false));
      } else {
        emit(NewCategoriesFailure(categories.message));
      }
    } catch (e) {
      emit(NewCategoriesFailure(e.toString()));
    }
  }

  List<NewCategory> getCategories() {
    if (state is NewCategoriesSuccess) {
      return (state as NewCategoriesSuccess).categories;
    }

    return <NewCategory>[];
  }
}
