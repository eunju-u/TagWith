import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // Added ThemeProvider
      ],
      child: const TagWithApp(),
    ),
  );
}

class TagWithApp extends StatelessWidget {
  const TagWithApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context); // Added this line
    
    return MaterialApp(
      title: 'TagWith', // Changed title
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Changed theme to lightTheme
      darkTheme: AppTheme.darkTheme, // Added darkTheme
      themeMode: themeProvider.themeMode, // Added themeMode
      home: const HomeScreen(),
    );
  }
}
