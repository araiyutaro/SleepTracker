import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../domain/entities/sleep_session.dart';
import '../domain/entities/user_profile.dart';
import '../domain/repositories/sleep_repository.dart';

class BackupData {
  final String version;
  final DateTime createdAt;
  final List<SleepSession> sessions;
  final UserProfile? userProfile;
  final Map<String, dynamic> metadata;

  BackupData({
    required this.version,
    required this.createdAt,
    required this.sessions,
    this.userProfile,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  Map<String, dynamic> toJson() => {
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        'sessions': sessions.map((s) => _sessionToJson(s)).toList(),
        'userProfile': userProfile != null ? _userProfileToJson(userProfile!) : null,
        'metadata': metadata,
      };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] ?? '1.0.0',
      createdAt: DateTime.parse(json['createdAt']),
      sessions: (json['sessions'] as List)
          .map((s) => _sessionFromJson(s))
          .toList(),
      userProfile: json['userProfile'] != null
          ? _userProfileFromJson(json['userProfile'])
          : null,
      metadata: json['metadata'] ?? {},
    );
  }

  static Map<String, dynamic> _sessionToJson(SleepSession session) => {
        'id': session.id,
        'startTime': session.startTime.toIso8601String(),
        'endTime': session.endTime?.toIso8601String(),
        'duration': session.duration?.inMinutes,
        'qualityScore': session.qualityScore,
        'createdAt': session.createdAt.toIso8601String(),
        'movements': session.movements.map((m) => {
          'timestamp': m.timestamp.toIso8601String(),
          'intensity': m.intensity,
        }).toList(),
        'sleepStages': session.sleepStages != null ? {
          'deepSleepPercentage': session.sleepStages!.deepSleepPercentage,
          'lightSleepPercentage': session.sleepStages!.lightSleepPercentage,
          'remSleepPercentage': session.sleepStages!.remSleepPercentage,
          'awakePercentage': session.sleepStages!.awakePercentage,
          'movementCount': session.sleepStages!.movementCount,
        } : null,
      };

  static SleepSession _sessionFromJson(Map<String, dynamic> json) {
    return SleepSession(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      duration: json['duration'] != null ? Duration(minutes: json['duration']) : null,
      qualityScore: json['qualityScore']?.toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      movements: (json['movements'] as List? ?? []).map((m) => MovementData(
        timestamp: DateTime.parse(m['timestamp']),
        intensity: m['intensity'].toDouble(),
      )).toList(),
      sleepStages: json['sleepStages'] != null ? SleepStageData(
        deepSleepPercentage: json['sleepStages']['deepSleepPercentage'].toDouble(),
        lightSleepPercentage: json['sleepStages']['lightSleepPercentage'].toDouble(),
        remSleepPercentage: json['sleepStages']['remSleepPercentage'].toDouble(),
        awakePercentage: json['sleepStages']['awakePercentage'].toDouble(),
        movementCount: json['sleepStages']['movementCount'],
      ) : null,
    );
  }

  static Map<String, dynamic> _userProfileToJson(UserProfile profile) => {
        'id': profile.id,
        'targetSleepHours': profile.targetSleepHours,
        'targetBedtime': '${profile.targetBedtime.hour}:${profile.targetBedtime.minute}',
        'targetWakeTime': '${profile.targetWakeTime.hour}:${profile.targetWakeTime.minute}',
        'points': profile.points,
        'createdAt': profile.createdAt.toIso8601String(),
        'updatedAt': profile.updatedAt.toIso8601String(),
        'achievements': profile.achievements.map((a) => {
          'id': a.id,
          'name': a.name,
          'description': a.description,
          'iconPath': a.iconPath,
          'points': a.points,
          'unlockedAt': a.unlockedAt?.toIso8601String(),
        }).toList(),
        'notificationSettings': {
          'bedtimeReminderEnabled': profile.notificationSettings.bedtimeReminderEnabled,
          'bedtimeReminderMinutes': profile.notificationSettings.bedtimeReminderMinutes,
          'wakeUpAlarmEnabled': profile.notificationSettings.wakeUpAlarmEnabled,
          'sleepQualityNotificationEnabled': profile.notificationSettings.sleepQualityNotificationEnabled,
          'weeklyReportEnabled': profile.notificationSettings.weeklyReportEnabled,
        },
      };

  static UserProfile _userProfileFromJson(Map<String, dynamic> json) {
    final bedtimeParts = json['targetBedtime'].split(':');
    final waketimeParts = json['targetWakeTime'].split(':');
    
    return UserProfile(
      id: json['id'],
      targetSleepHours: json['targetSleepHours'].toDouble(),
      targetBedtime: TimeOfDay(
        hour: int.parse(bedtimeParts[0]),
        minute: int.parse(bedtimeParts[1]),
      ),
      targetWakeTime: TimeOfDay(
        hour: int.parse(waketimeParts[0]),
        minute: int.parse(waketimeParts[1]),
      ),
      points: json['points'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      achievements: (json['achievements'] as List).map((a) => Achievement(
        id: a['id'],
        name: a['name'],
        description: a['description'],
        iconPath: a['iconPath'],
        points: a['points'],
        unlockedAt: a['unlockedAt'] != null ? DateTime.parse(a['unlockedAt']) : null,
      )).toList(),
      notificationSettings: NotificationSettings(
        bedtimeReminderEnabled: json['notificationSettings']['bedtimeReminderEnabled'],
        bedtimeReminderMinutes: json['notificationSettings']['bedtimeReminderMinutes'],
        wakeUpAlarmEnabled: json['notificationSettings']['wakeUpAlarmEnabled'],
        sleepQualityNotificationEnabled: json['notificationSettings']['sleepQualityNotificationEnabled'],
        weeklyReportEnabled: json['notificationSettings']['weeklyReportEnabled'],
      ),
    );
  }
}

