import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color smBlue = Color(0xFF1A3276); // 상명대 남색

  // ③ 폼 키 & 컨트롤러
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  // ④ 비밀번호 필드 포커스
  final FocusNode _pwFocus = FocusNode();

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  void _submit() {
    // ③ 유효성 검사 통과 시에만 진행
    if (_formKey.currentState?.validate() != true) return;

    // TODO: 실제 로그인 API 연동(내일)
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 빈 공간 탭 → 키보드 닫기
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey, // ③ Form 추가
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 로고 이미지
                  const CircleAvatar(
                    radius: 100,
                    backgroundImage: AssetImage('assets/sangmyung.jpg'),
                  ),
                  const SizedBox(height: 40),

                  // 아이디 입력
                  TextFormField(
                    controller: _idController,
                    textInputAction: TextInputAction.next, // ②: "다음"
                    style: const TextStyle(color: smBlue),
                    decoration: InputDecoration(
                      hintText: '아이디',
                      hintStyle: const TextStyle(color: smBlue),
                      prefixIcon: const Icon(Icons.person, color: smBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // ④: 아이디 제출 시 비번으로 포커스
                    onFieldSubmitted: (_) => _pwFocus.requestFocus(),
                    // ③: 간단 validator
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '아이디를 입력해 주세요' : null,
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호 입력
                  TextFormField(
                    controller: _pwController,
                    focusNode: _pwFocus, // ④: 포커스 대상
                    obscureText: true,
                    textInputAction: TextInputAction.done, // ②: "완료"
                    style: const TextStyle(color: smBlue),
                    decoration: InputDecoration(
                      hintText: '비밀번호',
                      hintStyle: const TextStyle(color: smBlue),
                      prefixIcon: const Icon(Icons.key, color: smBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // ④: 완료 → 제출
                    onFieldSubmitted: (_) => _submit(),
                    // ③: 간단 validator
                    validator: (v) =>
                        (v == null || v.isEmpty) ? '비밀번호를 입력해 주세요' : null,
                  ),
                  const SizedBox(height: 24),

                  // 로그인 버튼 (원래 스타일 유지)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: smBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        '로그인',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
