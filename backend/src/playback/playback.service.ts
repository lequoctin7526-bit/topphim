import {
  Injectable,
  ForbiddenException,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { ProvidersService } from '../providers/providers.service';
import { AuthorizePlaybackDto, PlaybackHeartbeatDto, ClosePlaybackDto } from './dto/playback.dto';
import { PlaybackSessionStatus } from '@prisma/client';

@Injectable()
export class PlaybackService {
  private readonly logger = new Logger(PlaybackService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly providersService: ProvidersService,
  ) {}

  async authorize(dto: AuthorizePlaybackDto, user: any, clientIp: string, clientCountry = 'VN') {
    // 1. Fetch episode & video source
    const episode = await this.prisma.episode.findUnique({
      where: { id: dto.episodeId },
      include: {
        season: {
          include: {
            movie: true,
          },
        },
        videoSources: {
          where: { status: 'ACTIVE' },
          include: {
            provider: true,
          },
          take: 1,
        },
        subtitles: true,
        audioTracks: true,
      },
    });

    if (!episode || episode.status !== 'ACTIVE') {
      throw new NotFoundException('Tập phim không khả dụng');
    }

    const videoSource = episode.videoSources[0];
    if (!videoSource) {
      throw new NotFoundException('Không tìm thấy nguồn video được cấp phép cho nội dung này');
    }

    // 2. Check License Availability Period
    const now = new Date();
    if (now < videoSource.availabilityStart || now > videoSource.availabilityEnd) {
      throw new ForbiddenException('Thời hạn cấp phép phát nội dung này chưa bắt đầu hoặc đã hết hiệu lực');
    }

    // 3. Region Entitlement Check (Vietnam Priority)
    if (videoSource.regionPolicy === 'VN_ONLY' && clientCountry !== 'VN') {
      throw new ForbiddenException('Nội dung này hiện chỉ được cấp quyền phát hành tại lãnh thổ Việt Nam');
    }

    // 4. Subscription & Concurrency Check
    const activeSub = await this.prisma.userSubscription.findFirst({
      where: {
        userId: user.id,
        status: 'ACTIVE',
        expiresAt: { gt: now },
      },
      include: { plan: true },
    });

    const maxStreams = activeSub?.plan?.maxStreams || 1;
    const maxResolution = activeSub?.plan?.maxResolution || '1080p';

    // Check concurrency via active sessions in last 30 seconds
    const activeSessionsCount = await this.prisma.playbackSession.count({
      where: {
        userId: user.id,
        sessionStatus: PlaybackSessionStatus.ACTIVE,
        lastHeartbeat: { gte: new Date(Date.now() - 30 * 1000) },
        deviceId: { not: dto.deviceId }, // Allow same device to re-authorize
      },
    });

    if (activeSessionsCount >= maxStreams) {
      throw new ForbiddenException(
        `Bạn đã đạt giới hạn ${maxStreams} thiết bị phát đồng thời theo gói dịch vụ. Vui lòng dừng phát trên thiết bị khác hoặc nâng cấp gói Premium.`,
      );
    }

    // 5. Query Resume Position from Watch History
    const history = await this.prisma.watchHistory.findUnique({
      where: {
        userId_episodeId: {
          userId: user.id,
          episodeId: dto.episodeId,
        },
      },
    });

    let resumePositionSeconds = 0;
    if (history && !history.isCompleted && history.positionSeconds > 10) {
      resumePositionSeconds = history.positionSeconds;
    }

    // 6. Delegate to Provider Adapter
    const adapter = this.providersService.getAdapter(videoSource.providerId);
    const authorizedStream = await adapter.authorizePlayback(
      {
        ...videoSource,
        episode,
      },
      {
        userId: user.id,
        movieId: episode.season.movieId,
        episodeId: episode.id,
        userIp: clientIp,
        userCountry: clientCountry,
        subscriptionPlanId: activeSub?.planId || 'PLAN_FREE',
        maxStreams,
        maxResolution,
        deviceId: dto.deviceId,
      },
    );

    // 7. Create Playback Session
    const session = await this.prisma.playbackSession.create({
      data: {
        userId: user.id,
        episodeId: episode.id,
        providerId: videoSource.providerId,
        deviceId: dto.deviceId,
        ipAddress: clientIp,
        sessionStatus: PlaybackSessionStatus.ACTIVE,
      },
    });

    // Increment movie view count asynchronously
    this.prisma.movie
      .update({
        where: { id: episode.season.movieId },
        data: { viewCount: { increment: 1 } },
      })
      .catch((e) => this.logger.warn(`Failed to increment viewCount: ${e.message}`));

    return {
      playbackSessionId: session.id,
      playbackUrl: authorizedStream.playbackUrl,
      drm: authorizedStream.drm,
      subtitles: authorizedStream.subtitles,
      audioTracks: authorizedStream.audioTracks,
      resumePositionSeconds,
      maxResolution,
      expiresAt: authorizedStream.expiresAt,
    };
  }

  async heartbeat(dto: PlaybackHeartbeatDto, userId: string) {
    const session = await this.prisma.playbackSession.findUnique({
      where: { id: dto.playbackSessionId },
    });

    if (!session || session.userId !== userId || session.sessionStatus !== 'ACTIVE') {
      throw new ForbiddenException('Phiên xem không hợp lệ hoặc đã kết thúc');
    }

    // Update session heartbeat
    await this.prisma.playbackSession.update({
      where: { id: dto.playbackSessionId },
      data: { lastHeartbeat: new Date() },
    });

    // Update Watch History
    const isCompleted = dto.positionSeconds >= dto.durationSeconds * 0.9;
    await this.prisma.watchHistory.upsert({
      where: {
        userId_episodeId: {
          userId,
          episodeId: session.episodeId,
        },
      },
      update: {
        positionSeconds: dto.positionSeconds,
        durationSeconds: dto.durationSeconds,
        isCompleted,
        updatedAt: new Date(),
      },
      create: {
        userId,
        movieId: (
          await this.prisma.episode.findUnique({
            where: { id: session.episodeId },
            select: { season: { select: { movieId: true } } },
          })
        )?.season.movieId!,
        episodeId: session.episodeId,
        positionSeconds: dto.positionSeconds,
        durationSeconds: dto.durationSeconds,
        isCompleted,
      },
    });

    return { success: true };
  }

  async close(dto: ClosePlaybackDto, userId: string) {
    const session = await this.prisma.playbackSession.findUnique({
      where: { id: dto.playbackSessionId },
    });

    if (!session || session.userId !== userId) {
      return { success: true };
    }

    const isCompleted = dto.positionSeconds >= dto.durationSeconds * 0.9;

    await Promise.all([
      this.prisma.playbackSession.update({
        where: { id: dto.playbackSessionId },
        data: {
          sessionStatus: PlaybackSessionStatus.TERMINATED,
          endedAt: new Date(),
        },
      }),
      this.prisma.watchHistory.upsert({
        where: {
          userId_episodeId: {
            userId,
            episodeId: session.episodeId,
          },
        },
        update: {
          positionSeconds: dto.positionSeconds,
          durationSeconds: dto.durationSeconds,
          isCompleted,
          updatedAt: new Date(),
        },
        create: {
          userId,
          movieId: (
            await this.prisma.episode.findUnique({
              where: { id: session.episodeId },
              select: { season: { select: { movieId: true } } },
            })
          )?.season.movieId!,
          episodeId: session.episodeId,
          positionSeconds: dto.positionSeconds,
          durationSeconds: dto.durationSeconds,
          isCompleted,
        },
      }),
    ]);

    return { success: true };
  }
}
