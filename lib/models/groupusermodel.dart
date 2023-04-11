import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ichat_app/constants/constants.dart';

class GroupUserChatModel {
  String id;
  String photoUrl;
  String nickName;
  bool? isSelected;

  GroupUserChatModel(
      {required this.id,
      required this.photoUrl,
      required this.nickName,
      this.isSelected = false});

  Map<String, String> toJson() {
    return {
      FirestoreConstants.id: id,
      FirestoreConstants.photoUrl: photoUrl,
      FirestoreConstants.nickname: nickName,
    };
  }

  factory GroupUserChatModel.fromDocument(DocumentSnapshot doc) {
    String id = "";
    String photoUrl = "";
    String nickName = "";
    try {
      id = doc.get(FirestoreConstants.id);
    } catch (e) {}
    try {
      photoUrl = doc.get(FirestoreConstants.photoUrl);
    } catch (e) {}
    try {
      nickName = doc.get(FirestoreConstants.nickname);
    } catch (e) {}

    return GroupUserChatModel(id: id, photoUrl: photoUrl, nickName: nickName);
  }
}
