import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:async';
import 'package:table_calendar/table_calendar.dart';
import 'config/app_config.dart';

// Place 모델을 정의합니다. (SwimDiaryScreen에서만 사용)
class Place {
  final int id;
  final String name;
  final String address;

  Place({
    required this.id,
    required this.name,
    required this.address,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }
}

// Record 모델을 정의합니다.
class Record {
  final int id;
  final String recordDate;
  final String startTime;
  final String endTime;
  final double poolLength;
  final int swimDistance;
  final String memo;
  final Place place;

  Record({
    required this.id,
    required this.recordDate,
    required this.startTime,
    required this.endTime,
    required this.poolLength,
    required this.swimDistance,
    required this.memo,
    required this.place,
  });

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      id: json['id'],
      recordDate: json['record_date'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      poolLength: (json['pool_length'] as num?)?.toDouble() ?? 0.0,
      swimDistance: json['swim_distance'] as int? ?? 0,
      memo: json['memo'] as String? ?? '',
      place: Place.fromJson(json['place']),
    );
  }
}

class SwimDiaryScreen extends StatefulWidget {
  const SwimDiaryScreen({super.key});

  @override
  _SwimDiaryScreenState createState() => _SwimDiaryScreenState();
}

class _SwimDiaryScreenState extends State<SwimDiaryScreen> {
  final _storage = const FlutterSecureStorage();
  final _scrollController = ScrollController();

  List<Record> _records = [];
  Map<DateTime, List<Record>> _recordsByDate = {}; // 날짜별 기록을 저장하는 맵
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _pageSize = 10;

  String? _errorMessage;

  // 달력 관련 상태 변수
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _fetchRecords(page: _currentPage);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 스크롤이 끝에 도달했을 때 다음 페이지를 불러오는 함수
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isFetchingMore &&
        _hasMoreData) {
      _fetchRecords(page: _currentPage + 1);
    }
  }

  // API에서 수영 기록을 가져오는 함수
  Future<void> _fetchRecords({required int page, bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _records = [];
        _recordsByDate = {}; // 맵 초기화
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
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
      return;
    }

    final queryParameters = {
      'page': page.toString(),
      'size': _pageSize.toString(),
    };

    final url = Uri.http(AppConfig.apiHost, '/records/', queryParameters);

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> items = responseData['result'];

        final newRecords = items.map((json) => Record.fromJson(json)).toList();

        // 날짜별 기록 맵에 추가
        for (var record in newRecords) {
          final date = DateTime.parse(record.recordDate);
          final normalizedDate = DateTime(date.year, date.month, date.day);
          if (_recordsByDate.containsKey(normalizedDate)) {
            _recordsByDate[normalizedDate]!.add(record);
          } else {
            _recordsByDate[normalizedDate] = [record];
          }
        }

        setState(() {
          _records.addAll(newRecords);
          _isLoading = false;
          _isFetchingMore = false;
          _currentPage = page;
          if (items.length < _pageSize) {
            _hasMoreData = false;
          }
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      } else {
        setState(() {
          _errorMessage = '수영 기록을 불러오는 데 실패했습니다: ${response.statusCode}';
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '네트워크 오류가 발생했습니다: $e';
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  // 특정 날짜의 총 수영 거리를 계산하는 헬퍼 함수
  int _getTotalDistanceForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final records = _recordsByDate[normalizedDay];
    if (records == null || records.isEmpty) {
      return 0;
    }
    return records.fold(0, (total, record) => total + record.swimDistance);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 탭의 개수
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title: const Text(
            '수영일기',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: '리스트'),
              Tab(text: '달력'),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildListView(),
            _buildCalendarView(),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
        ? Center(child: Text(_errorMessage!))
        : _records.isEmpty
        ? const Center(child: Text('수영 기록이 없습니다.'))
        : RefreshIndicator(
      onRefresh: () => _fetchRecords(page: 1, isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _records.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _records.length) {
            final record = _records[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(
                  record.place.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${record.recordDate} / ${record.startTime} ~ ${record.endTime}\n거리: ${record.swimDistance}m',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // 기록 상세 페이지로 이동하는 로직을 여기에 추가할 수 있습니다.
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => RecordDetailScreen(recordId: record.id)));
                },
              ),
            );
          } else {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              // 선택된 날짜에 맞는 기록을 보여주는 로직 추가
              // 예: _fetchRecordsByDate(selectedDay);
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: const CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          // 날짜 아래에 거리를 표시하는 빌더 추가
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              final totalDistance = _getTotalDistanceForDay(date);
              if (totalDistance > 0) {
                return Positioned(
                  bottom: 1,
                  child: Text(
                    '${totalDistance}m',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: Center(
            child: _selectedDay != null
                ? Text(
              '${_selectedDay!.toString().substring(0, 10)} 의 수영 기록입니다.',
              style: const TextStyle(fontSize: 18),
            )
                : const Text(
              '날짜를 선택해 기록을 확인하세요.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
