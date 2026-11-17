import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class MapModel extends ChangeNotifier {
  // Вуз: Москва, ул. Стромынка, 20
  static const String universityAddress = 'Москва, ул. Стромынка, 20';
  static const Point universityPoint = Point(latitude: 55.794259, longitude: 37.701448);

  YandexMapController? _controller;
  bool _isLoading = false;
  String? _error;
  String? _routeInfo;
  Point? _userPoint;
  List<MapObject> _mapObjects = [_universityMarker()];

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get routeInfo => _routeInfo;
  List<MapObject> get mapObjects => _mapObjects;

  static CircleMapObject _universityMarker() {
    return const CircleMapObject(
      mapId: MapObjectId('university'),
      circle: Circle(center: universityPoint, radius: 40),
      strokeColor: Colors.red,
      strokeWidth: 3,
      fillColor: Color(0x55FF0000),
    );
  }

  Future<void> onMapCreated(YandexMapController controller) async {
    _controller = controller;
    await controller.moveCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(target: universityPoint, zoom: 15),
      ),
    );
    await buildRoute();
  }

  // Получаем позицию по GPS и строим пеший маршрут до вуза
  Future<void> buildRoute() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _userPoint = await _getUserPoint();
      await _controller?.toggleUserLayer(visible: true);

      final (session, futureResult) = await YandexPedestrian.requestRoutes(
        points: [
          RequestPoint(point: _userPoint!, requestPointType: RequestPointType.wayPoint),
          const RequestPoint(point: universityPoint, requestPointType: RequestPointType.wayPoint),
        ],
        fitnessOptions: const FitnessOptions(avoidSteep: false, avoidStairs: false),
        timeOptions: TimeOptions(departureTime: DateTime.now()),
      );
      final result = await futureResult;
      await session.close();

      if (result.error != null || result.routes == null || result.routes!.isEmpty) {
        throw Exception('Не удалось построить маршрут: ${result.error ?? 'маршрут не найден'}');
      }

      final route = result.routes!.first;
      _routeInfo = 'Пешком: ${route.metadata.weight.time.text}, '
          '${route.metadata.weight.walkingDistance.text}';
      _mapObjects = [
        _universityMarker(),
        PolylineMapObject(
          mapId: const MapObjectId('route'),
          polyline: route.geometry,
          strokeColor: Colors.blue,
          strokeWidth: 4,
        ),
      ];

      await _controller?.moveCamera(
        CameraUpdate.newGeometry(
          Geometry.fromBoundingBox(_boundingBox(_userPoint!, universityPoint)),
        ),
      );
      await _controller?.moveCamera(CameraUpdate.zoomOut());
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Point> _getUserPoint() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Включите геолокацию на телефоне');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Нет доступа к геолокации');
    }
    final position = await Geolocator.getCurrentPosition();
    return Point(latitude: position.latitude, longitude: position.longitude);
  }

  BoundingBox _boundingBox(Point a, Point b) {
    return BoundingBox(
      northEast: Point(
        latitude: a.latitude > b.latitude ? a.latitude : b.latitude,
        longitude: a.longitude > b.longitude ? a.longitude : b.longitude,
      ),
      southWest: Point(
        latitude: a.latitude < b.latitude ? a.latitude : b.latitude,
        longitude: a.longitude < b.longitude ? a.longitude : b.longitude,
      ),
    );
  }
}
