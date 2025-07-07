import 'package:flutter/material.dart';
import '../fonts.dart';
import '../spacing.dart';
import '../color_guide.dart';

class LoggitHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final Widget? trailing;
  final VoidCallback? onBack;

  const LoggitHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: LoggitSpacing.lg),
        height: preferredSize.height,
        color: LoggitColors.pureWhite,
        child: Row(
          children: [
            if (showBack)
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: LoggitColors.darkGrayText,
                ),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                splashRadius: 24,
              )
            else
              SizedBox(width: 40),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: LoggitFonts.headline.copyWith(
                    fontSize: 24,
                    color: LoggitColors.darkGrayText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (trailing != null) trailing! else SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
