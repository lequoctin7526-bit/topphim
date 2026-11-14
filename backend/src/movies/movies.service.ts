import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { QueryMoviesDto } from './dto/query-movies.dto';
import { MovieStatus } from '@prisma/client';

@Injectable()
export class MoviesService {
  private readonly logger = new Logger(MoviesService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  async findAll(query: QueryMoviesDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = {
      status: MovieStatus.PUBLISHED,
    };

    if (query.genre) {
      where.genres = {
        some: {
          genre: {
            slug: query.genre,
          },
        },
      };
    }

    if (query.country) {
      where.countryId = query.country.toUpperCase();
    }

    if (query.type) {
      where.type = query.type;
    }

    if (query.year) {
      where.releaseYear = query.year;
    }

    let orderBy: any = { createdAt: 'desc' };
    if (query.sortBy === 'popular') {
      orderBy = { viewCount: 'desc' };
    } else if (query.sortBy === 'rating') {
      orderBy = { ratingAverage: 'desc' };
    }

    const [total, movies] = await Promise.all([
      this.prisma.movie.count({ where }),
      this.prisma.movie.findMany({
        where,
        skip,
        take: limit,
        orderBy,
        include: {
          country: true,
          genres: {
            include: { genre: true },
          },
        },
      }),
    ]);

    return {
      data: movies.map((m) => this.formatMovieSummary(m)),
      meta: {
        page,
        limit,
        totalItems: total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getFeatured() {
    const cacheKey = 'movies:featured';
    const cached = await this.redis.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }

    const movies = await this.prisma.movie.findMany({
      where: { status: MovieStatus.PUBLISHED },
      take: 6,
      orderBy: { viewCount: 'desc' },
      include: {
        country: true,
        genres: {
          include: { genre: true },
        },
      },
    });

    const result = movies.map((m) => this.formatMovieSummary(m));
    await this.redis.set(cacheKey, JSON.stringify(result), 300); // 5 min cache
    return result;
  }

  async getTrending() {
    const cacheKey = 'movies:trending';
    const cached = await this.redis.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }

    const movies = await this.prisma.movie.findMany({
      where: { status: MovieStatus.PUBLISHED },
      take: 12,
      orderBy: { viewCount: 'desc' },
      include: {
        country: true,
        genres: {
          include: { genre: true },
        },
      },
    });

    const result = movies.map((m) => this.formatMovieSummary(m));
    await this.redis.set(cacheKey, JSON.stringify(result), 300);
    return result;
  }

  async getLatest() {
    const movies = await this.prisma.movie.findMany({
      where: { status: MovieStatus.PUBLISHED },
      take: 12,
      orderBy: { createdAt: 'desc' },
      include: {
        country: true,
        genres: {
          include: { genre: true },
        },
      },
    });

    return movies.map((m) => this.formatMovieSummary(m));
  }

  async findOne(id: string, userId?: string) {
    const movie = await this.prisma.movie.findUnique({
      where: { id },
      include: {
        country: true,
        genres: { include: { genre: true } },
        actors: { include: { actor: true } },
        directors: { include: { director: true } },
        seasons: {
          orderBy: { seasonNumber: 'asc' },
          include: {
            episodes: {
              where: { status: 'ACTIVE' },
              orderBy: { episodeNumber: 'asc' },
            },
          },
        },
      },
    });

    if (!movie || movie.status !== MovieStatus.PUBLISHED) {
      throw new NotFoundException('Không tìm thấy phim');
    }

    let isFavorited = false;
    let userRating: number | null = null;

    if (userId) {
      const [fav, rat] = await Promise.all([
        this.prisma.favorite.findUnique({
          where: { userId_movieId: { userId, movieId: id } },
        }),
        this.prisma.rating.findUnique({
          where: { userId_movieId: { userId, movieId: id } },
        }),
      ]);
      isFavorited = !!fav;
      userRating = rat ? Number(rat.score) : null;
    }

    return {
      ...this.formatMovieSummary(movie),
      description: movie.description,
      actors: movie.actors.map((ma) => ({
        id: ma.actor.id,
        name: ma.actor.name,
        avatarUrl: ma.actor.avatarUrl,
        characterName: ma.characterName,
      })),
      directors: movie.directors.map((md) => ({
        id: md.director.id,
        name: md.director.name,
        avatarUrl: md.director.avatarUrl,
      })),
      seasons: movie.seasons.map((s) => ({
        id: s.id,
        seasonNumber: s.seasonNumber,
        title: s.title,
        overview: s.overview,
        episodes: s.episodes.map((ep) => ({
          id: ep.id,
          episodeNumber: ep.episodeNumber,
          title: ep.title,
          duration: ep.duration,
          overview: ep.overview,
          stillUrl: ep.stillUrl,
        })),
      })),
      isFavorited,
      userRating,
    };
  }

  async getEpisodes(movieId: string) {
    const seasons = await this.prisma.season.findMany({
      where: { movieId },
      orderBy: { seasonNumber: 'asc' },
      include: {
        episodes: {
          where: { status: 'ACTIVE' },
          orderBy: { episodeNumber: 'asc' },
        },
      },
    });

    return seasons;
  }

  async getRelated(movieId: string) {
    const movie = await this.prisma.movie.findUnique({
      where: { id: movieId },
      include: { genres: true },
    });

    if (!movie) return [];

    const genreIds = movie.genres.map((g) => g.genreId);

    const related = await this.prisma.movie.findMany({
      where: {
        id: { not: movieId },
        status: MovieStatus.PUBLISHED,
        genres: {
          some: {
            genreId: { in: genreIds },
          },
        },
      },
      take: 8,
      orderBy: { ratingAverage: 'desc' },
      include: {
        country: true,
        genres: { include: { genre: true } },
      },
    });

    return related.map((m) => this.formatMovieSummary(m));
  }

  private formatMovieSummary(m: any) {
    return {
      id: m.id,
      title: m.title,
      originalTitle: m.originalTitle,
      slug: m.slug,
      posterUrl: m.posterUrl,
      backdropUrl: m.backdropUrl,
      releaseYear: m.releaseYear,
      duration: m.duration,
      type: m.type,
      ratingAverage: Number(m.ratingAverage),
      ratingCount: m.ratingCount,
      viewCount: Number(m.viewCount),
      trailerUrl: m.trailerUrl,
      country: m.country ? { id: m.country.id, name: m.country.name } : null,
      genres: m.genres ? m.genres.map((g: any) => ({ id: g.genre.id, name: g.genre.name, slug: g.genre.slug })) : [],
      createdAt: m.createdAt,
    };
  }
}
