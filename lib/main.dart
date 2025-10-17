import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/item_provider.dart';
import 'providers/daily_plan_provider.dart';
import 'providers/review_provider.dart';
import 'providers/pds_diary_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/routine_provider.dart';
import 'screens/main_navigation.dart';
import 'screens/lock_screen_standalone.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'services/lock_screen_service.dart';
import 'services/location_notification_service.dart';
import 'services/time_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko', null);
  runApp(const ProductivityApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ProductivityApp extends StatefulWidget {
  const ProductivityApp({super.key});

  @override
  State<ProductivityApp> createState() => _ProductivityAppState();
}

class _ProductivityAppState extends State<ProductivityApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      await LocationNotificationService().initialize();
      await TimeNotificationService().initialize();

      // 잠금화면 서비스 시작
      final enabled = await LockScreenService.isLockScreenEnabled();
      if (enabled) {
        await LockScreenService.startForegroundService();
      }

      // 루틴 기반 작업 자동 생성 (비동기로 실행하여 앱 시작을 차단하지 않음)
      _initRoutineGeneration();
    } catch (e) {
      print('Service initialization error: $e');
    }
  }

  /// 루틴 기반 작업 자동 생성
  Future<void> _initRoutineGeneration() async {
    try {
      // 컨텍스트가 준비될 때까지 대기
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // RoutineProvider에 접근하여 작업 생성
      final routineProvider = Provider.of<RoutineProvider>(context, listen: false);
      final generatedTaskIds = await routineProvider.checkAndGenerateRoutineTasks();

      if (generatedTaskIds.isNotEmpty) {
        print('Generated ${generatedTaskIds.length} tasks from routines');
      }
    } catch (e) {
      print('Routine generation error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => DailyPlanProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => PDSDiaryProvider()),
        ChangeNotifierProvider(create: (_) => RoutineProvider()),
        ChangeNotifierProvider(
          create: (_) => AIProvider()..initialize(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'ProductivityFlow',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
          Locale('en', 'US'),
        ],
        locale: const Locale('ko', 'KR'),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B7355),
            brightness: Brightness.light,
            primary: const Color(0xFF8B7355),
            secondary: const Color(0xFFD4A574),
            surface: const Color(0xFFFDF6E3),
            background: const Color(0xFFF5F1E8),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: const Color(0xFF3C2A21),
            onBackground: const Color(0xFF3C2A21),
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F1E8),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF5F1E8),
            foregroundColor: Color(0xFF3C2A21),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3C2A21),
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFFFDF6E3),
            selectedItemColor: Color(0xFF8B7355),
            unselectedItemColor: Color(0xFF9C8B73),
            type: BottomNavigationBarType.fixed,
            elevation: 8,
            selectedLabelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B7355),
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: const Color(0xFF8B7355).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B7355),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDD4C0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDD4C0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8B7355), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            filled: true,
            fillColor: const Color(0xFFFDF6E3),
            contentPadding: const EdgeInsets.all(16),
            hintStyle: const TextStyle(
              color: Color(0xFF9C8B73),
              fontSize: 14,
            ),
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFFFDF6E3),
            elevation: 2,
            shadowColor: const Color(0xFF8B7355).withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFDDD4C0)),
            ),
            margin: const EdgeInsets.all(8),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFDDD4C0),
            thickness: 1,
            space: 1,
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFFEFE7D3),
            labelStyle: const TextStyle(
              color: Color(0xFF3C2A21),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: const Color(0xFF3C2A21),
            contentTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        ),
        home: Consumer<OnboardingProvider>(
          builder: (context, onboardingProvider, child) {
            // Show onboarding if not completed, otherwise show main navigation
            if (!onboardingProvider.isOnboardingCompleted) {
              return const OnboardingFlow();
            }
            return const MainNavigation();
          },
        ),
        routes: {
          '/lockScreenStandalone': (context) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => PDSDiaryProvider()),
            ],
            child: const LockScreenStandalone(),
          ),
        },
      ),
    );
  }
}