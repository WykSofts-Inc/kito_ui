// Copyright © 2026 wyksoftsinc.com. All rights reserved.
// Created by Wycliff Njenga on 29/09/2026.

import 'package:flutter/material.dart';
import 'package:kito_ui_core/kito_ui_core.dart';

import '../app/settings.dart';

/// The app's own settings: theme and layout direction.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final settings = AppSettingsScope.of(context);
    return Scaffold(
      backgroundColor: theme.colors.background,
      appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: theme.colors.background,
          surfaceTintColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Group(
            title: 'Theme',
            footer:
                'Every kit reads KitoTheme, so the whole app changes together.',
            child: Row(
              children: [
                for (final choice in ThemeChoice.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _ThemeSwatch(
                        choice: choice,
                        selected: settings.theme == choice,
                        onTap: () => settings.theme = choice,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Group(
            title: 'Layout direction',
            footer:
                'Right to left flips the whole app, so you can check every kit in Arabic or Hebrew layouts.',
            child: Column(
              children: [
                for (final choice in DirectionChoice.values)
                  Semantics(
                    selected: settings.direction == choice,
                    button: true,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        choice.label,
                        style: theme.typography.body
                            .copyWith(color: theme.colors.onSurface),
                      ),
                      trailing: AnimatedOpacity(
                        duration: KitoMotion.of(context, theme.motion.fast),
                        opacity: settings.direction == choice ? 1 : 0,
                        child: Icon(Icons.check_rounded,
                            color: theme.colors.primary),
                      ),
                      onTap: () => settings.direction = choice,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Group(
            title: 'About',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kito UI DevKit 1.0.0',
                    style: theme.typography.bodyEmphasized
                        .copyWith(color: theme.colors.onSurface)),
                const SizedBox(height: 4),
                Text(
                  'Every Kito Flutter kit, live. Built by Wycliff Njenga · wyksoftsinc.com',
                  style: theme.typography.caption.copyWith(
                      color: theme.colors.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.child, this.footer});

  final String title;
  final Widget child;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Text(title.toUpperCase(),
              style: theme.typography.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: theme.colors.primary)),
        ),
        KitoSurface(
            border: true,
            padding: const EdgeInsets.all(14),
            // ListTiles need a Material under them to paint their ink.
            child: Material(type: MaterialType.transparency, child: child)),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 0),
            child: Text(footer!,
                style: theme.typography.caption.copyWith(
                    color: theme.colors.onBackground.withValues(alpha: 0.55))),
          ),
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch(
      {required this.choice, required this.selected, required this.onTap});

  final ThemeChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.kito;
    final colors = switch (choice) {
      ThemeChoice.light => KitoColors.light,
      ThemeChoice.dark => KitoColors.dark,
      ThemeChoice.neon => KitoColors.neon,
      ThemeChoice.system => null,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: '${choice.label} theme',
      child: KitoPressable(
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              AnimatedContainer(
                duration: KitoMotion.of(context, theme.motion.medium),
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color:
                          selected ? theme.colors.primary : theme.colors.border,
                      width: selected ? 2.5 : 1),
                  gradient: colors == null
                      ? const LinearGradient(colors: [
                          Color(0xFFF6F6F8),
                          Color(0xFFF6F6F8),
                          Color(0xFF0B0B0F),
                          Color(0xFF0B0B0F)
                        ], stops: [
                          0,
                          0.5,
                          0.5,
                          1
                        ])
                      : LinearGradient(
                          colors: [colors.background, colors.surface]),
                ),
                child: Center(
                  child: Container(
                    width: 30,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors?.primary ?? const Color(0xFF7C7C88),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(choice.label,
                  style: theme.typography.caption.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      color: theme.colors.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}
