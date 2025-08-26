import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'dart:convert';
import 'add_record_screen.dart';
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

  late double _latitude;
  late double _longitude;

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

        _latitude = double.tryParse(place.yPos) ?? 37.5665;
        _longitude = double.tryParse(place.xPos) ?? 126.9780;

        setState(() {
          _place = place;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        if (mounted) Navigator.of(context).pushReplacementNamed('/');
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = '장소 정보를 불러오는 데 실패했습니다.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '네트워크 오류가 발생했습니다: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addBookmark(int placeId) async {
    final token = await _storage.read(key: 'jwt_token');
    if (!mounted || token == null) return;

    final url = Uri.parse('http://${AppConfig.apiHost}/bookmarks/');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'place_id': placeId}),
      );

      if (response.statusCode == 200) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('북마크가 추가되었습니다.')),
        );
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크 추가 실패: ${response.body}')),
        );
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
    _fetchPlaceDetail(); // 북마크 상태를 최신화
  }

  Future<void> _deleteBookmark(int placeId) async {
    final token = await _storage.read(key: 'jwt_token');
    if (!mounted || token == null) return;

    final url = Uri.parse('http://${AppConfig.apiHost}/bookmarks/$placeId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('북마크가 삭제되었습니다.')),
        );
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크 삭제 실패: ${response.body}')),
        );
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
    _fetchPlaceDetail(); // 북마크 상태를 최신화
  }

  Future<void> _toggleBookmark() async {
    if (_place == null) return;
    if (_place!.isBookmark) {
      await _deleteBookmark(_place!.id);
    } else {
      await _addBookmark(_place!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
            Container(
              height: 250,
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/images/pool_ex.jpg'), fit: BoxFit.cover)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      _place!.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.blueAccent),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          _place!.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16, color: Colors.black54),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _place!.address)).then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('주소가 복사되었습니다!'),
                                duration: Duration(milliseconds: 1500),
                              ),
                            );
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            backgroundColor: _place!.isBookmark ? Colors.blue : Colors.grey,
                          ),
                          onPressed: _toggleBookmark,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _place!.isBookmark ? Icons.bookmark : Icons.bookmark_border,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '북마크',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            backgroundColor: Colors.indigoAccent,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddRecordScreen(placeId: _place!.id, placeName: _place!.name,),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_note, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '기록추가',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map,
                        color: Colors.blueAccent,
                        size: 16,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '수영장 지도',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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