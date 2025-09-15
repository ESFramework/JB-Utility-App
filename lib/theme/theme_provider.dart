import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true; // Default to dark mode
  bool get isDarkMode => _isDarkMode;

  // Animation duration for theme transitions
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Theme colors
  final Color _darkPrimaryColor = const Color(0xFF121212);
  final Color _darkSecondaryColor = const Color(0xFF1E1E1E);
  final Color _lightPrimaryColor = const Color(0xFFFFFFFF); // Updated
  final Color _lightSecondaryColor = const Color(0xFFF2F2F2); // Updated
  final Color _lightSurfaceColor = const Color(0xFFE0E0E0);

  // Getters for theme colors
  Color get primaryColor =>
      _isDarkMode ? _darkPrimaryColor : _lightPrimaryColor;
  Color get secondaryColor =>
      _isDarkMode ? _darkSecondaryColor : _lightSecondaryColor;
  Color get surfaceColor =>
      _isDarkMode ? _darkSecondaryColor.withOpacity(0.8) : _lightSurfaceColor;
  Color get textColor => _isDarkMode ? Colors.white : Colors.black;
  Color get textColorSecondary => _isDarkMode ? Colors.white70 : Colors.black54;

  ThemeProvider() {
    loadThemePreference();
  }

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get themeData {
    return ThemeData(
      scaffoldBackgroundColor: _isDarkMode ? _darkPrimaryColor : primaryColor,
      primaryColor:
          _isDarkMode ? const Color(0xFFBB86FC) : const Color(0xFF6200EE),
      cardColor: secondaryColor,
      dividerColor: _isDarkMode ? Colors.white12 : Colors.black12,
      appBarTheme: AppBarTheme(
        backgroundColor: _isDarkMode ? _darkPrimaryColor : primaryColor,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      useMaterial3: true,
      colorScheme:
          _isDarkMode
              ? ColorScheme.dark(
                primary: const Color(0xFFBB86FC),
                primaryContainer: const Color(0xFF3700B3),
                secondary: const Color(0xFF03DAC6),
                secondaryContainer: const Color(0xFF018786),
                background: const Color(0xFF121212),
                surface: const Color(0xFF1E1E1E),
                error: const Color(0xFFCF6679),
                onPrimary: Colors.black,
                onSecondary: Colors.black,
                onBackground: Colors.white,
                onSurface: Colors.white,
                onError: Colors.black,
              )
              : ColorScheme.light(
                primary: const Color(0xFF6200EE),
                primaryContainer: const Color(0xFF3700B3),
                secondary: const Color(0xFF03DAC6),
                secondaryContainer: const Color(0xFF018786),
                background: const Color(0xFFFFFFFF),
                surface: const Color(0xFFF2F2F2),
                error: const Color(0xFFB00020),
                onPrimary: Colors.white,
                onSecondary: Colors.black,
                onBackground: Colors.black,
                onSurface: Colors.black,
                onError: Colors.white,
              ),
      textTheme:
          _isDarkMode
              ? const TextTheme(
                bodyLarge: TextStyle(color: Color(0xFFFFFFFF)),
                bodyMedium: TextStyle(color: Color(0xFFB3B3B3)),
              )
              : const TextTheme(
                bodyLarge: TextStyle(color: Color(0xFF000000)),
                bodyMedium: TextStyle(color: Color(0xFF4D4D4D)),
              ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((
          Set<MaterialState> states,
        ) {
          if (states.contains(MaterialState.selected)) {
            return Colors.blue;
          }
          return _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((
          Set<MaterialState> states,
        ) {
          if (states.contains(MaterialState.selected)) {
            return Colors.blue.withOpacity(0.5);
          }
          return _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _isDarkMode ? _darkPrimaryColor : _lightSurfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: textColor.withOpacity(0.5), fontSize: 13),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: textColor),
        menuStyle: MenuStyle(
          backgroundColor: MaterialStateProperty.all(secondaryColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isDarkMode ? Colors.blue : const Color(0xFF6200EE),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
