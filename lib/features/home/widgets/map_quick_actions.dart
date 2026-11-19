import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../connection/providers/connection_provider.dart';
import '../../location/providers/location_provider.dart';
import '../../../shared/widgets/app_chip_button.dart';

/// Row of quick-action chips ("All of Us", "Refresh", "Me") over the map.
class MapQuickActions extends StatelessWidget {
  final VoidCallback onShowAll;
  final VoidCallback onRefresh;
  final VoidCallback onMyLocation;

  const MapQuickActions({
    super.key,
    required this.onShowAll,
    required this.onRefresh,
    required this.onMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, _) {
        final locationProvider = context.read<LocationProvider>();
        return Row(
          children: [
            if (locationProvider.userLocations.isNotEmpty)
              AppChipButton(label: 'All of Us', onTap: onShowAll),
            const SizedBox(width: 10),
            AppChipButton(label: 'Refresh', onTap: onRefresh),
            const SizedBox(width: 10),
            AppChipButton(label: 'Me', onTap: onMyLocation),
          ],
        );
      },
    );
  }
}
