# 技術アーキテクチャ設計書

## 1. アーキテクチャ概要

### 1.1 採用パターン
- **Clean Architecture** + **MVVM**
- **Repository Pattern**
- **Dependency Injection**

### 1.2 レイヤー構成
```
┌─────────────────────────────────────┐
│      Presentation Layer             │
│  (Screens, Widgets, ViewModels)     │
├─────────────────────────────────────┤
│        Domain Layer                 │
│   (Entities, Use Cases, Repos)     │
├─────────────────────────────────────┤
│         Data Layer                  │
│  (Models, Data Sources, Impls)      │
├─────────────────────────────────────┤
│      Infrastructure Layer           │
│   (Services, External APIs)         │
└─────────────────────────────────────┘
```

## 2. 各レイヤーの詳細

### 2.1 Presentation Layer
```dart
// 画面例: HomeScreen
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SleepViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          body: SleepTrackingWidget(
            isTracking: viewModel.isTracking,
            onStartSleep: viewModel.startSleepTracking,
            onEndSleep: viewModel.endSleepTracking,
          ),
        );
      },
    );
  }
}

// ViewModel例
class SleepViewModel extends ChangeNotifier {
  final StartSleepTrackingUseCase _startSleepTracking;
  final EndSleepTrackingUseCase _endSleepTracking;
  
  bool _isTracking = false;
  bool get isTracking => _isTracking;
  
  Future<void> startSleepTracking() async {
    await _startSleepTracking.execute();
    _isTracking = true;
    notifyListeners();
  }
}
```

### 2.2 Domain Layer
```dart
// Entity
class SleepSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final double? qualityScore;
  
  bool get isActive => endTime == null;
}

// Use Case
class StartSleepTrackingUseCase {
  final SleepRepository _repository;
  
  StartSleepTrackingUseCase(this._repository);
  
  Future<SleepSession> execute() async {
    final session = SleepSession(
      id: Uuid().v4(),
      startTime: DateTime.now(),
    );
    return await _repository.startSession(session);
  }
}

// Repository Interface
abstract class SleepRepository {
  Future<SleepSession> startSession(SleepSession session);
  Future<SleepSession> endSession(String sessionId);
  Future<List<SleepSession>> getSessions({DateTime? from, DateTime? to});
}
```

### 2.3 Data Layer
```dart
// Model (Data Transfer Object)
class SleepRecordModel {
  final String id;
  final int startTimeEpoch;
  final int? endTimeEpoch;
  final int? durationMinutes;
  final double? qualityScore;
  
  // Mappers
  factory SleepRecordModel.fromEntity(SleepSession entity) {
    return SleepRecordModel(
      id: entity.id,
      startTimeEpoch: entity.startTime.millisecondsSinceEpoch,
      endTimeEpoch: entity.endTime?.millisecondsSinceEpoch,
      durationMinutes: entity.duration?.inMinutes,
      qualityScore: entity.qualityScore,
    );
  }
  
  SleepSession toEntity() {
    return SleepSession(
      id: id,
      startTime: DateTime.fromMillisecondsSinceEpoch(startTimeEpoch),
      endTime: endTimeEpoch != null 
        ? DateTime.fromMillisecondsSinceEpoch(endTimeEpoch!) 
        : null,
      duration: durationMinutes != null 
        ? Duration(minutes: durationMinutes!) 
        : null,
      qualityScore: qualityScore,
    );
  }
}

// Repository Implementation
class SleepRepositoryImpl implements SleepRepository {
  final LocalDataSource _localDataSource;
  final RemoteDataSource? _remoteDataSource;
  
  @override
  Future<SleepSession> startSession(SleepSession session) async {
    final model = SleepRecordModel.fromEntity(session);
    await _localDataSource.insertRecord(model);
    return session;
  }
}
```

### 2.4 Infrastructure Layer
```dart
// Local Data Source
class LocalDataSource {
  final Database _database;
  
  Future<void> insertRecord(SleepRecordModel record) async {
    await _database.insert(
      'sleep_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<List<SleepRecordModel>> getRecords({
    DateTime? from,
    DateTime? to,
  }) async {
    // SQLクエリ実装
  }
}

// Sensor Service
class SensorService {
  Stream<double> get accelerometerData => 
    accelerometerEvents.map((event) => 
      sqrt(event.x * event.x + event.y * event.y + event.z * event.z)
    );
  
  Stream<MovementData> detectMovements() {
    // 加速度データから体動を検出
  }
}
```

## 3. 状態管理アーキテクチャ

