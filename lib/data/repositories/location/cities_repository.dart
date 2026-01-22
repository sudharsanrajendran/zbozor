import 'package:Ebozor/data/model/data_output.dart';
import 'package:Ebozor/data/model/location/cityModel.dart';
import 'package:Ebozor/utils/ApiService/api.dart';

class CitiesRepository {
  // Cache for cities
  static final Map<String, DataOutput<CityModel>> _citiesCache = {};

  Future<DataOutput<CityModel>> fetchCities(
      {required int page, required int stateId, String? search}) async {
    String cacheKey = "page:$page-state:$stateId-search:$search";
    if (_citiesCache.containsKey(cacheKey)) {
      return _citiesCache[cacheKey]!;
    }

    Map<String, dynamic> parameters = {
      Api.page: page,
      Api.stateId: stateId,
      if (search != null) Api.search: search
    };

    Map<String, dynamic> response = await Api.get(
      url: Api.getCitiesApi,
      queryParameters: parameters,
      useBaseUrl: true,
    );

    List<CityModel> modelList = (response['data']['data'] as List)
        .map((e) => CityModel.fromJson(e))
        .toList();

    var result = DataOutput<CityModel>(
      total: response['data']['total'] ?? 0,
      modelList: modelList,
    );
    _citiesCache[cacheKey] = result;
    return result;
  }
}
