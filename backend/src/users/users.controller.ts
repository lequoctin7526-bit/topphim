import { Controller, Patch, Delete, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiBody } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('User Profile & Account')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Patch('me')
  @ApiOperation({ summary: 'Cập nhật thông tin hồ sơ (Tên hiển thị, Avatar)' })
  @ApiBody({
    schema: {
      properties: {
        displayName: { type: 'string' },
        avatarUrl: { type: 'string' },
      },
    },
  })
  async updateProfile(
    @CurrentUser('id') userId: string,
    @Body() body: { displayName?: string; avatarUrl?: string },
  ) {
    return this.usersService.updateProfile(userId, body);
  }

  @Delete('me')
  @ApiOperation({
    summary: 'Xóa tài khoản vĩnh viễn (Tuân thủ Apple App Store & GDPR Account Deletion)',
  })
  async deleteAccount(@CurrentUser('id') userId: string) {
    return this.usersService.deleteAccount(userId);
  }
}
