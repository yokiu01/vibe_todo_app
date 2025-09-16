import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/item_provider.dart';
import 'providers/daily_plan_provider.dart';
import 'providers/review_provider.dart';
import 'providers/pds_diary_provider.dart';
import 'screens/main_navigation.dart';
import 'screens/lock_screen.dart';
import 'services/lock_screen_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko', null);
  runApp(const ProductivityApp());
}

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

    // 잠금화면 서비스 초기화
    LockScreenService.initialize(onScreenOn: () {
      if (mounted) {
        showLockScreen(context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 앱이 포그라운드로 돌아왔을 때 (화면 켜짐 포함)
    if (state == AppLifecycleState.resumed) {
      // 약간 딜레이를 주어 앱이 완전히 로드된 후 잠금화면 표시
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          showLockScreen(context);
        }
      });
    }
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
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
            primary: const Color(0xFF2563EB),
            secondary: const Color(0xFF10B981),
            surface: Colors.white,
            background: const Color(0xFFF8FAFC),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: const Color(0xFF1E293B),
            onBackground: const Color(0xFF1E293B),
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF8FAFC),
            foregroundColor: Color(0xFF1E293B),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF2563EB),
            unselectedItemColor: Color(0xFF64748B),
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
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
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
              foregroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            margin: const EdgeInsets.all(8),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFE2E8F0),
            thickness: 1,
            space: 1,
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFFF1F5F9),
            labelStyle: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: const Color(0xFF1E293B),
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
        home: const MainNavigation(),
      ),
    );
  }
}