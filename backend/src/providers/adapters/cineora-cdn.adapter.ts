import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IContentProviderAdapter, PlaybackAuthContext, PlaybackAuthorizedStream } from '../provider.interface';
import * as crypto from 'crypto';

@Injectable()
export class CineoraCdnAdapter implements IContentProviderAdapter {
  readonly providerId = 'CINEORA_ORIGIN_CDN';
  readonly providerName = 'CINEORA Edge Streaming Origin CDN';
  private readonly logger = new Logger(CineoraCdnAdapter.name);

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

    const rawData = `cdn:${videoSource.externalContentId}:${context.userId}:${expiresUnix}`;
    const token = crypto.createHmac('sha256', signingKey).update(rawData).digest('hex');

    const separator = videoSource.playbackUrl.includes('?') ? '&' : '?';
    const signedUrl = `${videoSource.playbackUrl}${separator}hdnts=exp=${expiresUnix}~acl=*~hmac=${token}`;

    return {
      playbackUrl: signedUrl,
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
