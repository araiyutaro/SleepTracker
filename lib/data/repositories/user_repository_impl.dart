import 'package:flutter/foundation.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local_data_source.dart';
import '../models/user_profile_model.dart';

class UserRepositoryImpl implements UserRepository {
  final LocalDataSource _localDataSource;
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

}