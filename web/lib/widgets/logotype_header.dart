import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LogotypeHeader extends StatelessWidget {
  const LogotypeHeader({
    super.key,
    this.height = 48,
    this.onTap,
  });

  final double height;

  /// Called when the logotype is tapped. If null, defaults to popping to the
  /// root route via [Navigator.popUntil].
  final Future<bool> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (onTap != null) {
          final shouldNavigate = await onTap!();
          if (!shouldNavigate || !context.mounted) return;
        }
        if (!context.mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(
            themeNotifier.isDark
                ? 'assets/meetspace_logotype_darkmode.png'
                : 'assets/meetspace_logotype_lightmode.png',
            height: height,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
