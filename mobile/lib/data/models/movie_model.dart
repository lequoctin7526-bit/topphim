class MovieSummary {
  final String id;
  final String title;
  final String originalTitle;
  final String slug;
  final String posterUrl;
  final String backdropUrl;
  final int releaseYear;
  final int duration;
  final String type;
  final double ratingAverage;
  final int ratingCount;
  final int viewCount;
  final String? trailerUrl;
  final List<GenreItem> genres;

  MovieSummary({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.slug,
    required this.posterUrl,
    required this.backdropUrl,
    required this.releaseYear,
    required this.duration,
    required this.type,
    required this.ratingAverage,
    this.ratingCount = 0,
    this.viewCount = 0,
    this.trailerUrl,
    this.genres = const [],
  });

  factory MovieSummary.fromJson(Map<String, dynamic> json) {
    return MovieSummary(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      originalTitle: json['originalTitle'] ?? '',
      slug: json['slug'] ?? '',
      posterUrl: json['posterUrl'] ?? '',
      backdropUrl: json['backdropUrl'] ?? '',
      releaseYear: json['releaseYear'] ?? 0,
      duration: json['duration'] ?? 0,
      type: json['type'] ?? 'MOVIE',
      ratingAverage: (json['ratingAverage'] is num) ? (json['ratingAverage'] as num).toDouble() : 0.0,
      ratingCount: json['ratingCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      trailerUrl: json['trailerUrl'],
      genres: (json['genres'] as List<dynamic>?)
              ?.map((g) => GenreItem.fromJson(g))
              .toList() ??
          [],
    );
  }
}

class GenreItem {
  final String? id;
  final String name;
  final String slug;

  GenreItem({this.id, required this.name, required this.slug});

  factory GenreItem.fromJson(Map<String, dynamic> json) {
    return GenreItem(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}

class MovieDetail extends MovieSummary {
  final String description;
  final List<SeasonItem> seasons;
  final List<CastItem> actors;
  final List<CastItem> directors;
  final bool isFavorited;
  final double? userRating;

  MovieDetail({
    required super.id,
    required super.title,
    required super.originalTitle,
    required super.slug,
    required super.posterUrl,
    required super.backdropUrl,
    required super.releaseYear,
    required super.duration,
    required super.type,
    required super.ratingAverage,
    super.ratingCount,
    super.viewCount,
    super.trailerUrl,
    super.genres,
    required this.description,
    this.seasons = const [],
    this.actors = const [],
    this.directors = const [],
    this.isFavorited = false,
    this.userRating,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    return MovieDetail(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      originalTitle: json['originalTitle'] ?? '',
      slug: json['slug'] ?? '',
      posterUrl: json['posterUrl'] ?? '',
      backdropUrl: json['backdropUrl'] ?? '',
      releaseYear: json['releaseYear'] ?? 0,
      duration: json['duration'] ?? 0,
      type: json['type'] ?? 'MOVIE',
      ratingAverage: (json['ratingAverage'] is num) ? (json['ratingAverage'] as num).toDouble() : 0.0,
      ratingCount: json['ratingCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      trailerUrl: json['trailerUrl'],
      genres: (json['genres'] as List<dynamic>?)
              ?.map((g) => GenreItem.fromJson(g))
              .toList() ??
          [],
      description: json['description'] ?? '',
      seasons: (json['seasons'] as List<dynamic>?)
              ?.map((s) => SeasonItem.fromJson(s))
              .toList() ??
          [],
      actors: (json['actors'] as List<dynamic>?)
              ?.map((a) => CastItem.fromJson(a))
              .toList() ??
          [],
      directors: (json['directors'] as List<dynamic>?)
              ?.map((d) => CastItem.fromJson(d))
              .toList() ??
          [],
      isFavorited: json['isFavorited'] ?? false,
      userRating: (json['userRating'] is num) ? (json['userRating'] as num).toDouble() : null,
    );
  }
}

class SeasonItem {
  final String id;
  final int seasonNumber;
  final String title;
  final String? overview;
  final List<EpisodeItem> episodes;

  SeasonItem({
    required this.id,
    required this.seasonNumber,
    required this.title,
    this.overview,
    this.episodes = const [],
  });

  factory SeasonItem.fromJson(Map<String, dynamic> json) {
    return SeasonItem(
      id: json['id'] ?? '',
      seasonNumber: json['seasonNumber'] ?? 1,
      title: json['title'] ?? '',
      overview: json['overview'],
      episodes: (json['episodes'] as List<dynamic>?)
              ?.map((e) => EpisodeItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class EpisodeItem {
  final String id;
  final int episodeNumber;
  final String title;
  final int duration;
  final String? overview;
  final String? stillUrl;

  EpisodeItem({
    required this.id,
    required this.episodeNumber,
    required this.title,
    required this.duration,
    this.overview,
    this.stillUrl,
  });

  factory EpisodeItem.fromJson(Map<String, dynamic> json) {
    return EpisodeItem(
      id: json['id'] ?? '',
      episodeNumber: json['episodeNumber'] ?? 1,
      title: json['title'] ?? '',
      duration: json['duration'] ?? 0,
      overview: json['overview'],
      stillUrl: json['stillUrl'],
    );
  }
}

class CastItem {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? characterName;

  CastItem({required this.id, required this.name, this.avatarUrl, this.characterName});

  factory CastItem.fromJson(Map<String, dynamic> json) {
    return CastItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatarUrl'],
      characterName: json['characterName'],
    );
  }
}
