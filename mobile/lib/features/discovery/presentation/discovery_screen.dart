import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/movie_model.dart';
import '../../home/presentation/widgets/movie_card.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  String? _selectedGenre;
  String? _selectedCountry;
  String? _selectedType;
  String _selectedSortBy = 'latest';

  final List<Map<String, String>> _genres = [
    {'name': 'Tất cả', 'slug': ''},
    {'name': 'Hành Động', 'slug': 'hanh-dong'},
    {'name': 'Lãng Mạn', 'slug': 'lang-man'},
    {'name': 'Khoa Học Viễn Tưởng', 'slug': 'khoa-hoc-vien-tuong'},
    {'name': 'Hoạt Hình', 'slug': 'hoat-hinh-anime'},
    {'name': 'Kinh Dị', 'slug': 'kinh-di'},
    {'name': 'Hài Hước', 'slug': 'hai-huoc'},
    {'name': 'Tài Liệu', 'slug': 'tai-lieu'},
  ];

  final List<Map<String, String>> _countries = [
    {'name': 'Tất cả quốc gia', 'code': ''},
    {'name': 'Việt Nam', 'code': 'VN'},
    {'name': 'Hàn Quốc', 'code': 'KR'},
    {'name': 'Trung Quốc', 'code': 'CN'},
    {'name': 'Âu Mỹ', 'code': 'US'},
    {'name': 'Nhật Bản', 'code': 'JP'},
  ];

  @override
  Widget build(BuildContext context) {
    final movieRepo = ref.watch(movieRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Khám phá kho phim',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Horizontal Scroll
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _genres.length,
              itemBuilder: (context, index) {
                final g = _genres[index];
                final isSelected = (_selectedGenre == null && g['slug'] == '') ||
                    _selectedGenre == g['slug'];

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(g['name']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedGenre = g['slug']!.isEmpty ? null : g['slug'];
                      });
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Secondary Filter Row (Country, Type, Sort)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Country Dropdown
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCountry ?? '',
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceElevated,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                        items: _countries.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['code'],
                            child: Text(c['name']!),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCountry = (val == null || val.isEmpty) ? null : val;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Sort Dropdown
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSortBy,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceElevated,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                        items: const [
                          DropdownMenuItem(value: 'latest', child: Text('Mới nhất')),
                          DropdownMenuItem(value: 'popular', child: Text('Phổ biến')),
                          DropdownMenuItem(value: 'rating', child: Text('Đánh giá cao')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSortBy = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Movie Grid Query
          Expanded(
            child: FutureBuilder<List<MovieSummary>>(
              future: movieRepo.getFilteredMovies(
                genre: _selectedGenre,
                country: _selectedCountry,
                type: _selectedType,
                sortBy: _selectedSortBy,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Lỗi tải dữ liệu: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  );
                }

                final movies = snapshot.data ?? [];
                if (movies.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.movie_filter_outlined, size: 54, color: AppColors.textTertiary),
                        SizedBox(height: 12),
                        Text(
                          'Không tìm thấy phim phù hợp với bộ lọc',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return MovieCard(
                      movie: movie,
                      width: double.infinity,
                      height: 160,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
