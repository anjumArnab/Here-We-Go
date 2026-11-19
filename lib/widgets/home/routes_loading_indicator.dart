import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/route_provider.dart';

/// Small "Loading Routes..." badge pinned to the top-left of the map.
/// Must be placed inside a [Stack].
class RoutesLoadingIndicator extends StatelessWidget {
  const RoutesLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteProvider>(
      builder: (context, routeProvider, _) {
        if (!routeProvider.isLoadingRoutes) return const SizedBox.shrink();

        return Positioned(
          top: AppTheme.position,
          left: AppTheme.position,
          child: Container(
            padding: EdgeInsets.all(AppTheme.spacingSmall + 4),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: [AppTheme.lightShadow],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.infoBlue,
                  ),
                ),
                SizedBox(width: AppTheme.spacingSmall),
                Text(
                  'Loading Routes...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.infoBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
