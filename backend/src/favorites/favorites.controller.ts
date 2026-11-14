import { Controller, Get, Post, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiBody } from '@nestjs/swagger';
import { FavoritesService } from './favorites.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Favorites')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
@Controller('users/me/favorites')
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  @Get()
  @ApiOperation({ summary: 'Lấy danh sách phim yêu thích của người dùng' })
  async getFavorites(
    @CurrentUser('id') userId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.favoritesService.getUserFavorites(userId, Number(page), Number(limit));
  }

  @Post()
  @ApiOperation({ summary: 'Thêm phim vào danh sách yêu thích' })
  @ApiBody({ schema: { properties: { movieId: { type: 'string' } }, required: ['movieId'] } })
  async addFavorite(@CurrentUser('id') userId: string, @Body('movieId') movieId: string) {
    return this.favoritesService.addFavorite(userId, movieId);
  }

  @Delete(':movieId')
  @ApiOperation({ summary: 'Xóa phim khỏi danh sách yêu thích' })
  async removeFavorite(
    @CurrentUser('id') userId: string,
    @Param('movieId') movieId: string,
  ) {
    return this.favoritesService.removeFavorite(userId, movieId);
  }
}
