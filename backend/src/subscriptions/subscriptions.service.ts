import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SubscriptionsService {
  constructor(private readonly prisma: PrismaService) {}

  async getPlans() {
    return this.prisma.subscriptionPlan.findMany({
      where: { status: 'ACTIVE' },
      orderBy: { price: 'asc' },
    });
  }

  async getCurrentSubscription(userId: string) {
    const sub = await this.prisma.userSubscription.findFirst({
      where: {
        userId,
        status: 'ACTIVE',
        expiresAt: { gt: new Date() },
      },
      include: { plan: true },
      orderBy: { expiresAt: 'desc' },
    });

    if (!sub) {
      return {
        planId: 'PLAN_FREE',
        planName: 'Gói Miễn Phí',
        status: 'ACTIVE',
        expiresAt: null,
        maxStreams: 1,
        maxResolution: '1080p',
      };
    }

    return {
      planId: sub.planId,
      planName: sub.plan.name,
      status: sub.status,
      startsAt: sub.startsAt,
      expiresAt: sub.expiresAt,
      maxStreams: sub.plan.maxStreams,
      maxResolution: sub.plan.maxResolution,
    };
  }

  async verifyIapReceipt(userId: string, receiptData: { platform: 'ios' | 'android'; receipt: string; productId: string }) {
    // In compliance with Phần XI:
    // "Chưa có tài khoản thanh toán thì vẫn phải xây dựng giao diện và API ở trạng thái chưa kích hoạt, không giả lập giao dịch thành công."
    throw new BadRequestException({
      code: 'BILLING_GATEWAY_PENDING_CONFIG',
      message: 'Cổng thanh toán In-App Purchase / Google Play Billing đang ở chế độ chờ cấu hình tài khoản nhà phát triển chính thức.',
    });
  }
}
