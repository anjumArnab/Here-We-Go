import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/user_location_handler.dart';
import '../models/location_result.dart';
import '../models/user_location.dart';
import '../models/map_marker_data.dart';

class UserLocationProvider extends ChangeNotifier {
  final UserLocationHandler _userLocationHandler = UserLocationHandler();

  // State
  bool _isLoadingLocation = false;
  bool _locationPermissionGranted = false;
  String? _locationError;

  // Getters
  LatLng? get currentLocation => _userLocationHandler.currentLocation;
  bool get isLoadingLocation => _isLoadingLocation;
  bool get locationPermissionGranted => _locationPermissionGranted;
  String? get locationError => _locationError;

  Future<LocationResult> getCurrentLocation() async {
    _isLoadingLocation = true;
    _locationError = null;
    notifyListeners();

    final result = await _userLocationHandler.getCurrentLocation();

    _isLoadingLocation = false;
    _locationPermissionGranted = result.isSuccess;

    if (!result.isSuccess) {
      _locationError = result.error;
    }

    notifyListeners();
    return result;
  }

  LocationResult setDefaultLocation() {
    final result = _userLocationHandler.setDefaultLocation();
    _locationPermissionGranted = false;
    notifyListeners();
    return result;
  }

  List<MapMarkerData> generateUserMarkerData({
    required Map<String, UserLocation> userLocations,
    required String? currentUserId,
  }) {
    return _userLocationHandler.generateUserMarkerData(
      userLocations: userLocations,
      currentUserId: currentUserId,
      hasLocationPermission: _locationPermissionGranted,
    );
  }

  LatLngBounds? calculateBoundsForAllLocations({
    required Map<String, UserLocation> userLocations,
  }) {
    return _userLocationHandler.calculateBoundsForAllLocations(
      userLocations: userLocations,
    );
  }

  LatLng getFocusLocationForUser(UserLocation userLocation) {
    return _userLocationHandler.getFocusLocationForUser(userLocation);
  }

  LatLng? getFocusLocationForCurrent() {
    return _userLocationHandler.getFocusLocationForCurrent();
  }

  String formatTimestamp(String timestamp) {
    return _userLocationHandler.formatTimestamp(timestamp);
  }

  void clearLocationError() {
    _locationError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userLocationHandler.dispose();
    super.dispose();
  }
}
