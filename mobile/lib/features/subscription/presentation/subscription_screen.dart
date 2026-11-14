import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _selectedPlanIndex = 1; // Default to Monthly

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'PLAN_FREE',
      'name': 'Gói Miễn Phí',
      'price': '0 đ',
      'period': 'Mãi mãi',
      'resolution': 'Full HD 1080p',
      'streams': '1 thiết bị',
      'features': ['Xem phim có bản quyền', 'Chất lượng 1080p', '1 thiết bị phát'],
    },
    {
      'id': 'PLAN_PREMIUM_MONTHLY',
      'name': 'Gói Premium Tháng',
      'price': '79.000 đ',
      'period': '/ tháng',
      'resolution': '4K Ultra HD & HDR',
      'streams': '2 thiết bị đồng thời',
      'isPopular': true,
      'features': [
        'Toàn bộ kho phim điện ảnh',
        'Chất lượng 4K Ultra HD & HDR',
        'Âm thanh vòm Dolby Atmos',
        '2 thiết bị phát đồng thời',
        'Không quảng cáo gián đoạn',
      ],
    },
    {
      'id': 'PLAN_PREMIUM_YEARLY',
      'name': 'Gói Premium Năm',
      'price': '790.000 đ',
      'period': '/ năm (Tiết kiệm 20%)',
      'resolution': '4K Ultra HD & HDR',
      'streams': '4 thiết bị đồng thời',
      'features': [
        'Mọi đặc quyền của Premium',
        '4 thiết bị phát đồng thời',
        'Ưu tiên phim chiếu sớm',
        'Tiết kiệm 2 tháng phí',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gói dịch vụ CINEORA', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 54),
            const SizedBox(height: 12),
            const Text(
              'Trải nghiệm điện ảnh đỉnh cao',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thưởng thức phim 4K HDR không giới hạn, không quảng cáo trên mọi thiết bị.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Plan Cards
            ...List.generate(_plans.length, (index) {
              final plan = _plans[index];
              final isSelected = _selectedPlanIndex == index;
              final isPopular = plan['isPopular'] == true;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPlanIndex = index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF200709) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            plan['name'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isPopular)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PHỔ BIẾN NHẤT',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            plan['price'],
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            plan['period'],
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.border, height: 20),
                      ...((plan['features'] as List<String>).map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                              const SizedBox(width: 8),
                              Text(f, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // In-App Purchase Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Compliant notice: Display status pending store merchant configuration
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('Thông báo hệ thống thanh toán'),
                      content: const Text(
                        'Cổng thanh toán In-App Purchase (Apple StoreKit & Google Play Billing) đang ở trạng thái chuẩn bị phê duyệt tài khoản nhà phát hành trên App Store và Google Play.\n\nHiện tại bạn có thể trải nghiệm toàn bộ kho phim thử nghiệm có bản quyền ở chế độ Miễn Phí.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đã hiểu', style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Nâng cấp ngay'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tuân thủ chính sách thanh toán kỹ thuật số của Apple App Store & Google Play Store.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
