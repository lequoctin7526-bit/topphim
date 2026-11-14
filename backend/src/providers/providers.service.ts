import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { IContentProviderAdapter } from './provider.interface';
import { PublicDomainAdapter } from './adapters/public-domain.adapter';
import { CineoraCdnAdapter } from './adapters/cineora-cdn.adapter';

@Injectable()
export class ProvidersService {
  private readonly logger = new Logger(ProvidersService.name);
  private readonly adapters = new Map<string, IContentProviderAdapter>();

  constructor(
    private readonly publicDomainAdapter: PublicDomainAdapter,
    private readonly cineoraCdnAdapter: CineoraCdnAdapter,
  ) {
    this.registerAdapter(this.publicDomainAdapter);
    this.registerAdapter(this.cineoraCdnAdapter);
  }

  registerAdapter(adapter: IContentProviderAdapter) {
    this.adapters.set(adapter.providerId, adapter);
    this.logger.log(`Registered Content Provider Adapter: [${adapter.providerId}] - ${adapter.providerName}`);
  }

  getAdapter(providerId: string): IContentProviderAdapter {
    const adapter = this.adapters.get(providerId);
    if (!adapter) {
      throw new NotFoundException(`Nhà cung cấp nội dung '${providerId}' chưa được cấu hình hoặc không khả dụng`);
    }
    return adapter;
  }
}
