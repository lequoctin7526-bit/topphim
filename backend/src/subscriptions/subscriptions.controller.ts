import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SubscriptionsService } from './subscriptions.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('Subscriptions & Plans')
@Controller('subscriptions')
export class SubscriptionsController {
  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  @Public()
  @Get('plans')
  @ApiOperation({ summary: 'Lấy danh sách các gói dịch vụ (Free, Premium)' })
  async getPlans() {
    return this.subscriptionsService.getPlans();
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Get('me')
  @ApiOperation({ summary: 'Lấy thông tin gói dịch vụ hiện tại của người dùng' })
  async getCurrentSubscription(@CurrentUser('id') userId: string) {
    return this.subscriptionsService.getCurrentSubscription(userId);
  }

  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @Post('verify')
  @ApiOperation({ summary: 'Xác thực biên lai thanh toán App Store / Google Play In-App Purchase' })
  async verifyReceipt(
    @CurrentUser('id') userId: string,
    @Body() body: { platform: 'ios' | 'android'; receipt: string; productId: string },
  ) {
    return this.subscriptionsService.verifyIapReceipt(userId, body);
  }
}
