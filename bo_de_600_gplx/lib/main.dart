import 'package:flutter/material.dart';

import 'package:bo_de_600_gplx/router/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DrivePrep',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF2C5C7C)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
            foregroundColor: Colors.black,
            elevation: 0,
            scrolledUnderElevation: 0, // ✅ không phủ màu khi cuộn (M3)
            surfaceTintColor: Colors.transparent, // ✅ tránh lớp tint của M3
            shadowColor: Colors.transparent),
      ),
      debugShowCheckedModeBanner: false,

      initialRoute: AppRouter.splash,
      routes: AppRouter.routes, // check login trước
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
