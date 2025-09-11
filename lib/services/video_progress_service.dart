// lib/services/video_progress_service.dart
import '../models/video_progress.dart';
import 'db_service.dart';

class VideoProgressService {
  final DBService _db = DBService();

  Future<void> saveProgressForCourseLink({
    required String courseLink,
    required List<VideoProgress> rows,
  }) async {
    final lectureId = await _db.getLectureIdByLink(courseLink);
    if (lectureId == null) throw StateError('lecture not found for link: $courseLink');
    await _db.replaceVideoProgressForLecture(lectureId, rows);
  }

  Future<void> saveProgressForLectureId({
    required int lectureId,
    required List<VideoProgress> rows,
  }) async {
    await _db.replaceVideoProgressForLecture(lectureId, rows);
  }

  Future<List<VideoProgress>> loadByLectureId(int lectureId) {
    return _db.getVideoProgressByLectureId(lectureId);
  }

  Future<List<VideoProgress>> loadByCourseLink(String courseLink) async {
    final id = await _db.getLectureIdByLink(courseLink);
    if (id == null) return [];
    return _db.getVideoProgressByLectureId(id);
  }

  Future<void> clearByLectureId(int lectureId) async {
    final rows = await _db.getVideoProgressByLectureId(lectureId);
    for (final r in rows) {
      if (r.id != null) {
        await _db.deleteVideoProgress(r.id!);
      }
    }
  }
}
