import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:my_way_client/utils/key_config.dart';

void main() async {
  await _initialize();
  runApp(const NaverMapApp());
}

Future<NLatLng> getLocation() async {
  LocationPermission permission = await Geolocator.requestPermission();

  switch (permission) {
    case LocationPermission.always:
      break;
    case LocationPermission.whileInUse:
      break;
    case LocationPermission.denied:
      break;
    case LocationPermission.deniedForever:
      break;
    case LocationPermission.unableToDetermine:
      break;
  }

  // 현재 위치 정보 가져오기
  Position position = await Geolocator.getCurrentPosition();

  // 위치 정보 처리
  print(position.latitude);
  print(position.longitude);

  return NLatLng(position.latitude, position.longitude);
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
  final Completer<NaverMapController> _controller =
      Completer(); // For map controller
  NLatLng? _position; // Store location

  bool _locationInitialized = false; // 위치 정보 초기화 여부 변수 추가

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            elevation: 0.0,
            title: const TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: "검색어를 입력하세요.",
                border: InputBorder.none,
              ),
            ),
          ),
          body: FutureBuilder<NLatLng>(
            future: _initializeLocationIfNeeded(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return NaverMap(
                  options: NaverMapViewOptions(
                    initialCameraPosition: _position != null
                        ? NCameraPosition(
                            target: _position!,
                            zoom: 17,
                          )
                        : const NCameraPosition(
                            target: NLatLng(37.5665, 126.9784),
                            zoom: 10,
                          ),
                    indoorEnable: true,
                    scrollGesturesFriction: 0,
                    mapType: NMapType.navi,
                    activeLayerGroups: [
                      NLayerGroup.building,
                      NLayerGroup.transit
                    ],
                  ),
                  onMapReady: (controller) async {
                    debugPrint("네이버 맵 로딩됨");
                    log("onMapReady", name: "onMapReady");
                  },
                  onMapTapped: (point, latLng) {
                    debugPrint("${latLng.latitude}, ${latLng.longitude}");
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
          )),
    );
  }
}
