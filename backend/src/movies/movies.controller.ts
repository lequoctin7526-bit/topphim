import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { MoviesService } from './movies.service';
import { QueryMoviesDto } from './dto/query-movies.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('Movies & Catalog')
@Controller('movies')
export class MoviesController {
  constructor(private readonly moviesService: MoviesService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'Lấy danh sách phim theo bộ lọc và phân trang' })
  async findAll(@Query() query: QueryMoviesDto) {
    return this.moviesService.findAll(query);
  }

  @Public()
  @Get('featured')
  @ApiOperation({ summary: 'Lấy danh sách banner phim nổi bật cho trang chủ' })
  async getFeatured() {
    return this.moviesService.getFeatured();
  }

  @Public()
  @Get('trending')
  @ApiOperation({ summary: 'Lấy danh sách phim thịnh hành' })
  async getTrending() {
    return this.moviesService.getTrending();
  }

  @Public()
  @Get('latest')
  @ApiOperation({ summary: 'Lấy danh sách phim mới nhất' })
  async getLatest() {
    return this.moviesService.getLatest();
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'Chi tiết phim, mùa, tập và thông tin diễn viên' })
  async findOne(@Param('id') id: string, @CurrentUser('id') userId?: string) {
    return this.moviesService.findOne(id, userId);
  }

  @Public()
  @Get(':id/episodes')
  @ApiOperation({ summary: 'Lấy danh sách tập phim theo mùa' })
  async getEpisodes(@Param('id') id: string) {
    return this.moviesService.getEpisodes(id);
  }

  @Public()
  @Get(':id/related')
  @ApiOperation({ summary: 'Lấy danh sách phim đề xuất liên quan' })
  async getRelated(@Param('id') id: string) {
    return this.moviesService.getRelated(id);
  }
}
