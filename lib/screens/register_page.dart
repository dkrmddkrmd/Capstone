import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../services/db_service.dart';
import '../services/ecampus_api.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color smBlue = Color(0xFF1A3276);

  final _formKey = GlobalKey<FormState>();
  final _idC = TextEditingController();
  final _pwC = TextEditingController();

  bool _isBusy = false;
  bool _obscurePw = true;

  @override
  void dispose() {
    _idC.dispose();
    _pwC.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isBusy = true);
    try {
      final userId = _idC.text.trim();
      final userPw = _pwC.text;

      // 1) 서버로 자격 검증
      final ok = await EcampusApi.verifyCredentials(userId: userId, userPw: userPw);

      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('아이디와 비밀번호를 확인해주세요'),
            backgroundColor: Colors.red,
          ),
        );
        return; // 저장하지 않음
      }

      // 2) 검증 성공 시 로컬 DB 저장
      await DBService().createUser(userId, userPw);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록 완료! 로그인 페이지로 돌아갑니다.')),
      );
      Navigator.pop(context);
    } on DatabaseException catch (e) {
      String msg = '등록 실패';
      if (e.isUniqueConstraintError()) msg = '이미 존재하는 아이디입니다.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('등록하기'),
          backgroundColor: smBlue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _idC,
                  decoration: InputDecoration(
                    hintText: '아이디',
                    prefixIcon: const Icon(Icons.person, color: smBlue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '아이디를 입력해 주세요' : null,
                  enabled: !_isBusy,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pwC,
                  obscureText: _obscurePw,
                  decoration: InputDecoration(
                    hintText: '비밀번호',
                    prefixIcon: const Icon(Icons.key, color: smBlue),
                    suffixIcon: IconButton(
                      onPressed: _isBusy
                          ? null
                          : () => setState(() => _obscurePw = !_obscurePw),
                      icon: Icon(
                        _obscurePw ? Icons.visibility : Icons.visibility_off,
                        color: smBlue,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? '비밀번호를 입력해 주세요' : null,
                  enabled: !_isBusy,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: smBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isBusy
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text(
                      '등록하기',
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
    );
  }
}
