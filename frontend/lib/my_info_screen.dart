import 'package:flutter/material.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // dotenv 추가
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'; // 카카오 SDK 추가
import 'config/app_config.dart';
import 'login_screen.dart';
import 'register_screen.dart'; // 로그인/회원가입 화면

class MyInfoScreen extends StatefulWidget {
  const MyInfoScreen({super.key});

  @override
  _MyInfoScreenState createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends State<MyInfoScreen> {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic> _userInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final jwtToken = await _storage.read(key: 'jwt_token');

      if (jwtToken == null) {
        throw Exception('토큰이 없습니다. 로그인이 필요합니다.');
      }

      final url = Uri.parse('http://${AppConfig.apiHost}/users/me');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _userInfo = userData;
          _isLoading = false;
        });
      } else {
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('사용자 정보 로딩 실패: $e');
      setState(() {
        _isLoading = false;
      });
      _logout('local'); // 토큰이 유효하지 않으면 로그아웃 처리
    }
  }

  Future<void> _logout(String provider) async {
    if (provider == 'kakao') {
      try {
        await UserApi.instance.logout();
        debugPrint('카카오 로그아웃 성공');
      } catch (error) {
        debugPrint('카카오 로그아웃 실패: $error');
      }
    } else if (provider == 'naver') {
      try {
        final NaverLoginResult res = await FlutterNaverLogin.logOut();
        if (res.status == NaverLoginStatus.loggedOut) {
          debugPrint('네이버 로그아웃 성공');
        }
      } catch (error) {
        debugPrint('네이버 로그아웃 실패: $error');
      }
    } else if (provider == 'google') {
      try {
        await GoogleSignIn().signOut();
        debugPrint('구글 로그아웃 성공');
      } catch (error) {
        debugPrint('구글 로그아웃 실패: $error');
      }
    } else {

    }

    await _storage.delete(key: 'jwt_token');
    debugPrint('JWT 토큰 삭제 완료');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    String loginMessage;
    switch (_userInfo['provider']) {
      case 'kakao':
        loginMessage = '카카오로 로그인하였습니다.';
        break;
      case 'naver':
        loginMessage = '네이버로 로그인하였습니다.';
        break;
      case 'google':
        loginMessage = '구글로 로그인하였습니다.';
        break;
      default:
        loginMessage = '이메일로 로그인하였습니다.';
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          '내 정보',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 80,
                backgroundImage: _userInfo['profile_image'] != null
                    ? NetworkImage(_userInfo['profile_image']) as ImageProvider
                    : const AssetImage('assets/images/fin_icon.png') as ImageProvider,
                onBackgroundImageError: (exception, stackTrace) {
                  debugPrint('프로필 이미지 로딩 실패: $exception');
                },
              ),
              const SizedBox(height: 30),
              _buildInfoContainer('닉네임', _userInfo['nickname'] ?? '닉네임'),
              const SizedBox(height: 10),
              _buildInfoContainer('이메일', _userInfo['email'] ?? '이메일'),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  loginMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _logout(_userInfo['provider'] ?? 'local'),
                child: const Text('로그아웃'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoContainer(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
