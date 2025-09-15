import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme_provider.dart';
import '../services/update_provider.dart';
import '../widgets/update_checker_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.primaryColor,
      appBar: AppBar(
        backgroundColor: themeProvider.primaryColor,
        title: Text(
          'Settings',
          style: TextStyle(
            color: themeProvider.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: themeProvider.textColor),
        elevation: 0,
      ),
      body: Animate(
        effects: [
          ScaleEffect(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.0, 1.0),
            duration: 300.ms,
            curve: Curves.easeOutQuart,
          ),
          FadeEffect(begin: 0.0, end: 1.0, duration: 300.ms),
        ],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Appearance',
                style: TextStyle(
                  color: themeProvider.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeProvider.secondaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: themeProvider.textColor,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Dark Mode',
                          style: TextStyle(
                            color: themeProvider.textColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                      activeColor: Colors.blue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Updates',
                style: TextStyle(
                  color: themeProvider.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const UpdateCheckerSection(),
              const SizedBox(height: 20),
              Text(
                'About',
                style: TextStyle(
                  color: themeProvider.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeProvider.secondaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JB Calculator',
                      style: TextStyle(
                        color: themeProvider.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: themeProvider.textColorSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '© 2024 JB Calculator',
                      style: TextStyle(
                        color: themeProvider.textColorSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Developed by Sounanda Roy',
                      style: TextStyle(
                        color: themeProvider.textColorSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