### 3.1 Provider構成
```dart
// App全体のProvider構成
MultiProvider(
  providers: [
    // Services
    Provider<DatabaseService>(
      create: (_) => DatabaseService(),
    ),
    Provider<NotificationService>(
      create: (_) => NotificationService(),
    ),
    
    // Repositories
    Provider<SleepRepository>(
      create: (context) => SleepRepositoryImpl(
        localDataSource: LocalDataSource(
          context.read<DatabaseService>().database,
        ),
      ),
    ),
    
    // ViewModels
    ChangeNotifierProvider<SleepViewModel>(
      create: (context) => SleepViewModel(
        startSleepTracking: StartSleepTrackingUseCase(
          context.read<SleepRepository>(),
        ),
      ),
    ),
  ],
  child: MyApp(),
);
```

### 3.2 状態の種類
```dart
// アプリケーション状態
class AppState {
  final UserProfile? currentUser;
  final AppSettings settings;
  final bool isFirstLaunch;
}

// 画面固有の状態
class SleepTrackingState {
  final bool isTracking;
  final DateTime? startTime;
  final Duration? currentDuration;
}

// 一時的なUI状態
class LoadingState {
  final bool isLoading;
  final String? errorMessage;
}
```

## 4. データフロー

### 4.1 睡眠記録開始のフロー
```
User Tap → HomeScreen → SleepViewModel 
    → StartSleepTrackingUseCase → SleepRepository 
    → LocalDataSource → SQLite Database
    
同時に:
    → NotificationService (バックグラウンド記録開始)
    → SensorService (センサーデータ収集開始)
```

### 4.2 データ同期フロー（将来実装）
```
LocalDataSource → SyncService → RemoteDataSource
    ↓                              ↓
SQLite DB                     Cloud Storage
    ↓                              ↓
    └──────── Conflict Resolution ←┘
```

## 5. エラーハンドリング戦略

### 5.1 エラーの種類
```dart
// カスタム例外クラス
abstract class AppException implements Exception {
  final String message;
  final String? code;
  AppException(this.message, {this.code});
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message, code: 'NETWORK_ERROR');
}

class DatabaseException extends AppException {
  DatabaseException(String message) : super(message, code: 'DATABASE_ERROR');
}

class ValidationException extends AppException {
  ValidationException(String message) : super(message, code: 'VALIDATION_ERROR');
}
```

### 5.2 エラーハンドリング実装
```dart
class SleepViewModel extends ChangeNotifier {
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  Future<void> startSleepTracking() async {
    try {
      _errorMessage = null;
      await _startSleepTracking.execute();
    } on AppException catch (e) {
      _errorMessage = e.message;
      _handleError(e);
    } catch (e) {
      _errorMessage = '予期しないエラーが発生しました';
      _logError(e);
    } finally {
      notifyListeners();
    }
  }
}
```

## 6. パフォーマンス最適化

### 6.1 メモリ管理
- 大きな画像はキャッシュサイズを制限
- 不要なProviderのdispose
- StreamSubscriptionの適切なキャンセル

### 6.2 バッテリー最適化
```dart
class BackgroundService {
  // バッテリー消費を抑えるための設定
  static const Duration SENSOR_SAMPLING_INTERVAL = Duration(minutes: 5);
  static const Duration DATA_SYNC_INTERVAL = Duration(hours: 6);
  
  void configureLowPowerMode() {
    // センサーのサンプリングレートを下げる
    // バックグラウンドでの処理を最小限に
  }
}
```

### 6.3 データベース最適化
- インデックスの適切な設定
- バッチ処理の活用
- 古いデータの自動削除

## 7. セキュリティ考慮事項

### 7.1 データ保護
- センシティブデータの暗号化
- 生体認証によるアプリロック（オプション）
- セキュアストレージの使用

### 7.2 プライバシー
- 最小限の権限要求
- データの匿名化
- ユーザーによるデータ削除機能

## 8. テスト戦略

### 8.1 Unit Tests
```dart
// Use Case のテスト例
test('StartSleepTrackingUseCase creates new session', () async {
  final mockRepository = MockSleepRepository();
  final useCase = StartSleepTrackingUseCase(mockRepository);
  
  when(mockRepository.startSession(any))
    .thenAnswer((_) async => SleepSession(...));
  
  final result = await useCase.execute();
  
  expect(result.isActive, true);
  verify(mockRepository.startSession(any)).called(1);
});
```

### 8.2 Widget Tests
```dart
testWidgets('Sleep button changes state', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => MockSleepViewModel(),
        child: HomeScreen(),
      ),
    ),
  );
  
  expect(find.text('睡眠開始'), findsOneWidget);
  
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();
  
  expect(find.text('睡眠終了'), findsOneWidget);
});
```

### 8.3 Integration Tests
- エンドツーエンドのシナリオテスト
- 実際のデータベースを使用したテスト
- バックグラウンド処理のテスト