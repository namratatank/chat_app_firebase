import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.grey,
        ),
      ),
    );
  }
}
