import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/movie_repository.dart';
import '../../data/repositories/playback_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/models/movie_model.dart';

final storageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(storageService: storage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthRepository(apiClient: client, storageService: storage);
});

final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return MovieRepository(apiClient: client);
});

final playbackRepositoryProvider = Provider<PlaybackRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return PlaybackRepository(apiClient: client);
});

// Current User State Notifier
class AuthStateNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _authRepo;

  AuthStateNotifier(this._authRepo) : super(const AsyncValue.loading()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      final user = await _authRepo.getMe();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepo.login(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> register(String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepo.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    state = const AsyncValue.data(null);
  }
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<UserModel?>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(authRepo);
});

// Catalog Providers
final featuredMoviesProvider = FutureProvider<List<MovieSummary>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getFeaturedMovies();
});

final trendingMoviesProvider = FutureProvider<List<MovieSummary>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getTrendingMovies();
});

final latestMoviesProvider = FutureProvider<List<MovieSummary>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getLatestMovies();
});

final favoritesProvider = FutureProvider<List<MovieSummary>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getFavorites();
});

final watchHistoryProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getWatchHistory();
});
