import 'package:Ebozor/data/model/newcategorymodel.dart';
import 'package:Ebozor/utils/ApiService/api.dart';

class NewCategoriesRepository {
  // Simple in-memory cache to store category responses
  static final Map<String, NewCategoryResponseModel> _categoryCache = {};

  Future<NewCategoryResponseModel> fetchCategories({
    required int page,
    bool forceRefresh = false,
  }) async {
    try {
      // Generate a unique cache key
      final String cacheKey = "page:$page-new-cat";

      // Return cached data if available and not forcing refresh
      if (!forceRefresh && _categoryCache.containsKey(cacheKey)) {
        return _categoryCache[cacheKey]!;
      }

      Map<String, dynamic> response =
          await Api.get(url: 'get-parent-category-list');

      final result = NewCategoryResponseModel.fromJson(response);

      // Save to cache
      _categoryCache[cacheKey] = result;

      return result;
    } catch (e) {
      rethrow;
    }
  }
}
