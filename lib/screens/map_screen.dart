import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../core/local_storage.dart';
import '../services/api_service.dart';
import '../models/location_model.dart';
import '../models/plan_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final ApiService _api = ApiService();
  
  // Default position if GPS is not available (Bangkok)
  LatLng _currentPosition = const LatLng(13.7563, 100.5018); 
  
  // Destination will be fetched from API later
  LatLng? _destinationPosition;
  
  bool _isLoadingLocation = true;
  String _locationError = '';
  String _currentAddress = 'กำลังค้นหาที่อยู่...';
  String _currentAddressDetail = '';

  String? _userId;
  String? _tripId;
  PlanModel? _currentPlan;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isCheckedIn = false;

  void setPlan(PlanModel plan) {
    if (mounted) {
      setState(() {
        _currentPlan = plan;
        _destinationPosition = LatLng(plan.destination.lat, plan.destination.lng);
      });
      _mapController.move(LatLng(plan.origin.lat, plan.origin.lng), 14.0);
    }
  }

  @override
  void initState() {
    super.initState();
    _initMapAndSession();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initMapAndSession() async {
    _userId = await LocalStorage.getUserId();
    _tripId = await LocalStorage.getTripId();

    await _determinePosition();
    
    if (_tripId != null) {
      setState(() {
        _isCheckedIn = true;
      });
      _startContinuousTracking();
    }
  }

  Future<void> _startTrip() async {
    if (_userId == null) return;
    try {
      final res = await _api.startTrip(_userId!, planId: _currentPlan?.id);
      _tripId = res['tripId'];
      if (_tripId != null) {
        await LocalStorage.saveTripId(_tripId!);
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Start trip error: $e');
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            _currentAddress = (place.name != null && place.name!.isNotEmpty) ? place.name! : (place.street ?? 'ไม่ทราบสถานที่');
            _currentAddressDetail = '${place.subLocality ?? ''} ${place.locality ?? ''} ${place.administrativeArea ?? ''}'.trim();
          });
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
  }

  void _startContinuousTracking() {
    _positionStreamSubscription?.cancel();
    
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        
        _mapController.move(_currentPosition, _mapController.camera.zoom);
        _getAddressFromLatLng(position.latitude, position.longitude);
        _updateLocationToApi(position);
      }
    });
  }

  Future<void> _updateLocationToApi(Position position) async {
    if (_tripId == null || _userId == null) return;
    try {
      await _api.updateLocation(
        _tripId!,
        LocationModel(
          userId: _userId,
          lat: position.latitude,
          lng: position.longitude,
          speed: position.speed,
          timestamp: DateTime.now().toUtc().toIso8601String(),
        ),
      );
    } catch (e) {
      debugPrint('Update location error: $e');
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    if (mounted) {
      setState(() {
        _isLoadingLocation = true;
        _locationError = '';
      });
    }

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      } 

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _getAddressFromLatLng(position.latitude, position.longitude);
      }
      
      _mapController.move(_currentPosition, _mapController.camera.zoom > 10 ? _mapController.camera.zoom : 14.0);

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถดึงตำแหน่งได้: $_locationError'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _centerOnCurrentLocation() {
    _mapController.move(_currentPosition, 15.0);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  void _showActionModal(BuildContext context, String type) {
    if (type == 'report') {
      _issueTitleController.clear();
      _issueDescController.clear();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        if (type == 'checkin') return _buildCheckinModal(context);
        if (type == 'report') return _buildReportModal(context);
        if (type == 'finish') return _buildFinishModal(context);
        return const SizedBox();
      },
    );
  }

  Widget _buildCheckinModal(BuildContext context) {
    return const SizedBox(); // Not used, handled directly in button tap
  }

  final TextEditingController _issueTitleController = TextEditingController();
  final TextEditingController _issueDescController = TextEditingController();

  Widget _buildReportModal(BuildContext modalContext) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24.0, right: 24.0, top: 24.0, 
        bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24.0
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('รายงานปัญหา', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('หัวข้อปัญหา', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TextField(
            controller: _issueTitleController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'เช่น รถยางแตก, รถติดหนัก',
            ),
          ),
          const SizedBox(height: 12),
          const Text('รายละเอียด', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TextField(
            controller: _issueDescController,
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'รายละเอียดเพิ่มเติม...',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(modalContext),
                  style: TextButton.styleFrom(backgroundColor: AppColors.bgLight, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('ยกเลิก', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_tripId != null) {
                      final title = _issueTitleController.text.trim();
                      final desc = _issueDescController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาระบุหัวข้อปัญหา')));
                        return;
                      }
                      Navigator.pop(modalContext);
                      try {
                        final userId = await LocalStorage.getUserId();
                        if (userId != null) {
                          await _api.reportIssue(_tripId!, userId, title, desc);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งรายงานปัญหาแล้ว')));
                        } else {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Not logged in')));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    } else {
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ยังไม่มีการเริ่มเดินทาง')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('ส่งรายงาน'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinishModal(BuildContext modalContext) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: Color(0xFFFEE2E2), shape: BoxShape.circle),
            child: const Center(child: FaIcon(FontAwesomeIcons.flagCheckered, color: Colors.red, size: 32)),
          ),
          const SizedBox(height: 16),
          const Text('จบการเดินทาง (ปิดงาน)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('คุณต้องการยืนยันการจบงานใช่หรือไม่?', style: TextStyle(color: AppColors.textLight)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(modalContext),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.bgLight,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('ยกเลิก', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(modalContext);
                    if (_tripId != null) {
                      try {
                        await _api.endTrip(_tripId!, 15.5, '');
                        await LocalStorage.removeTripId();
                        _tripId = null;
                        _currentPlan = null;
                        _destinationPosition = null;
                        _positionStreamSubscription?.cancel();
                        if (mounted) {
                          setState(() {
                            _isCheckedIn = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ปิดงานเรียบร้อย')));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('ยืนยันจบงาน'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.trip_history_app',
                ),
                if (_currentPlan != null && _destinationPosition != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          LatLng(_currentPlan!.origin.lat, _currentPlan!.origin.lng),
                          _destinationPosition!,
                        ],
                        strokeWidth: 4.0,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (_destinationPosition != null)
                      Marker(
                        point: _destinationPosition!,
                        width: 50,
                        height: 50,
                        child: const FaIcon(FontAwesomeIcons.locationDot, color: Colors.red, size: 40),
                      ),
                    Marker(
                      point: _currentPosition,
                      width: 50,
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isLoadingLocation)
                            const CircularProgressIndicator(color: AppColors.primaryGreen)
                          else
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const FaIcon(FontAwesomeIcons.truckFast, color: AppColors.primaryGreen, size: 24),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 16, left: 16, right: 16),
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('งานปัจจุบัน', style: TextStyle(color: Color(0xFFBBF7D0), fontSize: 12)),
                      Text(_currentPlan != null ? _currentPlan!.title : (_tripId != null ? 'กำลังเดินทาง' : 'ยังไม่มีงาน'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Text(_tripId != null ? 'OD-${_tripId?.substring(0, 4)}' : '-', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            right: 16,
            child: Column(
              children: [
                _buildMapToolBtn(icon: const FaIcon(FontAwesomeIcons.locationCrosshairs, color: AppColors.primaryGreen, size: 20), onTap: _centerOnCurrentLocation),
                const SizedBox(height: 8),
                _buildMapToolBtn(icon: const FaIcon(FontAwesomeIcons.plus, color: AppColors.textDark, size: 20), onTap: _zoomIn),
                const SizedBox(height: 8),
                _buildMapToolBtn(icon: const FaIcon(FontAwesomeIcons.minus, color: AppColors.textDark, size: 20), onTap: _zoomOut),
              ],
            ),
          ),

          Positioned(
            bottom: 16, left: 16, right: 16,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ตำแหน่งปัจจุบัน', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                          Text(_isLoadingLocation ? 'กำลังค้นหา...' : 'อัปเดตล่าสุด', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20)),
                            child: const Center(child: FaIcon(FontAwesomeIcons.locationCrosshairs, color: AppColors.primaryGreen, size: 20)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_currentAddress, style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text(
                                  _currentAddressDetail.isNotEmpty ? _currentAddressDetail : '${_currentPosition.latitude.toStringAsFixed(6)}, ${_currentPosition.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildActionBtn(
                      _isCheckedIn ? 'กำลังเดินทาง' : 'เริ่มงาน (เช็คอิน)', 
                      const FaIcon(FontAwesomeIcons.clipboardCheck, color: Colors.white, size: 20), 
                      _isCheckedIn ? Colors.amber.shade700 : AppColors.primaryGreen, 
                      () async {
                        if (!_isCheckedIn) {
                          try {
                            if (_tripId == null) {
                              await _startTrip();
                            }
                            if (_tripId != null) {
                              _startContinuousTracking();
                              if (mounted) {
                                setState(() {
                                  _isCheckedIn = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เริ่มการเดินทางเรียบร้อยแล้ว')));
                              }
                            } else {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่สามารถเริ่มงานใหม่ได้')));
                            }
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('คุณกำลังเดินทางอยู่แล้ว')));
                        }
                      }
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _buildActionBtn('รายงาน', const FaIcon(FontAwesomeIcons.camera, color: Colors.white, size: 20), Colors.blue, () => _showActionModal(context, 'report'))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildActionBtn('จบงาน', const FaIcon(FontAwesomeIcons.flagCheckered, color: Colors.white, size: 20), Colors.red, () => _showActionModal(context, 'finish'))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildActionBtn(String label, Widget icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
