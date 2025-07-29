import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/themes/app_theme.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/providers/sleep_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/serverless_analytics_provider.dart';
import 'presentation/providers/sleep_literacy_test_provider.dart';
import 'domain/repositories/sleep_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'data/repositories/sleep_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/datasources/local_data_source.dart';
import 'domain/usecases/start_sleep_tracking_usecase.dart';
import 'domain/usecases/end_sleep_tracking_usecase.dart';
import 'services/database_service.dart';
import 'services/analytics_service.dart';
import 'presentation/screens/sleep_literacy_test_intro_screen.dart';
import 'presentation/screens/sleep_literacy_test_screen.dart';
import 'presentation/screens/sleep_literacy_test_result_screen.dart';
import 'presentation/screens/main_screen.dart';
import 'config/flavor_config.dart';

class SleepApp extends StatelessWidget {
  const SleepApp({Key? key}) : super(key: key);
  
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),
        Provider<LocalDataSource>(
          create: (context) => LocalDataSource(
            databaseService: context.read<DatabaseService>(),
          ),
        ),
        Provider<SleepRepository>(
          create: (context) => SleepRepositoryImpl(
            localDataSource: context.read<LocalDataSource>(),
          ),
        ),
        Provider<UserRepository>(
          create: (context) => UserRepositoryImpl(
            localDataSource: context.read<LocalDataSource>(),
          ),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (context) {
            final userRepository = context.read<UserRepository>();
            return UserProvider(userRepository: userRepository);
          },
        ),
        ChangeNotifierProxyProvider<UserProvider, SleepProvider>(
          create: (context) {
            final sleepRepository = context.read<SleepRepository>();
            final userRepository = context.read<UserRepository>();
            
            return SleepProvider(
              startSleepTracking: StartSleepTrackingUseCase(sleepRepository),
              endSleepTracking: EndSleepTrackingUseCase(
                sleepRepository,
                userRepository,
              ),
              sleepRepository: sleepRepository,
            );
          },
          update: (context, userProvider, sleepProvider) {
            sleepProvider?.setUserProvider(userProvider);
            return sleepProvider!;
          },
        ),
        ChangeNotifierProvider<ServerlessAnalyticsProvider>(
          create: (context) => ServerlessAnalyticsProvider(),
        ),
        ChangeNotifierProvider<SleepLiteracyTestProvider>(
          create: (context) => SleepLiteracyTestProvider(),
        ),
      ],
      child: MaterialApp(
        title: FlavorConfig.appTitle,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        navigatorObservers: [
          if (AnalyticsService().observer != null) AnalyticsService().observer!,
        ],
        routes: {
          '/sleep-literacy-test-intro': (context) => const SleepLiteracyTestIntroScreen(),
          '/sleep-literacy-test': (context) => const SleepLiteracyTestScreen(),
          '/sleep-literacy-test-result': (context) => const SleepLiteracyTestResultScreen(),
          '/main': (context) => const MainScreen(),
        },
      ),
    );
  }
}