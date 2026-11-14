import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/movie_model.dart';
import '../../../../shared/widgets/cached_movie_image.dart';

class HeroBannerCarousel extends StatefulWidget {
  final List<MovieSummary> movies;

  const HeroBannerCarousel({super.key, required this.movies});

  @override
  State<HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<HeroBannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) return const SizedBox.shrink();

    final screenHeight = MediaQuery.of(context).size.height;
    final bannerHeight = screenHeight * 0.52;

    return SizedBox(
      height: bannerHeight,
      child: Stack(
        children: [
          // Carousel PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.movies.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final movie = widget.movies[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Backdrop Image
                  CachedMovieImage(
                    imageUrl: movie.backdropUrl.isNotEmpty ? movie.backdropUrl : movie.posterUrl,
                    fit: BoxFit.cover,
                    borderRadius: 0,
                  ),
                  // Dark Vignette Gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.posterVignette,
                    ),
                  ),
                  // Bottom Content Details & Action Buttons
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Genre Tags
                        if (movie.genres.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            children: movie.genres.take(3).map((g) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  g.name,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 8),
                        // Title
                        Text(
                          movie.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Action Buttons: Xem ngay & Trailer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                context.push('/movie/${movie.id}');
                              },
                              icon: const Icon(Icons.play_arrow_rounded, size: 22),
                              label: const Text('Xem ngay'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                context.push('/movie/${movie.id}');
                              },
                              icon: const Icon(Icons.info_outline_rounded, size: 20),
                              label: const Text('Chi tiết'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.surface.withOpacity(0.7),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          // Page Indicator Dots
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.movies.length,
                (index) => Container(
                  width: _currentPage == index ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppColors.primary : AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
