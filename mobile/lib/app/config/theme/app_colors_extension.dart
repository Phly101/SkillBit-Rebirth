// AI-generated (Claude), reviewed by the author.
import 'package:material_ui/material_ui.dart';
import 'package:skillbit_rebirth/app/config/theme/app_colors.dart';

/// Colors that Material's ColorScheme has no slot for
/// (success, warning, info, corner, shadow, inactive icon).
/// Read them anywhere with: context.appColors.success
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const new({
    required this.success,
    required this.warning,
    required this.info,
    required this.corner,
    required this.shadow,
    required this.inactiveIcon,
  });

  final Color success;
  final Color warning;
  final Color info;
  final Color corner;
  final Color shadow;
  final Color inactiveIcon;

  static const AppColorsExtension light = AppColorsExtension(
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.info,
    corner: AppColors.cornerLight,
    shadow: AppColors.shadowLight,
    inactiveIcon: AppColors.inactiveIcon,
  );

  static const AppColorsExtension dark = AppColorsExtension(
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.info,
    corner: AppColors.cornerDark,
    shadow: AppColors.shadowDark,
    inactiveIcon: AppColors.inactiveIcon,
  );

  @override
  AppColorsExtension copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? corner,
    Color? shadow,
    Color? inactiveIcon,
  }) {
    return AppColorsExtension(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      corner: corner ?? this.corner,
      shadow: shadow ?? this.shadow,
      inactiveIcon: inactiveIcon ?? this.inactiveIcon,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      corner: Color.lerp(corner, other.corner, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      inactiveIcon: Color.lerp(inactiveIcon, other.inactiveIcon, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>()!;
}
