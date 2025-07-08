import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/themes/app_theme.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/providers/sleep_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'domain/repositories/sleep_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'data/repositories/sleep_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/datasources/local_data_source.dart';
import 'domain/usecases/start_sleep_tracking_usecase.dart';
import 'domain/usecases/end_sleep_tracking_usecase.dart';
import 'services/database_service.dart';

class SleepApp extends StatelessWidget {
  const SleepApp({Key? key}) : super(key: key);

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
      ],
      child: MaterialApp(
        title: 'Sleep Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}