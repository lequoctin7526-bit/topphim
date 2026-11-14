import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/movie_model.dart';

class MovieRepository {
  final ApiClient apiClient;

  MovieRepository({required this.apiClient});

  Future<List<MovieSummary>> getFeaturedMovies() async {
    final response = await apiClient.dio.get(ApiConstants.featuredMovies);
    final List<dynamic> data = response.data;
    return data.map((json) => MovieSummary.fromJson(json)).toList();
  }

  Future<List<MovieSummary>> getTrendingMovies() async {
    final response = await apiClient.dio.get(ApiConstants.trendingMovies);
    final List<dynamic> data = response.data;
    return data.map((json) => MovieSummary.fromJson(json)).toList();
  }

  Future<List<MovieSummary>> getLatestMovies() async {
    final response = await apiClient.dio.get(ApiConstants.latestMovies);
    final List<dynamic> data = response.data;
    return data.map((json) => MovieSummary.fromJson(json)).toList();
  }

  Future<List<MovieSummary>> getFilteredMovies({
    String? genre,
    String? country,
    String? type,
    int? year,
    String? sortBy,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (genre != null && genre.isNotEmpty) query['genre'] = genre;
    if (country != null && country.isNotEmpty) query['country'] = country;
    if (type != null && type.isNotEmpty) query['type'] = type;
    if (year != null) query['year'] = year;
    if (sortBy != null && sortBy.isNotEmpty) query['sortBy'] = sortBy;

    final response = await apiClient.dio.get(
      ApiConstants.movies,
      queryParameters: query,
    );

    final List<dynamic> data = response.data['data'];
    return data.map((json) => MovieSummary.fromJson(json)).toList();
  }

  Future<MovieDetail> getMovieDetail(String movieId) async {
    final response = await apiClient.dio.get('${ApiConstants.movies}/$movieId');
    return MovieDetail.fromJson(response.data);
  }

  Future<List<MovieSummary>> searchMovies(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await apiClient.dio.get(
      ApiConstants.search,
      queryParameters: {'q': query},
    );
    final List<dynamic> data = response.data['data'];
    return data.map((json) => MovieSummary.fromJson(json)).toList();
  }

  Future<List<dynamic>> getSearchSuggestions(String prefix) async {
    if (prefix.trim().length < 2) return [];
    final response = await apiClient.dio.get(
      ApiConstants.searchSuggestions,
      queryParameters: {'q': prefix},
    );
    return response.data as List<dynamic>;
  }

  Future<bool> toggleFavorite(String movieId, bool isCurrentlyFavorited) async {
    if (isCurrentlyFavorited) {
      await apiClient.dio.delete('${ApiConstants.favorites}/$movieId');
      return false;
    } else {
      await apiClient.dio.post(ApiConstants.favorites, data: {'movieId': movieId});
      return true;
    }
  }

  Future<List<MovieSummary>> getFavorites() async {
    final response = await apiClient.dio.get(ApiConstants.favorites);
    final List<dynamic> data = response.data['data'];
    return data.map((json) => MovieSummary.fromJson(json)).toList();
  }

  Future<List<dynamic>> getWatchHistory() async {
    final response = await apiClient.dio.get(ApiConstants.watchHistory);
    return response.data['data'] as List<dynamic>;
  }
}
