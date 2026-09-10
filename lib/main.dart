import 'package:flutter/material.dart';

import 'global_presentation/pixel_ui/pixel_ui.dart';
import 'exploration/exploration_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EXPCOMP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'monospace',
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: PixelUiMetrics.title),
          bodyMedium: TextStyle(fontSize: PixelUiMetrics.body),
          bodySmall: TextStyle(fontSize: PixelUiMetrics.caption),
        ),
        // Sunderkeep is the shared menu skin; creature cards override it by source.
        extensions: <ThemeExtension<dynamic>>[SunderedKeepUi.theme],
      ),
      home: const ExplorationPage(),
    );
  }
}
