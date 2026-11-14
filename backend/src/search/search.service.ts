import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { MovieStatus } from '@prisma/client';

@Injectable()
export class SearchService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  private normalizeText(str: string): string {
    return str
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/đ/g, 'd')
      .replace(/Đ/g, 'D')
      .toLowerCase()
      .trim();
  }

  async search(query: string, page = 1, limit = 20) {
    if (!query || query.trim().length === 0) {
      return { data: [], meta: { page: 1, limit, totalItems: 0, totalPages: 0 } };
    }

    const cleanQuery = query.trim();
    const normalized = this.normalizeText(cleanQuery);
    const skip = (page - 1) * limit;

    // Search across Title, Original Title, Actors, and Directors
    const whereCondition: any = {
      status: MovieStatus.PUBLISHED,
      OR: [
        { title: { contains: cleanQuery, mode: 'insensitive' } },
        { originalTitle: { contains: cleanQuery, mode: 'insensitive' } },
        { slug: { contains: normalized } },
        {
          actors: {
            some: {
              actor: {
                name: { contains: cleanQuery, mode: 'insensitive' },
              },
            },
          },
        },
        {
          directors: {
            some: {
              director: {
                name: { contains: cleanQuery, mode: 'insensitive' },
              },
            },
          },
        },
      ],
    };

    const [total, movies] = await Promise.all([
      this.prisma.movie.count({ where: whereCondition }),
      this.prisma.movie.findMany({
        where: whereCondition,
        skip,
        take: limit,
        orderBy: { viewCount: 'desc' },
        include: {
          country: true,
          genres: { include: { genre: true } },
          actors: { include: { actor: true }, take: 3 },
        },
      }),
    ]);

    return {
      data: movies.map((m) => ({
        id: m.id,
        title: m.title,
        originalTitle: m.originalTitle,
        slug: m.slug,
        posterUrl: m.posterUrl,
        backdropUrl: m.backdropUrl,
        releaseYear: m.releaseYear,
        type: m.type,
        ratingAverage: Number(m.ratingAverage),
        genres: m.genres.map((g) => ({ name: g.genre.name, slug: g.genre.slug })),
        actors: m.actors.map((a) => a.actor.name),
      })),
      meta: {
        page,
        limit,
        totalItems: total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getSuggestions(prefix: string) {
    if (!prefix || prefix.trim().length < 2) {
      return [];
    }

    const cleanPrefix = prefix.trim();
    const cacheKey = `search:suggest:${cleanPrefix.toLowerCase()}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }

    const movies = await this.prisma.movie.findMany({
      where: {
        status: MovieStatus.PUBLISHED,
        OR: [
          { title: { contains: cleanPrefix, mode: 'insensitive' } },
          { originalTitle: { contains: cleanPrefix, mode: 'insensitive' } },
        ],
      },
      take: 6,
      select: {
        id: true,
        title: true,
        originalTitle: true,
        posterUrl: true,
        releaseYear: true,
        type: true,
      },
    });

    await this.redis.set(cacheKey, JSON.stringify(movies), 120); // 2 mins cache
    return movies;
  }
}
