import 'package:flutter/material.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../../services/notification_service.dart';
import '../../services/analytics_service.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  final NotificationService _notificationService = NotificationService();
  UserProfile? _userProfile;

  UserProvider({
    required UserRepository userRepository,
  }) : _userRepository = userRepository;

  UserProfile? get userProfile => _userProfile;
  UserProfile? get profile => _userProfile;

  Future<void> initialize() async {
    await _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _notificationService.initialize();
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
      // 通知サービスの初期化に失敗してもアプリを継続
    }
    
    try {
      await _loadUserProfile();
      await _scheduleNotifications();
    } catch (e) {
      debugPrint('UserProfile initialization failed: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    debugPrint('Loading user profile from repository...');
    _userProfile = await _userRepository.getUserProfile();
    debugPrint('Loaded profile: ${_userProfile != null}');
    if (_userProfile != null) {
      debugPrint('Profile ID: ${_userProfile!.id}');
      debugPrint('isOnboardingCompleted: ${_userProfile!.isOnboardingCompleted}');
    }
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
    await _scheduleNotifications();
    notifyListeners();
  }

  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    if (_userProfile == null) return;

    final updatedProfile = _userProfile!.copyWith(
      notificationSettings: settings,
    );

    await _userRepository.saveUserProfile(updatedProfile);
    _userProfile = updatedProfile;
    await _scheduleNotifications();
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

  Future<void> _scheduleNotifications() async {
    if (_userProfile == null) return;

    try {
      final settings = _userProfile!.notificationSettings;

      if (settings.bedtimeReminderEnabled) {
        await _notificationService.scheduleBedtimeReminder(
          bedtime: _userProfile!.targetBedtime,
          reminderMinutes: settings.bedtimeReminderMinutes,
        );
      }

      if (settings.wakeUpAlarmEnabled) {
        await _notificationService.scheduleWakeUpAlarm(
          wakeTime: _userProfile!.targetWakeTime,
          enabled: true,
        );
      }

      if (settings.weeklyReportEnabled) {
        await _notificationService.scheduleWeeklyReport();
      }
    } catch (e) {
      debugPrint('Failed to schedule notifications: $e');
      // テスト環境では通知サービスが利用できないため、エラーを無視
    }
  }

  Future<void> showSleepQualityNotification({
    required double qualityScore,
    required Duration sleepDuration,
  }) async {
    try {
      if (_userProfile?.notificationSettings.sleepQualityNotificationEnabled == true) {
        await _notificationService.showSleepQualityNotification(
          qualityScore: qualityScore,
          sleepDuration: sleepDuration,
        );
      }
    } catch (e) {
      debugPrint('Failed to show sleep quality notification: $e');
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    debugPrint('UserProvider: Saving profile with ID: ${profile.id}');
    debugPrint('UserProvider: isOnboardingCompleted: ${profile.isOnboardingCompleted}');
    await _userRepository.saveUserProfile(profile);
    debugPrint('UserProvider: Profile saved to repository');
    
    // Analytics: ユーザー属性を設定
    await AnalyticsService().setUserProperties(
      userId: profile.id,
      ageGroup: profile.ageGroup,
      gender: profile.gender,
      occupation: profile.occupation,
    );
    
    _userProfile = profile;
    await _scheduleNotifications();
    notifyListeners();
    debugPrint('UserProvider: State updated and listeners notified');
  }
}