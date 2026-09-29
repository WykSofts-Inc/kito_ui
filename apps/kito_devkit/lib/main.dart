// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_toasts/kito_ui_toasts.dart';

import 'app/settings.dart';
import 'app/toasts.dart';
import 'home/home_page.dart';

void main() => runApp(KitoDevKitApp(settings: AppSettings()));

class KitoDevKitApp extends StatelessWidget {
  const KitoDevKitApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      settings: settings,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          title: 'Kito UI',
          debugShowCheckedModeBanner: false,
          theme: settings.lightTheme().toThemeData(),
          darkTheme: settings.darkTheme().toThemeData(),
          themeMode: settings.themeMode,
          builder: (context, child) => settings.applyDirection(
            // Toasts from any sample show above every page and dialog.
            KitoToastHost(
                center: devKitToasts, child: child ?? const SizedBox()),
          ),
          home: const HomePage(),
        ),
      ),
    );
  }
}
