import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PlaybackSessionStatus, Role } from '@prisma/client';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  async getAnalytics() {
    const [totalUsers, totalMovies, activeSessions, topMovies] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.movie.count(),
      this.prisma.playbackSession.count({
        where: {
          sessionStatus: PlaybackSessionStatus.ACTIVE,
          lastHeartbeat: { gte: new Date(Date.now() - 30 * 1000) },
        },
      }),
      this.prisma.movie.findMany({
        take: 5,
        orderBy: { viewCount: 'desc' },
        select: {
          id: true,
          title: true,
          viewCount: true,
          ratingAverage: true,
          posterUrl: true,
        },
      }),
    ]);

    return {
      metrics: {
        totalUsers,
        totalMovies,
        concurrentActiveStreams: activeSessions,
      },
      topMovies: topMovies.map((m) => ({
        ...m,
        viewCount: Number(m.viewCount),
        ratingAverage: Number(m.ratingAverage),
      })),
      timestamp: new Date().toISOString(),
    };
  }

  async createMovie(data: any, adminId: string) {
    const movie = await this.prisma.movie.create({
      data: {
        title: data.title,
        originalTitle: data.originalTitle || data.title,
        slug: data.slug,
        description: data.description,
        posterUrl: data.posterUrl,
        backdropUrl: data.backdropUrl,
        releaseYear: data.releaseYear,
        duration: data.duration || 0,
        type: data.type || 'MOVIE',
        countryId: data.countryId || 'VN',
        trailerUrl: data.trailerUrl,
      },
    });

    await this.logAudit(adminId, 'CREATE_MOVIE', 'Movie', movie.id, { title: movie.title });
    return movie;
  }

  async updateMovie(id: string, data: any, adminId: string) {
    const updated = await this.prisma.movie.update({
      where: { id },
      data,
    });
    await this.logAudit(adminId, 'UPDATE_MOVIE', 'Movie', id, data);
    return updated;
  }

  async deleteMovie(id: string, adminId: string) {
    await this.prisma.movie.delete({ where: { id } });
    await this.logAudit(adminId, 'DELETE_MOVIE', 'Movie', id, null);
    return { success: true, message: 'Đã xóa phim thành công' };
  }

  async getAuditLogs(page = 1, limit = 50) {
    const skip = (page - 1) * limit;
    const [total, logs] = await Promise.all([
      this.prisma.auditLog.count(),
      this.prisma.auditLog.findMany({
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          admin: { select: { email: true, displayName: true, role: true } },
        },
      }),
    ]);

    return {
      data: logs,
      meta: { page, limit, totalItems: total, totalPages: Math.ceil(total / limit) },
    };
  }

  private async logAudit(adminId: string, action: string, entity: string, entityId: string, changes: any) {
    try {
      await this.prisma.auditLog.create({
        data: {
          adminId,
          action,
          entity,
          entityId,
          changes: changes ? JSON.parse(JSON.stringify(changes)) : undefined,
        },
      });
    } catch (e) {}
  }
}
