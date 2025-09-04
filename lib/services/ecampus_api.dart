// lib/services/ecampus_api.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/lecture.dart';

class EcampusApi {
  // 로컬/배포 환경에 맞게 수정
  static const String _baseUrl = 'http://192.168.0.42:8080/api';

  static Uri _u(String path) => Uri.parse('$_baseUrl$path');

  static Map<String, String> get _jsonHeaders => {
    'Content-Type': 'application/json',
  };

  static Future<http.Response> _postJson(String path, Map<String, dynamic> body) {
    return http
        .post(_u(path), headers: _jsonHeaders, body: jsonEncode(body))
        .timeout(const Duration(seconds: 12));
  }

  static Future<http.Response> _get(String path) {
    return http
        .get(_u(path), headers: _jsonHeaders)
        .timeout(const Duration(seconds: 12));
  }

  /// 자격 검증: 200이면 true
  static Future<bool> verifyCredentials({
    required String userId,
    required String userPw,
  }) async {
    try {
      final resp = await _postJson('/crawl/ecampus', {
        'userId': userId,
        'userPw': userPw,
      });
      return resp.statusCode == 200;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 강의 목록 가져오기 (crawler 응답 파싱)
  static Future<List<Lecture>> fetchLectures({
    required String userId,
    required String userPw,
  }) async {
    final res = await _postJson('/crawl/ecampus', {
      'userId': userId,
      'userPw': userPw,
    });

    if (res.statusCode != 200) {
      throw Exception('API ${res.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (decoded is! Map || decoded['courses'] is! List) {
      throw Exception('Unexpected JSON');
    }

    return (decoded['courses'] as List)
        .map((e) => Lecture.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 단일 강의 조회 (백엔드에 해당 엔드포인트가 있을 때)
  static Future<Lecture> fetchLecture(String lectureId) async {
    final response = await _get('/lectures/$lectureId');

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return Lecture.fromJson(decoded);
      } else {
        throw Exception('Unexpected JSON format: ${response.body}');
      }
    } else {
      throw Exception('Failed to load lecture: ${response.statusCode}');
    }
  }
}