class BackupService {
  final SleepRepository _sleepRepository;
  static const String _backupVersion = '1.0.0';
  static const int _maxLocalBackups = 5;

  BackupService({required SleepRepository sleepRepository})
      : _sleepRepository = sleepRepository;

  Future<File> createBackup({
    UserProfile? userProfile,
    bool includeMetadata = true,
  }) async {
    try {
      final sessions = await _sleepRepository.getSessions();
      
      final metadata = includeMetadata ? {
        'deviceInfo': 'Flutter App',
        'totalSessions': sessions.length,
        'dateRange': sessions.isNotEmpty ? {
          'from': sessions.last.startTime.toIso8601String(),
          'to': sessions.first.startTime.toIso8601String(),
        } : null,
      } : <String, dynamic>{};

      final backupData = BackupData(
        version: _backupVersion,
        createdAt: DateTime.now(),
        sessions: sessions,
        userProfile: userProfile,
        metadata: metadata,
      );

      final jsonString = JsonEncoder.withIndent('  ').convert(backupData.toJson());
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/sleep_backup_$timestamp.json');
      
      await file.writeAsString(jsonString);
      
      await _cleanupOldBackups();
      
      debugPrint('Backup created: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('Failed to create backup: $e');
      rethrow;
    }
  }

  Future<BackupData> restoreFromFile(File file) async {
    try {
      if (!await file.exists()) {
        throw Exception('バックアップファイルが見つかりません');
      }

      final content = await file.readAsString();
      final json = jsonDecode(content);
      
      final backupData = BackupData.fromJson(json);
      
      if (!_isVersionCompatible(backupData.version)) {
        throw Exception('非対応のバックアップバージョンです: ${backupData.version}');
      }

      await _validateBackupData(backupData);
      
      debugPrint('Backup loaded: ${backupData.sessions.length} sessions from ${backupData.createdAt}');
      return backupData;
    } catch (e) {
      debugPrint('Failed to restore from file: $e');
      rethrow;
    }
  }

  Future<void> restoreData(BackupData backupData, {bool overwriteExisting = false}) async {
    try {
      if (!overwriteExisting) {
        final existingSessions = await _sleepRepository.getSessions();
        if (existingSessions.isNotEmpty) {
          throw Exception('既存のデータがあります。上書きモードを有効にしてください。');
        }
      }

      for (final session in backupData.sessions) {
        try {
          final existingSession = await _sleepRepository.getSessionById(session.id);
          if (existingSession == null || overwriteExisting) {
            if (existingSession != null) {
              await _sleepRepository.deleteSession(session.id);
            }
            await _sleepRepository.startSession(session);
            if (session.endTime != null) {
              await _sleepRepository.endSession(session.id);
            }
          }
        } catch (e) {
          debugPrint('Failed to restore session ${session.id}: $e');
        }
      }

      debugPrint('Data restoration completed: ${backupData.sessions.length} sessions restored');
    } catch (e) {
      debugPrint('Failed to restore data: $e');
      rethrow;
    }
  }

  Future<List<File>> getLocalBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
          .whereType<File>()
          .where((file) => file.path.contains('sleep_backup_') && file.path.endsWith('.json'))
          .toList();
      
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (e) {
      debugPrint('Failed to get local backups: $e');
      return [];
    }
  }

  Future<void> deleteBackup(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        debugPrint('Backup deleted: ${file.path}');
      }
    } catch (e) {
      debugPrint('Failed to delete backup: $e');
      rethrow;
    }
  }

  Future<void> _cleanupOldBackups() async {
    try {
      final backups = await getLocalBackups();
      if (backups.length > _maxLocalBackups) {
        final toDelete = backups.skip(_maxLocalBackups);
        for (final backup in toDelete) {
          await deleteBackup(backup);
        }
      }
    } catch (e) {
      debugPrint('Failed to cleanup old backups: $e');
    }
  }

  bool _isVersionCompatible(String version) {
    final supportedVersions = ['1.0.0'];
    return supportedVersions.contains(version);
  }

  Future<void> _validateBackupData(BackupData backupData) async {
    if (backupData.sessions.isEmpty) {
      throw Exception('バックアップにセッションデータがありません');
    }

    for (final session in backupData.sessions) {
      if (session.id.isEmpty) {
        throw Exception('無効なセッションID');
      }
      if (session.startTime.isAfter(DateTime.now())) {
        throw Exception('未来の日付のセッションが含まれています');
      }
    }
  }

  Future<String> getBackupInfo(File file) async {
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content);
      final backupData = BackupData.fromJson(json);
      
      final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');
      final sessions = backupData.sessions.length;
      final created = dateFormat.format(backupData.createdAt);
      final size = await file.length();
      final sizeKB = (size / 1024).toStringAsFixed(1);
      
      return '''
バックアップ情報:
作成日時: $created
セッション数: $sessions
ファイルサイズ: ${sizeKB}KB
バージョン: ${backupData.version}
''';
    } catch (e) {
      return 'バックアップ情報の読み込みに失敗しました: $e';
    }
  }
}