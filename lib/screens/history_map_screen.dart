import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../models/trip_model.dart';

class HistoryMapScreen extends StatefulWidget {
  final TripModel trip;

  const HistoryMapScreen({Key? key, required this.trip}) : super(key: key);

  @override
  State<HistoryMapScreen> createState() => _HistoryMapScreenState();
}

class _HistoryMapScreenState extends State<HistoryMapScreen> {
  final MapController _mapController = MapController();
  final ApiService _api = ApiService();

  List<LatLng> _routeCoords = [];
  List<LatLng> _denseCoords = [];

  bool _isLoading = true;
  bool _isPlaying = false;
  bool _isTracking = true;
  int _currentIndex = 0;
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    if (widget.trip.tripId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    
    try {
      final locations = await _api.getTripRoute(widget.trip.tripId!);
      if (locations.isNotEmpty) {
        _routeCoords = locations.map((loc) => LatLng(loc.lat, loc.lng)).toList();
        _denseCoords = _generateDenseRoute(_routeCoords, 30);

        final bounds = LatLngBounds.fromPoints(_routeCoords);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading route: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<LatLng> _generateDenseRoute(List<LatLng> waypoints, int stepsPerSegment) {
    List<LatLng> dense = [];
    if (waypoints.length < 2) return waypoints;

    for (int i = 0; i < waypoints.length - 1; i++) {
      LatLng p1 = waypoints[i];
      LatLng p2 = waypoints[i + 1];
      for (int j = 0; j < stepsPerSegment; j++) {
        dense.add(LatLng(
          p1.latitude + (p2.latitude - p1.latitude) * (j / stepsPerSegment),
          p1.longitude + (p2.longitude - p1.longitude) * (j / stepsPerSegment),
        ));
      }
    }
    dense.add(waypoints.last);
    return dense;
  }

  void _togglePlay() {
    if (_denseCoords.isEmpty) return;

    if (_isPlaying) {
      _playbackTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      if (_currentIndex >= _denseCoords.length - 1) {
        _currentIndex = 0;
      }
      setState(() => _isPlaying = true);
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        setState(() {
          _currentIndex++;
          if (_currentIndex >= _denseCoords.length) {
            _stopPlayback();
          } else if (_isTracking) {
            _mapController.move(_denseCoords[_currentIndex], _mapController.camera.zoom);
          }
        });
      });
    }
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _currentIndex = 0;
    });
  }

  void _seekPlayback(double percent) {
    if (_denseCoords.isEmpty) return;
    int target = ((percent / 100) * (_denseCoords.length - 1)).floor();
    setState(() {
      _currentIndex = target;
      if (_isTracking) {
        _mapController.move(_denseCoords[_currentIndex], _mapController.camera.zoom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehiclePos = _denseCoords.isNotEmpty && _currentIndex < _denseCoords.length
        ? _denseCoords[_currentIndex]
        : null;

    double progress = _denseCoords.isNotEmpty
        ? (_currentIndex / (_denseCoords.length - 1)) * 100
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('เส้นทางย้อนหลัง: ${widget.trip.tripId ?? '-'}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _routeCoords.isNotEmpty ? _routeCoords.first : const LatLng(13.7563, 100.5018),
                      initialZoom: 10,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.trip_history_app',
                      ),
                      if (_routeCoords.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routeCoords,
                              strokeWidth: 5.0,
                              color: AppColors.primaryGreen.withOpacity(0.8),
                              pattern: StrokePattern.dashed(segments: const [10.0, 10.0]),
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (_routeCoords.isNotEmpty)
                            Marker(
                              point: _routeCoords.first,
                              width: 24,
                              height: 24,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                                ),
                              ),
                            ),
                          if (_routeCoords.length > 1)
                            Marker(
                              point: _routeCoords.last,
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                                ),
                                child: const Center(
                                  child: FaIcon(FontAwesomeIcons.flagCheckered, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          if (vehiclePos != null)
                            Marker(
                              point: vehiclePos,
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                                ),
                                child: const Center(
                                  child: FaIcon(FontAwesomeIcons.truck, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                        top: 16,
                        right: 16,
                        child: Column(
                          children: [
                            _buildMapToolBtn(
                              icon: FaIcon(
                                FontAwesomeIcons.crosshairs,
                                color: _isTracking ? AppColors.primaryGreen : AppColors.textLight,
                                size: 20,
                              ),
                              onTap: () {
                                setState(() {
                                  _isTracking = !_isTracking;
                                  if (_isTracking && _denseCoords.isNotEmpty) {
                                    _mapController.move(
                                      _denseCoords[_currentIndex < _denseCoords.length ? _currentIndex : 0],
                                      _mapController.camera.zoom,
                                    );
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildMapToolBtn(icon: const FaIcon(FontAwesomeIcons.route, color: AppColors.primaryGreen, size: 20), onTap: _centerOnRoute),
                            const SizedBox(height: 8),
                            _buildMapToolBtn(icon: const FaIcon(FontAwesomeIcons.plus, color: AppColors.textDark, size: 20), onTap: _zoomIn),
                            const SizedBox(height: 8),
                            _buildMapToolBtn(icon: const FaIcon(FontAwesomeIcons.minus, color: AppColors.textDark, size: 20), onTap: _zoomOut),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Footer Controls
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.borderLight)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ระยะทางรวม: ${widget.trip.distance?.toStringAsFixed(1) ?? '0.0'} กม.', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.bgLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: IconButton(
                              onPressed: _stopPlayback,
                              icon: const FaIcon(FontAwesomeIcons.stop, size: 16, color: AppColors.textDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: _togglePlay,
                              icon: FaIcon(_isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play, size: 16, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Slider(
                              value: progress,
                              min: 0,
                              max: 100,
                              activeColor: Colors.blue,
                              inactiveColor: AppColors.borderLight,
                              onChanged: _seekPlayback,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _centerOnRoute() {
    if (_routeCoords.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(_routeCoords);
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  Widget _buildMapToolBtn({required Widget icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
        child: Center(child: icon),
      ),
    );
  }
}
