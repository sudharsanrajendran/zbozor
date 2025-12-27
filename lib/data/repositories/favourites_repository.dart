

import 'package:Ebozor/data/model/data_output.dart';
import 'package:Ebozor/data/model/item/item_model.dart';
import 'package:Ebozor/utils/ApiService/api.dart';

class FavoriteRepository {
  Future<void> manageFavorites(int id) async {
    Map<String, dynamic> parameters = {
      Api.itemId: id,
    };

    Map<String, dynamic> response = await Api.post(
      url: Api.manageFavouriteApi,
      parameter: parameters,
      useBaseUrl: true,
    );
  }

  Future<DataOutput<ItemModel>> fetchFavorites({required int page}) async {
    Map<String, dynamic> parameters = {
      Api.page: page,
    };

    Map<String, dynamic> response = await Api.get(
      url: Api.getFavoriteItemApi,
      queryParameters: parameters,
      useBaseUrl: true,
    );

    List<ItemModel> modelList = (response['data']['data'] as List)
        .map((e) => ItemModel.fromJson(e))
        .toList();

    return DataOutput<ItemModel>(
      total: response['data']['total'] ?? 0,
      modelList: modelList,
    );
  }
}
