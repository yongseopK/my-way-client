import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_way_client/screens/screen_modify_profile.dart';
import 'package:my_way_client/utils/http_config.dart';

class MyPage extends StatefulWidget {
  final Uint8List propsImage;

  const MyPage({super.key, required this.propsImage});

  @override
  State<MyPage> createState() => _MyPageState();
}

final _dio = Dio();

class _MyPageState extends State<MyPage> {
  String? email;
  String? username;
  String? birthdate;
  double? weight;
  String? gender;
  String? profileImg;
  String? joinDate;

  final passwordController = TextEditingController();

  Image? image;
  Uint8List? imageData;
  File? imageFile;

  bool isLoading = true;

  bool _profileImageChanged = false;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    String infoURL = "$memberApiBaseUrl/info";

    const storate = FlutterSecureStorage();
    final token = await storate.read(key: 'token');
    try {
      final res = await _dio.get(
        infoURL,
        options: Options(headers: {
          'Content-Type': 'Application/json',
          'Authorization': 'Bearer $token'
        }),
      );

      if (res.statusCode == 200) {
        final jsonData = res.data;
        setState(() {
          email = jsonData['email'];
          username = jsonData['userName'];
          birthdate = jsonData['birthDate'];
          weight = jsonData['weight'];
          gender = jsonData['gender'];
          joinDate = jsonData['joinDate'];

          isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (e.response!.statusCode == 400) {
        _handleError("정보 조회 실패 $e");
      }
      print('$e');
    } catch (e) {
      print('$e');
    }
  }

  Future<void> _loadProfile() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) return;

    String loadURL = "$memberApiBaseUrl/profile";
    try {
      final response = await _dio.get(loadURL,
          options: Options(
              responseType: ResponseType.bytes,
              headers: {"Authorization": "Bearer $token"}));

      if (response.statusCode == 200 && mounted) {
        setState(() {
          imageData = Uint8List.fromList(response.data);
          image = Image.memory(
            imageData!,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          );
        });
      } else {
        throw Exception('Failed to load profile image');
      }
    } catch (e) {
      print('Error fetching image: $e');
    }
  }

  Future<void> changeProfileImage() async {
    String changeURL = "$memberApiBaseUrl/change";

    final ImagePicker picker = ImagePicker();

    var pickedImage = await picker.pickImage(source: ImageSource.gallery);

    String path = pickedImage!.path;

    setState(() {
      imageFile = File(path);
    });

    const storate = FlutterSecureStorage();
    final token = await storate.read(key: 'token');

    FormData formData = FormData();

    formData.files
        .add(MapEntry('image', await MultipartFile.fromFile(imageFile!.path)));
    try {
      final res = await _dio.patch(
        changeURL,
        data: formData,
        options: Options(
          headers: {
            "Content-Type": "Application/json",
            "Authorization": "Bearer $token"
          },
        ),
      );

      if (res.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "프로필 사진을 변경했습니다.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );

        setState(() {
          _profileImageChanged = true;
          imageData = imageFile!.readAsBytesSync();
          image = Image.memory(
            imageData!,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          );
        });
      }
    } on DioException catch (e) {
      if (e.response!.statusCode == 400) {
        print('사진 변경에 실패했삼');
      }
    } catch (e) {
      print('$e');
    }
  }

