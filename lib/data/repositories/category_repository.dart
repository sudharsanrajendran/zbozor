import 'package:Ebozor/data/model/category_model.dart';
import 'package:Ebozor/data/model/data_output.dart';
import 'package:Ebozor/utils/ApiService/api.dart';

class CategoryRepository {
  // Simple in-memory cache to store category responses
  static final Map<String, DataOutput<CategoryModel>> _categoryCache = {};

  Future<DataOutput<CategoryModel>> fetchCategories({
    required int page,
    int? categoryId,
    bool forceRefresh = false, // Add forceRefresh to bypass cache if needed
  }) async {
    try {
      // Generate a unique cache key
      final String cacheKey = "page:$page-cat:$categoryId";

      // Return cached data if available and not forcing refresh
      if (!forceRefresh && _categoryCache.containsKey(cacheKey)) {
        return _categoryCache[cacheKey]!;
      }

      Map<String, dynamic> parameters = {
        Api.page: page,
      };

      if (categoryId != null) {
        parameters[Api.categoryId] = categoryId;
      }
      Map<String, dynamic> response =
          await Api.get(url: Api.getCategoriesApi, queryParameters: parameters);

      List<CategoryModel> modelList = (response['data']['data'] as List).map(
        (e) {
          return CategoryModel.fromJson(e);
        },
      ).toList();

      // [NEW] Parse self_category if available (contains filters for the parent/current category)
      CategoryModel? selfCategory;
      if (response.containsKey('self_category') &&
          response['self_category'] != null) {
        selfCategory = CategoryModel.fromJson(response['self_category']);
      }

      final result = DataOutput(
        total: response['data']['total'] ?? 0,
        modelList: modelList,
        extraData: selfCategory != null ? ExtraData(data: selfCategory) : null,
      );

      // Save to cache
      _categoryCache[cacheKey] = result;

      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<DataOutput<CategoryModel>> fetchSubCategories(
      {required int parentId}) async {
    return await fetchCategories(page: 1, categoryId: parentId);
  }
}
