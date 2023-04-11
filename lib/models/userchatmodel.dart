import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ichat_app/constants/constants.dart';

class UserChatModel {
  String id;
  String photoUrl;
  String nickName;
  String aboutMe;
  String phoneNumber;
  bool isRead;

  UserChatModel({
    required this.id,
    required this.photoUrl,
    required this.nickName,
    required this.aboutMe,
    required this.phoneNumber,
    required this.isRead,
  });

  Map<String, dynamic> toJson() {
    return {
      FirestoreConstants.id: id,
      FirestoreConstants.photoUrl: photoUrl,
      FirestoreConstants.nickname: nickName,
      FirestoreConstants.aboutMe:aboutMe,
      FirestoreConstants.phoneNumber: phoneNumber,
      FirestoreConstants.isRead:isRead,
    };
  }

  factory UserChatModel.fromDocument(DocumentSnapshot doc) {
    String photoUrl = "";
    String nickName = "";
    String aboutMe = "";
    String phoneNumber = "";
    bool isRead = false;
    try {
      photoUrl = doc.get(FirestoreConstants.photoUrl);
    } catch (e) {}
    try {
      nickName = doc.get(FirestoreConstants.nickname);
    } catch (e) {}
    try {
      aboutMe = doc.get(FirestoreConstants.aboutMe);
    } catch (e) {}
    try {
      phoneNumber = doc.get(FirestoreConstants.phoneNumber);
    } catch (e) {}
    try {
      isRead = doc.get(FirestoreConstants.isRead);
    } catch (e) {}

    return UserChatModel(
        id: doc.id,
        photoUrl: photoUrl,
        nickName: nickName,
        aboutMe: aboutMe,
        phoneNumber: phoneNumber, isRead: isRead);
  }
}
