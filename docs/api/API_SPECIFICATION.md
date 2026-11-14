# CINEORA REST API Specification (v1)

> **Base URL:** `/api/v1`  
> **Documentation:** Swagger UI at `/api/docs`  
> **Headers:**  
> - `Content-Type: application/json`  
> - `Authorization: Bearer <access_token>` (for authenticated routes)  
> - `X-Device-Id: <uuid>` (for session & playback management)

---

## 1. Authentication Endpoints (`/api/v1/auth`)

### `POST /auth/register`
Create a new user account.
- **Request Body:**
  ```json
  {
    "email": "user@example.com",
    "password": "StrongPassword123!",
    "displayName": "Nguyễn Văn A"
  }
  ```
- **Response `201 Created`:**
  ```json
  {
    "success": true,
    "user": {
      "id": "c1f7b0a8-...",
      "email": "user@example.com",
      "displayName": "Nguyễn Văn A",
      "role": "USER",
      "avatarUrl": null
    },
    "tokens": {
      "accessToken": "eyJhbGciOi...",
      "refreshToken": "d7a4b8...",
      "expiresIn": 900
    }
  }
  ```

### `POST /auth/login`
Authenticate existing user.
- **Request Body:**
  ```json
  {
    "email": "user@example.com",
    "password": "StrongPassword123!"
  }
  ```
- **Response `200 OK`:** Same as register response.

### `POST /auth/refresh`
Rotate refresh token and issue a new access token.
- **Request Body:**
  ```json
  {
    "refreshToken": "d7a4b8..."
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "e8c9f0...",
    "expiresIn": 900
  }
  ```

### `POST /auth/logout`
Invalidate current user refresh token.
- **Response `200 OK`:** `{ "success": true, "message": "Logged out successfully" }`

### `GET /auth/me`
Retrieve profile of currently authenticated user.
- **Response `200 OK`:**
  ```json
  {
    "id": "c1f7b0a8-...",
    "email": "user@example.com",
    "displayName": "Nguyễn Văn A",
    "role": "USER",
    "avatarUrl": "https://...",
    "subscription": {
      "planId": "PLAN_PREMIUM_MONTHLY",
      "planName": "Premium Tháng",
      "status": "ACTIVE",
      "expiresAt": "2026-12-31T23:59:59Z"
    }
  }
  ```

---

## 2. Movies & Catalog Endpoints (`/api/v1/movies`)

### `GET /movies`
List movies with advanced filters and pagination.
- **Query Parameters:**
  - `page`: default 1
  - `limit`: default 20 (max 50)
  - `genre`: slug (e.g., `hanh-dong`)
  - `country`: country code (e.g., `VN`, `KR`, `US`)
  - `type`: `MOVIE` or `SERIES`
  - `year`: integer (e.g., `2024`)
  - `sortBy`: `latest`, `popular`, `rating`
- **Response `200 OK`:**
  ```json
  {
    "data": [
      {
        "id": "m1-uuid",
        "title": "Mắt Biếc",
        "originalTitle": "Dreamy Eyes",
        "slug": "mat-biec",
        "posterUrl": "https://...",
        "backdropUrl": "https://...",
        "releaseYear": 2019,
        "duration": 117,
        "type": "MOVIE",
        "ratingAverage": 8.5,
        "genres": [{ "id": "g1", "name": "Lãng Mạn", "slug": "lang-man" }]
      }
    ],
    "meta": {
      "page": 1,
      "limit": 20,
      "totalItems": 142,
      "totalPages": 8
    }
  }
  ```

### `GET /movies/featured`
Returns top carousel banners (high-res backdrop, synopsis, trailer).

### `GET /movies/trending`
Returns trending movies and series calculated by recent watch counts.

### `GET /movies/latest`
Returns newly added movies sorted by `created_at` descending.

### `GET /movies/:id`
Full movie detail including genres, actors, directors, seasons (for series), and user status (isFavorited, userRating).

### `GET /movies/:id/episodes`
Returns list of seasons and episodes with stills and duration.

### `GET /movies/:id/related`
Returns recommended similar titles based on genres and cast.

