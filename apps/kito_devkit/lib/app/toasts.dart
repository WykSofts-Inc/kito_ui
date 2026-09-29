// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:kito_ui_toasts/kito_ui_toasts.dart';

/// The app-wide toast center, hosted in `MaterialApp.builder` so toasts from any sample show
/// over every page and dialog.
final devKitToasts =
    KitoToastCenter(presentation: const KitoToastPresentation.stack());
