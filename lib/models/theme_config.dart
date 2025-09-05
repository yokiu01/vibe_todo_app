enum AppTheme {
  white('화이트', '깔끔한 화이트'),
  ivory('아이보리', '따뜻한 아이보리'),
  lavender('라벤더', '차분한 라벤더'),
  peach('피치', '부드러운 피치'),
  coral('코랄', '활기찬 코랄'),
  brown('브라운', '따뜻한 브라운'),
  dark('다크', '모던한 다크');

  const AppTheme(this.displayName, this.description);
  final String displayName;
  final String description;
}

class ThemeConfig {
  final AppTheme theme;
  final String primaryColor;
  final String backgroundColor;
  final String surfaceColor;
  final String textColor;
  final String accentColor;

  const ThemeConfig({
    required this.theme,
    required this.primaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.accentColor,
  });

  String get displayName => theme.displayName;
  String get description => theme.description;

  static const Map<AppTheme, ThemeConfig> themes = {
    AppTheme.white: ThemeConfig(
      theme: AppTheme.white,
      primaryColor: '#FFFFFF',
      backgroundColor: '#FAFAFA',
      surfaceColor: '#F5F5F5',
      textColor: '#2C2C2C',
      accentColor: '#6366F1',
    ),
    AppTheme.ivory: ThemeConfig(
      theme: AppTheme.ivory,
      primaryColor: '#F5F5DC',
      backgroundColor: '#FEFEFE',
      surfaceColor: '#F8F8F0',
      textColor: '#3C3C3C',
      accentColor: '#8B5A2B',
    ),
    AppTheme.lavender: ThemeConfig(
      theme: AppTheme.lavender,
      primaryColor: '#E6E6FA',
      backgroundColor: '#F8F6FF',
      surfaceColor: '#F0EDFF',
      textColor: '#4A4A4A',
      accentColor: '#8B5CF6',
    ),
    AppTheme.peach: ThemeConfig(
      theme: AppTheme.peach,
      primaryColor: '#FFDAB9',
      backgroundColor: '#FFF8F0',
      surfaceColor: '#FFE4CC',
      textColor: '#5C3C2C',
      accentColor: '#FF6B6B',
    ),
    AppTheme.coral: ThemeConfig(
      theme: AppTheme.coral,
      primaryColor: '#FF7F7F',
      backgroundColor: '#FFF5F5',
      surfaceColor: '#FFE5E5',
      textColor: '#4A2C2C',
      accentColor: '#FF4757',
    ),
    AppTheme.brown: ThemeConfig(
      theme: AppTheme.brown,
      primaryColor: '#D2B48C',
      backgroundColor: '#FDF5E6',
      surfaceColor: '#F5E6D3',
      textColor: '#3C2C1C',
      accentColor: '#8B4513',
    ),
    AppTheme.dark: ThemeConfig(
      theme: AppTheme.dark,
      primaryColor: '#2D2D2D',
      backgroundColor: '#1A1A1A',
      surfaceColor: '#2C2C2C',
      textColor: '#FFFFFF',
      accentColor: '#BB86FC',
    ),
  };

  static ThemeConfig getTheme(AppTheme theme) {
    return themes[theme] ?? themes[AppTheme.white]!;
  }
}
