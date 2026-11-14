import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/movie_model.dart';
import 'widgets/hero_banner_carousel.dart';
import 'widgets/movie_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredAsync = ref.watch(featuredMoviesProvider);
    final trendingAsync = ref.watch(trendingMoviesProvider);
    final latestAsync = ref.watch(latestMoviesProvider);
    final historyAsync = ref.watch(watchHistoryProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with Brand Logo and Action Icons
          SliverAppBar(
            floating: true,
            pinned: false,
            backgroundColor: AppColors.background.withOpacity(0.9),
            elevation: 0,
            title: Row(
              children: [
                // Logo Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      TextSpan(text: 'CINE'),
                      TextSpan(text: 'ORA', style: TextStyle(color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {
                  context.push('/search');
                },
                icon: const Icon(Icons.search_rounded, size: 26),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () {
                    context.go('/profile');
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.surfaceElevated,
                    child: const Icon(Icons.person_rounded, size: 20, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),

          // Hero Banner Carousel
          SliverToBoxAdapter(
            child: featuredAsync.when(
              data: (movies) => HeroBannerCarousel(movies: movies),
              loading: () => const SizedBox(
                height: 380,
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (err, _) => const SizedBox.shrink(),
            ),
          ),

          // Continue Watching Section
          historyAsync.when(
            data: (history) {
              if (history.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              return SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        'Tiếp tục xem',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final item = history[index];
                          final percent = (item['percentWatched'] as num?)?.toInt() ?? 0;
                          return GestureDetector(
                            onTap: () {
                              context.push('/player', extra: {
                                'episodeId': item['episodeId'],
                                'movieTitle': item['movieTitle'],
                                'episodeTitle': item['episodeTitle'],
                              });
                            },
                            child: Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                        child: Image.network(
                                          item['movieBackdropUrl'] ?? item['moviePosterUrl'] ?? '',
                                          height: 90,
                                          width: 200,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            height: 90,
                                            color: AppColors.surfaceElevated,
                                            child: const Center(child: Icon(Icons.movie, color: AppColors.textTertiary)),
                                          ),
                                        ),
                                      ),
                                      const Positioned.fill(
                                        child: Center(
                                          child: CircleAvatar(
                                            radius: 18,
                                            backgroundColor: Colors.black54,
                                            child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Progress Bar
                                  LinearProgressIndicator(
                                    value: percent / 100.0,
                                    backgroundColor: AppColors.border,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    minHeight: 3,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                      item['movieTitle'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // Phim thịnh hành (Trending Movies)
          SliverToBoxAdapter(
            child: _buildMovieSection(
              title: 'Phim thịnh hành',
              asyncValue: trendingAsync,
              onSeeMore: () => context.go('/discovery'),
            ),
          ),

          // Phim mới cập nhật (Latest Movies)
          SliverToBoxAdapter(
            child: _buildMovieSection(
              title: 'Phim mới cập nhật',
              asyncValue: latestAsync,
              onSeeMore: () => context.go('/discovery'),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildMovieSection({
    required String title,
    required AsyncValue<List<MovieSummary>> asyncValue,
    required VoidCallback onSeeMore,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: onSeeMore,
                child: const Row(
                  children: [
                    Text(
                      'Xem thêm',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 235,
          child: asyncValue.when(
            data: (movies) {
              if (movies.isEmpty) {
                return const Center(
                  child: Text('Đang cập nhật nội dung...', style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  return MovieCard(movie: movies[index]);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, _) => Center(
              child: Text('Không thể tải: $err', style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ),
        ),
      ],
    );
  }
}
