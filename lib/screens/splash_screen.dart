import 'package:flutter/material.dart';
import 'dart:async';
import 'main_navigation.dart';
import '../services/lock_screen_mode_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _brainController;
  late AnimationController _dotController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _brainAnimation;
  late Animation<double> _dotAnimation;

  @override
  void initState() {
    super.initState();
    
    // 페이드 인 애니메이션
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // 뇌 모양 플로팅 애니메이션
    _brainController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _brainAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _brainController,
      curve: Curves.easeInOut,
    ));

    // 점 애니메이션
    _dotController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _dotAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dotController,
      curve: Curves.easeInOut,
    ));

    // 애니메이션 시작
    _fadeController.forward();
    _brainController.repeat(reverse: true);
    _dotController.repeat();

    // 3초 후 조건부로 네비게이션
    Timer(const Duration(seconds: 3), () {
      _navigateBasedOnMode();
    });
  }

  void _navigateBasedOnMode() async {
    if (!mounted) return;

    print('🚀 SplashScreen: Starting navigation check...');
    
    try {
      // 잠금화면 모드인지 확인
      final isLockScreenMode = await LockScreenModeService.isLockScreenMode();
      print('🚀 SplashScreen: Lock screen mode detected: $isLockScreenMode');

      if (isLockScreenMode) {
        // 잠금화면 모드: 잠금화면으로 이동
        print('🚀 SplashScreen: Navigating to lock screen standalone');
        Navigator.of(context).pushReplacementNamed('/lockScreenStandalone');
      } else {
        // 일반 모드: 메인 화면으로 이동
        print('🚀 SplashScreen: Navigating to main screen (HomeScreen will be shown)');
        _navigateToMain();
      }
    } catch (e) {
      print('🚀 SplashScreen: Error checking lock screen mode: $e');
      // 에러 시 기본적으로 메인으로 이동
      print('🚀 SplashScreen: Fallback to main screen due to error');
      _navigateToMain();
    }
  }

  void _navigateToMain() {
    if (mounted) {
      try {
        Navigator.of(context).pushReplacementNamed('/main');
      } catch (e) {
        print('Error navigating to main: $e');
        // 대안: 직접 MainNavigation으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _brainController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFC3CFE2),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 배경 파티클들
            ...List.generate(4, (index) => _buildParticle(index)),
            
            // 메인 컨텐츠
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 뇌 모양 로고
                    AnimatedBuilder(
                      animation: _brainAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, -10 * _brainAnimation.value),
                          child: Transform.rotate(
                            angle: 0.02 * _brainAnimation.value,
                            child: _buildBrainLogo(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 앱 제목
                    const Text(
                      'Second Brain',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                        letterSpacing: -0.5,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 앱 부제목
                    const Text(
                      '똑똑한 할일관리의 시작',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF7F8C8D),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // 로딩 점들
                    _buildLoadingDots(),
                  ],
                ),
              ),
            ),
            
            // 버전 텍스트
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrainLogo() {
    return Container(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          // 메인 뇌 모양
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8FBC8F),
                  Color(0xFF9ACD32),
                  Color(0xFF8FBC8F),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8FBC8F).withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 중앙 구분선
                Center(
                  child: Container(
                    width: 2,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                
                // 왼쪽 뇌
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 58,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF8FBC8F),
                          Color(0xFF98D982),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(60),
                        bottomLeft: Radius.circular(60),
                        topRight: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
                
                // 오른쪽 뇌
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 58,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Color(0xFF98D982),
                          Color(0xFF8FBC8F),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(60),
                        bottomRight: Radius.circular(60),
                        topLeft: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _dotAnimation,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = -0.32 + (index * 0.16);
            final animationValue = (_dotAnimation.value + delay).clamp(0.0, 1.0);
            
            double scale;
            double opacity;
            
            if (animationValue <= 0.4) {
              scale = 0.8 + (animationValue / 0.4) * 0.4;
              opacity = 0.5 + (animationValue / 0.4) * 0.5;
            } else if (animationValue <= 0.8) {
              scale = 1.2 - ((animationValue - 0.4) / 0.4) * 0.4;
              opacity = 1.0 - ((animationValue - 0.4) / 0.4) * 0.5;
            } else {
              scale = 0.8;
              opacity = 0.5;
            }
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8FBC8F),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildParticle(int index) {
    final positions = [
      {'top': 0.2, 'left': 0.1},
      {'top': 0.8, 'left': 0.2},
      {'top': 0.3, 'right': 0.15},
      {'bottom': 0.2, 'right': 0.1},
    ];
    
    final position = positions[index];
    final delay = index * 1.0;
    
    return AnimatedBuilder(
      animation: _brainController,
      builder: (context, child) {
        final animationValue = (_brainController.value + delay) % 1.0;
        final translateY = -20 * (0.5 - (animationValue - 0.5).abs());
        final scale = 1.0 + 0.1 * (0.5 - (animationValue - 0.5).abs());
        final opacity = 0.7 - 0.4 * (0.5 - (animationValue - 0.5).abs());
        
        return Positioned(
          top: position['top'] != null ? MediaQuery.of(context).size.height * position['top']! : null,
          bottom: position['bottom'] != null ? MediaQuery.of(context).size.height * position['bottom']! : null,
          left: position['left'] != null ? MediaQuery.of(context).size.width * position['left']! : null,
          right: position['right'] != null ? MediaQuery.of(context).size.width * position['right']! : null,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8FBC8F).withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
