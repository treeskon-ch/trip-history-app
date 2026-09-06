import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/local_storage.dart';
import '../models/plan_model.dart';
import '../services/api_service.dart';

class PlansScreen extends StatefulWidget {
  final Function(PlanModel) onPlanSelected;

  const PlansScreen({Key? key, required this.onPlanSelected}) : super(key: key);

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final ApiService _api = ApiService();
  List<PlanModel> _plans = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = await LocalStorage.getUserId();
      if (userId == null) {
        setState(() {
          _error = 'ไม่พบข้อมูลผู้ใช้งาน กรุณาเข้าสู่ระบบใหม่';
          _isLoading = false;
        });
        return;
      }
      final plans = await _api.getJobPlans(userId);
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'ระบบปิดปรับปรุงชั่วคราว หรือไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แผนงาน (Job Plans)', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryGreen),
            onPressed: _fetchPlans,
          ),
        ],
      ),
      backgroundColor: AppColors.bgLight,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.build_circle_outlined, color: Colors.orange, size: 64),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('ขออภัยในความไม่สะดวก กรุณาลองใหม่อีกครั้งในภายหลัง', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textLight, fontSize: 14)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchPlans,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('ลองใหม่', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.assignment_outlined, color: AppColors.borderLight, size: 64),
            SizedBox(height: 16),
            Text('ไม่มีแผนงาน', style: TextStyle(color: AppColors.textLight, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _plans.length,
      itemBuilder: (context, index) {
        final plan = _plans[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => widget.onPlanSelected(plan),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(plan.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: plan.status == 'pending' ? Colors.orange.shade100 : (plan.status == 'completed' ? Colors.green.shade100 : Colors.blue.shade100),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          plan.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: plan.status == 'pending' ? Colors.orange.shade800 : (plan.status == 'completed' ? Colors.green.shade800 : Colors.blue.shade800),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildLocationRow(Icons.my_location, 'จุดเริ่มต้น', plan.origin.address ?? '${plan.origin.lat}, ${plan.origin.lng}'),
                  const SizedBox(height: 8),
                  _buildLocationRow(Icons.location_on, 'จุดหมายปลายทาง', plan.destination.address ?? '${plan.destination.lat}, ${plan.destination.lng}'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationRow(IconData icon, String title, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.bold)),
              Text(address, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
            ],
          ),
        ),
      ],
    );
  }
}
