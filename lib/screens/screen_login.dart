import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:my_way_client/screens/screen_register.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    final dio = Dio();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: height * 0.1,
                horizontal: width * 0.05,
              ),
              child: Container(
                // height: height * 0.3,
                // color: Colors.yellow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "로그인",
                          style: GoogleFonts.doHyeon(fontSize: 32),
                        )
                      ],
                    ),
                    SizedBox(
                      height: height * 0.05,
                    ),
                    const Text("이메일(E-mail)"),
                    TextFormField(
                      onChanged: (email) async {
                        debugPrint(email);
                      },
                    ),
                    SizedBox(
                      height: height * 0.05,
                    ),
                    const Text("비밀번호(Password)"),
                    TextFormField(),
                    SizedBox(
                      height: height * 0.01,
                    ),
                    GestureDetector(
                      onTap: () {
                        debugPrint("로그인 버튼 눌림");
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            '로그인',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: TextButton(
                          onPressed: () {
                            debugPrint("회원가입버튼");
                            Get.to(() => const SignUpPage());
                          },
                          child: Text("계정이 없다면 회원가입을 해보세요!")),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
