import 'package:bloc/bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale?> {
  new(this._prefs) : super(_read(_prefs));
  static const String _key = 'locale';
  final SharedPreferences _prefs;

  static Locale? _read(SharedPreferences prefs) {
    final code = prefs.getString(_key);
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    emit(locale);
    if (locale == null) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, locale.languageCode);
    }
  }
}
