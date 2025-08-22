import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'dart:convert';
import 'place_list_screen.dart'; // Place 모델
import 'config/app_config.dart';

class PlaceDetailScreen extends StatefulWidget {
  final int placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  _PlaceDetailScreenState createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final _storage = const FlutterSecureStorage();
  Place? _place;
  bool _isLoading = true;
  String? _errorMessage;

  late final double _latitude;
  late final double _longitude;

  @override
  void initState() {
    super.initState();
    _fetchPlaceDetail();
  }

  Future<void> _fetchPlaceDetail() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
      return;
    }

    final url = Uri.parse('http://${AppConfig.apiHost}/places/${widget.placeId}');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        if (!mounted) return;

        final place = Place.fromJson(data);

        // 좌표 안전하게 변환, 실패 시 기본값 서울 좌표
        _latitude = double.tryParse(place.yPos ?? '') ?? 37.5665;
        _longitude = double.tryParse(place.xPos ?? '') ?? 126.9780;

        setState(() {
          _place = place;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        if (mounted) Navigator.of(context).pushReplacementNamed('/');
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = '장소 정보를 불러오는 데 실패했습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '네트워크 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          '수영장 정보',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _place == null
          ? const Center(child: Text('장소 정보를 찾을 수 없습니다.'))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_place!.imageUrl.isNotEmpty)
              Image.network(
                _place!.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 250,
              )
            else
              Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey[200],
                child:
                const Icon(Icons.image, size: 100, color: Colors.grey),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_place!.name,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(_place!.address,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('북마크 여부: ',
                          style:
                          Theme.of(context).textTheme.bodyMedium),
                      Icon(
                        _place!.isBookmark
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color:
                        _place!.isBookmark ? Colors.blue : Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: NaverMap(
                      options: NaverMapViewOptions(
                        initialCameraPosition: NCameraPosition(
                          target: NLatLng(_latitude, _longitude),
                          zoom: 15,
                        ),
                      ),
                      onMapReady: (controller) {
                        final marker = NMarker(
                          id: 'place_marker',
                          position: NLatLng(_latitude, _longitude),
                        );
                        controller.addOverlay(marker);
                      },
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
}
