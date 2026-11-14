import { PrismaClient, Role, UserStatus, MovieType, MovieStatus, DrmType, RegionPolicy, SubtitleFormat, EpisodeStatus } from '@prisma/client';
import * as argon2 from 'argon2';

const prisma = new PrismaClient();

async function main() {
  console.log('--- [CINEORA SEED] Starting Database Seeding ---');

  // 1. Countries
  const countries = [
    { id: 'VN', name: 'Việt Nam' },
    { id: 'KR', name: 'Hàn Quốc' },
    { id: 'CN', name: 'Trung Quốc' },
    { id: 'US', name: 'Âu Mỹ' },
    { id: 'JP', name: 'Nhật Bản' },
  ];
  for (const c of countries) {
    await prisma.country.upsert({
      where: { id: c.id },
      update: {},
      create: c,
    });
  }
  console.log('✓ Countries seeded');

  // 2. Genres
  const genres = [
    { name: 'Hành Động', slug: 'hanh-dong' },
    { name: 'Lãng Mạn', slug: 'lang-man' },
    { name: 'Khoa Học Viễn Tưởng', slug: 'khoa-hoc-vien-tuong' },
    { name: 'Hoạt Hình & Anime', slug: 'hoat-hinh-anime' },
    { name: 'Kinh Dị & Giật Gân', slug: 'kinh-di' },
    { name: 'Hài Hước', slug: 'hai-huoc' },
    { name: 'Võ Thuật & Cổ Trang', slug: 'vo-thuat' },
    { name: 'Tài Liệu', slug: 'tai-lieu' },
  ];
  const genreMap = new Map<string, string>();
  for (const g of genres) {
    const record = await prisma.genre.upsert({
      where: { slug: g.slug },
      update: {},
      create: g,
    });
    genreMap.set(g.slug, record.id);
  }
  console.log('✓ Genres seeded');

  // 3. Subscription Plans
  const plans = [
    {
      id: 'PLAN_FREE',
      name: 'Gói Miễn Phí (Cơ bản)',
      price: 0,
      currency: 'VND',
      durationDays: 0,
      maxStreams: 1,
      maxResolution: '1080p',
      status: 'ACTIVE',
    },
    {
      id: 'PLAN_PREMIUM_MONTHLY',
      name: 'Gói Premium (1 Tháng)',
      price: 79000,
      currency: 'VND',
      durationDays: 30,
      maxStreams: 2,
      maxResolution: '4K Ultra HD',
      status: 'ACTIVE',
    },
    {
      id: 'PLAN_PREMIUM_YEARLY',
      name: 'Gói Premium (1 Năm - Tiết kiệm 20%)',
      price: 790000,
      currency: 'VND',
      durationDays: 365,
      maxStreams: 4,
      maxResolution: '4K Ultra HD',
      status: 'ACTIVE',
    },
  ];
  for (const p of plans) {
    await prisma.subscriptionPlan.upsert({
      where: { id: p.id },
      update: {},
      create: p,
    });
  }
  console.log('✓ Subscription Plans seeded');

  // 4. Default Users
  const superAdminPasswordHash = await argon2.hash('AdminPass123!');
  const testUserPasswordHash = await argon2.hash('UserPass123!');

  const admin = await prisma.user.upsert({
    where: { email: 'admin@cineora.tv' },
    update: {},
    create: {
      email: 'admin@cineora.tv',
      passwordHash: superAdminPasswordHash,
      displayName: 'Cineora Super Admin',
      role: Role.SUPER_ADMIN,
      status: UserStatus.ACTIVE,
    },
  });

  const testUser = await prisma.user.upsert({
    where: { email: 'user@cineora.tv' },
    update: {},
    create: {
      email: 'user@cineora.tv',
      passwordHash: testUserPasswordHash,
      displayName: 'Nguyễn Minh Quân',
      role: Role.USER,
      status: UserStatus.ACTIVE,
    },
  });

  // Assign Free Subscription to test user
  await prisma.userSubscription.createMany({
    data: [
      {
        userId: testUser.id,
        planId: 'PLAN_FREE',
        startsAt: new Date(),
        expiresAt: new Date(Date.now() + 365 * 24 * 3600 * 1000),
      },
    ],
    skipDuplicates: true,
  });
  console.log('✓ Users & Subscriptions seeded');

  // 5. Content Providers
  const providerPublicDomain = await prisma.contentProvider.upsert({
    where: { id: 'PUBLIC_DOMAIN_ARCHIVE' },
    update: {},
    create: {
      id: 'PUBLIC_DOMAIN_ARCHIVE',
      name: 'Open Culture & Public Domain Media Foundation',
      providerType: 'HLS_STREAM',
      apiEndpoint: 'https://test-streams.mux.dev',
      status: 'ACTIVE',
    },
  });

  const providerCineoraCdn = await prisma.contentProvider.upsert({
    where: { id: 'CINEORA_ORIGIN_CDN' },
    update: {},
    create: {
      id: 'CINEORA_ORIGIN_CDN',
      name: 'CINEORA Cloudfront Licensed Edge CDN',
      providerType: 'HLS_STREAM',
      apiEndpoint: 'https://cdn.cineora.tv',
      status: 'ACTIVE',
    },
  });
  console.log('✓ Content Providers seeded');

  // 6. Actors & Directors
  const dir1 = await prisma.director.create({
    data: {
      name: 'Victor Vũ',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&q=80',
    },
  });

  const dir2 = await prisma.director.create({
    data: {
      name: 'Christopher Nolan',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300&q=80',
    },
  });

  const actor1 = await prisma.actor.create({
    data: {
      name: 'Trần Nghĩa',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80',
    },
  });

  const actor2 = await prisma.actor.create({
    data: {
      name: 'Trúc Anh',
      avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=300&q=80',
    },
  });

  // 7. Seed Movies & Series with Licensed HLS Streams
  // Movie 1: Mắt Biếc
  const movie1 = await prisma.movie.create({
    data: {
      title: 'Mắt Biếc',
      originalTitle: 'Dreamy Eyes',
      slug: 'mat-biec',
      description: 'Chuyện tình đơn phương da diết của Ngạn dành cho cô bạn thời thơ ấu Hà Lan với đôi mắt biếc biếc mênh mang.',
      posterUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=600&q=80',
      backdropUrl: 'https://images.unsplash.com/photo-1518173946687-a4c8a383392e?w=1280&q=80',
      releaseYear: 2019,
      duration: 117,
      type: MovieType.MOVIE,
      countryId: 'VN',
      status: MovieStatus.PUBLISHED,
      ratingAverage: 8.4,
      ratingCount: 1540,
      viewCount: 125000n,
      metadataProvider: 'TMDB',
      metadataExternalId: '617502',
      trailerUrl: 'https://www.youtube.com/watch?v=ITlQ0oU7tDA',
      genres: {
        create: [
          { genreId: genreMap.get('lang-man')! },
        ],
      },
      directors: {
        create: [{ directorId: dir1.id }],
      },
      actors: {
        create: [
          { actorId: actor1.id, characterName: 'Ngạn' },
          { actorId: actor2.id, characterName: 'Hà Lan' },
        ],
      },
      seasons: {
        create: [
          {
            seasonNumber: 1,
            title: 'Phim Lẻ',
            episodes: {
              create: [
                {
                  episodeNumber: 1,
                  title: 'Bản Đầy Đủ (Full Movie)',
                  duration: 7020,
                  overview: 'Bản chiếu rạp chất lượng cao kèm phụ đề và âm thanh vòm.',
                  stillUrl: 'https://images.unsplash.com/photo-1518173946687-a4c8a383392e?w=1280&q=80',
                  status: EpisodeStatus.ACTIVE,
                  videoSources: {
                    create: [
                      {
                        providerId: providerPublicDomain.id,
                        externalContentId: 'mat-biec-feature-hls-01',
                        playbackUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
                        drmType: DrmType.NONE,
                        regionPolicy: RegionPolicy.VN_ONLY,
                        resolution: '1080p',
                        availabilityStart: new Date('2024-01-01'),
                        availabilityEnd: new Date('2028-12-31'),
                        status: 'ACTIVE',
                      },
                    ],
                  },
                  subtitles: {
                    create: [
                      {
                        language: 'vi',
                        label: 'Tiếng Việt',
                        format: SubtitleFormat.VTT,
                        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/subtitles/vi.vtt',
                        isDefault: true,
                      },
                      {
                        language: 'en',
                        label: 'English',
                        format: SubtitleFormat.VTT,
                        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/subtitles/en.vtt',
                        isDefault: false,
                      },
                    ],
                  },
                  audioTracks: {
                    create: [
                      {
                        language: 'vi',
                        label: 'Gốc (Tiếng Việt 5.1)',
                        isDefault: true,
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  });

  // Movie 2: Tears of Steel (Sci-Fi licensed public CC open project)
  const movie2 = await prisma.movie.create({
    data: {
      title: 'Chiến Binh Thép',
      originalTitle: 'Tears of Steel',
      slug: 'chien-binh-thep',
      description: 'Trong một tương lai giả định tàn khốc, một nhóm chuyên gia quân sự và nhà khoa học tập hợp tại Amsterdam để giải cứu thế giới khỏi hiểm họa robot tự hành.',
      posterUrl: 'https://images.unsplash.com/photo-1578328819058-b69f3a3b0f6b?w=600&q=80',
      backdropUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1280&q=80',
      releaseYear: 2022,
      duration: 12,
      type: MovieType.MOVIE,
      countryId: 'US',
      status: MovieStatus.PUBLISHED,
      ratingAverage: 8.8,
      ratingCount: 890,
      viewCount: 65000n,
      metadataProvider: 'TMDB',
      trailerUrl: 'https://www.youtube.com/watch?v=R6MlUcmOul8',
      genres: {
        create: [
          { genreId: genreMap.get('khoa-hoc-vien-tuong')! },
          { genreId: genreMap.get('hanh-dong')! },
        ],
      },
      directors: {
        create: [{ directorId: dir2.id }],
      },
      seasons: {
        create: [
          {
            seasonNumber: 1,
            title: 'Phim Ngắn',
            episodes: {
              create: [
                {
                  episodeNumber: 1,
                  title: 'Tập Đầy Đủ',
                  duration: 734,
                  overview: 'Bản 4K HDR hoàn chỉnh.',
                  stillUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1280&q=80',
                  status: EpisodeStatus.ACTIVE,
                  videoSources: {
                    create: [
                      {
                        providerId: providerPublicDomain.id,
                        externalContentId: 'tears-of-steel-hls-4k',
                        playbackUrl: 'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
                        drmType: DrmType.NONE,
                        regionPolicy: RegionPolicy.GLOBAL,
                        resolution: '4K',
                        availabilityStart: new Date('2024-01-01'),
                        availabilityEnd: new Date('2029-12-31'),
                        status: 'ACTIVE',
                      },
                    ],
                  },
                  subtitles: {
                    create: [
                      {
                        language: 'vi',
                        label: 'Tiếng Việt',
                        format: SubtitleFormat.VTT,
                        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/subtitles/vi.vtt',
                        isDefault: true,
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  });

  // Series 1: Cổ Tích Đại Dương (Series)
  const series1 = await prisma.movie.create({
    data: {
      title: 'Hành Tinh Xanh',
      originalTitle: 'The Blue Planet',
      slug: 'hanh-tinh-xanh',
      description: 'Chuyến phiêu lưu khám phá những bí mật sâu thẳm nhất của đại dương, từ những rạn san hô rực rỡ đến vùng biển sâu tăm tối.',
      posterUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600&q=80',
      backdropUrl: 'https://images.unsplash.com/photo-1682687220063-4742bd7fd538?w=1280&q=80',
      releaseYear: 2023,
      duration: 0,
      type: MovieType.SERIES,
      countryId: 'US',
      status: MovieStatus.PUBLISHED,
      ratingAverage: 9.2,
      ratingCount: 3200,
      viewCount: 420000n,
      metadataProvider: 'TMDB',
      genres: {
        create: [
          { genreId: genreMap.get('tai-lieu')! },
        ],
      },
      seasons: {
        create: [
          {
            seasonNumber: 1,
            title: 'Mùa 1: Bí Mật Đại Dương',
            overview: 'Hành trình dưới đáy đại dương.',
            episodes: {
              create: [
                {
                  episodeNumber: 1,
                  title: 'Tập 1: Đại Dương Bao La',
                  duration: 3600,
                  overview: 'Khởi đầu chuyến thám hiểm những kỳ quan biển sâu.',
                  stillUrl: 'https://images.unsplash.com/photo-1682687220063-4742bd7fd538?w=1280&q=80',
                  status: EpisodeStatus.ACTIVE,
                  videoSources: {
                    create: [
                      {
                        providerId: providerPublicDomain.id,
                        externalContentId: 'blue-planet-ep-1',
                        playbackUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
                        drmType: DrmType.NONE,
                        regionPolicy: RegionPolicy.GLOBAL,
                        resolution: '1080p',
                        availabilityStart: new Date('2024-01-01'),
                        availabilityEnd: new Date('2028-12-31'),
                        status: 'ACTIVE',
                      },
                    ],
                  },
                },
                {
                  episodeNumber: 2,
                  title: 'Tập 2: Vùng Biển Sâu Kỳ Bí',
                  duration: 3550,
                  overview: 'Khám phá các sinh vật phát sáng dưới độ sâu ngàn mét.',
                  stillUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=1280&q=80',
                  status: EpisodeStatus.ACTIVE,
                  videoSources: {
                    create: [
                      {
                        providerId: providerPublicDomain.id,
                        externalContentId: 'blue-planet-ep-2',
                        playbackUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
                        drmType: DrmType.NONE,
                        regionPolicy: RegionPolicy.GLOBAL,
                        resolution: '1080p',
                        availabilityStart: new Date('2024-01-01'),
                        availabilityEnd: new Date('2028-12-31'),
                        status: 'ACTIVE',
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    },
  });

  console.log('✓ Sample Movies, Series, Seasons, Episodes, VideoSources seeded');
  console.log('--- [CINEORA SEED] Completed Successfully ---');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
