import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ichat_app/constants/constants.dart';
import 'package:ichat_app/models/userchatmodel.dart';
import 'package:ichat_app/providers/authprovider.dart';
import 'package:ichat_app/screens/loginscreen.dart';
import 'package:ichat_app/screens/settingpage.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../providers/homeprovider.dart';
import 'chatpage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();
  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    // 'This channel is used for important notifications.', // description
    importance: Importance.high,
  );
  Uri APP_STORE_URL = Uri.parse('https://apps.apple.com');
  Uri PLAY_STORE_URL = Uri.parse('https://play.google.com/store/apps');

  int _limit = 20;
  int _limitIncrement = 20;
  String _textSearch = "";
  bool isLoading = false;

  late String currentUserId;
  late AuthProvider authProvider;
  late HomeProvider homeProvider;

  Future<void> handleSignOut() async {
    authProvider.handleSignOut();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false);
  }

  @override
  void initState() {
    super.initState();
    // try {
    // //  versionCheck(context);
    // } catch (e) {
    //   print(e);
    // }
    authProvider = context.read<AuthProvider>();
    if (authProvider.getUserFirebaseId()?.isNotEmpty == true) {
      currentUserId = authProvider.getUserFirebaseId()!;
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false);
    }
    registerNotification();
    configLocalNotification();
    // getNotification();
    // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    homeProvider = context.read<HomeProvider>();
    listScrollController.addListener(scrollListener);
  }

  void scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  // getNotification() async {
  //   NotificationSettings settings = await FirebaseMessaging.instance
  //       .requestPermission(alert: true, badge: true, sound: true);
  //   await FirebaseMessaging.instance
  //       .setForegroundNotificationPresentationOptions(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   );
  //   RemoteMessage? initialMessage =
  //   await FirebaseMessaging.instance.getInitialMessage();
  //   await flutterLocalNotificationsPlugin
  //       .resolvePlatformSpecificImplementation<
  //       AndroidFlutterLocalNotificationsPlugin>()
  //       ?.createNotificationChannel(channel);
  //   FirebaseMessaging.onMessage.listen((RemoteMessage event) {
  //     RemoteNotification? notification = event.notification;
  //     AndroidNotification? android = event.notification?.android;
  //     flutterLocalNotificationsPlugin.show(
  //       notification.hashCode,
  //       notification!.title,
  //       notification.body,
  //       NotificationDetails(
  //         android: AndroidNotificationDetails(
  //           channel.id,
  //           channel.name,
  //           //  channel.description,
  //           // TODO add a proper drawable resource to android, for now using
  //           //      one that already exists in example app.
  //           icon: '@mipmap/ic_launcher',
  //         ),
  //         iOS: DarwinNotificationDetails(
  //           subtitle: "Hello",
  //         ),
  //       ),
  //     );
  //   });
  //   if (initialMessage != null) {
  //     // App received a notification when it was killed
  //   }
  //   firebaseMessaging.getToken().then((token) {
  //         print('push token: $token');
  //         if (token != null) {
  //           homeProvider.updateDataFirestore(FirestoreConstants.pathUserCollection, currentUserId, {'pushToken': token});
  //         }
  //       }).catchError((err) {
  //         Fluttertoast.showToast(msg: err.message.toString());
  //       });
  //
  // }
  //
  // Future<void> _firebaseMessagingBackgroundHandler(
  //     RemoteMessage message) async {}

  void registerNotification() {
    firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('onMessage----------: $message');
      if (message.notification != null) {
        showNotification(message.notification!);
      }
      return;
    });

    firebaseMessaging.getToken().then((token) {
      print('push token: $token');
      if (token != null) {
        homeProvider.updateDataFirestore(FirestoreConstants.pathUserCollection,
            currentUserId, {'pushToken': token});
      }
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
  }

  void showNotification(RemoteNotification remoteNotification) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      Platform.isAndroid ? 'com.example.ichat_app' : 'com.example.ichat_app',
      'Flutter chat demo',
      playSound: true,
      enableVibration: true,
      importance: Importance.max,
      priority: Priority.high,
    );
    DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    print("remoteNotification----------$remoteNotification");

    await flutterLocalNotificationsPlugin.show(
      0,
      remoteNotification.title,
      remoteNotification.body,
      platformChannelSpecifics,
      payload: null,
    );
  }

  void configLocalNotification() {
    AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: ColorConstants.primaryColor,
        leading: IconButton(
          onPressed: () {},
          icon: Switch(
            value: isWhite,
            onChanged: (bool value) {
              setState(() {
                isWhite = value;
                print(value);
              });
            },
            activeTrackColor: Colors.grey,
            activeColor: Colors.white,
            inactiveThumbColor: Colors.black54,
            inactiveTrackColor: Colors.grey,
          ),
        ),
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'Sign out') {
                handleSignOut();
                print('SignOut');
              } else {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SettingPage()));
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'Settings',
                  child: Row(
                    children: const [
                      Icon(
                        Icons.settings,
                        color: Colors.black,
                      ),
                      SizedBox(width: 5),
                      Text('Settings'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'Sign out',
                  child: Row(
                    children: const [
                      Icon(
                        Icons.exit_to_app,
                        color: Colors.black,
                      ),
                      SizedBox(width: 5),
                      Text('Sign out'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .limit(_limit)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            if ((snapshot.data?.docs.length ?? 0) > 0) {
              return ListView.builder(
                itemCount: snapshot.data?.docs.length,
                controller: listScrollController,
                itemBuilder: (context, index) => buildHomeUserItem(
                  context,
                  snapshot.data?.docs[index],
                ),
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
    );
  }

  buildHomeUserItem(BuildContext context, DocumentSnapshot? document) {
    if (document != null) {
      UserChatModel userChat = UserChatModel.fromDocument(document);
      if (userChat.id == currentUserId) {
        return SizedBox.shrink();
      } else {
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
            trailing: Container(
              height: 18,
              width: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
              child: const Center(
                  child: Text(
                '1',
                style: TextStyle(color: Colors.white, fontSize: 12),
              )),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    peerId: userChat.id,
                    peerAvatar: userChat.photoUrl,
                    peerNickname: userChat.nickName,
                  ),
                ),
              );
            },
          ),
        );
      }
    } else {
      return SizedBox.shrink();
    }
  }

  versionCheck(context) async {
    //Get Current installed version of app
    final PackageInfo info = await PackageInfo.fromPlatform();
    int currentVersion = int.parse(info.version.characters.first);
    // int.parse(info.version.trim().replaceAll(".0", ""));

    //Get Latest version info from firebase config
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.fetch();
    await remoteConfig.activate();

    try {
      // Using default duration to force fetching from remote server.
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero));
      await remoteConfig.fetchAndActivate();

      int minimumVersion = remoteConfig.getInt('minimum_app_version');
      int latestVersion = remoteConfig.getInt('latest_app_version');

      print('current version ------------> $currentVersion');
      print('minimum version ------------> $minimumVersion');
      print('latest version ------------> $latestVersion');
      if (latestVersion > currentVersion) {
        setState(() {});
        _showUpdateVersionDialog(context);
        if (minimumVersion > currentVersion) {
          _showForceUpdateVersionDialog(context);
        }
      }
    } on PlatformException catch (exception) {
      // Fetch throttled.
      print(exception);
    } catch (exception) {
      print('Unable to fetch remote config. Cached or default values will be '
          'used');
    }
    return remoteConfig;
  }

  _showUpdateVersionDialog(context) async {
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String title = "New Update Available";
        String message =
            "There is a newer version of app available please update it now.";
        String btnUpdate = "Update Now";
        String btnLater = "Later";
        return Platform.isIOS
            ? CupertinoAlertDialog(
                title: Text(title),
                content: Text(message),
                actions: <Widget>[
                  TextButton(
                    child: Text(btnUpdate),
                    onPressed: () => _launchURL(APP_STORE_URL),
                  ),
                  TextButton(
                    child: Text(btnLater),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              )
            : AlertDialog(
                title: Text(title),
                content: Text(message),
                actions: <Widget>[
                  TextButton(
                    child: Text(btnUpdate),
                    onPressed: () => _launchURL(PLAY_STORE_URL),
                  ),
                  TextButton(
                    child: Text(btnLater),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              );
      },
    );
  }

  _showForceUpdateVersionDialog(context) async {
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String title = "Please update the app";
        String message = "Please update to continue using the app.";
        String btnUpdate = "Update";
        return Platform.isIOS
            ? CupertinoAlertDialog(
                title: Text(title),
                content: Text(message),
                actions: <Widget>[
                  TextButton(
                    child: Text(btnUpdate),
                    onPressed: () => _launchURL(APP_STORE_URL),
                  ),
                ],
              )
            : AlertDialog(
                title: Text(title),
                content: Text(message),
                actions: <Widget>[
                  TextButton(
                    child: Text(btnUpdate),
                    onPressed: () => _launchURL(PLAY_STORE_URL),
                  ),
                ],
              );
      },
    );
  }

  _launchURL(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
