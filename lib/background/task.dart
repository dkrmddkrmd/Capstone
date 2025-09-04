// background/task.dart
import 'dart:async';
import 'package:workmanager/workmanager.dart';
import '../services/lecture_repository.dart';

const String kTaskCrawlSync = 'crawl_sync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == kTaskCrawlSync) {
      try {
        await LectureRepository().refreshFromApi();
        return Future.value(true);
      } catch (_) {
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}
