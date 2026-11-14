import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class WatchHistoryService {
  constructor(private readonly prisma: PrismaService) {}

  async getHistory(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const [total, items] = await Promise.all([
      this.prisma.watchHistory.count({ where: { userId } }),
      this.prisma.watchHistory.findMany({
        where: { userId },
        skip,
        take: limit,
        orderBy: { updatedAt: 'desc' },
        include: {
          movie: {
            include: { country: true, genres: { include: { genre: true } } },
          },
          episode: {
            include: {
              season: true,
            },
          },
        },
      }),
    ]);

    return {
      data: items.map((h) => {
        const percent = h.durationSeconds > 0
          ? Math.min(100, Math.round((h.positionSeconds / h.durationSeconds) * 100))
          : 0;

        return {
          id: h.id,
          movieId: h.movieId,
          episodeId: h.episodeId,
          movieTitle: h.movie.title,
          moviePosterUrl: h.movie.posterUrl,
          movieBackdropUrl: h.movie.backdropUrl,
          movieType: h.movie.type,
          seasonNumber: h.episode.season.seasonNumber,
          episodeNumber: h.episode.episodeNumber,
          episodeTitle: h.episode.title,
          episodeStillUrl: h.episode.stillUrl,
          positionSeconds: h.positionSeconds,
          durationSeconds: h.durationSeconds,
          percentWatched: percent,
          isCompleted: h.isCompleted,
          updatedAt: h.updatedAt,
        };
      }),
      meta: {
        page,
        limit,
        totalItems: total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async removeItem(userId: string, id: string) {
    await this.prisma.watchHistory.deleteMany({
      where: { id, userId },
    });
    return { success: true };
  }

  async clearAll(userId: string) {
    await this.prisma.watchHistory.deleteMany({
      where: { userId },
    });
    return { success: true };
  }
}
