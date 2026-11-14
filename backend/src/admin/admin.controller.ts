import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Role } from '@prisma/client';

@ApiTags('Admin & CMS Management')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.SUPER_ADMIN, Role.CONTENT_MANAGER)
@ApiBearerAuth()
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('analytics')
  @ApiOperation({ summary: 'Thống kê tổng quan hệ thống (người dùng, số luồng xem đồng thời, top phim)' })
  async getAnalytics() {
    return this.adminService.getAnalytics();
  }

  @Post('movies')
  @ApiOperation({ summary: 'Tạo phim/series mới' })
  async createMovie(@Body() body: any, @CurrentUser('id') adminId: string) {
    return this.adminService.createMovie(body, adminId);
  }

  @Patch('movies/:id')
  @ApiOperation({ summary: 'Cập nhật thông tin phim' })
  async updateMovie(
    @Param('id') id: string,
    @Body() body: any,
    @CurrentUser('id') adminId: string,
  ) {
    return this.adminService.updateMovie(id, body, adminId);
  }

  @Delete('movies/:id')
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: 'Xóa phim khỏi hệ thống (Chỉ Super Admin)' })
  async deleteMovie(@Param('id') id: string, @CurrentUser('id') adminId: string) {
    return this.adminService.deleteMovie(id, adminId);
  }

  @Get('audit-logs')
  @Roles(Role.SUPER_ADMIN)
  @ApiOperation({ summary: 'Xem nhật ký thay đổi quản trị (Audit Trail)' })
  async getAuditLogs(@Query('page') page = 1, @Query('limit') limit = 50) {
    return this.adminService.getAuditLogs(Number(page), Number(limit));
  }
}
