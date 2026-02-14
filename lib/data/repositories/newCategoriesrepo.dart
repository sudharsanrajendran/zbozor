import 'package:Ebozor/data/model/newcategorymodel.dart';
import 'package:Ebozor/utils/ApiService/api.dart';
import 'package:Ebozor/utils/LocalStoreage/hive_utils.dart';

class NewCategoriesRepository {
  // Simple in-memory cache to store category responses
  static final Map<String, NewCategoryResponseModel> _categoryCache = {};

  Future<NewCategoryResponseModel> fetchCategories({
    required int page,
    bool forceRefresh = false,
  }) async {
    try {
      // Get current language code
      var lang = HiveUtils.getLanguage();
      String langCode = "en";
      if (lang != null && lang['code'] != null) {
        langCode = lang['code'];
      }

      // Generate a unique cache key
      final String cacheKey = "$langCode-page:$page-new-cat";

      // Return cached data if available and not forcing refresh
      if (!forceRefresh && _categoryCache.containsKey(cacheKey)) {
        return _categoryCache[cacheKey]!;
      }

      Map<String, dynamic> parameters = {
        Api.page: page,
      };

      Map<String, dynamic> response = await Api.get(
          url: 'get-parent-category-list', queryParameters: parameters);

      final result = NewCategoryResponseModel.fromJson(response);

      // Save to cache
      _categoryCache[cacheKey] = result;

      return result;
    } catch (e) {
      rethrow;
    }
  }
}
