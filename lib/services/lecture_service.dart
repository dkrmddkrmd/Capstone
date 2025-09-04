// lib/services/lecture_service.dart
import '../models/lecture.dart';
import 'ecampus_api.dart';

class LectureService {
  // /crawl/ecampus 통해 강의 목록
  static Future<List<Lecture>> fetchLectures(String userId, String userPw) {
    return EcampusApi.fetchLectures(userId: userId, userPw: userPw);
  }

  // 단일 강의
  static Future<Lecture> fetchLecture(String lectureId) {
    return EcampusApi.fetchLecture(lectureId);
  }
}
