import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ichat_app/models/messagechatmodel.dart';
import 'package:ichat_app/screens/camerascreen.dart';
import 'package:ichat_app/screens/loginscreen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/color_constants.dart';
import '../constants/firestore_constants.dart';
import '../providers/authprovider.dart';
import '../providers/chatprovider.dart';

class ChatPage extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String peerNickname;

  const ChatPage(
      {Key? key,
      required this.peerId,
      required this.peerAvatar,
      required this.peerNickname})
      : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late String currentUserId;

  List<QueryDocumentSnapshot> listMessage = [];
  int _limit = 20;
  int _limitIncrement = 20;
  String groupChatId = "";

  File? imageFile;
  bool isLoading = false;
  bool isShowSticker = false;
  String imageUrl = "";

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  late ChatProvider chatProvider;
  late AuthProvider authProvider;

  @override
  void initState() {
    super.initState();
    chatProvider = context.read<ChatProvider>();
    authProvider = context.read<AuthProvider>();

    // focusNode.addListener(onFocusChange);
    listScrollController.addListener(_scrollListener);
    readLocal();
  }

  // void onFocusChange() {
  //   if (focusNode.hasFocus) {
  //     // Hide sticker when keyboard appear
  //     setState(() {
  //       isShowSticker = false;
  //     });
  //   }
  // }

  void readLocal() {
    if (authProvider.getUserFirebaseId()?.isNotEmpty == true) {
      currentUserId = authProvider.getUserFirebaseId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
    String peerId = widget.peerId;
    if (currentUserId.compareTo(peerId) > 0) {
      groupChatId = '$currentUserId-$peerId';
    } else {
      groupChatId = '$peerId-$currentUserId';
    }

    chatProvider.updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      currentUserId,
      {FirestoreConstants.chattingWith: peerId},
    );
  }

  void _pickFile() async {
    Navigator.pop(context);
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null) return;
  }

  Future getImageFromGallery() async {
    Navigator.pop(context);
    XFile? pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      imageFile = File(pickedImage.path);
      if (imageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadImageFile();
      }
    }
  }

  Future getImageFromCamera() async {
    Navigator.pop(context);
    XFile? pickedImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      imageFile = File(pickedImage.path);
      if (imageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadImageFile();
      }
    }
  }

  Future uploadImageFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask = chatProvider.uploadFile(imageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, TypeMessage.image);
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void onSendMessage(String content, int type) {
    if (content.trim().isNotEmpty) {
      textEditingController.clear();
      chatProvider.sendMessage(
          content, type, groupChatId, currentUserId, widget.peerId);
      if (listScrollController.hasClients) {
        listScrollController.animateTo(0,
            duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } else {
      Fluttertoast.showToast(
          msg: 'Nothing to send', backgroundColor: ColorConstants.greyColor);
    }
  }

  _scrollListener() {
    if (!listScrollController.hasClients) return;
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange &&
        _limit <= listMessage.length) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.peerNickname,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            buildListMessage(),
            buildInput(),
          ],
        ),
      ),
    );
  }

  buildListMessage() {
    return Flexible(
      child: groupChatId.isNotEmpty
          ? StreamBuilder(
              stream: chatProvider.getChatStream(groupChatId, _limit),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                 if (snapshot.hasData) {
                  listMessage = snapshot.data!.docs;
                  if (listMessage.isNotEmpty) {
                    return ListView.builder(
                      itemCount: snapshot.data?.docs.length,
                      controller: listScrollController,
                      reverse: true,
                      itemBuilder: (context, index) =>
                          buildItem(index, snapshot.data?.docs[index]),
                    );
                  } else {
                    return const Center(child: Text("No message here yet..."));
                  }
                } else {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ColorConstants.themeColor,
                    ),
                  );
                }
              })
          : const Center(
              child: CircularProgressIndicator(
                color: ColorConstants.themeColor,
              ),
            ),
    );
  }

  buildItem(int index, QueryDocumentSnapshot<Object?>? doc) {
    if (doc != null) {
      MessageChatModel messageChatModel = MessageChatModel.fromDocument(doc);
      if (messageChatModel.idFrom == currentUserId) {
        // Right My message
        return Align(
          alignment: Alignment.centerRight,
          child: messageChatModel.type == TypeMessage.text
              ? Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: ColorConstants.primaryColor,
                      borderRadius: BorderRadius.circular(10)),
                  width: MediaQuery.of(context).size.width - 150,
                  child: Text(
                    messageChatModel.content,
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Container(
                  padding: EdgeInsets.all(5),
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: ColorConstants.primaryColor,
                      borderRadius: BorderRadius.circular(10)),
                  width: MediaQuery.of(context).size.width - 150,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        messageChatModel.content,
                        fit: BoxFit.cover,
                      )),
                ),
        );
      } else {
        // left other message
        return Align(
          alignment: Alignment.centerLeft,
          child: messageChatModel.type == TypeMessage.text
              ? Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10)),
                  width: MediaQuery.of(context).size.width - 150,
                  child: Text(
                    messageChatModel.content,
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Container(
                  padding: EdgeInsets.all(5),
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10)),
                  width: MediaQuery.of(context).size.width - 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      messageChatModel.content,
                      fit: BoxFit.cover,
                      width: 200,
                    ),
                  ),
                ),
        );
      }
    } else {
      return SizedBox.shrink();
    }
  }

  Widget buildInput() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(color: ColorConstants.greyColor2, width: 0.5)),
          color: Colors.white),
      child: Row(
        children: <Widget>[
          // Button send image
          Container(
            margin: EdgeInsets.symmetric(horizontal: 1),
            child: IconButton(
              icon: const Icon(Icons.image),
              // onPressed: (){
              //    Navigator.push(context, MaterialPageRoute(builder: (builder)=>CameraScreen()));
              // },
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (builder) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: getImageFromCamera,
                        child: const Text(
                          'Camera',
                          style: TextStyle(color: ColorConstants.primaryColor),
                        ),
                      ),
                      const Divider(thickness: 1),
                      TextButton(
                        onPressed: getImageFromGallery,
                        child: const Text('Gallery',
                            style:
                                TextStyle(color: ColorConstants.primaryColor)),
                      ),
                    ],
                  ),
                );
              },
              color: ColorConstants.primaryColor,
            ),
          ),

          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                onSubmitted: (value) {
                  onSendMessage(textEditingController.text, TypeMessage.text);
                },
                style: const TextStyle(
                    color: ColorConstants.primaryColor, fontSize: 15),
                controller: textEditingController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: ColorConstants.greyColor),
                  suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          focusNode.unfocus();
                          focusNode.canRequestFocus = false;
                        });
                        showModalBottomSheet(
                            context: context,
                            builder: (context) => bottomSheet());
                      },
                      icon: const Icon(
                        Icons.attach_file_rounded,
                        color: ColorConstants.primaryColor,
                      )),
                ),
                focusNode: focusNode,
              ),
            ),
          ),

          // Button send message
          Material(
            color: Colors.white,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                icon: Icon(Icons.send),
                onPressed: () =>
                    onSendMessage(textEditingController.text, TypeMessage.text),
                color: ColorConstants.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bottomSheet() {
    return Container(
      height: 270,
      width: MediaQuery.of(context).size.width,
      child: Card(
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildAttachIcon(
                    Icons.insert_drive_file, Colors.indigo, 'Document', () {
                  _pickFile();
                }),
                buildAttachIcon(Icons.camera_alt, Colors.pink, 'Camera', () {
                  getImageFromCamera();
                }),
                buildAttachIcon(Icons.photo, Colors.purple, 'Gallery', () {
                  getImageFromGallery();
                }),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildAttachIcon(Icons.headset, Colors.orange, 'Audio', () {
                  _pickFile();
                }),
                buildAttachIcon(
                    Icons.location_pin, Colors.pinkAccent, 'Location', () {
                  Navigator.pop(context);
                }),
                buildAttachIcon(Icons.person, Colors.blue, 'Contact', () {
                  Navigator.pop(context);
                }),
              ],
            )
          ],
        ),
      ),
    );
  }

  buildAttachIcon(
      IconData icon, Color color, String text, void Function() onTap) {
    return InkWell(
      onTap: () {
        onTap();
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 25, right: 25, top: 25),
            child: CircleAvatar(
              radius: 27,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
          ),
          SizedBox(height: 5),
          Text(
            text,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
