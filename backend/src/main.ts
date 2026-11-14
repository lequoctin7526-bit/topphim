import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const logger = new Logger('CineoraBootstrap');
  const app = await NestFactory.create(AppModule);

  const config = app.get(ConfigService);
  const port = config.get<number>('PORT', 3000);

  // Global Prefix: /api/v1
  app.setGlobalPrefix('api/v1');

  // Global Validation Pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Global Exception Filter
  app.useGlobalFilters(new AllExceptionsFilter());

  // CORS Configuration
  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  // OpenAPI / Swagger Documentation
  const swaggerConfig = new DocumentBuilder()
    .setTitle('CINEORA Streaming API')
    .setDescription(
      'Enterprise REST API documentation for CINEORA Mobile (iOS & Android) and Admin CMS.\n\n"Your Cinema. Everywhere."',
    )
    .setVersion('1.0.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'Authorization',
        description: 'Nhập access token JWT',
        in: 'header',
      },
      'bearer',
    )
    .addTag('Authentication', 'Đăng ký, đăng nhập, làm mới token, thông tin hồ sơ')
    .addTag('Movies & Catalog', 'Kho phim, chi tiết phim, mùa và tập phim')
    .addTag('Search', 'Tìm kiếm phim không dấu tiếng Việt và gợi ý nhanh')
    .addTag('Playback Engine & Authorization', 'Xác thực quyền xem, chữ ký stream URL, DRM, nhịp tim')
    .addTag('Favorites', 'Danh sách phim yêu thích cá nhân')
    .addTag('Watch History & Continue Watching', 'Lịch sử xem và tiếp tục xem')
    .addTag('Subscriptions & Plans', 'Gói cước và xác thực biên lai App Store / Google Play')
    .addTag('User Profile & Account', 'Hồ sơ người dùng và xóa tài khoản vĩnh viễn')
    .addTag('Admin & CMS Management', 'Quản trị nội dung, phân quyền RBAC và thống kê')
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document, {
    customSiteTitle: 'CINEORA API Docs',
    customCss: '.swagger-ui .topbar { background-color: #090909; border-bottom: 2px solid #E50914; }',
  });

  await app.listen(port);
  logger.log(`🚀 CINEORA Backend is running at http://localhost:${port}/api/v1`);
  logger.log(`📖 Swagger API Documentation is available at http://localhost:${port}/api/docs`);
}

bootstrap();
