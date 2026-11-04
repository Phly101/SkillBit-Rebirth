import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillbit_rebirth/app/bloc/localeCubit/locale_cubit.dart';
import 'package:skillbit_rebirth/app/bloc/themeCubit/theme_cubit.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();

  getIt
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerFactory<ThemeCubit>(() => ThemeCubit(getIt()))
    ..registerFactory<LocaleCubit>(() => LocaleCubit(getIt()));
}
