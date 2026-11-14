import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsInt, Min } from 'class-validator';

export class AuthorizePlaybackDto {
  @ApiProperty({ example: 'ep-uuid', description: 'ID tập phim cần phát' })
  @IsString()
  @IsNotEmpty()
  episodeId: string;

  @ApiProperty({ example: 'device-unique-id-123', description: 'ID định danh thiết bị' })
  @IsString()
  @IsNotEmpty()
  deviceId: string;
}

export class PlaybackHeartbeatDto {
  @ApiProperty({ example: 'session-uuid', description: 'ID phiên phát đang hoạt động' })
  @IsString()
  @IsNotEmpty()
  playbackSessionId: string;

  @ApiProperty({ example: 450, description: 'Vị trí phát hiện tại tính bằng giây' })
  @IsInt()
  @Min(0)
  positionSeconds: number;

  @ApiProperty({ example: 7200, description: 'Tổng thời lượng video tính bằng giây' })
  @IsInt()
  @Min(1)
  durationSeconds: number;
}

export class ClosePlaybackDto {
  @ApiProperty({ example: 'session-uuid', description: 'ID phiên phát' })
  @IsString()
  @IsNotEmpty()
  playbackSessionId: string;

  @ApiProperty({ example: 7100, description: 'Vị trí xem cuối cùng' })
  @IsInt()
  @Min(0)
  positionSeconds: number;

  @ApiProperty({ example: 7200, description: 'Tổng thời lượng' })
  @IsInt()
  @Min(1)
  durationSeconds: number;
}
