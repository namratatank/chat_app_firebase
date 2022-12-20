import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ichat_app/providers/authprovider.dart';
import 'package:ichat_app/widgets/loading_view.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';

import 'homepage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    switch (authProvider.status) {
      case Status.authenticateError:
        Fluttertoast.showToast(msg: "Sign in error");
        break;
      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: "Sign in canceled");
        break;
      case Status.authenticated:
        Fluttertoast.showToast(msg: "Signed in successfully");
        break;
      default:
        break;
    }
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Image.asset("images/back.png"),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: InkWell(
              onTap: () async {
                authProvider.handleSignIn().then((isSuccess) {
                  if (isSuccess) {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => HomePage()));
                  }
                });
              },
              child: Image.asset('images/google_login.jpg'),
            ),
          ),
          authProvider.status == Status.authenticating
              ? LoadingView()
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}