  void _handleError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
    );
  }

  Future<void> withdrawMembership() async {
    final storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    String withdrawURL = "$memberApiBaseUrl/delete";
    try {
      final response = await _dio.delete(withdrawURL,
          options: Options(
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "Application/json"
            },
          ),
          data: {"password": passwordController.text});

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "회원탈퇴가 완료되었습니다.",
          toastLength: Toast.LENGTH_LONG,
        );

        setState(() {
          isLogout = 1;
          passwordController.text = '';
        });
        Navigator.pop(context, isLogout);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 555) {
        _handleError(e.response!.data.toString());
      }
    } catch (e) {
      _handleError("$e");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  double? startDragPosition;
  int isLogout = 0;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onHorizontalDragStart: (details) {
        startDragPosition = details.globalPosition.dx;
      },
      onHorizontalDragEnd: (details) {
        if (startDragPosition != null &&
            startDragPosition! < 100 &&
            details.velocity.pixelsPerSecond.dx > 300) {
          Navigator.pop(context, _profileImageChanged);
          startDragPosition = null; // reset for next drag operation
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, _profileImageChanged);
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              "내 정보",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: SafeArea(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        child: image ??
                                            Image.memory(
                                              widget.propsImage,
                                              width: 150,
                                              height: 150,
                                              fit: BoxFit.cover,
                                            ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 10,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () async {
                                          await changeProfileImage()
                                              .then((value) async {
                                            // await _loadProfile();
                                          });
                                        },
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                width: 3, color: Colors.white),
                                            borderRadius:
                                                BorderRadius.circular(50),
                                            color: Colors.black,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 20),
                              child: Column(
                                children: [
                                  _buildListTile("이메일", email!),
                                  _buildListTileWithIcon(
                                      "이름", username!, Icons.arrow_forward_ios),
                                  _buildListTileWithIcon("생년월일", birthdate!,
                                      Icons.arrow_forward_ios),
                                  _buildListTileWithIcon("몸무게", "${weight!} Kg",
                                      Icons.arrow_forward_ios),
                                  _buildListTileWithIcon(
                                      "성별",
                                      gender! == "MALE" ? "남성" : "여성",
                                      Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            child: const Text(
                              "로그아웃",
                              style: TextStyle(color: Colors.grey),
                            ),
                            onPressed: () async {
                              // await logout();
                              setState(() {
                                isLogout = 1;
                              });

                              Navigator.pop(context, isLogout);
                            },
                          ),
                          Container(
                            height: 15,
                            width: 1,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                            ),
                          ),
                          TextButton(
                            child: const Text(
                              "회원탈퇴",
                              style: TextStyle(color: Colors.grey),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return GestureDetector(
                                    onTap: () {
                                      FocusScope.of(context).unfocus();
                                    },
                                    child: AlertDialog(
                                      title: const Text('회원탈퇴'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            '회원탈퇴를 진행하시려면 비밀번호를 입력해주세요.',
                                          ),
                                          const SizedBox(height: 16),
                                          TextField(
                                            controller: passwordController,
                                            obscureText: true,
                                            decoration: const InputDecoration(
                                              labelText: '비밀번호',
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            passwordController.text = '';
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('취소'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (passwordController
                                                .text.isNotEmpty) {
                                              withdrawMembership();
                                              Navigator.of(context).pop();
                                            } else {
                                              _handleError("입력란이 비어있습니다!");
                                            }
                                          },
                                          child: const Text('확인'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(String title, String trailingText) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(width: 1, color: Colors.grey.shade300),
          bottom: BorderSide(width: 1, color: Colors.grey.shade300),
          left: BorderSide(width: 1, color: Colors.grey.shade300),
          right: BorderSide(width: 1, color: Colors.grey.shade300),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          topLeft: Radius.circular(10),
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: GestureDetector(
          onTap: () {
            _handleError("이메일은 수정할 수 없습니다.");
          },
          child: Text(
            trailingText,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTileWithIcon(
      String title, String trailingText, IconData iconData) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1, color: Colors.grey.shade300),
          left: BorderSide(width: 1, color: Colors.grey.shade300),
          right: BorderSide(width: 1, color: Colors.grey.shade300),
        ),
        borderRadius: title == "성별"
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              )
            : null,
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: GestureDetector(
          onTap: () {
            String value;
            switch (title) {
              case "이름":
                value = username!;
                break;
              case "생년월일":
                value = birthdate!;
                break;
              case "몸무게":
                value = weight!.toString();
                break;
              case "성별":
                value = gender!;
                break;
              default:
                value = "";
            }

            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (builder) => ModifyProfile(
                  category: title,
                  value: value,
                ),
              ),
            )
                .then((value) async {
              await _getUserInfo();
              setState(() {});
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trailingText,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                iconData,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
