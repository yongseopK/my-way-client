import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "안녕",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
          child: Container(
        child: const Text("안녕"),
      )),
    );
  }
}
