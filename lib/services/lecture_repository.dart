// services/lecture_repository.dart
import 'db_service.dart';
import 'lecture_service.dart';
import 'secure_storage.dart';
import '../models/lecture.dart';

class LectureRepository {
  final _db = DBService();

  /// 앱에서 강의 목록 요청할 때 호출:
  /// - DB 비어있으면: API 호출→저장→DB에서 반환
  /// - DB 있으면: DB에서 바로 반환
  Future<List<Lecture>> getLecturesPreferLocal() async {
    final count = await _db.lecturesCount();
    if (count > 0) {
      return _db.getAllLecturesWithAssignments();
    }
    // 첫 가입/최초 실행 → API로 채우기
    final (id, pw) = await SecureStore.readCreds();
    if (id == null || pw == null) {
      throw Exception('No credentials saved');
    }
    final remote = await LectureService.fetchLectures(id, pw);
    await _db.saveCourses(remote);
    return _db.getAllLecturesWithAssignments();
  }

  /// 수동 새로고침(또는 백그라운드에서 사용)
  Future<void> refreshFromApi() async {
    final (id, pw) = await SecureStore.readCreds();
    if (id == null || pw == null) return;
    final remote = await LectureService.fetchLectures(id, pw);
    await _db.saveCourses(remote);
  }
}
