import 'package:flutter/material.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository;
  UserProfile? _userProfile;

  UserProvider({
    required UserRepository userRepository,
  }) : _userRepository = userRepository {
    _loadUserProfile();
  }

  UserProfile? get userProfile => _userProfile;

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
}