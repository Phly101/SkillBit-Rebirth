import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillbit_rebirth/app/bloc/localeCubit/locale_cubit.dart';

void main() {
  late SharedPreferences prefs;

  Future<LocaleCubit> createCubit(Map<String, Object> saved) async {
    SharedPreferences.setMockInitialValues(saved);
    prefs = await SharedPreferences.getInstance();
    final cubit = LocaleCubit(prefs);
    addTearDown(cubit.close);
    return cubit;
  }

  // Runs [action] and returns every state the cubit emitted meanwhile
  Future<List<Locale?>> collectStates(
    LocaleCubit cubit,
    Future<void> Function() action,
  ) async {
    final states = <Locale?>[];
    final sub = cubit.stream.listen(states.add);
    await action();
    await Future<void>.delayed(Duration.zero); // let the stream deliver
    await sub.cancel();
    return states;
  }

  group('LocaleCubit', () {
    test('starts as null (follow device) when nothing is saved', () async {
      final cubit = await createCubit({});
      expect(cubit.state, isNull);
    });

    test('starts with the saved locale', () async {
      final cubit = await createCubit({'locale': 'ar'});
      expect(cubit.state, const Locale('ar'));
    });

    test('emits the new locale and saves its language code', () async {
      final cubit = await createCubit({});
      final states = await collectStates(
        cubit,
        () => cubit.setLocale(const Locale('ar')),
      );
      expect(states, [const Locale('ar')]);
      expect(prefs.getString('locale'), 'ar');
    });

    test('setting null emits null and removes the saved value', () async {
      final cubit = await createCubit({'locale': 'ar'});
      final states = await collectStates(cubit, () => cubit.setLocale(null));
      expect(states, [null]);
      expect(prefs.containsKey('locale'), isFalse);
    });
  });
}
