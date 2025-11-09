import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../services/route_service.dart';
import '../models/route_data.dart';
import '../models/route_info.dart';
import '../models/user_location.dart';

class RouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();

  // State
  bool _isLoadingRoutes = false;
  List<RouteData> _currentRoutes = [];
  String? _routeError;

  // Getters
  bool get isLoadingRoutes => _isLoadingRoutes;
  List<RouteData> get currentRoutes => List.unmodifiable(_currentRoutes);
  String get routeMode => _routeService.routeMode;
  List<String> get selectedUsers => _routeService.selectedUsers;
  String? get routeError => _routeError;

  void setRouteMode(String mode) {
    _routeService.setRouteMode(mode);
    notifyListeners();
  }

  void setSelectedUsers(List<String> users) {
    _routeService.setSelectedUsers(users);
    notifyListeners();
  }

  void addSelectedUser(String userId) {
    _routeService.addSelectedUser(userId);
    notifyListeners();
  }

  void removeSelectedUser(String userId) {
    _routeService.removeSelectedUser(userId);
    notifyListeners();
  }

  void clearSelectedUsers() {
    _routeService.clearSelectedUsers();
    notifyListeners();
  }

  bool isUserSelected(String userId) {
    return selectedUsers.isEmpty || selectedUsers.contains(userId);
  }

  Future<void> generateRoutes({
    required LatLng currentLocation,
    required Map<String, UserLocation> userLocations,
    required String? currentUserId,
  }) async {
    _isLoadingRoutes = true;
    _routeError = null;
    notifyListeners();

    try {
      final routes = await _routeService.generateRoutes(
        currentLocation: currentLocation,
        userLocations: userLocations,
        currentUserId: currentUserId,
      );

      _currentRoutes = routes;
      _isLoadingRoutes = false;
      notifyListeners();
    } catch (e) {
      _routeError = e.toString();
      _isLoadingRoutes = false;
      _currentRoutes = [];
      notifyListeners();
    }
  }

  void clearRoutes() {
    _currentRoutes = [];
    notifyListeners();
  }

  RouteInfo getRouteInfo({
    required String userId,
    required UserLocation userLocation,
    required LatLng currentLocation,
  }) {
    return _routeService.getRouteInfo(
      userId: userId,
      userLocation: userLocation,
      currentLocation: currentLocation,
    );
  }

  double calculateDistance(LatLng from, LatLng to) {
    return _routeService.calculateDistance(from, to);
  }

  void clearCache() {
    _routeService.clearCache();
    notifyListeners();
  }

  void clearRouteError() {
    _routeError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _routeService.dispose();
    super.dispose();
  }
}
