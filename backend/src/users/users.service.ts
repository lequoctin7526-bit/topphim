import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async updateProfile(userId: string, data: { displayName?: string; avatarUrl?: string }) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        displayName: data.displayName?.trim(),
        avatarUrl: data.avatarUrl,
      },
    });

    return {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      role: user.role,
    };
  }

  async deleteAccount(userId: string) {
    // Delete user cascades to favorites, watch_history, subscriptions, playback_sessions
    await this.prisma.user.delete({
      where: { id: userId },
    });

    return {
      success: true,
      message: 'Tài khoản và toàn bộ dữ liệu liên quan đã được xóa vĩnh viễn theo yêu cầu.',
    };
  }
}
