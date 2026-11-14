import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineora/core/theme/app_theme.dart';
import 'package:cineora/data/models/movie_model.dart';
import 'package:cineora/features/home/presentation/widgets/movie_card.dart';
import 'package:cineora/shared/widgets/cineora_scaffold.dart';

void main() {
  testWidgets('CINEORA Theme and Shell Scaffold smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const CineoraScaffold(
          child: Center(
            child: Text('CINEORA Test Body'),
          ),
        ),
      ),
    );

    expect(find.text('CINEORA Test Body'), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Khám phá'), findsOneWidget);
    expect(find.text('Yêu thích'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);
  });

  testWidgets('MovieCard widget renders title and rating badge', (WidgetTester tester) async {
    final movie = MovieSummary(
      id: 'm1',
      title: 'Mắt Biếc',
      originalTitle: 'Dreamy Eyes',
      slug: 'mat-biec',
      posterUrl: '',
      backdropUrl: '',
      releaseYear: 2019,
      duration: 117,
      type: 'MOVIE',
      ratingAverage: 8.4,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: MovieCard(movie: movie),
        ),
      ),
    );

    expect(find.text('Mắt Biếc'), findsOneWidget);
    expect(find.text('8.4'), findsOneWidget);
    expect(find.text('2019'), findsOneWidget);
  });
}
