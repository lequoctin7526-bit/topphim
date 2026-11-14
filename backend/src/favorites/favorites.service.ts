import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class FavoritesService {
  constructor(private readonly prisma: PrismaService) {}

  async getUserFavorites(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const [total, favorites] = await Promise.all([
      this.prisma.favorite.count({ where: { userId } }),
      this.prisma.favorite.findMany({
        where: { userId },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          movie: {
            include: {
              country: true,
              genres: { include: { genre: true } },
            },
          },
        },
      }),
    ]);

    return {
      data: favorites.map((f) => ({
        id: f.movie.id,
        title: f.movie.title,
        originalTitle: f.movie.originalTitle,
        slug: f.movie.slug,
        posterUrl: f.movie.posterUrl,
        backdropUrl: f.movie.backdropUrl,
        releaseYear: f.movie.releaseYear,
        duration: f.movie.duration,
        type: f.movie.type,
        ratingAverage: Number(f.movie.ratingAverage),
        genres: f.movie.genres.map((g) => ({ name: g.genre.name, slug: g.genre.slug })),
        addedAt: f.createdAt,
      })),
      meta: {
        page,
        limit,
        totalItems: total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async addFavorite(userId: string, movieId: string) {
    const movie = await this.prisma.movie.findUnique({ where: { id: movieId } });
    if (!movie) {
      throw new NotFoundException('Không tìm thấy phim');
    }

    try {
      await this.prisma.favorite.create({
        data: { userId, movieId },
      });
      return { success: true, message: 'Đã thêm vào danh sách yêu thích' };
    } catch (e) {
      return { success: true, message: 'Phim đã có trong danh sách yêu thích' };
    }
  }

  async removeFavorite(userId: string, movieId: string) {
    await this.prisma.favorite.deleteMany({
      where: { userId, movieId },
    });
    return { success: true, message: 'Đã xóa khỏi danh sách yêu thích' };
  }
}
