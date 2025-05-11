  import 'package:flutter/material.dart';

  class AppTheme {
    static final ThemeData lightTheme = ThemeData(
            // ── Add this block ──
      pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _CustomPageTransitionBuilder(),
            TargetPlatform.fuchsia: _CustomPageTransitionBuilder(),
            TargetPlatform.linux: _CustomPageTransitionBuilder(),
            TargetPlatform.macOS: _CustomPageTransitionBuilder(),
           TargetPlatform.windows: _CustomPageTransitionBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
            ),
      primaryColor: Colors.green, // Consistent primary color
      colorScheme: const ColorScheme.light(
        secondary: Colors.amber,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: Colors.black, // improved contrast
        ),
        bodyMedium: TextStyle(fontSize: 16.0, color: Colors.black87),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.black54),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
      ),
    );

    static final ThemeData darkTheme = ThemeData(
            // ── And also here ──
           pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _CustomPageTransitionBuilder(),
           TargetPlatform.fuchsia: _CustomPageTransitionBuilder(),
           TargetPlatform.linux: _CustomPageTransitionBuilder(),
            TargetPlatform.macOS: _CustomPageTransitionBuilder(),
           TargetPlatform.windows: _CustomPageTransitionBuilder(),
           TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
          ),
      primaryColor: Colors.green[800], // Consistent primary color for dark
      colorScheme: const ColorScheme.dark(
        secondary: Colors.amber,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(fontSize: 16.0, color: Colors.white70),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.white60),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.greenAccent, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
      ),
    );
  }
  class _CustomPageTransitionBuilder extends PageTransitionsBuilder {
    const _CustomPageTransitionBuilder();

    @override
    Widget buildTransitions<T>(
        PageRoute<T> route,
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
        ) {
      // Animates opacity from 0→1 over the route's transitionDuration
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: child,
      );
    }
  }