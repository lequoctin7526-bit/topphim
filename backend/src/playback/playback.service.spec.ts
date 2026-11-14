import { Test, TestingModule } from '@nestjs/testing';
import { PlaybackService } from './playback.service';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { ProvidersService } from '../providers/providers.service';
import { ForbiddenException, NotFoundException } from '@nestjs/common';

describe('PlaybackService', () => {
  let service: PlaybackService;

  const mockPrismaService = {
    episode: {
      findUnique: jest.fn(),
    },
    userSubscription: {
      findFirst: jest.fn(),
    },
    playbackSession: {
      count: jest.fn(),
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    watchHistory: {
      findUnique: jest.fn(),
      upsert: jest.fn(),
    },
    movie: {
      update: jest.fn().mockResolvedValue({}),
    },
  };

  const mockRedisService = {
    get: jest.fn(),
    set: jest.fn(),
  };

  const mockAdapter = {
    providerId: 'PUBLIC_DOMAIN_ARCHIVE',
    providerName: 'Public Domain',
    authorizePlayback: jest.fn().mockResolvedValue({
      playbackUrl: 'https://cdn.cineora.tv/hls/master.m3u8?token=mock_signed',
      drm: { type: 'NONE' },
      subtitles: [],
      audioTracks: [],
      expiresAt: new Date(Date.now() + 7200000),
    }),
  };

  const mockProvidersService = {
    getAdapter: jest.fn().mockReturnValue(mockAdapter),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PlaybackService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: RedisService, useValue: mockRedisService },
        { provide: ProvidersService, useValue: mockProvidersService },
      ],
    }).compile();

    service = module.get<PlaybackService>(PlaybackService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should deny authorization if episode is not found', async () => {
    mockPrismaService.episode.findUnique.mockResolvedValueOnce(null);

    await expect(
      service.authorize(
        { episodeId: 'invalid-ep', deviceId: 'dev-1' },
        { id: 'u1' },
        '127.0.0.1',
        'VN',
      ),
    ).rejects.toThrow(NotFoundException);
  });

  it('should reject stream when region policy is VN_ONLY and user is outside VN', async () => {
    mockPrismaService.episode.findUnique.mockResolvedValueOnce({
      id: 'ep-1',
      status: 'ACTIVE',
      season: { movieId: 'm1' },
      videoSources: [
        {
          id: 'vs-1',
          providerId: 'PUBLIC_DOMAIN_ARCHIVE',
          regionPolicy: 'VN_ONLY',
          availabilityStart: new Date('2020-01-01'),
          availabilityEnd: new Date('2030-01-01'),
        },
      ],
    });

    await expect(
      service.authorize(
        { episodeId: 'ep-1', deviceId: 'dev-1' },
        { id: 'u1' },
        '203.0.113.1',
        'US', // Outside Vietnam
      ),
    ).rejects.toThrow(ForbiddenException);
  });

  it('should reject stream when concurrent stream limit is exceeded', async () => {
    mockPrismaService.episode.findUnique.mockResolvedValueOnce({
      id: 'ep-1',
      status: 'ACTIVE',
      season: { movieId: 'm1' },
      videoSources: [
        {
          id: 'vs-1',
          providerId: 'PUBLIC_DOMAIN_ARCHIVE',
          regionPolicy: 'VN_ONLY',
          availabilityStart: new Date('2020-01-01'),
          availabilityEnd: new Date('2030-01-01'),
        },
      ],
    });

    mockPrismaService.userSubscription.findFirst.mockResolvedValueOnce({
      plan: { maxStreams: 1, maxResolution: '1080p' },
    });

    // 1 stream already active on another device
    mockPrismaService.playbackSession.count.mockResolvedValueOnce(1);

    await expect(
      service.authorize(
        { episodeId: 'ep-1', deviceId: 'dev-2' },
        { id: 'u1' },
        '127.0.0.1',
        'VN',
      ),
    ).rejects.toThrow(ForbiddenException);
  });

  it('should authorize and issue signed stream URL when all checks pass', async () => {
    mockPrismaService.episode.findUnique.mockResolvedValueOnce({
      id: 'ep-1',
      status: 'ACTIVE',
      season: { movieId: 'm1' },
      videoSources: [
        {
          id: 'vs-1',
          providerId: 'PUBLIC_DOMAIN_ARCHIVE',
          regionPolicy: 'VN_ONLY',
          availabilityStart: new Date('2020-01-01'),
          availabilityEnd: new Date('2030-01-01'),
        },
      ],
      subtitles: [],
      audioTracks: [],
    });

    mockPrismaService.userSubscription.findFirst.mockResolvedValueOnce({
      plan: { maxStreams: 2, maxResolution: '4K' },
    });

    mockPrismaService.playbackSession.count.mockResolvedValueOnce(0);
    mockPrismaService.watchHistory.findUnique.mockResolvedValueOnce(null);
    mockPrismaService.playbackSession.create.mockResolvedValueOnce({
      id: 'new-session-uuid',
    });

    const result = await service.authorize(
      { episodeId: 'ep-1', deviceId: 'dev-1' },
      { id: 'u1' },
      '127.0.0.1',
      'VN',
    );

    expect(result.playbackSessionId).toBe('new-session-uuid');
    expect(result.playbackUrl).toContain('mock_signed');
  });
});
