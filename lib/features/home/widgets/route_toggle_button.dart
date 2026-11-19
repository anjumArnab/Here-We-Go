import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../location/providers/location_provider.dart';
import '../../navigation/providers/navigation_provider.dart';

/// App bar button that shows or hides routes to the other users.
class RouteToggleButton extends StatelessWidget {
  final bool showRoutes;
  final VoidCallback onToggle;

  const RouteToggleButton({
    super.key,
    required this.showRoutes,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocationProvider, NavigationProvider>(
      builder: (context, locationProvider, navigationProvider, _) {
        final hasUsers = locationProvider.userLocations.isNotEmpty;
        final isNavigating = navigationProvider.isActive;

        return Container(
          margin: EdgeInsets.only(right: AppTheme.spacingSmall),
          decoration: BoxDecoration(
            color: showRoutes ? AppTheme.primaryGreen : AppTheme.cardWhite,
            shape: BoxShape.circle,
            boxShadow: [AppTheme.lightShadow],
          ),
          child: IconButton(
            onPressed: (hasUsers && !isNavigating) ? onToggle : null,
            icon: Icon(
              showRoutes ? Icons.route : Icons.route_outlined,
              color: showRoutes ? AppTheme.cardWhite : AppTheme.textDark,
            ),
            tooltip: showRoutes ? 'Hide Routes' : 'Show Routes',
          ),
        );
      },
    );
  }
}
