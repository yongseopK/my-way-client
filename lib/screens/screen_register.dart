import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_way_client/utils/http_config.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

enum Gender { male, female }

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _weightController = TextEditingController();
  final _birthdayController = TextEditingController();

  String? _selectedGender;

  String _emailErrorMessage = '';
  String _nameErrorMessage = '';
  String _passwordErrorMessage = '';
  String _confirmPasswordErrorMessage = '';
  String _weightErrorMessage = '';
  String _birthdayErrorMessage = '';

  bool _isEmailDuplicate = false;
  bool _isNameValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;
  bool _isWeightValid = false;
  bool _isBirthdayValid = false;

  bool isSignUpButtonEnabled = false;

  final correct = [false, false, false, false, false, false, false];

  final _dio = Dio();

  Future<void> _checkEmailDuplicate(String email) async {
    try {
      String checkURL = "$memberApiBaseUrl/check?email=$email";
      final res = await _dio.get(checkURL);
      if (res.data) {
        setState(() {
          _isEmailDuplicate = res.data;
          _emailErrorMessage = '이미 사용 중인 이메일입니다.';
          correct[0] = false;
        });
      } else {
        setState(() {
          _isEmailDuplicate = res.data;
          _emailErrorMessage = '';
          correct[0] = true;
        });
      }
    } catch (e) {
      setState(() {
        _emailErrorMessage = '네트워크 오류가 발생했습니다.';
      });
      debugPrint("error : $e");
    }
  }

  void nameHandler(String name) {
    RegExp nameRegex = RegExp(r"^[가-힣]{2,5}$");

    if (nameRegex.hasMatch(name)) {
      setState(() {
        _isNameValid = false;
        _nameErrorMessage = '';
        correct[1] = true;
      });
    } else {
      setState(() {
        _isNameValid = true;
        _nameErrorMessage = '이름은 2~5자의 한글로 입력해주세요.';
        correct[1] = false;
      });
    }
  }

  void passwordHandler(String password) {
    RegExp passwordRegex = RegExp(
        r"^(?=.*[A-Za-z])(?=.*\d)(?=.*[$@$!%*#?&])[A-Za-z\d$@$!%*#?&]{8,20}$");

    if (password.isEmpty) {
      setState(() {
        _passwordErrorMessage = '비밀번호는 필수 입력값입니다.';
        _isPasswordValid = true;
        correct[2] = false;
      });
    } else if (passwordRegex.hasMatch(password)) {
      setState(() {
        _isPasswordValid = false;
        _passwordErrorMessage = '';
        correct[2] = true;
      });
    } else {
      setState(() {
        _isPasswordValid = true;
        _passwordErrorMessage = '8글자 이상의 영문,숫자,특수문자를 포함해주세요!';
        correct[2] = false;
      });
    }
  }

  void weightHandler(String weight) {
    RegExp weightRegex = RegExp(r'^[0-9]+(\.[0-9]+)?$');

    if (weightRegex.hasMatch(weight) && double.parse(weight) >= 10.0) {
      setState(() {
        _isWeightValid = false;
        _weightErrorMessage = '';
        correct[4] = true;
      });
    } else {
      setState(() {
        _isWeightValid = true;
        _weightErrorMessage = '유효하지 않은 값입니다!';
        correct[4] = false;
      });
    }
  }

  void birthdayHandler(String birthday) {
    RegExp birthdayRegex = RegExp(r'^[0-9]{8}$');

    try {
      if (birthdayRegex.hasMatch(birthday)) {
        setState(() {
          _isBirthdayValid = false;
          _birthdayErrorMessage = '';
          correct[5] = true;
        });
      } else if (int.parse(birthday) > 19000000) {
        setState(() {
          _isBirthdayValid = true;
          _birthdayErrorMessage = '유효한 생년월일을 입력 해주세요!';
          correct[5] = false;
        });
      } else if (birthday.isEmpty) {
        setState(() {
          _isBirthdayValid = true;
          _birthdayErrorMessage = '유효한 생년월일을 입력 해주세요!';
          correct[5] = false;
        });
      } else {
        setState(() {
          _isBirthdayValid = true;
          _birthdayErrorMessage = '유효한 생년월일을 입력 해주세요!';
          correct[5] = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  bool isAllTrue(List<bool> list) {
    return list.every((element) => element == true);
  }

  Future<void> register() async {
    try {
      String registerURL = "$memberApiBaseUrl/register";

      final Map<String, dynamic> data = {
        'email': _emailController.text,
        'userName': _nameController.text,
        'password': _passwordController.text,
        'weight': _weightController.text,
        'birthDate': _birthdayController.text,
        'gender': _selectedGender
      };

      final res = await _dio.post(
        registerURL,
        data: jsonEncode(data),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (res.statusCode == 200) {
        print('회원가입 완료');
        Fluttertoast.showToast(
          msg: "회원가입에 성공했습니다.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
        );

        Navigator.of(context).pop();
      } else {
        print('에러 발생 : ${res.statusCode}');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    isSignUpButtonEnabled = isAllTrue(correct);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.05,
                vertical: height * 0.01,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "회원가입",
                        style: GoogleFonts.doHyeon(fontSize: 32),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.03),
                  const Text(
                    "* 이메일(E-mail)",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (_emailErrorMessage.isNotEmpty)
                    Text(
                      _emailErrorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  TextFormField(
                    textInputAction: TextInputAction.next,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _isEmailDuplicate ? Colors.red : Colors.black,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _isEmailDuplicate ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      _checkEmailDuplicate(value);
                    },
                  ),
                  SizedBox(height: height * 0.03),
                  const Text(
                    "* 이름(Name)",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_nameErrorMessage.isNotEmpty)
                    Text(
                      _nameErrorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  TextFormField(
                    textInputAction: TextInputAction.next,
                    controller: _nameController,
                    onChanged: (value) => nameHandler(value),
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _isNameValid ? Colors.red : Colors.black,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _isNameValid ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.03),
                  const Text(
                    "* 비밀번호(Password)",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_passwordErrorMessage.isNotEmpty)
                    Text(
                      _passwordErrorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  TextFormField(
                    textInputAction: TextInputAction.next,
                    controller: _passwordController,
                    obscureText: true,
                    onChanged: (value) => passwordHandler(value),
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _isPasswordValid ? Colors.red : Colors.black,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _isPasswordValid ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.03),
                  const Text(
                    "* 비밀번호 확인(Confirm Password)",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_confirmPasswordErrorMessage.isNotEmpty)
                    Text(
                      _confirmPasswordErrorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  TextFormField(
                    textInputAction: TextInputAction.next,
                    controller: _confirmPasswordController,
                    obscureText: true,
                    onChanged: (value) {
                      if (_passwordController.value ==
                          _confirmPasswordController.value) {
                        setState(() {
                          _isConfirmPasswordValid = false;
                          _confirmPasswordErrorMessage = '';
                          correct[3] = true;
                        });
                      } else {
                        setState(() {
                          _isConfirmPasswordValid = true;
                          _confirmPasswordErrorMessage = "비밀번호를 확인해주세요";
                          correct[3] = false;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _isConfirmPasswordValid
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _isConfirmPasswordValid
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.03),
                  Row(
                    children: [
                      const Text(
                        "* 체중(Weight)",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Fluttertoast.showToast(
                            msg: "체중 정보는 칼로리를 계산할 때 사용됩니다.",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.CENTER,
                          );
                        },
                        child: const Icon(
                          Icons.question_mark,
                          size: 15,
                          color: Colors.red,
                        ),
                      )
                    ],
                  ),
                  if (_weightErrorMessage.isNotEmpty)
                    Text(
                      _weightErrorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  TextFormField(
                    textInputAction: TextInputAction.next,
                    controller: _weightController,
                    onChanged: (value) => weightHandler(value),
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _isWeightValid ? Colors.red : Colors.black,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _isWeightValid ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.03),
                  const Text(
                    "* 생년월일",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_birthdayErrorMessage.isNotEmpty)
                    Text(
                      _birthdayErrorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  TextFormField(
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    controller: _birthdayController,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => birthdayHandler(value),
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _isBirthdayValid ? Colors.red : Colors.black,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _isBirthdayValid ? Colors.red : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.03),
                  const Text(
                    "* 성별",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      Radio<String>(
                        value: 'male',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _selectedGender = value;
                            correct[6] = true;
                          });
                        },
                      ),
                      const Text('남성'),
                      Radio<String>(
                        value: 'female',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _selectedGender = value;
                            correct[6] = true;
                          });
                        },
                      ),
                      const Text('여성')
                    ],
                  ),
                  SizedBox(height: height * 0.03),
                  GestureDetector(
                    onTap: isSignUpButtonEnabled
                        ? () {
                            print('조건 다 충족 함');
                            register();
                          }
                        : () {
                            print(correct);
                          },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:
                            isSignUpButtonEnabled ? Colors.black : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          '회원가입',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
