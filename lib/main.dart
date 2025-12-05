import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/calculator_screen.dart';
import 'theme/theme_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => ThemeProvider())],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Utility App',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: AnimatedTheme(
              data: themeProvider.themeData,
              duration: const Duration(milliseconds: 300),
              child: CalculatorScreen(),
            ),
          );
        },
      ),
    );
  }
}
