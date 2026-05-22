import 'package:flutter/material.dart';
import '../../core/ui/responsive.dart';
import '../../core/theme/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color? backgroundColor;
  final bool showLogo;
  final PreferredSizeWidget? bottom;
  final bool constrainContent;
  final double? maxContentWidth;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.showLogo = false,
    this.backgroundColor,
    this.bottom,
    this.constrainContent = false,
    this.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      toolbarHeight: kToolbarHeight,
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      leading: null,
      title: _CustomAppBarContent(
        title: title,
        actions: actions,
        showBackButton: showBackButton,
        showLogo: showLogo,
      ),
      bottom: bottom,
    );

    if (!constrainContent) return appBar;

    return PreferredSize(
      preferredSize: preferredSize,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final r = R(Size(constraints.maxWidth, kToolbarHeight));
          final maxWidth = maxContentWidth ?? r.maxContentWidth;

          return AppBar(
            toolbarHeight: kToolbarHeight,
            backgroundColor: backgroundColor ?? Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            titleSpacing: 0,
            automaticallyImplyLeading: false,
            leading: null,
            title: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: _CustomAppBarContent(
                  title: title,
                  actions: actions,
                  showBackButton: showBackButton,
                  showLogo: showLogo,
                ),
              ),
            ),
            bottom: bottom == null
                ? null
                : PreferredSize(
                    preferredSize: bottom!.preferredSize,
                    child: Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: bottom!,
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

class _CustomAppBarContent extends StatelessWidget {
  const _CustomAppBarContent({
    required this.title,
    required this.actions,
    required this.showBackButton,
    required this.showLogo,
  });

  final Widget title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kToolbarHeight,
      child: Row(
        children: [
          if (showBackButton)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: SizedBox(
                width: 40,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    color: AppColors.textPrimary,
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            )
          else if (showLogo)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 12),
              child: Image.asset(
                'assets/images/logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            )
          else
            const SizedBox(width: 20),
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: title),
          ),
          if (actions != null) ...actions!,
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}
