import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_way_client/screens/screen_register.dart';
import 'package:my_way_client/utils/http_config.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _dio = Dio();

  bool _obscureText = true;

  // Key loginButtonKey = ;

  static const String TOKEN_KEY = 'token';
  static const String USERNAME_KEY = 'username';
  static const String ROLE_KEY = 'role';
  static const String EMAIL_KEY = 'email';

  Future<void> loginProcess() async {
    const storage = FlutterSecureStorage();
    String loginURL = '$memberApiBaseUrl/login';

    Map<String, dynamic> data = {
      'email': _emailController.text,
      'password': _passwordController.text,
    };

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "값을 입력해주세요",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
      return;
    }
    try {
      final response = await _dio.post(
        loginURL,
        data: jsonEncode(data),
        options: Options(headers: {"Content-Type": "Application/json"}),
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        final token = jsonData['token'];
        final userName = jsonData['userName'];
        final role = jsonData['role'];
        final email = jsonData['email'];

        await storage.write(key: TOKEN_KEY, value: token);
        await storage.write(key: USERNAME_KEY, value: userName);
        await storage.write(key: ROLE_KEY, value: role);
        await storage.write(key: EMAIL_KEY, value: email);

        Fluttertoast.showToast(msg: "로그인 성공!", toastLength: Toast.LENGTH_LONG);
        Navigator.of(context).pop(true);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final text = e.response?.data.toString();
        Fluttertoast.showToast(
          msg: text!,
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
        );
      } else {
        Fluttertoast.showToast(
          msg: "알 수 없는 에러가 발생했습니다.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

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
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                    ),
                    SizedBox(
                      height: height * 0.05,
                    ),
                    const Text("비밀번호(Password)"),
                    TextFormField(
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                      textInputAction: TextInputAction.join,
                      obscureText: _obscureText,
                      controller: _passwordController,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).unfocus();

                        if (_emailController.text.isEmpty) {
                          Fluttertoast.showToast(
                            msg: "이메일을 입력해주세요",
                            toastLength: Toast.LENGTH_LONG,
                            backgroundColor: Colors.red,
                            gravity: ToastGravity.BOTTOM,
                          );
                        } else if (_passwordController.text.isEmpty) {
                          Fluttertoast.showToast(
                            msg: "패스워드를 입력해주세요",
                            toastLength: Toast.LENGTH_LONG,
                            backgroundColor: Colors.red,
                            gravity: ToastGravity.BOTTOM,
                          );
                        } else if (_emailController.text.isEmpty &&
                            _passwordController.text.isEmpty) {
                          Fluttertoast.showToast(
                            msg: "이메일 및 패스워드를 입력해주세요",
                            toastLength: Toast.LENGTH_LONG,
                            backgroundColor: Colors.red,
                            gravity: ToastGravity.BOTTOM,
                          );
                        } else {
                          loginProcess();
                        }
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () {}, child: const Text("비밀번호를 잊으셨나요?"))
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {
                        loginProcess();
                        FocusScope.of(context).unfocus();
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
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: height * 0.03,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          width: 100,
                          height: 1,
                          color: Colors.black,
                        ),
                        const Text("간단 로그인"),
                        Container(
                          width: 100,
                          height: 1,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    const Row(
                      children: [],
                    ),
                    Center(
                      child: TextButton(
                          onPressed: () {
                            Get.to(() => const SignUpPage());
                          },
                          child: const Text("계정이 없다면 회원가입을 해보세요!")),
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
