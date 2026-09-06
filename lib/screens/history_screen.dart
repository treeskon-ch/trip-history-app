import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/trip_model.dart';
import 'history_map_screen.dart';
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();
  List<TripModel> _allTrips = [];
  List<TripModel> _filteredTrips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTrips();
  }

  Future<void> loadTrips() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.getCurrentUser();
      if (user != null) {
        final trips = await _api.getTrips(user.uid);
        setState(() {
          _allTrips = trips;
          _filteredTrips = trips;
        });
      }
    } catch (e) {
      debugPrint('Error loading trips: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilter() {
    setState(() {
      if (_startDate == null || _endDate == null) {
        _filteredTrips = _allTrips;
        return;
      }

      DateTime start = DateTime(
        _startDate!.year, _startDate!.month, _startDate!.day,
        _startTime?.hour ?? 0, _startTime?.minute ?? 0,
      );

      DateTime end = DateTime(
        _endDate!.year, _endDate!.month, _endDate!.day,
        _endTime?.hour ?? 23, _endTime?.minute ?? 59,
      );

      _filteredTrips = _allTrips.where((trip) {
        if (trip.startTime == null) return false;
        try {
          DateTime tripTime = DateTime.parse(trip.startTime!);
          return tripTime.isAfter(start) && tripTime.isBefore(end);
        } catch (e) {
          return false;
        }
      }).toList();
    });
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initialDate = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    
    final initialTime = isStart ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now());
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime == null) return;

    setState(() {
      if (isStart) {
        _startDate = pickedDate;
        _startTime = pickedTime;
      } else {
        _endDate = pickedDate;
        _endTime = pickedTime;
      }
      _applyFilter();
    });
  }

  String _formatDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return 'เลือกเวลา';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final y = date.year.toString().length >= 4 ? date.year.toString().substring(2) : date.year.toString();
    return '${date.day}/${date.month}/$y $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการเดินทาง'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.filter, size: 20, color: AppColors.textLight),
            onPressed: () {},
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderLight, height: 1.0),
        ),
      ),
      body: Container(
        color: AppColors.bgLight,
        child: Column(
          children: [
            // Date Range Picker Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateTimePickerBox('เริ่มต้น', _startDate, _startTime, () => _pickDateTime(true)),
                  ),
                  const SizedBox(width: 8),
                  const FaIcon(FontAwesomeIcons.arrowRightLong, color: AppColors.textLight, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDateTimePickerBox('สิ้นสุด', _endDate, _endTime, () => _pickDateTime(false)),
                  ),
                ],
              ),
            ),
            
            // List Section
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                  : _filteredTrips.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: const [
                            SizedBox(height: 32),
                            Center(
                              child: Text(
                                'ยังไม่มีประวัติการเดินทาง',
                                style: TextStyle(color: AppColors.textLight, fontSize: 14),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredTrips.length,
                          itemBuilder: (context, index) {
                            final trip = _filteredTrips[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: AppColors.borderLight),
                              ),
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HistoryMapScreen(trip: trip),
                                    ),
                                  );
                                },
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.bgLight,
                                  child: FaIcon(FontAwesomeIcons.truck, color: AppColors.primaryGreen, size: 18),
                                ),
                                title: Text('Trip: ${trip.tripId ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('ระยะทาง: ${trip.distance?.toStringAsFixed(2) ?? '0.00'} km\nเวลา: ${_formatTripTime(trip.startTime)}'),
                                trailing: _buildStatusBadge(trip.status),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTripTime(String? timeString) {
    if (timeString == null) return '-';
    try {
      final dt = DateTime.parse(timeString).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final y = dt.year.toString().length >= 4 ? dt.year.toString().substring(2) : dt.year.toString();
      return '${dt.day}/${dt.month}/$y $h:$m';
    } catch (e) {
      return timeString;
    }
  }

  Widget _buildStatusBadge(String? status) {
    Color bgColor = AppColors.bgLight;
    Color textColor = AppColors.textLight;
    String text = status ?? 'Unknown';

    if (status == 'COMPLETED') {
      bgColor = Colors.green.shade50;
      textColor = AppColors.primaryGreen;
      text = 'สำเร็จ';
    } else if (status == 'IN_PROGRESS') {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue;
      text = 'กำลังเดินทาง';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDateTimePickerBox(String label, DateTime? date, TimeOfDay? time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.calendarDay, size: 14, color: AppColors.primaryGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatDateTime(date, time),
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
