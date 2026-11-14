class ApiConstants {
  // Configurable base URL: Android emulator uses 10.0.2.2, iOS simulator uses localhost
  static const String defaultBaseUrl = 'http://10.0.2.2:3000/api/v1';
  static const String iosLocalBaseUrl = 'http://localhost:3000/api/v1';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Movies
  static const String movies = '/movies';
  static const String featuredMovies = '/movies/featured';
  static const String trendingMovies = '/movies/trending';
  static const String latestMovies = '/movies/latest';

  // Search
  static const String search = '/search';
  static const String searchSuggestions = '/search/suggestions';

  // Playback
  static const String playbackAuthorize = '/playback/authorize';
  static const String playbackHeartbeat = '/playback/heartbeat';
  static const String playbackClose = '/playback/close';

  // User Features
  static const String favorites = '/users/me/favorites';
  static const String watchHistory = '/users/me/history';
  static const String userProfile = '/users/me';
  static const String subscriptionPlans = '/subscriptions/plans';
  static const String userSubscription = '/subscriptions/me';
}
