import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoplayNext = true;
  bool _cellularDataSaver = false;
  String _defaultQuality = '1080p';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cài đặt ứng dụng', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Trình phát & Video'),
          _buildSwitchTile(
            title: 'Tự động phát tập tiếp theo',
            subtitle: 'Tự chuyển sang tập kế tiếp khi kết thúc',
            value: _autoplayNext,
            onChanged: (val) => setState(() => _autoplayNext = val),
          ),
          _buildSwitchTile(
            title: 'Tiết kiệm dữ liệu di động',
            subtitle: 'Giới hạn chất lượng video ở 720p khi dùng 4G/5G',
            value: _cellularDataSaver,
            onChanged: (val) => setState(() => _cellularDataSaver = val),
          ),
          _buildListTile(
            title: 'Chất lượng phát mặc định',
            trailingText: _defaultQuality,
            onTap: () {
              // Quality dialog
            },
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Pháp lý & Thông tin'),
          _buildListTile(
            title: 'Chính sách bảo mật (Privacy Policy)',
            onTap: () {},
          ),
          _buildListTile(
            title: 'Điều khoản dịch vụ (Terms of Service)',
            onTap: () {},
          ),
          _buildListTile(
            title: 'Giấy phép mã nguồn & Bản quyền nội dung',
            onTap: () {},
          ),
          _buildListTile(
            title: 'Phiên bản ứng dụng',
            trailingText: '1.0.0 (Build 2026.11)',
            onTap: () {},
          ),

          if (user != null) ...[
            const SizedBox(height: 32),
            _buildSectionHeader('Quản lý tài khoản'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.5)),
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                title: const Text(
                  'Xóa tài khoản vĩnh viễn',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Toàn bộ lịch sử xem và dữ liệu sẽ bị xóa không thể khôi phục',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                onTap: () => _confirmAccountDeletion(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        value: value,
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        trailing: trailingText != null
            ? Text(trailingText, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))
            : const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  void _confirmAccountDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Xác nhận xóa tài khoản?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Hành động này tuân thủ quy định App Store Guideline 5.1.1(v) và sẽ xóa toàn bộ thông tin đăng nhập, lịch sử xem phim và gói dịch vụ của bạn trên hệ thống CINEORA.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final client = ref.read(apiClientProvider);
                await client.dio.delete('/users/me');
                await ref.read(authStateProvider.notifier).logout();
                if (mounted) {
                  context.go('/');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }
}
