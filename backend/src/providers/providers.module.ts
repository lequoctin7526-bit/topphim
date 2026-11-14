import { Module } from '@nestjs/common';
import { ProvidersService } from './providers.service';
import { PublicDomainAdapter } from './adapters/public-domain.adapter';
import { CineoraCdnAdapter } from './adapters/cineora-cdn.adapter';

@Module({
  providers: [ProvidersService, PublicDomainAdapter, CineoraCdnAdapter],
  exports: [ProvidersService],
})
export class ProvidersModule {}
