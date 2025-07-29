import 'package:flutter/material.dart';
import '../entities/sleep_session.dart';
import '../repositories/sleep_repository.dart';
import '../repositories/user_repository.dart';

class EndSleepTrackingUseCase {
  final SleepRepository _sleepRepository;
  final UserRepository _userRepository;

  EndSleepTrackingUseCase(
    this._sleepRepository,
    this._userRepository,
  );

  Future<SleepSession> execute() async {
    final activeSession = await _sleepRepository.getActiveSession();
    if (activeSession == null) {
      throw Exception('アクティブな睡眠記録がありません');
    }

    SleepSession endedSession;
    try {
      endedSession = await _sleepRepository.endSession(activeSession.id);
    } catch (e) {
      throw Exception('睡眠記録の終了に失敗しました: $e');
    }
    
    
    return endedSession;
  }

}