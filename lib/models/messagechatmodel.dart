import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_constants.dart';

class MessageChatModel {
  String idFrom;
  String idTo;
  String timestamp;
  String content;
  int type;
  bool isRead;

  MessageChatModel({
    required this.idFrom,
    required this.idTo,
    required this.timestamp,
    required this.content,
    required this.type,
    required this.isRead,
  });

  Map<String, dynamic> toJson() {
    return {
      FirestoreConstants.idFrom: idFrom,
      FirestoreConstants.idTo: idTo,
      FirestoreConstants.timestamp: timestamp,
      FirestoreConstants.content: content,
      FirestoreConstants.type: type,
      FirestoreConstants.isRead: isRead,
    };
  }

  factory MessageChatModel.fromDocument(DocumentSnapshot doc) {
    String idFrom = doc.get(FirestoreConstants.idFrom);
    String idTo = doc.get(FirestoreConstants.idTo);
    String timestamp = doc.get(FirestoreConstants.timestamp);
    String content = doc.get(FirestoreConstants.content);
    int type = doc.get(FirestoreConstants.type);
    bool isRead = doc.get(FirestoreConstants.isRead);
    return MessageChatModel(idFrom: idFrom, idTo: idTo, timestamp: timestamp, content: content, type: type, isRead: isRead);
  }
}