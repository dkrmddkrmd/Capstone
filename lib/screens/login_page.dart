import 'package:flutter/material.dart';
import '../services/secure_storage.dart'; // ✅ 자격 저장용

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color smBlue = Color(0xFF1A3276); // 상명대 남색

  // 폼 키 & 컨트롤러
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  // 비밀번호 필드 포커스
  final FocusNode _pwFocus = FocusNode();

  bool _isBusy = false; // ✅ 로딩 상태

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isBusy = true);
    try {
      final id = _idController.text.trim();
      final pw = _pwController.text;

      // TODO: 실제 로그인 API 검증 로직이 들어갈 자리 (성공 시에만 아래 저장 실행)
      // await AuthService.login(id, pw);

      // ✅ 자격 저장 (백그라운드 동기화 & 홈 진입 시 필요)
      await SecureStore.saveCreds(id, pw);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
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
              key: _formKey,
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
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: smBlue),
                    decoration: InputDecoration(
                      hintText: '아이디',
                      hintStyle: const TextStyle(color: smBlue),
                      prefixIcon: const Icon(Icons.person, color: smBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onFieldSubmitted: (_) => _pwFocus.requestFocus(),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '아이디를 입력해 주세요' : null,
                    enabled: !_isBusy,
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호 입력
                  TextFormField(
                    controller: _pwController,
                    focusNode: _pwFocus,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: smBlue),
                    decoration: InputDecoration(
                      hintText: '비밀번호',
                      hintStyle: const TextStyle(color: smBlue),
                      prefixIcon: const Icon(Icons.key, color: smBlue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) =>
                    (v == null || v.isEmpty) ? '비밀번호를 입력해 주세요' : null,
                    enabled: !_isBusy,
                  ),
                  const SizedBox(height: 24),

                  // 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isBusy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: smBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isBusy
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text(
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
