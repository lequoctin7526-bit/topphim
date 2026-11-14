import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IContentProviderAdapter, PlaybackAuthContext, PlaybackAuthorizedStream } from '../provider.interface';
import * as crypto from 'crypto';

@Injectable()
export class PublicDomainAdapter implements IContentProviderAdapter {
  readonly providerId = 'PUBLIC_DOMAIN_ARCHIVE';
  readonly providerName = 'Open Culture & Public Domain Media Foundation';
  private readonly logger = new Logger(PublicDomainAdapter.name);

  constructor(private readonly config: ConfigService) {}

  async authorizePlayback(
    videoSource: any,
    context: PlaybackAuthContext,
  ): Promise<PlaybackAuthorizedStream> {
    const signingKey = this.config.get<string>(
      'PLAYBACK_SIGNING_KEY',
      'cineora_playback_hmac_sha256_signing_key_secure_vault',
    );
    const ttlSeconds = Number(this.config.get<number>('PLAYBACK_URL_TTL_SECONDS', 7200));
    const expiresAt = new Date(Date.now() + ttlSeconds * 1000);
    const expiresUnix = Math.floor(expiresAt.getTime() / 1000);

    // Sign playback URL with HMAC-SHA256 to prevent hotlinking and URL tampering
    const rawData = `${videoSource.externalContentId}:${context.userId}:${expiresUnix}`;
    const signature = crypto.createHmac('sha256', signingKey).update(rawData).digest('hex');

    const separator = videoSource.playbackUrl.includes('?') ? '&' : '?';
    const signedPlaybackUrl = `${videoSource.playbackUrl}${separator}token=${signature}&expires=${expiresUnix}&uid=${context.userId}`;

    return {
      playbackUrl: signedPlaybackUrl,
      drm: {
        type: videoSource.drmType || 'NONE',
        licenseServerUrl: videoSource.licenseUrl,
        certificateUrl: videoSource.certificateUrl,
      },
      subtitles: (videoSource.episode?.subtitles || []).map((s: any) => ({
        id: s.id,
        language: s.language,
        label: s.label,
        format: s.format,
        url: s.url,
        isDefault: s.isDefault,
      })),
      audioTracks: (videoSource.episode?.audioTracks || []).map((a: any) => ({
        id: a.id,
        language: a.language,
        label: a.label,
        isDefault: a.isDefault,
      })),
      expiresAt,
    };
  }

  async validateHealth(): Promise<boolean> {
    return true;
  }
}
