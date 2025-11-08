// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'app_action_button.dart';
import '../app_theme.dart';
import '../widgets/app_text_field.dart';
import '../services/location_service.dart';
import '../services/route_service.dart';
import '../models/user_location.dart';
import '../models/connection_status.dart';

class InteractivePane extends StatefulWidget {
  final LocationService locationService;
  final RouteService routeService;
  final LatLng? currentLocation;
  final VoidCallback? onSendLocation;
  final TextEditingController serverUrlController;
  final TextEditingController roomIdController;
  final TextEditingController userIdController;
  final bool isConnecting;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final Function(String) onRouteModeChanged;
  final VoidCallback onRouteFilterChanged;
  const InteractivePane({
    super.key,
    required this.locationService,
    required this.routeService,
    required this.currentLocation,
    required this.onSendLocation,
    required this.serverUrlController,
    required this.roomIdController,
    required this.userIdController,
    required this.isConnecting,
    required this.onConnect,
    required this.onDisconnect,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onRouteModeChanged,
    required this.onRouteFilterChanged,
  });

  @override
  State<InteractivePane> createState() => _InteractivePaneState();
}

class _InteractivePaneState extends State<InteractivePane> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
            if (widget.isExpanded)
              Flexible(
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        children: [
                          _buildServerConnectionSection(),
                          _buildLocationSenderSection(),
                          _buildRoutesSection(),
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
            widget.isExpanded ?  Icons.expand_more : Icons.expand_less,
            color: AppTheme.cardWhite,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: widget.onToggleExpand,
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingXSmall),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color:
                  _currentPage == index
                      ? AppTheme.primaryGreen
                      : AppTheme.gray300,
              borderRadius: BorderRadius.circular(AppTheme.spacingXSmall),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildServerConnectionSection() {
    final isConnected = widget.locationService.isConnected;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: isConnected ? AppTheme.successGreen : AppTheme.gray600,
                size: 16,
              ),
              SizedBox(width: AppTheme.spacingSmall - 2),
              Text(
                'Connect with your friends',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingSmall + 2),
          if (!isConnected) ...[
            AppTextField(
              controller: widget.serverUrlController,
              label: '',
              hint: 'https://abc123.ngrok.io',
              icon: Icons.cloud,
            ),
            SizedBox(height: AppTheme.spacingSmall),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: widget.roomIdController,
                    label: '',
                    hint: 'Room ID',
                    icon: Icons.meeting_room,
                  ),
                ),
                SizedBox(width: AppTheme.spacingSmall),
                Expanded(
                  child: AppTextField(
                    controller: widget.userIdController,
                    label: '',
                    hint: 'User ID',
                    icon: Icons.person,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingSmall + 2),

            AppActionButton(
              label: 'Connect',
              icon: Icons.link,
              backgroundColor: AppTheme.infoBlue,
              foregroundColor: AppTheme.cardWhite,
              onPressed: widget.isConnecting ? null : widget.onConnect,
            ),
          ] else ...[
            _buildConnectionInfo(),
            SizedBox(height: AppTheme.spacingSmall),

            AppActionButton(
              label: 'Disconnect',
              icon: Icons.link_off,
              backgroundColor: AppTheme.errorRed,
              foregroundColor: AppTheme.cardWhite,
              onPressed: widget.onDisconnect,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionInfo() {
    return StreamBuilder<ConnectionStatus>(
      stream: widget.locationService.connectionStream,
      initialData: ConnectionStatus(
        isConnected: widget.locationService.isConnected,
        roomId: widget.locationService.currentRoomId,
        userId: widget.locationService.currentUserId,
        roomUsers: widget.locationService.roomUsers,
      ),
      builder: (context, snapshot) {
        final status = snapshot.data;

        return Container(
          padding: EdgeInsets.all(AppTheme.spacingSmall),
          decoration: BoxDecoration(
            color: AppTheme.gray100,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: AppTheme.gray200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.successGreen,
                    size: 14,
                  ),
                  SizedBox(width: AppTheme.spacingSmall - 2),
                  Expanded(
                    child: Text(
                      status != null
                          ? '${status.message ?? "Connected"} • Room: ${status.roomId ?? "N/A"} • User: ${status.userId ?? "N/A"} • Users: ${status.roomUsers.length}'
                          : 'Connected',
                      style: TextStyle(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationSenderSection() {
    final isConnected = widget.locationService.isConnected;
    final hasLocation = widget.currentLocation != null;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.my_location,
                color: hasLocation ? AppTheme.successGreen : AppTheme.gray600,
                size: 16,
              ),
              SizedBox(width: AppTheme.spacingSmall - 2),
              Text(
                'Send them your location',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacingSmall + 2),
          if (hasLocation)
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
                      'You are currently on Lat: ${widget.currentLocation!.latitude.toStringAsFixed(5)} • Lng: ${widget.currentLocation!.longitude.toStringAsFixed(5)}',
                      style: TextStyle(fontSize: 10, color: AppTheme.infoBlue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: AppTheme.spacingSmall + 2),
          AppActionButton(
            label: isConnected ? 'Send Location' : 'Connect First',
            icon: Icons.send,
            backgroundColor:
                isConnected ? AppTheme.successGreen : AppTheme.gray400,
            foregroundColor: AppTheme.cardWhite,
            onPressed:
                isConnected && hasLocation ? widget.onSendLocation : null,
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesSection() {
    return StreamBuilder<Map<String, UserLocation>>(
      stream: widget.locationService.allLocationsStream,
      initialData: widget.locationService.userLocations,
      builder: (context, snapshot) {
        final userLocations = snapshot.data ?? {};
        final currentUserId = widget.locationService.currentUserId;

        final otherUsers =
            userLocations.entries.where((e) => e.key != currentUserId).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppTheme.spacingMedium),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSmall - 2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.gray100,
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                    child: Text(
                      '${otherUsers.length}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.primaryNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingSmall + 2),
              _buildRouteModeSelector(),
              SizedBox(height: AppTheme.spacingSmall),

              // Show Routes To section
              if (otherUsers.isNotEmpty) ...[
                _buildShowRoutesToSection(otherUsers),
                SizedBox(height: AppTheme.spacingSmall),
              ],

              if (otherUsers.isEmpty)
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
                            color: AppTheme.gray700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children:
                      otherUsers
                          .map(
                            (entry) => _buildRouteItem(entry.key, entry.value),
                          )
                          .toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  // Show Routes To section with All Users toggle and individual checkboxes
  Widget _buildShowRoutesToSection(
    List<MapEntry<String, UserLocation>> otherUsers,
  ) {
    final currentUserId = widget.locationService.currentUserId;
    final isAllSelected = widget.routeService.selectedUsers.isEmpty;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacingSmall),
      decoration: BoxDecoration(
        color: AppTheme.gray300,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            'Show Routes To:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: AppTheme.spacingSmall - 2),

          // All Users checkbox
          InkWell(
            onTap: () {
              if (isAllSelected) {
                // If all is selected, select all users individually
                widget.routeService.setSelectedUsers(
                  otherUsers.map((e) => e.key).toList(),
                );
              } else {
                // Clear selection (which means show all)
                widget.routeService.clearSelectedUsers();
              }
              widget.onRouteFilterChanged();
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSmall - 2,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color:
                    isAllSelected
                        ? AppTheme.primaryGreen.withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    isAllSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 16,
                    color:
                        isAllSelected
                            ? AppTheme.primaryGreen
                            : AppTheme.gray600,
                  ),
                  SizedBox(width: AppTheme.spacingSmall - 2),
                  Text(
                    'All Users',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isAllSelected ? FontWeight.w600 : FontWeight.normal,
                      color:
                          isAllSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 4),
          Divider(height: 1, color: AppTheme.gray200),
          SizedBox(height: 4),

          // Individual user checkboxes
          ...otherUsers.map((entry) {
            final userId = entry.key;
            final isUserSelected =
                isAllSelected ||
                widget.routeService.selectedUsers.contains(userId);
            final isEnabled = !isAllSelected;

            return InkWell(
              onTap:
                  isEnabled
                      ? () {
                        if (isUserSelected) {
                          widget.routeService.removeSelectedUser(userId);
                        } else {
                          widget.routeService.addSelectedUser(userId);
                        }
                        widget.onRouteFilterChanged();
                      }
                      : null,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSmall - 2,
                  vertical: 4,
                ),
                margin: EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color:
                      isUserSelected && isEnabled
                          ? AppTheme.infoBlue.withOpacity(0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(
                      isUserSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 16,
                      color:
                          isEnabled
                              ? (isUserSelected
                                  ? AppTheme.infoBlue
                                  : AppTheme.gray600)
                              : AppTheme.gray400,
                    ),
                    SizedBox(width: AppTheme.spacingSmall - 2),
                    Expanded(
                      child: Text(
                        userId,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isUserSelected && isEnabled
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                          color:
                              isEnabled
                                  ? (isUserSelected
                                      ? AppTheme.infoBlue
                                      : AppTheme.textDark)
                                  : AppTheme.gray300,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRouteModeSelector() {
    final modes = ['driving', 'walking', 'cycling'];
    final icons = [
      Icons.directions_car,
      Icons.directions_walk,
      Icons.directions_bike,
    ];

    return Row(
      children: List.generate(modes.length, (index) {
        final mode = modes[index];
        final isSelected = widget.routeService.routeMode == mode;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < modes.length - 1 ? AppTheme.spacingSmall - 2 : 0,
            ),
            child: InkWell(
              onTap: () => widget.onRouteModeChanged(mode),
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
                child: Column(
                  children: [
                    Icon(
                      icons[index],
                      color: isSelected ? AppTheme.cardWhite : AppTheme.gray600,
                      size: 16,
                    ),
                    SizedBox(height: 2),
                    Text(
                      mode[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        color:
                            isSelected ? AppTheme.cardWhite : AppTheme.gray600,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRouteItem(String userId, UserLocation location) {
    final routeInfo =
        widget.currentLocation != null
            ? widget.routeService.getRouteInfo(
              userId: userId,
              userLocation: location,
              currentLocation: widget.currentLocation!,
            )
            : null;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingSmall - 2),
      padding: EdgeInsets.all(AppTheme.spacingSmall),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppTheme.gray100,
                child: Text(
                  userId.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.infoBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              SizedBox(width: AppTheme.spacingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userId,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: AppTheme.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (routeInfo != null)
                      Text(
                        routeInfo.lastUpdated,
                        style: TextStyle(fontSize: 9, color: AppTheme.textGray),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (routeInfo != null) ...[
            SizedBox(height: AppTheme.spacingSmall - 2),
            Row(
              children: [
                Icon(Icons.straighten, size: 11, color: AppTheme.gray600),
                SizedBox(width: 3),
                Text(
                  routeInfo.directDistance,
                  style: TextStyle(fontSize: 10, color: AppTheme.gray700),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
