import 'package:material_ui/material_ui.dart';

class AppColors {
  new _();

  // AI-generated (Claude), reviewed by the author.
  // ───────── Shared (same in light & dark) ─────────
  static const Color border = Color(0xFFA5BFE3);
  static const Color primary = Color(0xFF1370D3);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color tertiary = Color(0xFF4F3EF3);
  static const Color info = Color(0xFF3B82F6);
  static const Color gitColor = Color(0xFFF05133);
  static const Color gitCommand = Color(0xFF0D9488);
  static const Color terminal = Color(0xFF191D22);
  static const Color inactiveIcon = Color(0xFF666666);

  // Pills
  static const Color successPill = Color(0xFFC6ECE6);
  static const Color errorPill = Color(0xFFF2D5DA);
  static const Color warningPill = Color(0xFFFCE2B6);
  static const Color tertiaryPill = Color(0xFFE2E6FF);
  static const Color tertiaryCard = Color(0xFF24244C);
  static const Color errorBackground = Color(0xFFFDE3E3);

  // ───────── Light theme ─────────
  static const Color backgroundLight = Color(0xFFF3F9FF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textMainLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF869ED5);
  static const Color cornerLight = Color(0xFFD8EAFB);
  static const Color shadowLight = Color(0xFF111827);

  // ───────── Dark theme ─────────
  static const Color backgroundDark = Color(0xFF191D22);
  static const Color cardDark = Color(0xFF111827);
  static const Color textMainDark = Color(0xFFF3F9FF);
  static const Color textSecondaryDark = Color(0xFF9AB3F4);
  static const Color cornerDark = Color(0xFFE5F0FB);
  static const Color shadowDark = Color(0xFFF3F9FF);

  // ───────── Gradients ─────────
  static const LinearGradient activeStatus = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF09B89C), Color(0xFF13D4C7), Color(0xFF07CED2)],
  );

  static const LinearGradient completedStatus = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF96EC76), Color(0xFF4CD887), Color(0xFF06B49E)],
  );

  static const LinearGradient mainButtons = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFF1859D0), Color(0xFF107BD5), Color(0xFF0A97D2)],
  );

  static const LinearGradient strokes = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1669D3), Color(0xFF1678DD), Color(0xFF195DD4)],
  );

  static const LinearGradient percentage = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF25CE9F), Color(0xFF00AFDB), Color(0xFF5264F8)],
  );

  static const LinearGradient minorUses = LinearGradient(
    colors: [Color(0xFF74E180), Color(0xFF05C6B5), Color(0xFF09ADCD)],
  );
}
