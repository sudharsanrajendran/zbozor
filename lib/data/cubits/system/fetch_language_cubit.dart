// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:Ebozor/utils/ApiService/api.dart';

abstract class FetchLanguageState {}

class FetchLanguageInitial extends FetchLanguageState {}

class FetchLanguageInProgress extends FetchLanguageState {}

class FetchLanguageSuccess extends FetchLanguageState {
  final String code;
  final String name;
  final String engName;
  final String image;
  final Map data;
  final bool rtl;

  FetchLanguageSuccess({
    required this.code,
    required this.name,
    required this.engName,
    required this.data,
    required this.image,
    required this.rtl,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'name': name,
      'name_in_english': engName,
      'image': image,
      'file_name': data,
      'rtl': rtl,
    };
  }

  factory FetchLanguageSuccess.fromMap(Map<String, dynamic> map) {
    return FetchLanguageSuccess(
      code: map['code'] as String,
      name: map['name'] as String,
      engName: map['name_in_english'] as String,
      image: map['image'] as String,
      data: map['file_name'] as Map,
      rtl: map['rtl'] as bool,
    );
  }
}

class FetchLanguageFailure extends FetchLanguageState {
  final String errorMessage;

  FetchLanguageFailure(this.errorMessage);
}

class FetchLanguageCubit extends Cubit<FetchLanguageState> {
  FetchLanguageCubit() : super(FetchLanguageInitial());

  Future<void> getLanguage(String languageCode) async {
    try {
      emit(FetchLanguageInProgress());

      Map<String, dynamic> response = await Api.get(
        url: Api.getLanguageApi,
        queryParameters: {Api.languageCode: languageCode},
      );

      // [PATCH] Inject missing keys for Arabic/RTL support (or any language)
      Map<dynamic, dynamic> fileData = response['data']['file_name'];
      fileData['ShowverifiedPropertiesFirst'] =
          "Show verified properties first";
      fileData['similaads'] = "Similar Ads";
      fileData['gotVerifiedBadge'] = "Get Verified Badge";
      fileData['enhanceVisibilityCredibility'] =
          "Enhance your visibility and credibility";
      fileData['viewNow'] = "View Now";
      fileData['message'] = "Chats";

      emit(FetchLanguageSuccess(
          code: response['data']['code'],
          rtl: response['data']['rtl'],
          image: response['data']['image'],
          engName: response['data']['name_in_english'],
          data: fileData,
          name: response['data']['name']));
    } catch (e) {
      emit(FetchLanguageFailure(e.toString()));
    }
  }
}
