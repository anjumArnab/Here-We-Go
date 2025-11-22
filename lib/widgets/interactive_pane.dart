// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'app_action_button.dart';
import '../app_theme.dart';
import '../widgets/app_text_field.dart';
import '../providers/connection_provider.dart';
import '../providers/location_provider.dart';
import '../providers/route_provider.dart';
import '../models/user_location.dart';

class InteractivePane extends StatelessWidget {
  final LatLng? currentLocation;
  final VoidCallback? onSendLocation;
  final TextEditingController serverUrlController;
  final TextEditingController roomIdController;
  final TextEditingController userIdController;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final Function(String) onRouteModeChanged;
  final VoidCallback onRouteFilterChanged;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const InteractivePane({
    super.key,
    required this.currentLocation,
    required this.onSendLocation,
    required this.serverUrlController,
    required this.roomIdController,
    required this.userIdController,
    required this.onConnect,
    required this.onDisconnect,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onRouteModeChanged,
    required this.onRouteFilterChanged,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 10,
      left: 10,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.50,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [AppTheme.cardShadow],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (isExpanded)
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: PageView(
                        controller: pageController,
                        onPageChanged: onPageChanged,
                        children: [
                          _buildServerConnectionSection(context),
                          _buildLocationSenderSection(context),
                          _buildRoutesSection(context),
                        ],
                      ),
                    ),
                    _buildPageIndicator(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingSmall),
      child: CircleAvatar(
        backgroundColor: AppTheme.primaryNavy,
        child: IconButton(
          icon: Icon(
            isExpanded ? Icons.expand_more : Icons.expand_less,
            color: AppTheme.cardWhite,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onToggleExpand,
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: AppTheme.spacingSmall,
        top: AppTheme.spacingSmall - 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingXSmall),
            width: currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color:
                  currentPage == index
                      ? AppTheme.primaryGreen
                      : AppTheme.gray300,
              borderRadius: BorderRadius.circular(AppTheme.spacingXSmall),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildServerConnectionSection(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, _) {
        final isConnected = connectionProvider.isConnected;
        final isConnecting = connectionProvider.isConnecting;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    isConnected ? Icons.cloud_done : Icons.cloud_off,
                    color:
                        isConnected ? AppTheme.successGreen : AppTheme.gray600,
                    size: 16,
                  ),
                  SizedBox(width: AppTheme.spacingSmall - 2),
                  Text(
                    'Connect with your friends',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingSmall + 2),
              if (!isConnected) ...[
                AppTextField(
                  controller: serverUrlController,
                  hint: 'https://abc123.ngrok.io',
                  icon: Icons.cloud,
                ),
                SizedBox(height: AppTheme.spacingSmall),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: roomIdController,
                        hint: 'Room ID',
                        icon: Icons.meeting_room,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacingSmall),
                    Expanded(
                      child: AppTextField(
                        controller: userIdController,
                        hint: 'User ID',
                        icon: Icons.person,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingSmall + 2),
                AppActionButton(
                  label: isConnecting ? 'Connecting...' : 'Connect',
                  icon: Icons.link,
                  backgroundColor: AppTheme.infoBlue,
                  foregroundColor: AppTheme.cardWhite,
                  onPressed: isConnecting ? null : onConnect,
                ),
              ] else ...[
                _buildConnectionInfo(connectionProvider),
                SizedBox(height: AppTheme.spacingSmall + 2),
                AppActionButton(
                  label: 'Disconnect',
                  icon: Icons.link_off,
                  backgroundColor: AppTheme.errorRed,
                  foregroundColor: AppTheme.cardWhite,
                  onPressed: onDisconnect,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionInfo(ConnectionProvider connectionProvider) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingSmall),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Text(
        'Connected with room ${connectionProvider.currentRoomId ?? "N/A"}\n'
        'You: ${connectionProvider.currentUserId ?? "N/A"}\n'
        'Friends: ${connectionProvider.roomUsers.length} online • ${connectionProvider.connectionStatusMessage ?? "Connected"}',
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.successGreen,
          fontWeight: FontWeight.w500,
        ),
        softWrap: true,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildLocationSenderSection(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, _) {
        final isConnected = connectionProvider.isConnected;
        final hasLocation = currentLocation != null;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.my_location,
                    color:
                        hasLocation ? AppTheme.successGreen : AppTheme.gray600,
                    size: 16,
                  ),
                  SizedBox(width: AppTheme.spacingSmall - 2),
                  Text(
                    'Send them your location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              if (hasLocation) ...[
                SizedBox(height: AppTheme.spacingSmall + 2),
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.gray100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: AppTheme.gray200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'You are currently on\nLat: ${currentLocation!.latitude.toStringAsFixed(5)} • Lng: ${currentLocation!.longitude.toStringAsFixed(5)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.infoBlue,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: AppTheme.spacingSmall + 2),
              AppActionButton(
                label: isConnected ? 'Send Location' : 'Connect First',
                icon: Icons.send,
                backgroundColor:
                    isConnected ? AppTheme.successGreen : AppTheme.gray400,
                foregroundColor: AppTheme.cardWhite,
                onPressed: isConnected && hasLocation ? onSendLocation : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoutesSection(BuildContext context) {
    return Consumer3<ConnectionProvider, LocationProvider, RouteProvider>(
      builder: (context, connectionProvider, locationProvider, routeProvider, _) {
        final userLocations = locationProvider.userLocations;
        final currentUserId = connectionProvider.currentUserId;

        final otherUsers =
            userLocations.entries.where((e) => e.key != currentUserId).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.route, color: AppTheme.primaryNavy, size: 16),
                  SizedBox(width: AppTheme.spacingSmall - 2),
                  Text(
                    'See where your friends are',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingSmall + 2),
              _buildRouteModeSelector(context, routeProvider),
              if (otherUsers.isNotEmpty) ...[
                SizedBox(height: AppTheme.spacingSmall + 2),
                _buildMergedShowRoutesToSection(
                  context,
                  otherUsers,
                  routeProvider,
                ),
              ] else ...[
                SizedBox(height: AppTheme.spacingSmall + 2),
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingSmall + 2),
                  decoration: BoxDecoration(
                    color: AppTheme.gray100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.gray600,
                        size: 14,
                      ),
                      SizedBox(width: AppTheme.spacingSmall),
                      Expanded(
                        child: Text(
                          'Your friends are not sharing their location yet',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.gray700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMergedShowRoutesToSection(
    BuildContext context,
    List<MapEntry<String, UserLocation>> otherUsers,
    RouteProvider routeProvider,
  ) {
    final isAllSelected = routeProvider.selectedUsers.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Show Routes To:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        SizedBox(height: AppTheme.spacingSmall),
        Wrap(
          spacing: AppTheme.spacingSmall,
          runSpacing: AppTheme.spacingSmall,
          children: [
            _buildAllUsersChip(
              context,
              isAllSelected,
              otherUsers,
              routeProvider,
            ),
            ...otherUsers.map(
              (entry) => _buildUserRouteChip(
                context,
                entry.key,
                entry.value,
                isAllSelected,
                routeProvider,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAllUsersChip(
    BuildContext context,
    bool isAllSelected,
    List<MapEntry<String, UserLocation>> otherUsers,
    RouteProvider routeProvider,
  ) {
    return InkWell(
      onTap: () {
        if (isAllSelected) {
          routeProvider.setSelectedUsers(otherUsers.map((e) => e.key).toList());
        } else {
          routeProvider.clearSelectedUsers();
        }
        onRouteFilterChanged();
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: AppTheme.spacingSmall + 2,
        ),
        decoration: BoxDecoration(
          color:
              isAllSelected
                  ? AppTheme.primaryGreen.withOpacity(0.15)
                  : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isAllSelected ? AppTheme.primaryGreen : AppTheme.gray300,
            width: isAllSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAllSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: isAllSelected ? AppTheme.primaryGreen : AppTheme.gray600,
            ),
            SizedBox(width: AppTheme.spacingSmall),
            Text(
              'Everyone',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isAllSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isAllSelected ? AppTheme.primaryGreen : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRouteChip(
    BuildContext context,
    String userId,
    UserLocation location,
    bool isAllSelected,
    RouteProvider routeProvider,
  ) {
    final isUserSelected =
        isAllSelected || routeProvider.selectedUsers.contains(userId);
    final isEnabled = !isAllSelected;

    final routeInfo =
        currentLocation != null
            ? routeProvider.getRouteInfo(
              userId: userId,
              userLocation: location,
              currentLocation: currentLocation!,
            )
            : null;

    return InkWell(
      onTap:
          isEnabled
              ? () {
                if (isUserSelected) {
                  routeProvider.removeSelectedUser(userId);
                } else {
                  routeProvider.addSelectedUser(userId);
                }
                onRouteFilterChanged();
              }
              : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: AppTheme.spacingSmall + 2,
        ),
        decoration: BoxDecoration(
          color:
              isUserSelected && isEnabled
                  ? AppTheme.infoBlue.withOpacity(0.15)
                  : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color:
                isUserSelected && isEnabled
                    ? AppTheme.infoBlue
                    : AppTheme.gray300,
            width: isUserSelected && isEnabled ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUserSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color:
                  isEnabled
                      ? (isUserSelected ? AppTheme.infoBlue : AppTheme.gray600)
                      : AppTheme.gray400,
            ),
            SizedBox(width: AppTheme.spacingSmall),
            Text(
              userId,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isUserSelected && isEnabled
                        ? FontWeight.w600
                        : FontWeight.w500,
                color:
                    isEnabled
                        ? (isUserSelected
                            ? AppTheme.infoBlue
                            : AppTheme.textDark)
                        : AppTheme.gray400,
              ),
            ),
            if (routeInfo != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '•',
                  style: TextStyle(
                    fontSize: 13,
                    color: isEnabled ? AppTheme.gray600 : AppTheme.gray400,
                  ),
                ),
              ),
              Text(
                routeInfo.lastUpdated,
                style: TextStyle(
                  fontSize: 11,
                  color: isEnabled ? AppTheme.textGray : AppTheme.gray400,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '•',
                  style: TextStyle(
                    fontSize: 13,
                    color: isEnabled ? AppTheme.gray600 : AppTheme.gray400,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.straighten,
                    size: 12,
                    color: isEnabled ? AppTheme.gray600 : AppTheme.gray400,
                  ),
                  SizedBox(width: 3),
                  Text(
                    routeInfo.directDistance,
                    style: TextStyle(
                      fontSize: 11,
                      color: isEnabled ? AppTheme.gray700 : AppTheme.gray400,
                    ),
                  ),
                ],
              ),
            ],
          ],
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