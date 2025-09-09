import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../services/db_service.dart';
import '../services/secure_storage.dart';

class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  static const Color smBlue = Color(0xFF1A3276);

  final _formKey = GlobalKey<FormState>();
  final _idC = TextEditingController();
  final _pwC = TextEditingController();

  bool _isBusy = false;
  bool _obscurePw = true;

  @override
  void initState() {
    super.initState();
    _loadSavedId();
  }

  Future<void> _loadSavedId() async {
    final creds = await SecureStore.getCreds();
    final savedId = creds['id'];
    if (savedId != null && savedId.isNotEmpty) {
      setState(() {
        _idC.text = savedId;
      });
    }
  }

  @override
  void dispose() {
    _idC.dispose();
    _pwC.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isBusy = true);
    try {
      final userId = _idC.text.trim();
      final newPw = _pwC.text;

      // 0) 유저 존재 여부 확인
      final exists = await DBService().hasUser(userId);
      if (!exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('존재하지 않는 아이디입니다. 먼저 등록해 주세요.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 1) 로컬 DB 비밀번호 업데이트
      final changed = await DBService().updateUserPassword(userId, newPw);
      if (changed == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('비밀번호 변경에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2) 보안 저장소 자격 갱신
      await SecureStore.saveCreds(userId, newPw);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 변경되었습니다.')),
      );
      Navigator.pop(context);
    } on DatabaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('DB 오류: ${e.toString()}'), backgroundColor: Colors.red),
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
          title: const Text('등록하기'), // 그대로 유지
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
                    hintText: '변경된 비밀번호',
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
                  (v == null || v.isEmpty) ? '변경된 비밀번호를 입력해 주세요' : null,
                  enabled: !_isBusy,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _update,
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
                      '변경하기',
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
