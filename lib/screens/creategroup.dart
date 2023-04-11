import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ichat_app/constants/app_constants.dart';
import 'package:ichat_app/constants/color_constants.dart';
import 'package:ichat_app/constants/firestore_constants.dart';
import 'package:ichat_app/models/groupusermodel.dart';
import 'package:ichat_app/models/userchatmodel.dart';
import 'package:ichat_app/providers/settingprovider.dart';
import 'package:ichat_app/screens/chatpage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/authprovider.dart';
import '../widgets/loading_view.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({Key? key}) : super(key: key);

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  TextEditingController? groupNameController;

  //TextEditingController? aboutMeController;
  TextEditingController _controller = TextEditingController();

  //String dialCodeDigits = '+00';

  String id = '';
  String photoUrl = '';
  String createGroupText = '';

  // String aboutMe = '';
  // String phoneNumber = '';
  // late List<bool> _isChecked;
   List<GroupUserChatModel> _checkedUser=[];
  bool isLoading = false;
  File? dpImageFile;
  late SettingProvider settingProvider;
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNodeCreateGroup = FocusNode();

  //final FocusNode focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    super.initState();
    settingProvider = context.read<SettingProvider>();
    readLocal();
  }

  void readLocal() {
    id = settingProvider.getPref(FirestoreConstants.id) ?? '';
    //photoUrl = settingProvider.getPref(FirestoreConstants.photoUrl) ?? '';
    //nickName = settingProvider.getPref(FirestoreConstants.nickname) ?? '';

    groupNameController = TextEditingController(text: createGroupText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.black,
        iconTheme: const IconThemeData(color: ColorConstants.primaryColor),
        title: const Text(
          AppConstants.createGroupTitle,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              // Avatar
              CupertinoButton(
                onPressed: getImageFromGallery,
                child: Container(
                  margin: EdgeInsets.all(5),
                  child: dpImageFile == null
                      ? photoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(45),
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                width: 90,
                                height: 90,
                                errorBuilder: (context, object, stackTrace) {
                                  return const Icon(
                                    Icons.account_circle,
                                    size: 90,
                                    color: ColorConstants.greyColor,
                                  );
                                },
                                loadingBuilder: (BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 90,
                                    height: 90,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: ColorConstants.themeColor,
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.account_circle,
                              size: 90,
                              color: ColorConstants.greyColor,
                            )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(45),
                          child: Image.file(
                            dpImageFile!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),

              // Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Username
                  Container(
                    margin: EdgeInsets.only(left: 10, bottom: 5, top: 10),
                    child: const Text(
                      'Create Group Name',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryColor),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 30, right: 30),
                    child: TextField(
                      style: TextStyle(
                          color: isWhite
                              ? Colors.black
                              : ColorConstants.greyColor2),
                      decoration: const InputDecoration(
                        hintText: 'Enter Group Name',
                        contentPadding: EdgeInsets.all(5),
                        hintStyle: TextStyle(color: Colors.white),
                      ),
                      controller: groupNameController,
                      onChanged: (value) {
                        createGroupText = value;
                      },
                      focusNode: focusNodeCreateGroup,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 10, bottom: 5, top: 10),
                    child: const Text(
                      'Select Contact to add into Group',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryColor),
                    ),
                  ),
                ],
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('id',
                          isNotEqualTo:
                              context.read<AuthProvider>().getUserFirebaseId())
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasData) {
                      if ((snapshot.data?.docs.length ?? 0) > 0) {
                        snapshot.data?.docs.forEach((element) {
                          _checkedUser.add(GroupUserChatModel.fromDocument(element));
                        });
                        // _isChecked = List<bool>.filled(
                        //     snapshot.data?.docs.length ?? 0, false);
                        return ListView.builder(
                          itemCount: snapshot.data?.docs.length,
                          controller: listScrollController,
                          itemBuilder: (context, index) => _fetchUserList(
                              context, snapshot.data?.docs[index], index),
                        );
                      } else {
                        return const Center(
                            child: Text(
                          'No users',
                          style: TextStyle(color: Colors.white),
                        ));
                      }
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: ColorConstants.themeColor,
                        ),
                      );
                    }
                  },
                ),
              ),

              // Button
              Container(
                margin: EdgeInsets.only(top: 10, bottom: 10),
                child: TextButton(
                  onPressed: handleUpdateData,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        ColorConstants.primaryColor),
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      EdgeInsets.fromLTRB(30, 10, 30, 10),
                    ),
                  ),
                  child: const Text(
                    'Create',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          // Loading
          Positioned(child: isLoading ? LoadingView() : SizedBox.shrink()),
        ],
      ),
    );
  }

  _fetchUserList(BuildContext context, DocumentSnapshot? document, int index) {
    if (document != null) {
      UserChatModel userChat = UserChatModel.fromDocument(document);

      return Container(
        child: ListTile(
          leading: userChat.photoUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                  child: Image.network(
                    userChat.photoUrl,
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(Icons.person),
          title: Text(
            userChat.nickName,
            style: TextStyle(color: isWhite ? Colors.black : Colors.white),
          ),
          subtitle: Text(
            userChat.aboutMe,
            style: TextStyle(color: isWhite ? Colors.black : Colors.white),
          ),
          trailing: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Checkbox(
              value: _checkedUser[index].isSelected,
              side: BorderSide(
                color: isWhite ? Colors.black : Colors.white,
                //your desire colour here
                width: 1.5,
              ),
              onChanged: (bool? value) {
                setState(() {
                  _checkedUser[index].isSelected = value ?? false;
                });
              },
            );
          }),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Future getImageFromGallery() async {
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
        nickName: "",
        aboutMe: "",
        phoneNumber: "", isRead: false,
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
    var selectedUserList = _checkedUser.where((element) => element.isSelected==true);
     List<String> sUserIdList=[];
    selectedUserList.forEach((element) {
      sUserIdList.add(element.id);
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          peerId: jsonEncode(sUserIdList),
          peerAvatar: photoUrl,
          peerNickname: createGroupText,
          isFromGroup: true,
        ),
      ),
    );
    /*focusNodeCreateGroup.unfocus();
    //focusNodeAboutMe.unfocus();
    setState(() {
      isLoading = true;

      // if (dialCodeDigits != "+00" && _controller.text != "") {
      //   phoneNumber = dialCodeDigits + _controller.text.toString();
      // }
    });
    UserChatModel updateInfo = UserChatModel(
      id: id,
      photoUrl: photoUrl,
      nickName: "",
      aboutMe: "",
      phoneNumber: "",
    );

    settingProvider
        .updateDataFireStore(
            FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
        .then((data) async {
      // await settingProvider.setPrefs(FirestoreConstants.nickname, nickName);
      // await settingProvider.setPrefs(FirestoreConstants.aboutMe, aboutMe);
      // await settingProvider.setPrefs(FirestoreConstants.photoUrl, photoUrl);
      // await settingProvider.setPrefs(
      //     FirestoreConstants.phoneNumber, phoneNumber);
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Updated successfully');
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: err.toString());
    });*/
  }
}
