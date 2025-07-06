import 'package:uuid/uuid.dart';
import '../entities/sleep_session.dart';
import '../repositories/sleep_repository.dart';

class StartSleepTrackingUseCase {
  final SleepRepository _repository;
  final _uuid = const Uuid();

  StartSleepTrackingUseCase(this._repository);

  Future<SleepSession> execute() async {
    final activeSession = await _repository.getActiveSession();
    if (activeSession != null) {
      throw Exception('既にアクティブな睡眠記録があります');
    }

    final session = SleepSession(
      id: _uuid.v4(),
      startTime: DateTime.now(),
    );

    return await _repository.startSession(session);
  }
}