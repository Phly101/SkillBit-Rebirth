import 'package:bloc/bloc.dart';
import 'package:skillbit_rebirth/core/logging/app_logger.dart';

class AppBlocObserver extends BlocObserver {
  static final AppLogger _log = AppLogger('BlocObserver');

  /// Sees every cubit/bloc in the app, so individual cubits need no logging.
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    _log.debug('${bloc.runtimeType} created');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    _log.info(
      '${bloc.runtimeType}: ${change.currentState} -> ${change.nextState}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _log.error(
      '${bloc.runtimeType} threw an error',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    _log.debug('${bloc.runtimeType} closed');
  }
}
