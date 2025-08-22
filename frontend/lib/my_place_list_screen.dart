import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:async';
import 'config/app_config.dart';
import 'place_detail_screen.dart';
import 'add_record_screen.dart';

// Place 모델
class Place {
  final int id;
  final String name;
  final String address;
  final bool isBookmark;
  final String imageUrl;

  Place({
    required this.id,
    required this.name,
    required this.address,
    required this.isBookmark,
    required this.imageUrl,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      isBookmark: true,
      imageUrl: json['image_url'] ?? '',
    );
  }
}

// Bookmark 모델
class Bookmark {
  final int id;
  final int placeId;
  final Place place;

  Bookmark({
    required this.id,
    required this.placeId,
    required this.place,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'],
      placeId: json['place_id'],
      place: Place.fromJson(json['place']),
    );
  }
}

class MyPlaceListScreen extends StatefulWidget {
  const MyPlaceListScreen({super.key});

  @override
  _MyPlaceListScreenState createState() => _MyPlaceListScreenState();
}

class _MyPlaceListScreenState extends State<MyPlaceListScreen> {
  final _storage = const FlutterSecureStorage();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  List<Place> _places = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _pageSize = 30;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPlaces(page: _currentPage);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore &&
        _hasMoreData) {
      _fetchPlaces(page: _currentPage + 1);
    }
  }

  Future<void> _fetchPlaces({required int page, bool isRefresh = false}) async {
    if (!mounted) return;

    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _places = [];
        _currentPage = 1;
        _hasMoreData = true;
      });
    } else {
      if (_isFetchingMore) return;
      setState(() {
        _isFetchingMore = true;
      });
    }

    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/');
      return;
    }

    final queryParameters = {
      'page': page.toString(),
      'size': _pageSize.toString(),
      'search': _searchController.text,
    };

    final url = Uri.http(AppConfig.apiHost, '/bookmarks/', queryParameters);

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> items = responseData['result'];

        setState(() {
          _places.addAll(items.map((json) {
            final bookmark = Bookmark.fromJson(json);
            return bookmark.place;
          }).toList());

          _isLoading = false;
          _isFetchingMore = false;
          _currentPage = page;
          if (items.length < _pageSize) {
            _hasMoreData = false;
          }
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        setState(() {
          _errorMessage = '장소 목록을 불러오는 데 실패했습니다: ${response.statusCode}';
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '네트워크 오류가 발생했습니다: $e';
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  Future<void> _addBookmark(int placeId, int index) async {
    final token = await _storage.read(key: 'jwt_token');
    if (!mounted) return;
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

      if (!mounted) return;

      if (response.statusCode == 200) {
        _updatePlaceBookmarkStatus(index, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크 추가 실패: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  Future<void> _deleteBookmark(int placeId, int index) async {
    final token = await _storage.read(key: 'jwt_token');
    if (!mounted) return;
    final url = Uri.parse('http://${AppConfig.apiHost}/bookmarks/$placeId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _places.removeAt(index);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크 삭제 실패: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네트워크 오류: $e')),
      );
    }
  }

  void _toggleBookmark(int index) {
    final place = _places[index];
    if (place.isBookmark) {
      _deleteBookmark(place.id, index);
    } else {
      _addBookmark(place.id, index);
    }
  }

  void _updatePlaceBookmarkStatus(int index, bool isBookmarked) {
    if (!mounted) return;
    setState(() {
      _places[index] = Place(
        id: _places[index].id,
        name: _places[index].name,
        address: _places[index].address,
        isBookmark: isBookmarked,
        imageUrl: _places[index].imageUrl,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          '내 수영장',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _places.isEmpty
                ? const Center(
              child: Text(
                '검색결과가 없습니다',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ):
            RefreshIndicator(
              onRefresh: () => _fetchPlaces(page: 1, isRefresh: true),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _places.length + (_hasMoreData ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _places.length) {
                    final place = _places[index];
                    return Column(
                      children: [
                        ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PlaceDetailScreen(placeId: place.id),
                              ),
                            );
                          },
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                place.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note, color: Colors.grey),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddRecordScreen(placeId: place.id, placeName: place.name,),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  place.isBookmark ? Icons.bookmark : Icons.bookmark_border,
                                  color: place.isBookmark ? Colors.blue : Colors.grey,
                                ),
                                onPressed: () {
                                  if (place.isBookmark) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('북마크 해제'),
                                          content: const Text('북마크를 해제하시겠습니까?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('취소'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                _toggleBookmark(index);
                                              },
                                              child: const Text('확인'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    _toggleBookmark(index);
                                  }
                                },
                              )
                            ]
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 16.0, right: 16.0),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

}
