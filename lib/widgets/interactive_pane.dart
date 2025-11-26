// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:herewego/widgets/app_chip_button.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'app_action_button.dart';
import '../app_theme.dart';
import '../widgets/app_text_field.dart';
import '../providers/connection_provider.dart';

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
          maxHeight: MediaQuery.of(context).size.height * 0.35,
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
    return AppChipButton(
      label: isExpanded ? 'Hide Options' : 'Show Options',
      onTap: onToggleExpand,
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
        children: List.generate(2, (index) {
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
}
