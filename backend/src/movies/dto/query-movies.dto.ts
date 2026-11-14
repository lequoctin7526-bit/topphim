import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsInt, Min, Max, IsEnum } from 'class-validator';
import { Type } from 'class-transformer';
import { MovieType } from '@prisma/client';

export class QueryMoviesDto {
  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @ApiPropertyOptional({ default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number = 20;

  @ApiPropertyOptional({ description: 'Slug thể loại (e.g. hanh-dong, lang-man)' })
  @IsOptional()
  @IsString()
  genre?: string;

  @ApiPropertyOptional({ description: 'Mã quốc gia (e.g. VN, KR, US, JP)' })
  @IsOptional()
  @IsString()
  country?: string;

  @ApiPropertyOptional({ enum: MovieType, description: 'MOVIE hoặc SERIES' })
  @IsOptional()
  @IsEnum(MovieType)
  type?: MovieType;

  @ApiPropertyOptional({ description: 'Năm phát hành (e.g. 2024)' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  year?: number;

  @ApiPropertyOptional({ enum: ['latest', 'popular', 'rating'], default: 'latest' })
  @IsOptional()
  @IsString()
  sortBy?: 'latest' | 'popular' | 'rating' = 'latest';
}
