import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillbit_rebirth/app/bloc/themeCubit/theme_cubit.dart';

void main() {
  late SharedPreferences preferences;

  Future<void> loadPrefs(Map<String, Object> init) async {
    SharedPreferences.setMockInitialValues(init);
    preferences = await SharedPreferences.getInstance();
  }

  Future<ThemeCubit> createCubit(Map<String, Object> saved) async {
    SharedPreferences.setMockInitialValues(saved);
    preferences = await SharedPreferences.getInstance();
    final cubit = ThemeCubit(preferences);
    addTearDown(cubit.close);
    return cubit;
  }

  // Runs [action] and returns every state the cubit emitted meanwhile
  Future<List<ThemeMode>> collectStates(
    ThemeCubit cubit,
    Future<void> Function() action,
  ) async {
    final states = <ThemeMode>[];
    final sub = cubit.stream.listen(states.add);
    await action();
    await Future<void>.delayed(Duration.zero); // let the stream deliver
    await sub.cancel();
    return states;
  }

  group('ThemeCubit', () {
    test('starts as system when nothing is saved', () async {
      await loadPrefs({});
      expect(ThemeCubit(preferences).state, ThemeMode.system);
    });

    test('start with the saved mode', () async {
      await loadPrefs({'theme_mode': 'dark'});
      expect(ThemeCubit(preferences).state, ThemeMode.dark);
    });

    test('falls back to system when the save value is garbage', () async {
      await loadPrefs({'theme_mode': 'purple'});
      expect(ThemeCubit(preferences).state, ThemeMode.system);
    });
  });

  test('emits the new mod and saves it', () async {
    final cubit = await createCubit({});
    final states = await collectStates(
      cubit,
      () => cubit.setThemeMode(ThemeMode.light),
    );
    expect(states, [ThemeMode.light]);
    expect(preferences.getString('theme_mode'), 'light');
  });
  test('does not emit again when set to the same mode twice', () async {
    final cubit = await createCubit({});
    final states = await collectStates(cubit, () async {
      await cubit.setThemeMode(ThemeMode.light);
      await cubit.setThemeMode(ThemeMode.light);
    });
    // The first emit always goes through, the repeat is skipped
    expect(states, [ThemeMode.light]);
  });
}
