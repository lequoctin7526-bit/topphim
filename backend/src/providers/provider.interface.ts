export interface PlaybackAuthContext {
  userId: string;
  movieId: string;
  episodeId: string;
  userIp: string;
  userCountry: string;
  subscriptionPlanId: string;
  maxStreams: number;
  maxResolution: string;
  deviceId: string;
}

export interface PlaybackAuthorizedStream {
  playbackUrl: string;
  drm: {
    type: 'NONE' | 'WIDEVINE' | 'FAIRPLAY' | 'CLEARKEY';
    licenseServerUrl?: string | null;
    certificateUrl?: string | null;
    drmToken?: string | null;
  };
  subtitles: {
    id: string;
    language: string;
    label: string;
    format: 'VTT' | 'SRT';
    url: string;
    isDefault: boolean;
  }[];
  audioTracks: {
    id: string;
    language: string;
    label: string;
    isDefault: boolean;
  }[];
  expiresAt: Date;
}

export interface IContentProviderAdapter {
  readonly providerId: string;
  readonly providerName: string;
  authorizePlayback(
    videoSource: any,
    context: PlaybackAuthContext,
  ): Promise<PlaybackAuthorizedStream>;
  validateHealth(): Promise<boolean>;
}
