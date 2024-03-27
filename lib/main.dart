import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/route_manager.dart';
import 'package:my_way_client/screens/screen_login.dart';
import 'package:my_way_client/screens/screen_my_page.dart';
import 'package:my_way_client/utils/http_config.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  await _initialize();
  SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );
  runApp(const NaverMapApp());
}

const storage = FlutterSecureStorage();

Future<void> _initialize() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NaverMapSdk.instance.initialize(
      clientId: naverMapApiKey,
      onAuthFailed: (e) => log("네이버 맵 인증오류 : $e", name: "onAuthFailed"));
}

class NaverMapApp extends StatefulWidget {
  const NaverMapApp({super.key});

  @override
  State<NaverMapApp> createState() => _NaverMapAppState();
}

class _NaverMapAppState extends State<NaverMapApp> {
  bool isLogin = false;
  String? token;
  String? username;
  String? role;
  String? email;

  // final Completer<NaverMapController> _controller = Completer();
  NaverMapController? _controller;
  NLatLng? _position;

  double zoomLevel = 16;

  List<String> searchPlaceNames = [];
  List<String> searchPlaceRoadAddress = [];
  List<double> searchPlaceMapx = [];
  List<double> searchPlaceMapy = [];

  void updateSearchResults(List<String> names, List<String> roadAddress,
      List<double> mapx, List<double> mapy) {
    setState(() {
      searchPlaceNames = names;
      searchPlaceRoadAddress = roadAddress;
      searchPlaceMapx = mapx;
      searchPlaceMapy = mapy;
    });
  }

  String? userSearchValue;

  bool _locationInitialized = false; // 위치 정보 초기화 여부 변수 추가

  var marker;

  final TextEditingController _searchController = TextEditingController();