---

## 3. Search Endpoints (`/api/v1/search`)

### `GET /search?q={keyword}&page=1&limit=20`
Full-text search supporting:
- Accent-insensitive Vietnamese matching (e.g. `mat biec` matches `Mắt Biếc`)
- Original English titles
- Actor & Director matching

### `GET /search/suggestions?q={prefix}`
Debounced auto-complete suggestions returning top 5 titles and keywords.

---

## 4. Playback Engine Endpoints (`/api/v1/playback`)

### `POST /playback/authorize`
**Crucial entitlement gate:** Validates user, subscription tier, country policy (Vietnam), and issues a signed, time-limited manifest stream.
- **Headers:** `Authorization: Bearer <token>`, `X-Device-Id: <uuid>`
- **Request Body:**
  ```json
  {
    "episodeId": "ep-uuid",
    "movieId": "movie-uuid"
  }
  ```
- **Response `200 OK`:**
  ```json
  {
    "playbackSessionId": "sess-uuid",
    "playbackUrl": "https://cdn.cineora.tv/hls/ep-uuid/master.m3u8?token=hmac_signed_token&expires=1731600000",
    "drm": {
      "type": "NONE",
      "licenseServerUrl": null
    },
    "subtitles": [
      {
        "language": "vi",
        "label": "Tiếng Việt",
        "format": "VTT",
        "url": "https://cdn.cineora.tv/subs/ep-uuid/vi.vtt",
        "isDefault": true
      }
    ],
    "audioTracks": [
      {
        "language": "vi",
        "label": "Gốc (Tiếng Việt)",
        "isDefault": true
      }
    ],
    "resumePositionSeconds": 342,
    "maxResolution": "1080p",
    "expiresAt": "2026-11-14T12:00:00Z"
  }
  ```
- **Denial Responses:**
  - `403 Forbidden` (`CONCURRENT_STREAM_LIMIT_EXCEEDED`): Max allowed devices playing simultaneously.
  - `403 Forbidden` (`GEO_RESTRICTED`): Content not licensed in user's geographic region.
  - `403 Forbidden` (`PREMIUM_REQUIRED`): Content reserved for Premium tier.

### `POST /playback/heartbeat`
Keep-alive every 10 seconds during playback; updates watch history and prevents duplicate streams.
- **Request Body:**
  ```json
  {
    "playbackSessionId": "sess-uuid",
    "positionSeconds": 352,
    "durationSeconds": 7200
  }
  ```

### `POST /playback/close`
Closes session cleanly, marks completion status if position > 90% of duration.

---

## 5. User Features Endpoints

### Favorites (`/api/v1/users/me/favorites`)
- `GET /users/me/favorites`: List user's watchlist with pagination.
- `POST /users/me/favorites`: Add movie to favorites (`{ "movieId": "uuid" }`).
- `DELETE /users/me/favorites/:movieId`: Remove movie from favorites.

### Watch History (`/api/v1/users/me/history`)
- `GET /users/me/history`: List continue watching items with progress percentage.
- `DELETE /users/me/history/:id`: Remove specific item from history.
- `DELETE /users/me/history`: Clear all watch history.

### Ratings & Reports
- `POST /movies/:id/rate`: Submit or update rating (1.0 to 10.0).
- `POST /reports`: Report broken video source, bad subtitle, or audio desync.

---

## 6. Admin & Management Endpoints (`/api/v1/admin`)
*(Protected by `RolesGuard(Role.SUPER_ADMIN, Role.CONTENT_MANAGER)`)*

- `GET /admin/analytics`: System stats (active sessions, total views, top movies).
- `POST /admin/movies`: Create new movie/series with TMDB import support.
- `PATCH /admin/movies/:id`: Update movie metadata.
- `DELETE /admin/movies/:id`: Archive/Delete movie.
- `POST /admin/episodes`: Add season episode.
- `POST /admin/providers`: Register licensed content provider.
- `POST /admin/video-sources`: Attach validated licensed HLS/DASH source to episode.
- `GET /admin/audit-logs`: Review admin activity logs.
