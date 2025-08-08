import 'package:flutter/foundation.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local_data_source.dart';
import '../models/user_profile_model.dart';
import '../../services/firestore_service.dart';

class UserRepositoryImpl implements UserRepository {
  final LocalDataSource _localDataSource;
  final FirestoreService _firestoreService;

  UserRepositoryImpl({
    required LocalDataSource localDataSource,
  }) : _localDataSource = localDataSource,
       _firestoreService = FirestoreService();

  @override
  Future<UserProfile?> getUserProfile() async {
    debugPrint('UserRepository: Fetching user profile from local database');
    
    // 既存のプロファイルを検索（default_userから開始）
    UserProfileModel? model = await _localDataSource.getUserProfile('default_user');
    
    if (model != null) {
      final entity = model.toEntity();
      debugPrint('UserRepository: Found profile with ID: ${entity.id}');
      debugPrint('UserRepository: isOnboardingCompleted: ${entity.isOnboardingCompleted}');
      
      // 古いdefault_userの場合、新しいUUIDに移行
      if (entity.id == 'default_user') {
        debugPrint('UserRepository: Migrating old profile to UUID...');
        final migratedProfile = UserProfile(
          // idを指定しないことで新しいUUIDが生成される
          nickname: entity.nickname,
          ageGroup: entity.ageGroup,
          gender: entity.gender,
          occupation: entity.occupation,
          targetSleepHours: entity.targetSleepHours,
          targetBedtime: entity.targetBedtime,
          targetWakeTime: entity.targetWakeTime,
          weekdayBedtime: entity.weekdayBedtime,
          weekdayWakeTime: entity.weekdayWakeTime,
          weekendBedtime: entity.weekendBedtime,
          weekendWakeTime: entity.weekendWakeTime,
          sleepConcerns: entity.sleepConcerns,
          caffeineHabit: entity.caffeineHabit,
          alcoholHabit: entity.alcoholHabit,
          exerciseHabit: entity.exerciseHabit,
          phoneUsageTime: entity.phoneUsageTime,
          phoneUsageContent: entity.phoneUsageContent,
          createdAt: entity.createdAt,
          updatedAt: DateTime.now(),
          notificationSettings: entity.notificationSettings,
          isOnboardingCompleted: entity.isOnboardingCompleted,
          sleepLiteracyScore: entity.sleepLiteracyScore,
          sleepLiteracyTestDate: entity.sleepLiteracyTestDate,
          sleepLiteracyTestDurationMinutes: entity.sleepLiteracyTestDurationMinutes,
          sleepLiteracyCategoryScores: entity.sleepLiteracyCategoryScores,
        );
        
        // 新しいUUIDで保存
        await saveUserProfile(migratedProfile);
        
        // 古いレコードを削除（オプション）
        // await _localDataSource.deleteUserProfile('default_user');
        
        return migratedProfile;
      }
      
      return entity;
    }
    
    debugPrint('UserRepository: No profile found, returning null');
    return null;
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    debugPrint('UserRepository: Saving profile with ID: ${profile.id}');
    debugPrint('UserRepository: isOnboardingCompleted: ${profile.isOnboardingCompleted}');
    final model = UserProfileModel.fromEntity(profile);
    debugPrint('UserRepository: Model isOnboardingCompleted: ${model.isOnboardingCompleted}');
    await _localDataSource.insertOrUpdateUserProfile(model);
    debugPrint('UserRepository: Profile saved to local data source');
    
    // Firestoreにも保存（エラーが発生してもローカル動作は継続）
    try {
      await _firestoreService.saveUserProfile(profile);
      debugPrint('UserRepository: Profile saved to Firestore');
    } catch (e) {
      debugPrint('UserRepository: Failed to save profile to Firestore: $e');
    }
  }

}