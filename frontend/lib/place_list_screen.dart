import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:async';
import 'config/app_config.dart';
import 'place_detail_screen.dart';

// Place 모델
class Place {
  final int id;
  final String name;
  final String address;
  final bool isBookmark;
  final String xPos;
  final String yPos;
  final String imageUrl;

  Place({
    required this.id,
    required this.name,
    required this.address,
    required this.isBookmark,
    required this.xPos,
    required this.yPos,
    required this.imageUrl,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      isBookmark: json['is_bookmark'] ?? false,
      xPos: json['x_position'],
      yPos: json['y_position'],
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class PlaceListScreen extends StatefulWidget {
  const PlaceListScreen({super.key});

  @override
  _PlaceListScreenState createState() => _PlaceListScreenState();
}

class _PlaceListScreenState extends State<PlaceListScreen> {
  final _storage = const FlutterSecureStorage();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  List<Place> _places = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _pageSize = 30;

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
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

    final url = Uri.http(AppConfig.apiHost, '/places/', queryParameters);

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
          _places.addAll(items.map((json) => Place.fromJson(json)).toList());
          _isLoading = false;
          _isFetchingMore = false;
          _currentPage = page;
          if (items.length < _pageSize) _hasMoreData = false;
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/');
      } else {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
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
        _updatePlaceBookmarkStatus(index, false);
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
        xPos: _places[index].xPos,
        yPos: _places[index].yPos,
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
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 43.0,
            child: SearchBar(
              controller: _searchController,
              hintText: '수영장 검색',
              leading: const Icon(Icons.search),
              onSubmitted: (query) {
                _fetchPlaces(page: 1, isRefresh: true);
              },
              trailing: [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _fetchPlaces(page: 1, isRefresh: true);
                  },
                ),
              ],
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
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
                          trailing: IconButton(
                            icon: Icon(
                              place.isBookmark
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: place.isBookmark ? Colors.blue : Colors.grey,
                            ),
                            onPressed: () => _toggleBookmark(index),
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
