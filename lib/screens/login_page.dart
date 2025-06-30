import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const Color sangmyungBlue = Color(0xFF1A3276); // 상명대 남색

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 이미지
              const CircleAvatar(
                radius: 100,
                backgroundImage: AssetImage('assets/sangmyung.jpg'),
              ),
              const SizedBox(height: 40),

              // 아이디 입력창
              TextField(
                style: const TextStyle(color: sangmyungBlue),
                decoration: InputDecoration(
                  hintText: '아이디',
                  hintStyle: const TextStyle(color: sangmyungBlue),
                  prefixIcon: const Icon(Icons.person, color: sangmyungBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 비밀번호 입력창
              TextField(
                obscureText: true,
                style: const TextStyle(color: sangmyungBlue),
                decoration: InputDecoration(
                  hintText: '비밀번호',
                  hintStyle: const TextStyle(color: sangmyungBlue),
                  prefixIcon: const Icon(Icons.key, color: sangmyungBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 로그인 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: sangmyungBlue,
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
    );
  }
}
