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
    
    try {
      await _calculateAndAddPoints(endedSession);
    } catch (e) {
      // ポイント計算に失敗してもセッション終了は成功とする
      debugPrint('Failed to calculate points: $e');
    }
    
    return endedSession;
  }

  Future<void> _calculateAndAddPoints(SleepSession session) async {
    int points = 0;
    
    final hours = session.calculatedDuration.inHours;
    if (hours >= 7 && hours <= 9) {
      points += 100;
    } else if (hours >= 6 && hours <= 10) {
      points += 50;
    } else {
      points += 25;
    }
    
    if (session.qualityScore != null && session.qualityScore! >= 80) {
      points += 50;
    }
    
    await _userRepository.updatePoints(points);
  }
}