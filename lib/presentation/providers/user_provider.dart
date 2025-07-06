import 'package:flutter/material.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../../services/notification_service.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  final NotificationService _notificationService = NotificationService();
  UserProfile? _userProfile;

  UserProvider({
    required UserRepository userRepository,
  }) : _userRepository = userRepository {
    _initialize();
  }

  UserProfile? get userProfile => _userProfile;

  Future<void> _initialize() async {
    await _notificationService.initialize();
    await _loadUserProfile();
    _scheduleNotifications();
  }

  Future<void> _loadUserProfile() async {
    _userProfile = await _userRepository.getUserProfile();
    notifyListeners();
  }

  Future<void> updateSettings({
    double? targetSleepHours,
    TimeOfDay? targetBedtime,
    TimeOfDay? targetWakeTime,
  }) async {
    if (_userProfile == null) return;

    final updatedProfile = _userProfile!.copyWith(
      targetSleepHours: targetSleepHours,
      targetBedtime: targetBedtime,
      targetWakeTime: targetWakeTime,
    );

    await _userRepository.saveUserProfile(updatedProfile);
    _userProfile = updatedProfile;
    _scheduleNotifications();
    notifyListeners();
  }

  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    if (_userProfile == null) return;

    final updatedProfile = _userProfile!.copyWith(
      notificationSettings: settings,
    );

    await _userRepository.saveUserProfile(updatedProfile);
    _userProfile = updatedProfile;
    _scheduleNotifications();
    notifyListeners();
  }

  Future<void> addPoints(int points) async {
    await _userRepository.updatePoints(points);
    await _loadUserProfile();
  }

  Future<void> unlockAchievement(String achievementId) async {
    await _userRepository.unlockAchievement(achievementId);
    await _loadUserProfile();
  }

  Future<bool> requestNotificationPermissions() async {
    return await _notificationService.requestPermissions();
  }

  void _scheduleNotifications() {
    if (_userProfile == null) return;

    final settings = _userProfile!.notificationSettings;

    if (settings.bedtimeReminderEnabled) {
      _notificationService.scheduleBedtimeReminder(
        bedtime: _userProfile!.targetBedtime,
        reminderMinutes: settings.bedtimeReminderMinutes,
      );
    }

    if (settings.wakeUpAlarmEnabled) {
      _notificationService.scheduleWakeUpAlarm(
        wakeTime: _userProfile!.targetWakeTime,
        enabled: true,
      );
    }

    if (settings.weeklyReportEnabled) {
      _notificationService.scheduleWeeklyReport();
    }
  }

  Future<void> showSleepQualityNotification({
    required double qualityScore,
    required Duration sleepDuration,
  }) async {
    if (_userProfile?.notificationSettings.sleepQualityNotificationEnabled == true) {
      await _notificationService.showSleepQualityNotification(
        qualityScore: qualityScore,
        sleepDuration: sleepDuration,
      );
    }
  }
}