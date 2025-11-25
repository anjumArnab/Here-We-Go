// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:herewego/providers/route_provider.dart';
import 'package:provider/provider.dart';
import '../models/navigation_metrics.dart';
import '../app_theme.dart';

class NavigationMetricsPanel extends StatelessWidget {
  final NavigationMetrics? metrics;
  final bool isRerouting;
  final String? destinationUserId;
  final Function(String) onRouteModeChanged;
  final VoidCallback onStop;
  final VoidCallback? onRecenter;

  const NavigationMetricsPanel({
    super.key,
    required this.metrics,
    this.isRerouting = false,
    this.destinationUserId,
    required this.onRouteModeChanged,
    required this.onStop,
    this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          if (!isRerouting && metrics != null) _buildMetrics(context),
          if (isRerouting) _buildReroutingIndicator(context),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.navigationBlue.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusLarge),
          topRight: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: Row(
        children: [
          // Navigation icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.navigationBlue,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(Icons.navigation, color: AppTheme.cardWhite, size: 20),
          ),
          SizedBox(width: AppTheme.spacingSmall),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Navigating to',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  destinationUserId ?? 'Destination',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(BuildContext context) {
    if (metrics == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall + 4,
      ),
      child: Column(
        children: [
          Consumer<RouteProvider>(
            builder: (context, routeProvider, _) {
              return _buildRouteModeSelector(context, routeProvider);
            },
          ),

          SizedBox(height: AppTheme.spacingSmall + 4),
          // Progress bar
          _buildProgressBar(),
          SizedBox(height: AppTheme.spacingSmall + 4),

          // Metrics row
          Row(
            children: [
              // Distance
              Expanded(
                child: _buildMetricItem(
                  label: 'Distance',
                  value: metrics!.formattedDistance,
                  color: AppTheme.infoBlue,
                ),
              ),

              // Divider
              Container(width: 1, height: 40, color: AppTheme.gray200),

              // ETA
              Expanded(
                child: _buildMetricItem(
                  label: 'ETA',
                  value: metrics!.formattedETA,
                  color: AppTheme.primaryGreen,
                ),
              ),

              // Divider
              Container(width: 1, height: 40, color: AppTheme.gray200),

              // Speed
              Expanded(
                child: _buildMetricItem(
                  label: 'Speed',
                  value: metrics!.formattedSpeed,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    if (metrics == null) return const SizedBox.shrink();

    final progress = metrics!.progressPercentage / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress percentage text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${metrics!.progressPercentage.toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.navigationBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.navigationBlue),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReroutingIndicator(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.reroutingOrange,
              ),
            ),
          ),
          SizedBox(width: AppTheme.spacingSmall),
          Text(
            'Recalculating route...',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.reroutingOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingSmall + 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.radiusLarge),
          bottomRight: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: Row(
        children: [
          // Recenter button
          if (onRecenter != null)
            Expanded(
              child: _buildActionButton(
                label: 'Recenter',
                color: AppTheme.infoBlue,
                onTap: onRecenter!,
              ),
            ),

          if (onRecenter != null) SizedBox(width: AppTheme.spacingSmall),

          // Stop navigation button
          Expanded(
            flex: onRecenter != null ? 1 : 2,
            child: _buildActionButton(
              label: 'Stop',
              color: AppTheme.errorRed,
              onTap: onStop,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteModeSelector(
    BuildContext context,
    RouteProvider routeProvider,
  ) {
    final modes = ['driving', 'walking', 'cycling'];
    final icons = [
      Icons.directions_car,
      Icons.directions_walk,
      Icons.directions_bike,
    ];

    return Row(
      children: List.generate(modes.length, (index) {
        final mode = modes[index];
        final isSelected = routeProvider.routeMode == mode;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < modes.length - 1 ? AppTheme.spacingSmall - 2 : 0,
            ),
            child: InkWell(
              onTap: () => onRouteModeChanged(mode),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: AppTheme.spacingSmall - 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryNavy : AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryNavy : AppTheme.gray300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  icons[index],
                  color: isSelected ? AppTheme.cardWhite : AppTheme.gray600,
                  size: 16,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
