import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ichat_app/constants/app_constants.dart';
import 'package:ichat_app/constants/color_constants.dart';
import 'package:ichat_app/constants/firestore_constants.dart';
import 'package:ichat_app/models/userchatmodel.dart';
import 'package:ichat_app/providers/settingprovider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../main.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  TextEditingController? nickNameController;
  TextEditingController? aboutMeController;
  TextEditingController _controller = TextEditingController();
  String dialCodeDigits = '+00';

  String id = '';
  String photoUrl = '';
  String nickName = '';
  String aboutMe = '';
  String phoneNumber = '';

  bool isLoading = false;
  File? dpImageFile;
  late SettingProvider settingProvider;

  final FocusNode focusNodeNickName = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    super.initState();
    settingProvider = context.read<SettingProvider>();
    readLocal();
  }

  void readLocal() {
    id = settingProvider.getPref(FirestoreConstants.id) ?? '';
    photoUrl = settingProvider.getPref(FirestoreConstants.photoUrl) ?? '';
    nickName = settingProvider.getPref(FirestoreConstants.nickname) ?? '';
    aboutMe = settingProvider.getPref(FirestoreConstants.aboutMe) ?? '';
    phoneNumber = settingProvider.getPref(FirestoreConstants.phoneNumber) ?? '';

    nickNameController = TextEditingController(text: nickName);
    aboutMeController = TextEditingController(text: aboutMe);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.black,
        iconTheme: const IconThemeData(color: ColorConstants.primaryColor),
        title: const Text(
          AppConstants.settingsTitle,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
    );
  }

  Future getImageFromGallery(BuildContext context, int index) async {
    XFile? pickedImage = await ImagePicker()
        .pickImage(source: ImageSource.gallery)
        .catchError((err) {
      Fluttertoast.showToast(msg: err.toString());
    });

    File? image;
    if (pickedImage != null) {
      image = File(pickedImage.path);
    }
    if (image != null) {
      setState(() {
        dpImageFile = image;
        isLoading = true;
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
    String fileName = id;
    UploadTask uploadTask = settingProvider.uploadFile(dpImageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();

      UserChatModel updateInfo = UserChatModel(
        id: id,
        photoUrl: photoUrl,
        nickName: nickName,
        aboutMe: aboutMe,
        phoneNumber: phoneNumber,
      );

      settingProvider
          .updateDataFireStore(
              FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
          .then((data) async {
        await settingProvider.setPrefs(FirestoreConstants.photoUrl, photoUrl);
        setState(() {
          isLoading = false;
        });
      }).catchError((err) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void handleUpdateData() {
    focusNodeNickName.unfocus();
    focusNodeAboutMe.unfocus();
    setState(() {
      isLoading = true;

      if (dialCodeDigits != "+00" && _controller.text != "") {
        phoneNumber = dialCodeDigits + _controller.text.toString();
      }
    });
    UserChatModel updateInfo = UserChatModel(
      id: id,
      photoUrl: photoUrl,
      nickName: nickName,
      aboutMe: aboutMe,
      phoneNumber: phoneNumber,
    );

    settingProvider
        .updateDataFireStore(
            FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
        .then((data) async {
      await settingProvider.setPrefs(FirestoreConstants.nickname, nickName);
      await settingProvider.setPrefs(FirestoreConstants.aboutMe, aboutMe);
      await settingProvider.setPrefs(FirestoreConstants.photoUrl, photoUrl);
      await settingProvider.setPrefs(
          FirestoreConstants.phoneNumber, phoneNumber);
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Updated successfully');
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: err.toString());
    });
  }
}
