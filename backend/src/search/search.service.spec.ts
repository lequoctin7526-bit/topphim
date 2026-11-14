import { Test, TestingModule } from '@nestjs/testing';
import { SearchService } from './search.service';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';

describe('SearchService', () => {
  let service: SearchService;

  const mockPrismaService = {
    movie: {
      count: jest.fn(),
      findMany: jest.fn(),
    },
  };

  const mockRedisService = {
    get: jest.fn().mockResolvedValue(null),
    set: jest.fn().mockResolvedValue(undefined),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SearchService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: RedisService, useValue: mockRedisService },
      ],
    }).compile();

    service = module.get<SearchService>(SearchService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should return empty result for blank queries', async () => {
    const res = await service.search('');
    expect(res.data).toEqual([]);
    expect(res.meta.totalItems).toBe(0);
  });

  it('should query movies matching title, slug, and actors', async () => {
    mockPrismaService.movie.count.mockResolvedValueOnce(1);
    mockPrismaService.movie.findMany.mockResolvedValueOnce([
      {
        id: 'm1',
        title: 'Mắt Biếc',
        originalTitle: 'Dreamy Eyes',
        slug: 'mat-biec',
        posterUrl: 'https://...',
        backdropUrl: 'https://...',
        releaseYear: 2019,
        type: 'MOVIE',
        ratingAverage: 8.5,
        genres: [{ genre: { name: 'Lãng Mạn', slug: 'lang-man' } }],
        actors: [{ actor: { name: 'Trần Nghĩa' } }],
      },
    ]);

    const res = await service.search('mat biec');
    expect(res.data.length).toBe(1);
    expect(res.data[0].title).toBe('Mắt Biếc');
  });
});
