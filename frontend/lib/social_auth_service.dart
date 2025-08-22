import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_token.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';

import 'config/app_config.dart';
import 'main_screen.dart';

class SocialAuthService {
  final _storage = const FlutterSecureStorage();

  Future<void> login(BuildContext context, String provider) async {
    if (provider == 'kakao') {
      OAuthToken? token;
      try {
        if (await isKakaoTalkInstalled()) {
          token = await UserApi.instance.loginWithKakaoTalk();
        } else {
          token = await UserApi.instance.loginWithKakaoAccount();
        }

        if (token != null) {
          var res = await http.post(
            Uri.parse('http://${AppConfig.apiHost}/users/login/kakao'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'access_token': token.accessToken}),
          );

          if (res.statusCode == 200) {
            final responseData = jsonDecode(res.body);
            final jwtToken = responseData['access_token'];
            await _storage.write(key: 'jwt_token', value: jwtToken);
            debugPrint('로그인 성공! 토큰: $jwtToken');

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
                  (Route<dynamic> route) => false,
            );
          } else {
            debugPrint('서버 로그인 실패: ${res.body}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('서버 로그인 실패')),
            );
          }
        }
      } on PlatformException catch (error) {
        if (error.code == 'CANCELED') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인 취소')),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 실패: 다시 시도해주세요.')),
        );
      } catch (error) {
        debugPrint('aaaa $error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 실패: 다시 시도해주세요.')),
        );
      }
    } else if (provider == 'naver') {
      try {
        final NaverLoginResult res = await FlutterNaverLogin.logIn();

        if (res.status == NaverLoginStatus.loggedIn) {
          final accessToken = res.accessToken;
          debugPrint('네이버 로그인 성공! 액세스 토큰: $accessToken');

          var serverRes = await http.post(
            Uri.parse('http://${AppConfig.apiHost}/users/login/naver'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'access_token': accessToken?.accessToken}),
          );

          if (serverRes.statusCode == 200) {
            final responseData = jsonDecode(serverRes.body);
            final jwtToken = responseData['access_token'];
            await _storage.write(key: 'jwt_token', value: jwtToken);
            debugPrint('서버 로그인 성공! 토큰: $jwtToken');

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
                  (Route<dynamic> route) => false,
            );
          } else {
            debugPrint('서버 로그인 실패: ${serverRes.body}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('서버 로그인 실패')),
            );
          }
        }
      } on PlatformException catch (error) {
        debugPrint('네이버 로그인 플랫폼 오류: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('네이버 로그인 실패: 다시 시도해주세요.')),
        );
      } catch (error) {
        debugPrint('네이버 로그인 일반 오류: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('네이버 로그인 실패: 다시 시도해주세요.')),
        );
      }
    } else if (provider == 'google') {
      try {
        final googleSignIn = GoogleSignIn(scopes: ['email']);
        final googleUser = await googleSignIn.signIn();

        if (googleUser != null) {
          final googleAuth = await googleUser.authentication;
          final accessToken = googleAuth.accessToken;

          if (accessToken != null) {
            var serverRes = await http.post(
              Uri.parse('http://${AppConfig.apiHost}/users/login/google'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'access_token': accessToken}),
            );

            if (serverRes.statusCode == 200) {
              final responseData = jsonDecode(serverRes.body);
              final jwtToken = responseData['access_token'];
              await _storage.write(key: 'jwt_token', value: jwtToken);
              debugPrint('구글 서버 로그인 성공! 토큰: $jwtToken');

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
                    (Route<dynamic> route) => false,
              );
            } else {
              debugPrint('구글 서버 로그인 실패: ${serverRes.body}');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('구글 서버 로그인 실패')),
              );
            }
          } else {
            debugPrint('Google ID 토큰을 가져오지 못했습니다.');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('구글 로그인 실패: ID 토큰 없음')),
            );
          }
        } else {
          debugPrint('구글 로그인 취소 또는 실패');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('구글 로그인 취소')),
          );
        }
      } catch (error) {
        debugPrint('구글 로그인 오류: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구글 로그인 실패: 다시 시도해주세요.')),
        );
      }
    }
  }
}