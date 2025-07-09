import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local_data_source.dart';
import '../models/user_profile_model.dart';

class UserRepositoryImpl implements UserRepository {
  final LocalDataSource _localDataSource;
  final _uuid = const Uuid();
  static const String _defaultUserId = 'default_user';

  UserRepositoryImpl({
    required LocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<UserProfile?> getUserProfile() async {
    debugPrint('UserRepository: Fetching profile for user: $_defaultUserId');
    final model = await _localDataSource.getUserProfile(_defaultUserId);
    debugPrint('UserRepository: Model found: ${model != null}');
    if (model == null) {
      // プロファイルが存在しない場合はnullを返す（オンボーディング未完了）
      debugPrint('UserRepository: No profile found, returning null');
      return null;
    }
    final entity = model.toEntity();
    debugPrint('UserRepository: Converted to entity, isOnboardingCompleted: ${entity.isOnboardingCompleted}');
    return entity;
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    debugPrint('UserRepository: Saving profile with ID: ${profile.id}');
    debugPrint('UserRepository: isOnboardingCompleted: ${profile.isOnboardingCompleted}');
    final model = UserProfileModel.fromEntity(profile);
    debugPrint('UserRepository: Model isOnboardingCompleted: ${model.isOnboardingCompleted}');
    await _localDataSource.insertOrUpdateUserProfile(model);
    debugPrint('UserRepository: Profile saved to local data source');
  }

  @override
  Future<void> updatePoints(int points) async {
    final profile = await getUserProfile();
    if (profile != null) {
      final updatedProfile = profile.copyWith(
        points: profile.points + points,
      );
      await saveUserProfile(updatedProfile);
    }
  }

  @override
  Future<void> unlockAchievement(String achievementId) async {
    final profile = await getUserProfile();
    if (profile != null) {
      final achievementIndex = profile.achievements.indexWhere(
        (a) => a.id == achievementId,
      );
      
      if (achievementIndex != -1 && !profile.achievements[achievementIndex].isUnlocked) {
        final updatedAchievements = List<Achievement>.from(profile.achievements);
        updatedAchievements[achievementIndex] = 
            updatedAchievements[achievementIndex].unlock();
        
        final updatedProfile = profile.copyWith(
          achievements: updatedAchievements,
          points: profile.points + updatedAchievements[achievementIndex].points,
        );
        
        await saveUserProfile(updatedProfile);
      }
    }
  }
}