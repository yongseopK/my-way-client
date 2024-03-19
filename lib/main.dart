import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeLocationIfNeeded();
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

  final dio = Dio();

  void searchMap() async {
    Options options = Options(headers: {
      "X-NCP-APIGW-API-KEY-ID": naverMapApiKey,
      "X-NCP-APIGW-API-KEY": naverMapApiSecretKey,
    });

    Response response = await dio.get(
      geocodingSearchUrl,
      queryParameters: {'query': userSearchValue},
      options: options,
    );

    if (response.statusCode == 200) {
      debugPrint("request search word : $userSearchValue");
      debugPrint("response : $response");
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return MaterialApp(
      home: Scaffold(
        drawer: Drawer(
          width: width * 0.645,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text("Drawer Header"),
              ),
              ListTile(
                title: const Text("Item 1"),
                onTap: () => debugPrint("1번 누름"),
              ),
              ListTile(
                title: const Text("Item 2"),
                onTap: () => debugPrint("2번 누름"),
              )
            ],
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
                      logoClickEnable: false,
                      mapType: NMapType.navi,
                      activeLayerGroups: [
                        NLayerGroup.building,
                        NLayerGroup.transit
                      ],
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
                              child: Builder(builder: (context) {
                                return ElevatedButton(
                                  onPressed: () {
                                    debugPrint("메뉴버튼 눌림");
                                    Scaffold.of(context).openDrawer();
                                    FocusScope.of(context).unfocus();
                                  },
                                  child: const Icon(Icons.menu),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            flex: 6,
                            child: Material(
                              elevation: 4.0,
                              borderRadius: BorderRadius.circular(5),
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
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () async {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  searchPlace();
                                },
                                child: const Icon(Icons.search),
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
                                      final distance = _position!.distanceTo(NLatLng(mapy, mapx));

                                      return GestureDetector(
                                        onTap: () async {
                                          debugPrint(placeName);
                                          debugPrint(roadAddress);
                                          debugPrint(mapx.toString());
                                          debugPrint(mapy.toString());

                                          final cameraUpdate =
                                              NCameraUpdate.withParams(
                                            target: NLatLng(mapy, mapx),
                                            zoom: zoomLevel,
                                          );

                                          marker = NMarker(
                                              id: 'selectionPlace',
                                              position: NLatLng(mapy, mapx));
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
                            ),
                            child: Column(
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: Colors.grey, width: 1.0))),
                                  child: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          zoomLevel += 1;
                                          var nCameraUpdate =
                                              NCameraUpdate.withParams(
                                            zoom: zoomLevel,
                                          );
                                          nCameraUpdate.setAnimation(animation: NCameraAnimation.none);
                                          _controller!
                                              .updateCamera(nCameraUpdate);
                                        });
                                      },
                                      icon:
                                          const Icon(Icons.keyboard_arrow_up)),
                                ),
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        zoomLevel -= 1;
                                        var nCameraUpdate =
                                            NCameraUpdate.withParams(
                                          zoom: zoomLevel,
                                        );
                                        nCameraUpdate.setAnimation(animation: NCameraAnimation.none);

                                        _controller!
                                            .updateCamera(nCameraUpdate);
                                      });
                                    },
                                    icon: const Icon(Icons.keyboard_arrow_down))
                              ],
                            ),
                          )
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
    debugPrint(searchText);

    if (searchText.isNotEmpty) {
      Response response = await dio.get(
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
