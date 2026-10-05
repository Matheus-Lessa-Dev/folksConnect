import 'package:flutter/material.dart';

void main() {
  runApp(const FolksConnectApp());
}

class FolksConnectApp extends StatelessWidget {
  const FolksConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Folks Connect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const Scaffold(
        body: SizedBox.expand(),
      ),
    );
  }
}
