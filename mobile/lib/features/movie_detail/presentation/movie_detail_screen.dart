import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/movie_model.dart';
import '../../../shared/widgets/cached_movie_image.dart';

class MovieDetailScreen extends ConsumerStatefulWidget {
  final String movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen> {
  int _selectedSeasonIndex = 0;
  bool _isFavorited = false;
  bool _hasFavoritedLoaded = false;

  @override
  Widget build(BuildContext context) {
    final movieRepo = ref.watch(movieRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<MovieDetail>(
        future: movieRepo.getMovieDetail(widget.movieId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final movie = snapshot.data!;
          if (!_hasFavoritedLoaded) {
            _isFavorited = movie.isFavorited;
            _hasFavoritedLoaded = true;
          }

          final currentSeason = movie.seasons.isNotEmpty ? movie.seasons[_selectedSeasonIndex] : null;

          return CustomScrollView(
            slivers: [
              // Backdrop App Bar
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.surface,
                leading: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedMovieImage(
                        imageUrl: movie.backdropUrl.isNotEmpty ? movie.backdropUrl : movie.posterUrl,
                        fit: BoxFit.cover,
                        borderRadius: 0,
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.posterVignette,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Original Title
                      Text(
                        movie.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (movie.originalTitle.isNotEmpty && movie.originalTitle != movie.title)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            movie.originalTitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),

                      // Metadata Row (Year, Rating, Duration, Quality)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FULL HD',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${movie.releaseYear}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(width: 8),
                          if (movie.duration > 0) ...[
                            Text('${movie.duration} phút', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(width: 8),
                          ],
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            movie.ratingAverage.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Action Buttons Row: Xem ngay (Primary) & Yêu thích (Secondary)
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Start first available episode
                                final firstEpId = movie.seasons.isNotEmpty && movie.seasons.first.episodes.isNotEmpty
                                    ? movie.seasons.first.episodes.first.id
                                    : '';
                                context.push('/player', extra: {
                                  'episodeId': firstEpId,
                                  'movieTitle': movie.title,
                                  'episodeTitle': movie.seasons.first.episodes.first.title,
                                });
                              },
                              icon: const Icon(Icons.play_arrow_rounded, size: 24),
                              label: const Text('Xem ngay'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final newState = await movieRepo.toggleFavorite(movie.id, _isFavorited);
                                setState(() {
                                  _isFavorited = newState;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      newState ? 'Đã thêm vào yêu thích' : 'Đã xóa khỏi yêu thích',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: Icon(
                                _isFavorited ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: _isFavorited ? AppColors.primary : Colors.white,
                              ),
                              label: Text(
                                _isFavorited ? 'Đã lưu' : 'Lưu',
                                style: TextStyle(
                                  color: _isFavorited ? AppColors.primary : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Description
                      Text(
                        movie.description,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Seasons & Episodes Section
                      if (movie.seasons.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Danh sách tập',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (movie.seasons.length > 1)
                              DropdownButton<int>(
                                value: _selectedSeasonIndex,
                                dropdownColor: AppColors.surfaceElevated,
                                underline: const SizedBox.shrink(),
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                items: List.generate(
                                  movie.seasons.length,
                                  (index) => DropdownMenuItem(
                                    value: index,
                                    child: Text(movie.seasons[index].title),
                                  ),
                                ),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedSeasonIndex = val;
                                    });
                                  }
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Episode List
                        if (currentSeason != null)
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: currentSeason.episodes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, epIndex) {
                              final ep = currentSeason.episodes[epIndex];
                              return GestureDetector(
                                onTap: () {
                                  context.push('/player', extra: {
                                    'episodeId': ep.id,
                                    'movieTitle': movie.title,
                                    'episodeTitle': ep.title,
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      // Thumbnail
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          ep.stillUrl ?? movie.backdropUrl,
                                          width: 100,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 100,
                                            height: 60,
                                            color: AppColors.surfaceElevated,
                                            child: const Icon(Icons.movie, color: AppColors.textTertiary),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Title & info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ep.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${(ep.duration / 60).round()} phút',
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 30),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],

                      const SizedBox(height: 24),

                      // Cast & Crew
                      if (movie.actors.isNotEmpty) ...[
                        const Text(
                          'Diễn viên',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: movie.actors.length,
                            itemBuilder: (context, index) {
                              final actor = movie.actors[index];
                              return Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundImage: actor.avatarUrl != null
                                          ? NetworkImage(actor.avatarUrl!)
                                          : null,
                                      backgroundColor: AppColors.surfaceElevated,
                                      child: actor.avatarUrl == null
                                          ? const Icon(Icons.person, color: AppColors.textSecondary)
                                          : null,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      actor.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
