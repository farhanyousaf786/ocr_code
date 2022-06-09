/*
This is our main file of application.
 */

import 'package:flutter/material.dart';
import 'package:ocr_app/Dashboard/dashboard.dart';

/// App start from here.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  /// This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      /// This title will show in our app when we see it in recent apps.

      title: 'Flutter OCR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,

      /// home: is just kind of our first widget that will appear to user, So
      /// we pass Dashboard class as our first Screen
      home: DashBoard(),
    );
  }
}
