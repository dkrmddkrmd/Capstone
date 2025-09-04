// services/lecture_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lecture.dart';

// services/lecture_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lecture.dart';

class LectureService {
  static const String baseUrl = 'http://192.168.0.42:8080/api';

  static Future<List<Lecture>> fetchLectures(String userId, String userPw) async {
    final res = await http.post(
      Uri.parse('$baseUrl/crawl/ecampus'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'userPw': userPw}),
    );
    if (res.statusCode != 200) {
      throw Exception('API ${res.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (decoded is! Map || decoded['courses'] is! List) {
      throw Exception('Unexpected JSON');
    }
    final list = (decoded['courses'] as List)
        .map((e) => Lecture.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }


  // 특정 강의 조회
  static Future<Lecture> fetchLecture(String lectureId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lectures/$lectureId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

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
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
