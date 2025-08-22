import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/app_config.dart'; // API 호스트 설정
import 'place_detail_screen.dart';

class Place {
  final int id;
  final String name;
  final String address;
  final String xPos;
  final String yPos;
  final bool isBookmark;

  Place({
    required this.id,
    required this.name,
    required this.address,
    required this.xPos,
    required this.yPos,
    required this.isBookmark,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      xPos: json['x_position'] ?? '0',
      yPos: json['y_position'] ?? '0',
      isBookmark: json['is_bookmark'] ?? false,
    );
  }
}

class PlaceMapScreen extends StatefulWidget {
  const PlaceMapScreen({super.key});

  @override
  State<PlaceMapScreen> createState() => _PlaceMapScreenState();
}

class _PlaceMapScreenState extends State<PlaceMapScreen> {
  final NLatLng initialPosition = const NLatLng(37.5665, 126.9780);
  final _storage = const FlutterSecureStorage();
  List<Place> _places = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  Future<void> _fetchPlaces() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    final url = Uri.http(AppConfig.apiHost, '/places/', {'page': '1', 'size': '50'});

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['result'];
        setState(() {
          _places = items.map((json) => Place.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        debugPrint('장소 불러오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('장소 불러오기 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          '수영장 지도',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NaverMap(
        options: NaverMapViewOptions(
          initialCameraPosition: NCameraPosition(
            target: initialPosition,
            zoom: 12,
          ),
            locationButtonEnable: true,
        ),
        onMapReady: (controller) async {
          for (var place in _places) {
            final marker = NMarker(
              id: place.id.toString(),
              position: NLatLng(
                double.tryParse(place.yPos) ?? 37.5665,
                double.tryParse(place.xPos) ?? 126.9780,
              ),
                caption: NOverlayCaption(text: place.name),
            );
            controller.addOverlay(marker);

            // marker.setOnTapListener((NMarker marker) {
            //   print("마커가 터치되었습니다. id: ${marker.info.id}");
            // });

            marker.setOnTapListener((NMarker tappedMarker) {
              final int? placeId = int.tryParse(tappedMarker.info.id);
              if (placeId != null) {
                // `place_id`를 PlaceDetailScreen으로 전달합니다.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaceDetailScreen(placeId: placeId),
                  ),
                );
              }
            });
          }
        },
      ),
    );
  }
}
