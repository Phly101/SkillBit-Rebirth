import 'package:bloc/bloc.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skillbit_rebirth/app.dart';
import 'package:skillbit_rebirth/app/observers/app_bloc_observer.dart';
import 'package:skillbit_rebirth/core/services/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  Bloc.observer = AppBlocObserver();
  await configureDependencies();
  runApp(const SkillbitApp());
}
