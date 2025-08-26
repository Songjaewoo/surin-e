import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/app_config.dart';

class AddRecordScreen extends StatefulWidget {
  final int placeId;
  final String placeName;

  const AddRecordScreen({super.key, required this.placeId, required this.placeName});

  @override
  _AddRecordScreenState createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  final _poolLengthController = TextEditingController();
  final _swimDistanceController = TextEditingController();
  final _memoController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _poolLengthController.dispose();
    _swimDistanceController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
        return;
      }

      final recordData = {
        'place_id': widget.placeId,
        'record_date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        'start_time': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        'end_time': '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        'pool_length': int.parse(_poolLengthController.text),
        'swim_distance': int.parse(_swimDistanceController.text),
        'memo': _memoController.text,
      };

      try {
        final url = Uri.http(AppConfig.apiHost, '/records/');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(recordData),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('기록이 성공적으로 저장되었습니다.')),
            );
            Navigator.of(context).pop();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('기록 저장 실패: ${response.body}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('네트워크 오류가 발생했습니다: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            '기록 추가',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '장소 ID: ${widget.placeId} ${widget.placeName}',
                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 날짜 선택
              ListTile(
                title: Text('날짜: ${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),

              // 시작 시간 및 종료 시간 선택
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text('시작 시간: ${_startTime.format(context)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context, true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text('종료 시간: ${_endTime.format(context)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _selectTime(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 수영장 길이
              TextFormField(
                controller: _poolLengthController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '수영장 길이 (m)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '수영장 길이를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 수영 거리
              TextFormField(
                controller: _swimDistanceController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '수영 거리 (m)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '수영 거리를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 메모
              TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '메모',
                  hintText: '오늘의 수영에 대한 간단한 기록을 남겨보세요.',
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveRecord,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
