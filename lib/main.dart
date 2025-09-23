import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/item_provider.dart';
import 'providers/daily_plan_provider.dart';
import 'providers/review_provider.dart';
import 'providers/pds_diary_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/lock_screen_standalone.dart';
import 'services/lock_screen_service.dart';
import 'services/lock_screen_mode_service.dart';
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

    // 앱 시작 시 캐시 초기화
    LockScreenModeService.reset();

    // 락 스크린 모드인지 확인하여 불필요한 초기화 건너뛰기
    // 더 긴 지연 시간으로 라우팅 시스템이 완전히 초기화되도록 대기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _initializeBasedOnRoute();
      });
    });
  }

  void _initializeBasedOnRoute() async {
    try {
      // context가 유효한지 확인
      if (!mounted) return;

      // 현재 라우트 확인 - 안전한 방법 사용
      final navigatorState = navigatorKey.currentState;
      final currentContext = navigatorState?.context;

      String? currentRoute;
      if (currentContext != null) {
        currentRoute = ModalRoute.of(currentContext)?.settings.name;
      }

      print('Current route detected: $currentRoute');

      // 락 스크린 모드 감지 - Android에서 직접 확인
      final isLockScreenMode = await LockScreenModeService.isLockScreenMode();
      print('Lock screen mode from Android: $isLockScreenMode');

      if (isLockScreenMode || currentRoute == '/lockScreenStandalone') {
        // 락 스크린 모드: 최소한의 초기화만
        print('Lock screen mode detected - minimal initialization');
        _initializeLockScreenOnly();
        
        // 잠금화면 모드일 때는 라우트를 강제로 변경
        if (currentRoute != '/lockScreenStandalone') {
          print('Redirecting to lock screen standalone route');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              navigatorState?.pushReplacementNamed('/lockScreenStandalone');
            }
          });
        }
      } else {
        // 일반 앱 모드: 모든 서비스 초기화
        print('Normal app mode - full initialization');
        _initializeAllServices();
      }
    } catch (e) {
      print('Error in _initializeBasedOnRoute: $e');
      // 에러가 발생하면 기본적으로 모든 서비스 초기화
      _initializeAllServices();
    }
  }

  void _initializeLockScreenOnly() async {
    try {
      // 락 스크린에 필요한 최소한의 설정만
      final isEnabled = await LockScreenService.isLockScreenEnabled();
      if (!isEnabled) {
        await LockScreenService.setLockScreenEnabled(true);
        print('Lock screen enabled (minimal mode)');
      }
      print('Lock screen minimal initialization completed');
    } catch (e) {
      print('Error in minimal lock screen initialization: $e');
    }
  }

  void _initializeAllServices() async {
    // 위치 알림 서비스 초기화
    await _initializeLocationNotificationService();

    // 시간 알림 서비스 초기화
    await _initializeTimeNotificationService();

    // 락스크린 활성화 설정
    await _initializeLockScreen();
  }

  Future<void> _initializeLocationNotificationService() async {
    try {
      await LocationNotificationService().initialize();
      print('Location notification service initialized');
    } catch (e) {
      print('Error initializing location notification service: $e');
    }
  }

  Future<void> _initializeTimeNotificationService() async {
    try {
      await TimeNotificationService().initialize();
      print('Time notification service initialized');
    } catch (e) {
      print('Error initializing time notification service: $e');
    }
  }

  Future<void> _initializeLockScreen() async {
    try {
      // 락스크린 설정만 저장 - 실제 화면 표시는 Android ScreenOnReceiver가 처리
      final isEnabled = await LockScreenService.isLockScreenEnabled();
      if (!isEnabled) {
        await LockScreenService.setLockScreenEnabled(true);
        print('Lock screen enabled by default (settings only - Android handles display)');
      }

      print('Lock screen settings initialized (Android handles screen events)');
    } catch (e) {
      print('Error initializing lock screen settings: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('App lifecycle state changed: $state');
  }


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => DailyPlanProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => PDSDiaryProvider()),
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
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/main': (context) => const MainNavigation(),
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