import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

/// Reads only today's step total from the user's chosen Health Connect sources.
class HealthConnectService {
  final Health _health = Health();

  Future<int?> connectAndReadTodaySteps() async {
    await _health.configure();
    final activityPermission = await Permission.activityRecognition.request();
    if (!activityPermission.isGranted) return null;
    const types = [HealthDataType.STEPS];
    if (!await _health.requestAuthorization(types)) return null;
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return _health.getTotalStepsInInterval(midnight, now);
  }
}
