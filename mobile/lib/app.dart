import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skillbit_rebirth/app/bloc/localeCubit/locale_cubit.dart';
import 'package:skillbit_rebirth/app/bloc/themeCubit/theme_cubit.dart';
import 'package:skillbit_rebirth/app/config/l10n/app_localizations.dart';
import 'package:skillbit_rebirth/app/config/theme/app_theme.dart';
import 'package:skillbit_rebirth/core/services/di/injection.dart';

class SkillbitApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ThemeCubit>()),
        BlocProvider(create: (_) => getIt<LocaleCubit>()),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    final locale = context.watch<LocaleCubit>().state;

    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Placeholder(),
    );
  }
}
