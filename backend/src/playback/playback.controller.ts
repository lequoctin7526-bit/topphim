import { Controller, Post, Body, UseGuards, Req, Ip } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse } from '@nestjs/swagger';
import { PlaybackService } from './playback.service';
import { AuthorizePlaybackDto, PlaybackHeartbeatDto, ClosePlaybackDto } from './dto/playback.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Playback Engine & Authorization')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
@Controller('playback')
export class PlaybackController {
  constructor(private readonly playbackService: PlaybackService) {}

  @Post('authorize')
  @ApiOperation({
    summary: 'Xác thực quyền xem, kiểm tra giới hạn thiết bị, cấp URL HLS/DASH có chữ ký',
  })
  @ApiResponse({ status: 200, description: 'Cấp quyền xem và đường dẫn phát thành công' })
  @ApiResponse({ status: 403, description: 'Bị từ chối do quá thiết bị hoặc không thuộc vùng cấp phép' })
  async authorize(
    @Body() dto: AuthorizePlaybackDto,
    @CurrentUser() user: any,
    @Ip() clientIp: string,
    @Req() req: any,
  ) {
    const geoCountry = req.headers['cf-ipcountry'] || req.headers['x-country-code'] || 'VN';
    return this.playbackService.authorize(dto, user, clientIp || '127.0.0.1', geoCountry);
  }

  @Post('heartbeat')
  @ApiOperation({ summary: 'Gửi nhịp tim (heartbeat) định kỳ 10s để duy trì phiên và lưu tiến trình xem' })
  async heartbeat(@Body() dto: PlaybackHeartbeatDto, @CurrentUser('id') userId: string) {
    return this.playbackService.heartbeat(dto, userId);
  }

  @Post('close')
  @ApiOperation({ summary: 'Đóng phiên xem khi thoát video player và cập nhật trạng thái hoàn thành' })
  async close(@Body() dto: ClosePlaybackDto, @CurrentUser('id') userId: string) {
    return this.playbackService.close(dto, userId);
  }
}