  Future<bool> _showLocationPermissionDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("위치 권한 허용"),
        content: const Text("원활한 앱 사용을 위해 위치 권한이 필요합니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text("설정으로 이동"),
          ),
        ],
      ),
    );
  }

  Future<NLatLng> getLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

    while (permission == LocationPermission.denied) {
      _showLocationPermissionDialog();
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return await Geolocator.getCurrentPosition()
          .then((position) => NLatLng(position.latitude, position.longitude));
    } else {
      return const NLatLng(37.5665, 126.9784);
    }
  }

  Future<void> getLoginInfo() async {
    token = await storage.read(key: 'token');
    username = await storage.read(key: 'username');
    role = await storage.read(key: 'role');
    email = await storage.read(key: 'email');

    if (token != null) {
      setState(() {
        isLogin = true;
      });
    } else {
      setState(() {
        isLogin = false;
      });
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _initializeLocationIfNeeded();
    getLoginInfo();
    _loadProfile();
  }

  Image? image;
  Uint8List? imageData;

  Future<void> _loadProfile() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    print('$token');

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

  Future<NLatLng> _initializeLocationIfNeeded() async {
    if (!_locationInitialized) {
      _locationInitialized = true;
      NLatLng location = await getLocation();
      setState(() {
        _position = location;
        log("location inside setState: $location");
      });
      return location;
    } else {
      return _position!;
    }
  }

  final _dio = Dio();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    Future<void> logout() async {
      await storage.delete(key: 'token').then((value) => token = '');
      await storage.delete(key: 'username').then((value) => username = '');
      await storage.delete(key: 'role').then((value) => role = '');
      await storage.delete(key: 'email').then((value) => email = '');

      if (token!.isEmpty) {
        setState(() {
          isLogin = false;
          image = null;
        });
      } else {
        setState(() {
          isLogin = true;
        });
      }
    }

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        drawer: Drawer(
          width: width * 0.645,
          child: Container(
            color: Colors.white,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.grey[400]!, Colors.grey[800]!],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: image ??
                              Image.asset(
                                "assets/images/anonymous.jpeg",
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      !isLogin
                          ? const Text(
                              "로그인이 필요한 서비스입니다.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            )
                          : Text(
                              username!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                      !isLogin
                          ? const SizedBox.shrink()
                          : Text(
                              email!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ],
                  ),
                ),
                isLogin
                    ? ListTile(
                        leading: const Icon(Icons.person, color: Colors.grey),
                        title: const Text(
                          "마이페이지",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Get.to(() => MyPage(
                                propsImage: imageData!,
                              ))?.then((value) {
                            _loadProfile();
                            getLoginInfo();
                          });
                        },
                      )
                    : const SizedBox.shrink(),
                !isLogin
                    ? ListTile(
                        leading: const Icon(Icons.login, color: Colors.grey),
                        title: const Text(
                          "로그인",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Get.to(() => const SignInPage())!.then((value) {
                            getLoginInfo();
                            _loadProfile();
                          });
                        },
                      )
                    : ListTile(
                        leading: const Icon(Icons.logout, color: Colors.grey),
                        title: const Text(
                          "로그아웃",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () async {
                          await logout();
                        },
                      ),
                ListTile(
                  leading: const Icon(Icons.vpn_key, color: Colors.grey),
                  title: const Text(
                    "토큰확인",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    print('isLogin : $isLogin');
                    print('token : $token');
                    print('username : $username');
                    print('role : $role');
                    print('email : $email');
                  },
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            FutureBuilder<NLatLng>(
              future: _initializeLocationIfNeeded(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return NaverMap(
                    options: NaverMapViewOptions(
                      initialCameraPosition: NCameraPosition(
                        target: _position!,
                        zoom: zoomLevel,
                      ),
                      indoorEnable: true,
                      locationButtonEnable: true,
                      scrollGesturesFriction: 0,
                      mapType: NMapType.navi,
                      activeLayerGroups: [
                        NLayerGroup.building,
                        NLayerGroup.transit,
                      ],
                      minZoom: 5.0,
                      maxZoom: 21.0,
                    ),
                    onMapReady: (controller) async {
                      _controller = controller;
                      debugPrint("네이버 맵 로딩됨");
                      log("onMapReady", name: "onMapReady");
                    },
                    onMapTapped: (point, latLng) {
                      debugPrint("${latLng.latitude}, ${latLng.longitude}");
                      FocusScope.of(context).unfocus();
                      _controller?.deleteOverlay(marker);
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("오류가 발생했습니다. ${snapshot.error}"),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
            Positioned(
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: Builder(
                                builder: (context) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade600,
                                          offset: const Offset(2.0, 2.0),
                                          blurRadius: 3.0,
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      color: Colors.white,
                                      onPressed: () {
                                        // debugPrint("메뉴버튼 눌림");
                                        Scaffold.of(context).openDrawer();
                                        FocusScope.of(context).unfocus();
                                      },
                                      icon: const Icon(Icons.menu),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            flex: 6,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade600,
                                    offset: const Offset(2.0, 2.0),
                                    blurRadius: 3.0,
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: (e) {
                                  searchPlace();
                                },
                                autofocus: false,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.all(15),
                                  hintText: "검색어를 입력하세요",
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade600,
                                    offset: const Offset(2.0, 2.0),
                                    blurRadius: 3.0,
                                  ),
                                ],
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: IconButton(
                                color: Colors.white,
                                onPressed: () async {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  searchPlace();
                                },
                                icon: const Icon(Icons.search),
                              ),
                            ),
                          ),
                        ],
                      ),
                      searchPlaceNames.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.white,
                                ),
                                width: width * 1,
                                height: height * 0.3,
                                child: ListView(
                                  children: List.generate(
                                    searchPlaceNames.length,
                                    (index) {
                                      final placeName = searchPlaceNames[index];
                                      final roadAddress =
                                          searchPlaceRoadAddress[index];
                                      final mapx = searchPlaceMapx[index];
                                      final mapy = searchPlaceMapy[index];
                                      final distance = _position!
                                          .distanceTo(NLatLng(mapy, mapx));

                                      return GestureDetector(
                                        onTap: () async {
                                          final cameraUpdate =
                                              NCameraUpdate.withParams(
                                            target: NLatLng(mapy, mapx),
                                            zoom: 16,
                                          );

                                          marker = NMarker(
                                            id: 'selectionPlace',
                                            position: NLatLng(mapy, mapx),
                                          );

                                          marker.setOnTapListener(
                                              (NMarker marker) {
                                            debugPrint(
                                                "마커 클릭됨 ${marker.position}");
                                          });
                                          setState(() {
                                            searchPlaceNames =
                                                List<String>.empty();
                                            searchPlaceRoadAddress =
                                                List<String>.empty();
                                            searchPlaceMapx =
                                                List<double>.empty();
                                            searchPlaceMapy =
                                                List<double>.empty();

                                            _controller
                                                ?.updateCamera(cameraUpdate);

                                            _controller?.addOverlay(marker);
                                          });
                                        },
                                        child: ListTile(
                                          title: Text(placeName),
                                          subtitle: Text(roadAddress),
                                          trailing: Text(
                                            distance < 1000
                                                ? "${distance.toStringAsFixed(1)}m"
                                                : "${(distance / 1000).toStringAsFixed(2)}Km",
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            )
                          : Container()
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey,
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      setState(
                                        () {
                                          if (zoomLevel < 21.0) {
                                            zoomLevel += 1;
                                            var nCameraUpdate =
                                                NCameraUpdate.withParams(
                                              zoom: zoomLevel,
                                            );
                                            // nCameraUpdate.setAnimation(
                                            //   animation: NCameraAnimation.none,
                                            // );
                                            _controller!
                                                .updateCamera(nCameraUpdate);
                                          } else {
                                            Fluttertoast.showToast(
                                              msg: "더 이상 확대할 수 없습니다.",
                                              toastLength: Toast.LENGTH_LONG,
                                              gravity: ToastGravity.CENTER,
                                              textColor: Colors.white,
                                              backgroundColor: Colors.black,
                                              fontSize: 16.0,
                                            );
                                          }
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.keyboard_arrow_up),
                                  ),
                                ),
                                IconButton(
                                    onPressed: () {
                                      setState(
                                        () {
                                          if (zoomLevel > 5.0) {
                                            zoomLevel -= 1;
                                            var nCameraUpdate =
                                                NCameraUpdate.withParams(
                                              zoom: zoomLevel,
                                            );

                                            // nCameraUpdate.setAnimation(
                                            //   animation: NCameraAnimation.none,
                                            // );

                                            _controller!
                                                .updateCamera(nCameraUpdate);
                                          } else {
                                            Fluttertoast.showToast(
                                              msg: "더 이상 축소할 수 없습니다.",
                                              toastLength: Toast.LENGTH_LONG,
                                              gravity: ToastGravity.CENTER,
                                              textColor: Colors.white,
                                              backgroundColor: Colors.black,
                                              fontSize: 16.0,
                                            );
                                          }
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.keyboard_arrow_down))
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String extractTitle(String title) {
    final regExp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);

    return title.replaceAll(regExp, '');
  }

  void searchPlace() async {
    String searchText = _searchController.text;

    if (searchText.isNotEmpty) {
      Response response = await _dio.get(
        "https://openapi.naver.com/v1/search/local.json",
        queryParameters: {'query': searchText, "display": 5},
        options: Options(
          headers: {
            "X-Naver-Client-Id": naverSearchApiId,
            "X-Naver-Client-Secret": naverSearchApiSecret,
          },
        ),
      );

      if (response.statusCode == 200) {
        final address = response.data["items"];
        final titles = address
            .map<String>((entry) => extractTitle(entry['title']))
            .toList();

        final roadAddress = address
            .map<String>((entry) => extractTitle(entry['roadAddress']))
            .toList();

        final mapxList = address
            .map<double>((entry) => double.parse(entry['mapx']) / 1e7)
            .toList();

        final mapyList = address
            .map<double>((entry) => double.parse(entry['mapy']) / 1e7)
            .toList();

        updateSearchResults(titles, roadAddress, mapxList, mapyList);
      }
    }

    _searchController.text = "";
  }
}
