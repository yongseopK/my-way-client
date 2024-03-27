import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_way_client/utils/http_config.dart';

class ModifyProfile extends StatefulWidget {
  final String category;
  final String value;

  const ModifyProfile({super.key, required this.category, required this.value});

  @override
  State<ModifyProfile> createState() => _ModifyProfileState();
}

String getPostPosition(String word) {
  int lastCharCode = word.codeUnitAt(word.length - 1);

  if (lastCharCode >= 44032 && lastCharCode <= 55203) {
    if ((lastCharCode - 44032) % 28 != 0) {
      return "을";
    }
  }

  return "를";
}

Dio _dio = Dio();

class _ModifyProfileState extends State<ModifyProfile> {
  final _inputTextController = TextEditingController();
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.value;
  }

  @override
  void dispose() {
    _inputTextController.dispose();
    super.dispose();
  }

  String formatDate(String inputDate) {
    if (inputDate.length == 8) {
      String year = inputDate.substring(0, 4);
      String month = inputDate.substring(4, 6);
      String day = inputDate.substring(6, 8);
      return "$year-$month-$day";
    }
    return inputDate;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    Future<void> modifyProfile() async {
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: "token");

      String modifyURL = "$memberApiBaseUrl/modify";

      Map<String, dynamic> data = {};

      switch (widget.category) {
        case "이름":
          data['userName'] = _inputTextController.text;
        case "생년월일":
          data['birthDate'] = formatDate(_inputTextController.text);
        case "몸무게":
          data['weight'] = double.parse(_inputTextController.text);
        case "성별":
          data['gender'] = _selectedGender;
      }

      print('$data');

      final response = await _dio.patch(
        modifyURL,
        data: data,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "Application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "정보가 변경되었습니다.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );

        if (widget.category == '이름') {
          await storage.write(
              key: "username", value: _inputTextController.text);
        }

        Navigator.pop(context, true);
      }
    }

    Future<void> checkValueAndHttpRequset(String data) async {
      print("data : $data");
      print("value : ${widget.value}");
      if (data == widget.value) {
        Fluttertoast.showToast(
          msg: "이전 정보와 같습니다!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
        );
        return;
      } else {
        await modifyProfile();
      }
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "${widget.category} 수정하기",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.05,
              vertical: height * 0.03,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "새로운 ${widget.category}${getPostPosition(widget.category)} 입력해주세요.",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.02),
                if (widget.category != "성별")
                  TextField(
                    keyboardType: widget.category == "생년월일"
                        ? TextInputType.number
                        : widget.category == "몸무게"
                            ? const TextInputType.numberWithOptions(
                                signed: false, decimal: true)
                            : TextInputType.text,
                    controller: _inputTextController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: widget.value,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1.0,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 16.0,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2.0,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.0,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                if (widget.category == "성별")
                  Column(
                    children: [
                      RadioListTile(
                        title: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: width * 0.05),
                          child: const Text(
                            "남성",
                            style: TextStyle(fontSize: 16.0),
                          ),
                        ),
                        value: "MALE",
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        activeColor: Colors.blue,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.trailing,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        tileColor: Colors.grey[200],
                        selectedTileColor: Colors.blue[50],
                      ),
                      const SizedBox(height: 12.0),
                      RadioListTile(
                        title: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: width * 0.05),
                          child: const Text(
                            "여성",
                            style: TextStyle(fontSize: 16.0),
                          ),
                        ),
                        value: "FEMALE",
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        activeColor: Colors.blue,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.trailing,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        tileColor: Colors.grey[200],
                        selectedTileColor: Colors.blue[50],
                      ),
                    ],
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        print(_inputTextController.text);
                        await checkValueAndHttpRequset(
                            _inputTextController.text);

                        FocusScope.of(context).unfocus();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: const Text(
                        "저장하기",
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
