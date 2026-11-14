import { Controller, Get, Delete, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { WatchHistoryService } from './watch-history.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Watch History & Continue Watching')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
@Controller('users/me/history')
export class WatchHistoryController {
  constructor(private readonly historyService: WatchHistoryService) {}

  @Get()
  @ApiOperation({ summary: 'Lấy danh sách tiếp tục xem và lịch sử xem của người dùng' })
  async getHistory(
    @CurrentUser('id') userId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.historyService.getHistory(userId, Number(page), Number(limit));
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Xóa một mục khỏi lịch sử xem' })
  async removeItem(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.historyService.removeItem(userId, id);
  }

  @Delete()
  @ApiOperation({ summary: 'Xóa toàn bộ lịch sử xem' })
  async clearAll(@CurrentUser('id') userId: string) {
    return this.historyService.clearAll(userId);
  }
}
