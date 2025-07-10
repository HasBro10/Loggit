import 'package:flutter/material.dart';
import '../utils/responsive.dart';

/// Responsive layout widget that adapts content based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? fallback;

  const ResponsiveLayout({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (Responsive.isTablet(context) && tablet != null) {
      return tablet!;
    }
    if (Responsive.isMobile(context) && mobile != null) {
      return mobile!;
    }
    return fallback ?? mobile ?? tablet ?? desktop ?? const SizedBox();
  }
}

/// Responsive container with adaptive padding and constraints
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final bool centerContent;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = padding ?? Responsive.screenPadding(context);
    final adaptiveMaxWidth = maxWidth ?? Responsive.maxContentWidth(context);

    Widget content = Container(
      constraints: BoxConstraints(maxWidth: adaptiveMaxWidth),
      padding: adaptivePadding,
      child: child,
    );

    if (centerContent) {
      content = Center(child: content);
    }

    return content;
  }
}

/// Responsive grid that adapts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    int columns;
    if (Responsive.isDesktop(context)) {
      columns = desktopColumns ?? 3;
    } else if (Responsive.isTablet(context)) {
      columns = tabletColumns ?? 2;
    } else {
      columns = mobileColumns ?? 1;
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.map((child) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 
                  (spacing * (columns - 1)) - 
                  Responsive.screenPadding(context).horizontal) / columns,
          child: child,
        );
      }).toList(),
    );
  }
}

/// Responsive text that scales appropriately
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double baseFontSize;
  final double? minFontSize;
  final double? maxFontSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.baseFontSize = 16,
    this.minFontSize,
    this.maxFontSize,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveSize = Responsive.responsiveFont(
      context,
      baseFontSize,
      min: minFontSize ?? 12,
      max: maxFontSize ?? 28,
    );

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(fontSize: responsiveSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive spacing widget
class ResponsiveSpacing extends StatelessWidget {
  final double baseSize;
  final Axis direction;

  const ResponsiveSpacing(
    this.baseSize, {
    super.key,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final adaptiveSize = Responsive.adaptiveSpacing(context, baseSize);
    
    return SizedBox(
      width: direction == Axis.horizontal ? adaptiveSize : null,
      height: direction == Axis.vertical ? adaptiveSize : null,
    );
  }
}

/// Responsive row/column layout that switches based on screen size
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool forceColumn;
  final double spacing;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.forceColumn = false,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    // Use column layout on mobile or if forced
    final useColumn = forceColumn || Responsive.isMobile(context);

    if (useColumn) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _addSpacing(children, true),
      );
    } else {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: _addSpacing(children, false),
      );
    }
  }

  List<Widget> _addSpacing(List<Widget> widgets, bool isColumn) {
    final List<Widget> spacedWidgets = [];
    for (int i = 0; i < widgets.length; i++) {
      spacedWidgets.add(widgets[i]);
      if (i < widgets.length - 1) {
        spacedWidgets.add(
          isColumn 
            ? SizedBox(height: spacing)
            : SizedBox(width: spacing),
        );
      }
    }
    return spacedWidgets;
  }
}