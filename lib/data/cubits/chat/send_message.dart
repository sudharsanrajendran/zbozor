// ignore_for_file: public_member_api_docs, sort_constructors_first


import 'package:dio/dio.dart';
import 'package:Ebozor/utils/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:Ebozor/data/repositories/chat_repository.dart';
// import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

class SendMessageState {}

class SendMessageInitial extends SendMessageState {}

class SendMessageInProgress extends SendMessageState {}

class SendMessageSuccess extends SendMessageState {
  final int messageId;
  final Map<String, dynamic> responseData;

  SendMessageSuccess({
    required this.messageId,
    required this.responseData,
  });
}

class SendMessageFailed extends SendMessageState {
  final dynamic error;

  SendMessageFailed(
    this.error,
  );
}

class SendMessageCubit extends Cubit<SendMessageState> {
  SendMessageCubit() : super(SendMessageInitial());
  final ChatRepostiory _chatRepostiory = ChatRepostiory();

  void send(
      {required int itemOfferId,
      required String message,
      dynamic audio,
      dynamic attachment}) async {
    try {
      emit(SendMessageInProgress());
      MultipartFile? audioFile;
      MultipartFile? attachmentFile;


      if (audio != "") {
        // String? audioFileType = path.extension(audio).substring(1);

        audioFile = await MultipartFile.fromFile(
          audio,
          contentType: MediaType('audio', 'mpeg'),
          filename: 'audio.mp3',
        );
      }
      if (attachment != "") {
        attachmentFile = await MultipartFile.fromFile(attachment!);
      }

      ///If use is not uploading any text so we will upload [File].
      var message0 = message;

      var result = await _chatRepostiory. sendMessageApi(
          message: message0,
          itemOfferId: itemOfferId,
          attachment: attachmentFile,
          audio: audioFile);

      print("chat result: messgae:${message0},\n itemid:${itemOfferId}",);


      emit(SendMessageSuccess(
          messageId: result['data']['id'], responseData: result['data']));
    } catch (e) {

      Logger.error(e.toString());
      emit(SendMessageFailed(e.toString()));
    }
  }



  ////



  Future<void> sendMedia({
    required int itemOfferId,
    dynamic audio,
    dynamic attachment,
  }) async {
    try {
      emit(SendMessageInProgress());

      MultipartFile? audioFile;
      MultipartFile? attachmentFile;

      // AUDIO
      if (audio != null && audio.toString().isNotEmpty) {
        audioFile = await MultipartFile.fromFile(
          audio,
          contentType: MediaType('audio', 'mpeg'),
          filename: 'audio.mp3',
        );
      }

      // ATTACHMENT (image / doc)
      if (attachment != null && attachment.toString().isNotEmpty) {
        attachmentFile = await MultipartFile.fromFile(attachment);
      }

      /// ❌ NO MESSAGE TEXT
      final result = await _chatRepostiory.sendMessageApi(
        itemOfferId: itemOfferId,
        message: "", // always empty
        attachment: attachmentFile,
        audio: audioFile,
      );

      emit(
        SendMessageSuccess(
          messageId: result['data']['id'],
          responseData: result['data'],
        ),
      );
    } catch (e) {
      Logger.error(e.toString());
      emit(SendMessageFailed(e.toString()));
    }
  }

//This will check if given file like audio recording or attachment is local or it is coming from remote server
  bool isRemoteFile(dynamic file) {
    if (file is String) {
      return true;
    } else {
      return false;
    }
  }
}
