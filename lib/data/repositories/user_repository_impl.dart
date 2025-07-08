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
    final model = await _localDataSource.getUserProfile(_defaultUserId);
    if (model == null) {
      // プロファイルが存在しない場合はnullを返す（オンボーディング未完了）
      return null;
    }
    return model.toEntity();
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    final model = UserProfileModel.fromEntity(profile);
    await _localDataSource.insertOrUpdateUserProfile(model);
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