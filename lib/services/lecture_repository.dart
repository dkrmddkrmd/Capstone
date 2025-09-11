// services/lecture_repository.dart
import 'db_service.dart';
import 'lecture_service.dart';
import 'secure_storage.dart';
import '../models/lecture.dart';
import '../models/video_progress.dart'; // ✅ 추가

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

    // 1) 강의/과제 동기화
    await _db.syncCourses(remote);

    // 2) 비디오 진도 동기화 (있을 때만 교체 저장)
    await _saveVideoProgressFor(remote);

    return _db.getAllLecturesWithAssignments();
  }

  /// 수동 새로고침(또는 백그라운드에서 사용)
  Future<void> refreshFromApi() async {
    final (id, pw) = await SecureStore.readCreds();
    if (id == null || pw == null) return;

    final remote = await LectureService.fetchLectures(id, pw);

    // 1) 강의/과제 동기화
    await _db.syncCourses(remote);

    // 2) 비디오 진도 동기화 (있을 때만 교체 저장)
    await _saveVideoProgressFor(remote);
  }

  /// 서버에서 받은 강의 리스트에 담긴 videoProgress를 DB에 저장
  /// - Lecture.videoProgress 가 null이면: 건드리지 않음(서버가 안 보낸 경우 기존 유지)
  /// - Lecture.videoProgress 가 []이면: 기존 것을 비움(서버가 "없음"을 의미)
  Future<void> _saveVideoProgressFor(List<Lecture> lectures) async {
    for (final lec in lectures) {
      final List<VideoProgress>? rows = lec.videoProgress;
      if (rows == null) continue; // 서버가 이 강의의 진도 정보를 안 보냈음 → 기존 유지

      final lectureId = await _db.getLectureIdByLink(lec.link);
      if (lectureId == null) continue;

      // 전량 교체 저장 (UNIQUE(lecture_id, title, week)로 id 없이 upsert)
      await _db.replaceVideoProgressForLecture(lectureId, rows);
    }
  }
}
