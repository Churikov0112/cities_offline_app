import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class BottomSheetController {
  static const _defaultCurve = Curves.easeOut;

  static Future<T?> showBottomSheet<T>(
    BuildContext context,
    WidgetBuilder childBuilder, {
    bool expand = false,
    bool enableDrag = true,
    String? routeName,
  }) async {
    return showBarModalBottomSheet<T?>(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      settings: routeName != null ? RouteSettings(name: routeName) : null,
      expand: expand,
      enableDrag: enableDrag,
      elevation: 0,
      useRootNavigator: true,
      animationCurve: _defaultCurve,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.transparent,
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      topControl: Builder(
        builder: (context) {
          final theme = Theme.of(context);

          return SizedBox(
            width: 28,
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: const BorderRadius.all(Radius.circular(42)),
              ),
            ),
          );
        },
      ),
      builder: (context) => childBuilder(context),
    );
  }
}
