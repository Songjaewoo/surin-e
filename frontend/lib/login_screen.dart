import 'package:flutter/material.dart';
import 'package:frontend/register_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:water_animation/water_animation.dart';
import 'dart:convert';
import 'config/app_config.dart';
import 'main_screen.dart';
import 'social_auth_service.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  final _socialAuthService = SocialAuthService();

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final response = await http.post(
          Uri.parse('http://${AppConfig.apiHost}/users/login/local'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text,
            'password': _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final jwtToken = responseData['access_token'];
          await _storage.write(key: 'jwt_token', value: jwtToken);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else if (response.statusCode == 401) {
          debugPrint('Login failed: ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                content: Text('이메일 또는 비밀번호를 확인해주세요.')),
          );
        } else {
          debugPrint('Network error: ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
          );
        }
      } catch (e) {
        debugPrint('Network error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: Transform.rotate(
              angle: math.pi, // 180도 회전
              child: WaterAnimation(
                width: MediaQuery.of(context).size.width,
                height: 300,
                waterFillFraction: 0.8,
                fillTransitionDuration: const Duration(seconds: 1),
                fillTransitionCurve: Curves.easeInOut,
                amplitude: 20,
                frequency: 1,
                speed: 3,
                waterColor: Colors.blue,
                gradientColors: const [Colors.blue, Colors.lightBlueAccent],
                enableRipple: true,
                enableShader: true,
                enableSecondWave: true,
                secondWaveColor: Colors.blueAccent,
                secondWaveAmplitude: 10.0,
                secondWaveFrequency: 1.5,
                secondWaveSpeed: 1.0,
                realisticWave: false,
              ),
            ),
          ),
          Align(
            alignment: Alignment(0.0, -0.3),
            child: SizedBox(
              height: 100, // Match the height of the WaterAnimation
              width: 100,
              child: Image.asset('assets/images/swim_icon.png', fit: BoxFit.cover),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 250),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: '이메일',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '이메일을 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: '비밀번호',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '비밀번호를 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            backgroundColor: Colors.indigoAccent,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text(
                              '로그인',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onPressed: () {
                            _login();
                          },
                        ),
                      ),
                      const SizedBox(height: 13),
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey, thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SNS계정으로 간편하게 로그인/회원가입',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => {
                              _socialAuthService.login(context, 'kakao')
                            },
                            child: SizedBox(
                              child: Image.asset('assets/images/login_kakao.png', width:45, height: 45,),
                            ),
                          ),
                          const SizedBox(width: 15.0),
                          GestureDetector(
                            onTap: () => {
                              _socialAuthService.login(context, 'naver')
                            },
                            child: SizedBox(
                              child: Image.asset('assets/images/login_naver.png', width:45, height: 45,),
                            ),
                          ),
                          const SizedBox(width: 15.0),
                          GestureDetector(
                            onTap: () => {
                              _socialAuthService.login(context, 'google')
                            },
                            child: SizedBox(
                              child: Image.asset('assets/images/login_google.png', width:45, height: 45,),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.black54,
                                width: 0.8,
                              ),
                            ),
                          ),
                          child: const Text(
                            '이메일로 회원가입',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                        )
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
